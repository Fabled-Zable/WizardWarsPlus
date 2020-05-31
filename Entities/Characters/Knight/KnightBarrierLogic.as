#include "ChargeCommon.as"

void onInit(CBlob@ this)
{

	this.set_u16("cooldown", 0); //supershield setup
	this.addCommandID("sync charge");

	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
	ChargeInfo@ chargeInfo;
	if (!this.get( "chargeInfo", @chargeInfo )) 
	{
		return;
	}

	
	if(this.get_bool("shifting")) //gets shifting from ShiftTrigger.as
	{
		if(this.isMyPlayer())
		{
			CBitStream params1;
			params1.write_s32(chargeInfo.charge); //gets current ch<arge
			this.SendCommand(this.getCommandID("sync charge"), params1);
		}

		if (!this.hasTag("materializing") && this.get_s32("charge") > 0) //if no shield is active and available charge, do what's below
		{
			this.Tag("materializing");
			this.set_u16("cooldown", getGameTime() + 25); //starts a timer where you can't remove your shield
			//this.SendCommand(this.getCommandID("spawn shield"), params);
			if( isServer() )
			{
				Vec2f targetPos = this.getAimPos() + Vec2f(0.0f,-2.0f);
				Vec2f userPos = this.getPosition() + Vec2f(0.0f,-2.0f);
				Vec2f castDir = (targetPos- userPos);
				castDir.Normalize();
				castDir *= 20; //all of this to get deviation 2.5 blocks in front of caster
				Vec2f castPos = userPos + castDir; //exact position of effect

				CBlob@ barrier = server_CreateBlob( "battering_ram" ); //creates "supershield"
				if (barrier !is null)
				{
					barrier.SetDamageOwnerPlayer( this.getPlayer() ); //<<important
					barrier.server_setTeamNum( this.getTeamNum() );
					barrier.setPosition( castPos );
					barrier.setAngleDegrees(-castDir.Angle()+90.0f);
				}
			}
		}
	}
	else if (!this.get_bool("shifting")) //gets shifting
	{
		if (this.hasTag("materializing") && getGameTime() > this.get_u16("cooldown")) //if cooldown still active, can't dematerialize the shield
		{
			this.Untag("materializing"); //removes tag which causes the supershield blob to server_Die
		}
	}

	if(this.hasTag("materializing")) //while shield active, reduce 2 charge per tick
	{
		s32 charge = this.get_s32("charge");
		if (charge < 0)
		this.Untag("materializing");

		if ( this.isMyPlayer() )
		{
			s32 maxCharge = chargeInfo.maxCharge;
			if (charge >= 1) //if the charge reaches 0, there's a -20 charge penalty.
			chargeInfo.charge -= 1;
            else
            chargeInfo.charge = -25;
		}
	}

}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("sync charge"))
	{
		this.set_s32("charge", params.read_s32());
	}
}
