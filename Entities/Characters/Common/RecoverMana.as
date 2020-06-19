//recover mana
#include "MagicCommon.as";

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
    if(!isClient())
    {
        return;
    }
    if (this.getTickSinceCreated() < 2)
    {
        ManaInfo@ manaInfo;
		if (!this.get( "manaInfo", @manaInfo )) 
		{
			return;
		}
        u8 manaRegenRate = manaInfo.manaRegen;//Default mana regen
        //adjusting mana regen rate based on team balance
        uint team0 = 0;
        uint team1 = 0;
        for (u32 i = 0; i < getPlayersCount(); i++)//Get amount of players on each team
        {
            CPlayer@ p = getPlayer(i);
            if (p !is null)
            {
                if (p.getTeamNum() == 0)
                    team0++;
                else if (p.getTeamNum() == 1)
                    team1++;
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

        if ( this.getTeamNum() == 3 )
        {
            manaRegenRate *= 2;
        }
        
        this.set_u8("mana regen rate", manaRegenRate);//Set the mana regen rate
    }

	if (getGameTime() % getTicksASecond() == 0)
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
		
        u8 adjustedManaRegenRate = this.get_u8("mana regen rate");
        
		if (mana < maxMana)
		{
			if (maxMana - mana >= adjustedManaRegenRate)
				manaInfo.mana += adjustedManaRegenRate;
            else
                manaInfo.mana = maxMana;
        }

    }
}