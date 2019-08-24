#include "NecromancerCommon.as";
#include "MagicCommon.as";

void SummonBlob(CBlob@ this, string name, Vec2f pos, int team)
{
    if (getNet().isServer())
	{
        CBlob@ summoned = server_CreateBlob( name, team, pos );
		if ( summoned !is null )
		{
			summoned.SetDamageOwnerPlayer( this.getPlayer() );
		}
	}
}

namespace NecromancerRainTypes
{
    enum type{
        finished = 0,
        zombieRain,
        meteorRain,
		meteorStrike,
        skeletonRain,
		arrowRain
    }
}

class NecromancerRain
{
    u8 type;
    u8 level;
    Vec2f position;
    int team;

    uint time;
    uint objectsAmount;

    NecromancerRain(CBlob@ blob, u8 i_type, u8 i_level, Vec2f pos, bool extra_damage)
    {
        type = i_type;
        level = i_level;
        position = pos;
        bool extra = extra_damage;
        team = blob.getTeamNum();

        if (type == NecromancerRainTypes::zombieRain)
        {
            if (level == NecromancerParams::extra_ready)
                SummonBlob(blob, "zombieknight", position, team);
            objectsAmount = 5;
            if (level == NecromancerParams::extra_ready)
                objectsAmount += XORRandom(15);
            else if (level == NecromancerParams::cast_3)
                objectsAmount += XORRandom(10);
            else if (level == NecromancerParams::cast_2)
                objectsAmount += XORRandom(6);
            else if (level == NecromancerParams::cast_1)
                objectsAmount += XORRandom(3);
            time = 1 + XORRandom(6);
        }
        else if (type == NecromancerRainTypes::meteorRain)
        {
            objectsAmount = 5;
            if (level == NecromancerParams::extra_ready)
                objectsAmount += XORRandom(10);
            else if (level == NecromancerParams::cast_3)
                objectsAmount += XORRandom(8);
            else if (level == NecromancerParams::cast_2)
                objectsAmount += XORRandom(6);
            else if (level == NecromancerParams::cast_1)
                objectsAmount += XORRandom(3);
            time = 1 + XORRandom(6);
        }
        else if (type == NecromancerRainTypes::meteorStrike)
        {
            objectsAmount = 1;
            time = 1;
        }
        else if (type == NecromancerRainTypes::skeletonRain)
        {
            objectsAmount = 5;
            if(extra)
                objectsAmount += 3;
            if (level == NecromancerParams::extra_ready)
                objectsAmount += XORRandom(15);
            else if (level == NecromancerParams::cast_3)
                objectsAmount += XORRandom(10);
            else if (level == NecromancerParams::cast_2)
                objectsAmount += XORRandom(6);
            else if (level == NecromancerParams::cast_1)
                objectsAmount += XORRandom(3);
            time = 1;
        }
        else if (type == NecromancerRainTypes::arrowRain)
        {
            objectsAmount = 5;
            if(extra)
                objectsAmount += 3;
            if (level == NecromancerParams::extra_ready)
                objectsAmount += 6;
            time = 1;
        }
    }

    void Manage( CBlob@ this )
    {
        time -= 1;
        if (time <= 0)
        {
            if (type == NecromancerRainTypes::zombieRain)
            {
                string[] possibleZombies = {"skeleton", "zombie"};
                if (level >= NecromancerParams::cast_3)
                {
                    possibleZombies.insertLast("greg");
                    possibleZombies.insertLast("wraith");
                }
                SummonBlob(this, possibleZombies[XORRandom(possibleZombies.length)], position + Vec2f(XORRandom(80) - 40, XORRandom(80) - 40), team);

                time = 1 + XORRandom(6);
            }
            else if (type == NecromancerRainTypes::meteorRain)
            {
                SummonBlob(this, "meteor", Vec2f(position.x + 100.0f - XORRandom(200.0f), 10.0f), team);

                time = 1 + XORRandom(6);
            }
            else if (type == NecromancerRainTypes::meteorStrike)
            {
                SummonBlob(this, "meteor", Vec2f(position.x, 10.0f), team);

                time = 1;
            }
            else if (type == NecromancerRainTypes::skeletonRain)
            {
                SummonBlob(this, "skeleton", position + Vec2f(XORRandom(80) - 40, XORRandom(80) - 40), team);
                time = 4;
            }
            else if (type == NecromancerRainTypes::arrowRain)
            {
				int arrowsPerWave = 10;
				f32 xVariation = 50.0f;
				f32 yVariation = 400.0f;
				for(int i = 0; i < arrowsPerWave; i++)
				{
					CBlob@ arrow = server_CreateBlobNoInit("arrow");
					if (arrow !is null)
					{
						arrow.set_u8("arrow type", XORRandom(4));
						arrow.Init();

						arrow.IgnoreCollisionWhileOverlapped(this);
						arrow.SetDamageOwnerPlayer(this.getPlayer());
						arrow.server_setTeamNum(team);
						arrow.setPosition( Vec2f(position.x + XORRandom(xVariation*2) - xVariation, XORRandom(yVariation*2) - 2.0f*yVariation) );
						arrow.setVelocity(Vec2f(0.0f, 8.0f));
					}
				}
                time = 8;
            }
            objectsAmount -= 1;
            if (objectsAmount <= 0)
            {
                type = NecromancerRainTypes::finished;
            }
        }
    }

