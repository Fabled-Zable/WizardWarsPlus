#include "MagicCommon.as";
#include "EffectMissileEnum.as";

Random _mana_circle_r(53124); //with the seed, I extract a float ranging from 0 to 1 for random events

void onInit(CBlob@ this)
{
    this.set_u8("frame", 0);
    this.Tag("magic_circle");
    this.getShape().SetGravityScale(0);
    if(this.getTeamNum() == 0){this.set("colour",SColor(255,100,255,255));}
    else{this.set("colour",SColor(255,255,100,100));}
}

f32 effectRadius = 73;

void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();
    
    bool fullCharge = this.hasTag("fullCharge");
    bool reverse = this.hasTag("reverse");

    if((!this.hasTag("finished") || reverse)  && getGameTime() % 2 == 0)
    {
        this.add_u8("frame", reverse ? -1 : 1);
        if(this.get_u8("frame") == 23)
        {
            this.Tag("finished");
        }
    }

    if(reverse && this.get_u8("frame") < 1) this.server_Die();

    if(!this.hasTag("finished")) return;

    CMap@ map = getMap(); //standard map check
	if(map is null)
	{return;}

    bool drainedMana = false;

    CBlob@[] blobs;
    map.getBlobsInRadius(this.getPosition(),effectRadius,@blobs);

    for(int i = 0; i < blobs.length; i++)
    {
        CBlob@ b = blobs[i];
		if (b is null)
		{continue;}

        if ( !b.hasTag("flesh") || this.getTeamNum() == b.getTeamNum() ) //if not made of flesh or not same team, abort
        {continue;}
        
        Vec2f vel = b.getVelocity();
        b.setVelocity(Vec2f(vel.x * 0.5,vel.y * 0.9));

        if(getGameTime() % 20 != 0) //only run code below every 20th tick
        {continue;}

        ManaInfo@ manaInfo;
        if ( !b.get( "manaInfo", @manaInfo ) ) 
        {continue;}

        drainedMana = true;
        
        s32 currentMana = manaInfo.mana;
        s32 manaRegen = b.get_s32("mana regen rate");
        s32 manaDrain = fullCharge ? manaRegen+1 : manaRegen;
        if ( currentMana >= 0 && (currentMana - manaDrain) < currentMana )
        {
            manaInfo.mana -= manaDrain;
        }

        if(isClient())
        {
            float pRot = 180.0f;
            Vec2f pVel = Vec2f_zero;
            for(int i = 0; i < 80; i++) //particle splash
            {
                pRot = 360.0f * _mana_circle_r.NextFloat();
                pVel = Vec2f( 5.0f*_mana_circle_r.NextFloat() , 0 );
                pVel.RotateByDegrees(pRot);
                u16 pTimeout = 10 * _mana_circle_r.NextFloat();

                CParticle@ p = ParticlePixelUnlimited(b.getPosition(), b.getVelocity() + pVel, randomManaColor(), true);
                if(p !is null)
                {
                    p.gravity = Vec2f(0,0);
                    p.fastcollision = true;
                    p.bounce = 0;
                    p.damping = 0.95f;
                    p.timeout = pTimeout + 10;
                }
            }
        }

        if (isServer()) //compensation mana creation
		{
			CBlob@ orb = server_CreateBlob( "effect_missile_circle", this.getTeamNum(), b.getPosition() ); 
			if (orb !is null)
			{
				orb.set_u8("effect", mana_effect_missile);
				orb.set_u8("mana_used", 1);
				orb.set_u8("caster_mana", 3);
                orb.set_bool("silent", true);

                Vec2f orbVel = Vec2f( 0.1f , 0 ).RotateByDegrees(XORRandom(360));
				orb.setVelocity( orbVel );
			}
		}
    }

    if ( isClient() && drainedMana )
    {
        sprite.PlaySound("ManaDraining.ogg", 0.4f, 1.0f + (_mana_circle_r.NextFloat()*0.2f) );
    }
}

void onInit(CSprite@ this)
{
    this.addSpriteLayer("bar","mana_drain_circle2.png",153,153);
    CSpriteLayer@ s = this.addSpriteLayer("circle","team_color_circle.png",100,100);
    s.setRenderStyle(RenderStyle::Style::light);
    s.ScaleBy(Vec2f(1.45,1.45));
    s.SetRelativeZ(-1);
}

void onTick(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    CSpriteLayer@ bar = this.getSpriteLayer("bar");
    bar.SetVisible(true);
    bar.SetFrame(blob.get_u8("frame"));

    this.SetFrame(blob.get_u8("frame"));

    bool fullCharge = blob.hasTag("fullCharge");
    float rotateSpeed = fullCharge ? 2 : 1;

    rotateSpeed /= (blob.get_u8("despelled") + 1);

    this.RotateBy(rotateSpeed, Vec2f_zero);
    bar.RotateBy(rotateSpeed * -2, Vec2f_zero);

    const Vec2f aimPos = blob.getPosition();
                
    //PARTICLESSSS
    CParticle@[] particleList;
    SColor col;
    blob.get("ParticleList",particleList);
    blob.get("colour",col);

    for(int a = 0; a < 2 + XORRandom(4); a++)
    {
        CParticle@ p = ParticlePixelUnlimited(getRandomVelocity(0,70,360) + aimPos, Vec2f(0,0), col,
            true);
        if(p !is null)
        {
            p.fastcollision = true;
            p.gravity = Vec2f(0,0);
            p.bounce = 0;
            p.Z = -10;
            p.timeout = 90;
            particleList.push_back(p);
        }
    }


    for(int a = 0; a < particleList.length(); a++)
    {
        CParticle@ particle = particleList[a];
        //check
        if(particle.timeout < 1)
        {
            particleList.erase(a);
            a--;
            continue;
        }

        //Gravity
        Vec2f tempGrav = Vec2f(0,0);
        tempGrav.x = -(particle.position.x - aimPos.x);
        tempGrav.y = -(particle.position.y - aimPos.y);
        tempGrav.RotateBy(45);


        //Colour
        SColor col = particle.colour;
        col.setRed(col.getRed() - 1);
        col.setGreen(col.getGreen() - 1);
        col.setBlue(col.getBlue() - 1);

        //set stuff
        particle.colour = col;
        particle.forcecolor = col;
        particle.gravity = tempGrav / 2400;

        //particleList[a] = @particle;

    }
    blob.set("ParticleList",particleList);

}

SColor randomManaColor()
{
    u8 red = 100 + (85*_mana_circle_r.NextFloat());
    u8 green = 80*_mana_circle_r.NextFloat();
    u8 blue = 200 + (55*_mana_circle_r.NextFloat());
    return SColor( 255 , red , green , blue );
}