#include "Hitters.as";

void onInit(CBlob@ this)
{
    this.set_u8("frame", 0);
    this.Tag("magic_circle");
    this.SetLightRadius(effectRadius);
    this.SetLightColor(SColor(255,255,0,0));
    this.SetLight(true);
}

const int effectRadius = 8*10;

void onTick(CBlob@ this)
{
    bool fullCharge = this.hasTag("fullCharge");
    bool reverse = this.hasTag("reverse");

    if((!this.hasTag("finished") || reverse)  && getGameTime() % 2 == 0)
    {
        this.add_u8("frame", reverse ? -1 : 1);
        if(this.get_u8("frame") == 29)
        {
            this.Tag("finished");
        }
    }

    if(reverse && this.get_u8("frame") < 1) this.server_Die();

    if(!this.hasTag("finished")) return;

    Vec2f pos = this.getInterpolatedPosition();
    CMap@ map = getMap();
    CBlob@[] blobs;
    map.getBlobsInRadius(pos,effectRadius,@blobs);

    if(getGameTime() % (fullCharge ? 5 : 10) == 0 && !this.hasTag("reverse"))
    {

        for(float i = 0; i < blobs.length; i++)
        {
            CBlob@ b = blobs[i];
            if( (b.getName() != "skeleton" && b.getName() != "zombie" && b.getName() != "zombieknight" && b.getPlayer() is null ) || b.getTeamNum() == this.getTeamNum()) continue;
            Vec2f bPos = b.getInterpolatedPosition();

            Vec2f norm = bPos-pos;
            norm.Normalize();

            for(int j = 1; j <= this.getDistanceTo(b); j+= XORRandom(5))
            {
                Vec2f pPos = pos + norm*j;
                float rx = XORRandom(100)/100.0 - 0.5;
                float ry = (XORRandom(100)/100.0)- 0.5;
                if(isClient())
                {
                    ParticleBlood(pPos,Vec2f(rx,ry),SColor(255,XORRandom(191) + 64,XORRandom(50),XORRandom(50)));
                }

            }


            this.getSprite().PlaySound("zap.ogg",10);
            if(getNet().isServer())
            {
                uint8 t = 11;
                float dmg = 0.2;
                b.server_Hit(b, bPos, Vec2f(0,0),dmg,Hitters::hits::burn);
            }

            int ammount = XORRandom(15) + 5;

                for(int i = 0; i < ammount; i++)
                {
                    int rx = XORRandom(10) - 5;
                    int ry = XORRandom(4) - 2;
                    if(isClient())
                    {
                        CParticle@ p = ParticlePixel(bPos, Vec2f(rx,ry), SColor(0,255,0,0),true,XORRandom(10));
                        if(p !is null)
                        {
                            p.gravity = Vec2f(0,0);
                            p.damping = (XORRandom(25) + 75)/100.0;
                        }
                    }
                }

        }
    }
}

const float rotateSpeed = 1;

void onInit(CSprite@ this)
{
    {
        CSpriteLayer@ s = this.addSpriteLayer("circle","team_color_circle.png",100,100);
        s.setRenderStyle(RenderStyle::Style::light);
        s.ScaleBy(Vec2f(1.562,1.562));
        s.SetRelativeZ(-2);
    }
    {
       CSpriteLayer@ s = this.addSpriteLayer("scythes","Arcane_Scythes.png",124,124);
       s.SetRelativeZ(-1);
    }
    this.ScaleBy(Vec2f(1.4,1.4));
    //this.SetZ(0);

    this.PlaySound("circle_create.ogg",10);
    //this.setRenderStyle(RenderStyle::light);

    //this.ReloadSprites(this.getBlob().getTeamNum(),0);

}

void onTick(CSprite@ this)
{
    bool reverse = this.getBlob().hasTag("reverse");
    CBlob@ b = this.getBlob();
    CSpriteLayer@ scythes = this.getSpriteLayer("scythes");
    if(b.get_u8("frame") != 29 || reverse)
    {
        this.SetFrame(b.get_u8("frame"));
        scythes.SetFrame(b.get_u8("frame"));
    }
    else
    {
        this.RotateByDegrees((b.hasTag("fullCharge") ? rotateSpeed*2 : rotateSpeed) / (b.get_u8("despelled") + 1) ,Vec2f(0,0));
        scythes.RotateByDegrees(-1 * ((b.hasTag("fullCharge") ? rotateSpeed*2 : rotateSpeed) / (b.get_u8("despelled") + 1)),Vec2f_zero);
    }
}

void onDie(CBlob@ this)
{
    this.getSprite().PlaySound("circle_create.ogg",10);
}