    bool CheckFinished()
    {
        return (type == NecromancerRainTypes::finished);
    }
}

void onInit(CBlob@ this)
{
    this.addCommandID("rain");

    NecromancerRain[] rains;
    this.set("necromancerRains", rains);

    this.getCurrentScript().tickFrequency = getTicksASecond()/4;
    this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
    if (!getNet().isServer())
        return;

    NecromancerRain[]@ rains;
    if (!this.get("necromancerRains", @rains)){
        return;
    }

    if (rains.length == 0)
        return;
    for (int i=rains.length-1; i>=0; i--)
    {
        if (rains[i].CheckFinished())
        {
            rains.removeAt(i);
        }
    }
    for (uint i=0; i<rains.length; i++)
        rains[i].Manage(this);
}

void addRain(CBlob@ this, string type, u8 level, Vec2f pos, bool extra_damage)
{
    NecromancerRain[]@ rains;
    if (!this.get("necromancerRains", @rains)){
        return;
    }
    if (!getNet().isServer())
        return;
    if (type == "zombie_rain")
        rains.insertLast(NecromancerRain(this, NecromancerRainTypes::zombieRain, level, pos, extra_damage));
    else if(type == "meteor_rain")
        rains.insertLast(NecromancerRain(this, NecromancerRainTypes::meteorRain, level, pos, extra_damage));
    else if(type == "meteor_strike")
        rains.insertLast(NecromancerRain(this, NecromancerRainTypes::meteorStrike, level, pos, extra_damage));
    else if(type == "skeleton_rain")
        rains.insertLast(NecromancerRain(this, NecromancerRainTypes::skeletonRain, level, pos, extra_damage));
    else if(type == "arrow_rain")
        rains.insertLast(NecromancerRain(this, NecromancerRainTypes::arrowRain, level, pos, extra_damage));
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("rain"))
    {
        string type = params.read_string();
        u8 charge_state = params.read_u8();
        Vec2f aimpos = params.read_Vec2f();
        bool extra_damage = params.read_bool();
        addRain(this, type, charge_state, aimpos, extra_damage);
    }
}


/*
void ManageRains( CBlob@ this )
{
    if (this.hasTag("ZombieRain"))
    {
        s32 time = this.get_s32("zombiesTimeSpawn") - 1;
        if (time <= 0 )
        {
            Vec2f pos = this.get_Vec2f("zombiesRainPos") + Vec2f(20.0f - XORRandom(40.0f), 20.0f - XORRandom(40.0f));
            string name = NecromancerParams::zombieTypes[XORRandom(NecromancerParams::zombieTypes.length)];
            SummonZombie(name, pos,  this.getTeamNum());
            u8 zombiesToSpawn = this.get_u8("zombiesToSpawn");
            this.set_u8("zombiesToSpawn", zombiesToSpawn - 1);
            time = 15 + XORRandom(90);
        }
        if (this.get_u8("zombiesToSpawn") <= 0)
            this.Untag("ZombieRain");
        this.set_s32("zombiesTimeSpawn", time);    
    }// zombie_rain
    if (this.hasTag("SkeletonRain"))
    {
        s32 time = this.get_s32("skeletonsTimeSpawn") - 1;
        if (time <= 0 )
        {
            if (!getNet().isServer())
                return;
            Vec2f pos = Vec2f(this.get_Vec2f("skeletonsRainPos").x + 20.0f - XORRandom(40.0f), 20.0f);
            server_CreateBlob( "skeleton", this.getTeamNum(), pos );
            u8 skeletonsToSpawn = this.get_u8("skeletonsToSpawn");
            this.set_u8("skeletonsToSpawn", skeletonsToSpawn - 1);
            this.set_s32("skeletonsTimeSpawn", 15 + XORRandom(90));
        }
        if (this.get_u8("skeletonsToSpawn") <= 0)
            this.Untag("SkeletonRain");
        this.set_s32("skeletonsTimeSpawn", time);     
    }// skeleton_rain
    if (this.hasTag("MeteorRain"))
    {
        s32 time = this.get_s32("meteorsTimeSpawn") - 1;
        if (time <= 0 )
        {
            if (!getNet().isServer())
                return;
            Vec2f pos = Vec2f(this.get_Vec2f("meteorsRainPos").x + 100.0f - XORRandom(200.0f), 20.0f);
            server_CreateBlob( "skeleton", this.getTeamNum(), pos );
            u8 meteorsToSpawn = this.get_u8("meteorsToSpawn");
            this.set_u8("meteorsToSpawn", meteorsToSpawn - 1);
            time = 15 + XORRandom(60);
        }
        if (this.get_u8("meteorsToSpawn") <= 0)
            this.Untag("MeteorRain");
        this.set_s32("meteorsTimeSpawn", time);     
    }// meteor_rain
}*/