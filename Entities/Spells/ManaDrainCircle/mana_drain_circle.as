#include "MagicCommon.as";

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

    CMap@ map = getMap();
    CBlob@[] blobs;
    map.getBlobsInRadius(this.getPosition(),effectRadius,@blobs);

    for(int i = 0; i < blobs.length; i++)
    {
        CBlob@ b = blobs[i];

        if(b.getPlayer() is null || b.getTeamNum() == this.getTeamNum()) continue;
        if(isClient())
        {
            Vec2f vel = b.getVelocity();
            b.setVelocity(Vec2f(vel.x * 0.5,vel.y * 0.9));

            if(getGameTime() % 20 != 0) return;

            ManaInfo@ manaInfo;
            if (!b.get( "manaInfo", @manaInfo )) 
            {
                return;
            }
        
            float mana = manaInfo.mana;
            mana -= (fullCharge ? 4 : 3);

            if(mana >= 0)
            {
                manaInfo.mana -= manaInfo.manaRegen + (fullCharge ? 4 : 3);
            }
        }

        if (isServer())
		{
            if(getGameTime() % 20 != 0) return;
			CBlob@ orb = server_CreateBlob( "effect_missile_circle", this.getTeamNum(), b.getPosition() ); 
			if (orb !is null)
			{
				orb.set_string("effect", "mana");
				orb.set_u8("mana_used", 1);
				orb.set_u8("caster_mana", 3);
                orb.set_bool("silent", true);

				orb.IgnoreCollisionWhileOverlapped( this );
                Vec2f orbVel = Vec2f( 0.1f , 0 ).RotateByDegrees(XORRandom(360));
				orb.setVelocity( orbVel );
			}
		}

        if(isClient())
        {
            for(int i = 0; i < 30; i++)
            {
                CParticle@ p = ParticlePixelUnlimited(b.getPosition(), b.getVelocity() + Vec2f(XORRandom(12) - 6, XORRandom(12) - 6), randomManaColor(), true);
                if(p !is null)
                {
                    p.gravity = Vec2f(0,0);
                    p.fastcollision = true;
                    p.bounce = 0;
                    p.timeout = 10;
                }
            }
        }
            
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


    /*CParticle@ p = ParticlePixel(blob.getPosition() + Vec2f(XORRandom(effectRadius*2) - effectRadius, XORRandom(effectRadius*2) - effectRadius),Vec2f(0,-1), randomManaColor(), true,30);
    if(p !is null)
    {
        p.gravity = Vec2f(0,0);
        p.damping = 1;
        p.collides = false;
    }*/
    const Vec2f aimPos = blob.getPosition();
    //print(currentCharge +'');
                
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
    return SColor(255,XORRandom(85) + 100,XORRandom(80),XORRandom(55) + 200);
}