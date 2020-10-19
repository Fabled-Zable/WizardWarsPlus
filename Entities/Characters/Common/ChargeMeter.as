#include "ChargeCommon.as"

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
        ChargeInfo@ chargeInfo;
		if (!this.get( "chargeInfo", @chargeInfo )) 
		{
			return;
		}
        u8 chargeRegenRate = chargeInfo.chargeRegen;//Default charge regen
        //adjusting charge regen rate based on team balance
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
                    chargeRegenRate *= (team1/team0);
                }
                else if ( team1 < team0 && thisPlayerTeamNum == 1 )//if we are team 1 and there are more team members on the enemy team
                {
                    chargeRegenRate *= (team0/team1);
                }
            }
        }
        this.set_u8("charge regen rate", chargeRegenRate);//Set the charge regen rate
    }

	if (getGameTime() % 4 == 0)
	{
		ChargeInfo@ chargeInfo;
		if (!this.get( "chargeInfo", @chargeInfo )) 
		{
			return;
        }
		
		//now regen charge
		s32 charge = chargeInfo.charge;
		s32 maxCharge = chargeInfo.maxCharge;
		
        u8 adjustedChargeRegenRate = this.get_u8("charge regen rate");
        
		if (charge < maxCharge)
		{
			if (maxCharge - charge >= adjustedChargeRegenRate)
				chargeInfo.charge += adjustedChargeRegenRate;
            else
                chargeInfo.charge = maxCharge;
        }

    }
}
