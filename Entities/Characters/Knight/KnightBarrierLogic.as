#include "ChargeCommon.as"

void onInit(CBlob@ this)
{

	this.set_u16("cooldown", 0); //supershield setup
	this.addCommandID("spawn shield");
	this.addCommandID("drain mana");

	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
	if (!isClient())
	{return;}

	ChargeInfo@ chargeInfo;
	if (!this.get( "chargeInfo", @chargeInfo )) 
	{
		return;
	}
	
	bool is_shifting = this.get_bool("shifting"); //gets shifting from ShiftTrigger.as

	if(is_shifting) //is shifting?
	{
		CBitStream params;
		Vec2f userPos = this.getPosition();
   		Vec2f targetPos = this.getAimPos();
		Vec2f castDir = (targetPos- userPos);
		castDir.Normalize();
		castDir *= 20; //all of this to get deviation 2.5 blocks in front of caster
		Vec2f castPos = userPos + castDir; //exact position of effect
		s32 castAngle = -castDir.Angle() + 90.0f;

		if (!this.hasTag("materializing") && chargeInfo.charge > 0) //if no shield is active and available charge, do what's below
		{
			this.Tag("materializing");
			this.set_u16("cooldown", getGameTime() + 25); //starts a timer where you can't remove your shield
			params.write_Vec2f(castPos);
			params.write_s32(castAngle);
        	this.SendCommand(this.getCommandID("spawn shield"), params);
		}
	}
	else if (!is_shifting) //gets shifting
	{
		if (this.hasTag("materializing") && getGameTime() > this.get_u16("cooldown")) //if cooldown still active, can't dematerialize the shield
		{
			this.Untag("materializing"); //removes tag which causes the supershield blob to server_Die
		}
	}

	if(this.hasTag("materializing")) //while shield active, reduce 2 charge per tick
	{
		this.SendCommand(this.getCommandID("drain mana"));

		if (chargeInfo.charge < 0)
		{
			this.Untag("materializing");
		}
	}

}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("spawn shield"))
	{
		if(isServer())
		{
			Vec2f castPos = params.read_Vec2f();
			s32 castAngle = params.read_s32();
			CBlob@ barrier = server_CreateBlob( "battering_ram" ); //creates "supershield"
			if (barrier !is null)
			{
				barrier.SetDamageOwnerPlayer( this.getPlayer() ); //<<important
				barrier.server_setTeamNum( this.getTeamNum() );
				barrier.setPosition( castPos );
				barrier.setAngleDegrees(castAngle);
			}
		}
	}
	if (cmd == this.getCommandID("drain mana"))
	{
		ChargeInfo@ chargeInfo;
		if (!this.get( "chargeInfo", @chargeInfo )) 
		{
			return;
		}

		if (chargeInfo.charge >= 1) //if the charge reaches 0, there's a -20 charge penalty.
		chargeInfo.charge -= 1;
        else
        chargeInfo.charge = -25;
		
		this.Sync("manaInfo", true);
	}
}
