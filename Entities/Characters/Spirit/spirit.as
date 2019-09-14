#include "spiritCommon.as";

void onInit(CBlob@ this)
{
    CShape@ shape = this.getShape();
    shape.SetGravityScale(0);
    shape.getConsts().mapCollisions = false;

    Energy@ e = Energy(100,10,1);
    this.set("energy",@e);
    this.Tag("invincible");
}

void onTick(CBlob@ this)
{
    Energy@ e;
    this.get("energy", @e);

    e.update(this);

    if(this.isKeyJustPressed(key_inventory))
    {
        this.ClearGridMenus();
    }

    CControls@ controls = getControls();

    if(this.isKeyJustPressed(key_use))
    {
        
        //use spirit power a bit
        CBlob@[] blobs;
        getMap().getBlobsInRadius(this.getPosition(),8,@blobs);

        for(int i = 0; i < blobs.length; i++)
        {
            s32 cost = 0;
            bool interacted = false;
            CBlob@ b = blobs[i];
            string name = b.getConfig();

            if(b.getPlayer() is null && !b.hasTag("dead") && b.hasTag("possessable"))
            {
                b.server_setTeamNum(this.getTeamNum());
                b.server_SetPlayer(this.getPlayer());

                b.set("energy",@e);
                interacted = true;

                b.getSprite().PlaySound("possess.ogg",2.5);

                this.server_Die();
            }

            u32 energy = e.energy;

            if(name == "mat_bombs")
            {   
                cost = 5;
                if(interacted = energy >= cost)
                {
                    if(isServer()) 
                    {
                        server_CreateBlob('bomb',b.getTeamNum(),b.getPosition());
                        b.server_Die();
                    }
                }

            }
            else if(name == "bomb")
            {
                cost = 5;
                if( energy >= cost)
                {
                    interacted = true;     
                    if(isServer())
                    {
                        server_CreateBlob('mat_bombs',b.getTeamNum(),b.getPosition());
                        b.server_Die();
                    }
                    b.Tag("ploxDontBoom");
                    b.Sync("ploxDontBoom",true);
                }
            }
            else if(name == "keg")
            {
                cost = 30;
                if(energy >= cost)
                {
                    interacted = true;     
                    if(b.hasTag("exploding"))
                    {
                        b.SendCommand(b.getCommandID("deactivate"));
                    }
                    else 
                    {
                        b.SendCommand(b.getCommandID("activate"));
                    }
                }
            }
            else if(name == "spikes")
            {
                cost = 0;
                if(interacted = energy >= cost)
                {                
                    b.set_u8("popup state",2);//extended
                }
            }


            if(!interacted) continue;

            e.setEnergy(e.energy - cost,this);
            for(int i =0; i < 15; i++)
            {
                CParticle@ p = ParticlePixel(b.getPosition(),getRandomVelocity(0,1, 360), SColor(255,255,255,255),true,60);
                if(p !is null)
                {
                    p.gravity = p.gravity * 0.1;
                    p.fastcollision = true;
                }
            }
            break;
        }
    }

}


void onSendCreateData( CBlob@ this, CBitStream@ stream ) 
{
    Energy@ e;
    this.get("energy",@e);
    stream.write_u32(e.energy);
}

bool onReceiveCreateData( CBlob@ this, CBitStream@ stream )
{
    Energy@ e;
    this.get("energy",@e);
    u32 energy = stream.read_u32();
    e.energy = energy;

    return true;
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    if(customData == 11)//suicide
    {
        return damage;
    }
    return 0;
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}