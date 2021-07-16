//recover mana
#include "MagicCommon.as";

const u8 MIN_FOCUS_TIME = 5; //in seconds

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";

    if(isClient())
    {
        this.set_u16("focus", 0);
    }

    this.set_s32("mana regen rate", 3);
}

void onTick(CBlob@ this)
{
    if(!isClient())
    {
        return;
    }

    ManaInfo@ manaInfo;
	if (!this.get( "manaInfo", @manaInfo )) 
	{
		return;
	}

    u8 ticksPerSecond = getTicksASecond();

    if (!this.hasTag("mana_calcs_done"))
    {
        u8 manaRegenRate = manaInfo.manaRegen;//Default mana regen
        //adjusting mana regen rate based on team balance
        uint team0 = 0;
        uint team1 = 0;
        uint teamUnspecified = 0;
        for (u32 i = 0; i < getPlayersCount(); i++)//Get amount of players on each team
        {
            CPlayer@ p = getPlayer(i);
            if (p !is null)
            {
                switch(p.getTeamNum())
                {
                    case 0:
                    {
                        team0++;
                    }
                    break;

                    case 1:
                    {
                        team1++;
                    }
                    break;

                    case 3:
                    {
                        manaRegenRate *= 3;
                    }

                    default:
                    {
                        teamUnspecified++;
                    }
                    break;
                }
            }
        }
        
        if ( team0 > 0 && team1 > 0 )//If there is a player on either team
        {
            CPlayer@ thisPlayer = this.getPlayer();
            if ( thisPlayer !is null )
            {
                int thisPlayerTeamNum = thisPlayer.getTeamNum();//Get the players team
                
                if ( team0 < team1 && thisPlayerTeamNum == 0 )//if we are team 0 and there are more team members on the enemy team
                {
                    manaRegenRate *= (team1/team0);
                }
                else if ( team1 < team0 && thisPlayerTeamNum == 1 )//if we are team 1 and there are more team members on the enemy team
                {
                    manaRegenRate *= (team0/team1);
                }
            }
        }
        
        this.set_s32("mana regen rate", manaRegenRate);//Set the mana regen rate
        this.set_s32("OG_manaRegen", manaRegenRate); //Reminder for the original value
        this.Tag("mana_calcs_done");
    }

	if (getGameTime() % ticksPerSecond == 0)
	{
		ManaInfo@ manaInfo;
		if (!this.get( "manaInfo", @manaInfo )) 
		{
			return;
        }
		
		//now regen mana
		s32 mana = manaInfo.mana;
		s32 maxMana = manaInfo.maxMana;
		s32 maxtestmana = manaInfo.maxtestmana;
		
        u8 adjustedManaRegenRate = this.get_s32("mana regen rate");

		if (mana < maxMana && !this.get_bool("burnState"))
		{
			if (maxMana - mana >= adjustedManaRegenRate)
				manaInfo.mana += adjustedManaRegenRate;
            else
                manaInfo.mana = maxMana;
        }

    }

    if( this is null || !this.hasTag("mana_calcs_done") )
    return;

    u8 ogRegen = this.get_s32("OG_manaRegen");

    if(this.getVelocity() == Vec2f_zero)
    {
        if(this.get_u16("focus") > (ticksPerSecond * MIN_FOCUS_TIME) )
        {
            if(ogRegen != 0)
            {
                this.set_s32("mana regen rate", ogRegen+1);
            }

            if(!this.hasTag("focused"))
            {
                this.Tag("focused");
            }
                
            Vec2f thisPos = this.getPosition();
            for (int i = 0; i < 3; i++)
            {
                Vec2f pixelPos = thisPos + Vec2f( XORRandom(26)-13,XORRandom(26)-13 );
                CParticle@ p = ParticlePixel( pixelPos , Vec2f_zero , SColor( 255, 120+XORRandom(40), 0, 255) , true , XORRandom(7)+3);
                if(p !is null)
                {
                    p.gravity = Vec2f(0,-0.3f);
                }
            }
        }
        else
        {
            this.set_u16("focus", this.get_u16("focus")+1);
        }
    }
    else
    {
        if(this.hasTag("focused"))
        {
            this.Untag("focused");
        }
        
        this.set_u16("focus", 0);
        this.set_s32("mana regen rate", ogRegen);
        return;
    }
}