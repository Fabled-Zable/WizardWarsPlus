#include "ChargeCommon.as"

void onInit(CBlob@ this)
{
	this.set_u16("cooldown", 0); //supershield setup

	this.getCurrentScript().removeIfTag = "dead";

	this.addCommandID("addMaterializing");
	this.addCommandID("removeMaterializing");
	this.addCommandID("makeBarrier");
}

void onTick(CBlob@ this)
{
	if(!this.isMyPlayer())
    {
        return;
    }

	ChargeInfo@ chargeInfo;
	if (!this.get( "chargeInfo", @chargeInfo )) 
	{
		return;
	}

	s32 currentCharge = chargeInfo.charge;
	
	if(this.get_bool("shifting")) //gets shifting from ShiftTrigger.as
	{
		if (!this.hasTag("materializing") && currentCharge > 0) //if no shield is active and available charge, do what's below
		{
			this.Tag("materializing");
			this.SendCommand(this.getCommandID("addMaterializing"));
			this.set_u16("cooldown", getGameTime() + 30); //starts a timer where you can't remove your shield
			
			this.SendCommand(this.getCommandID("makeBarrier"));
		}
	}
	else if (!this.get_bool("shifting") && getGameTime() > this.get_u16("cooldown")) //if cooldown still active, can't dematerialize the shield
	{
		if (this.hasTag("materializing") ) 
		{
			this.Untag("materializing"); //removes tag which causes the supershield blob to server_Die
			this.SendCommand(this.getCommandID("removeMaterializing"));
		}
	}

	if(this.hasTag("materializing")) //while shield active, reduce 1 charge per tick
	{
		if (currentCharge > 0)
		{
			chargeInfo.charge -= 1;
		}
		else
		{
			this.Untag("materializing");
			this.SendCommand(this.getCommandID("removeMaterializing"));

			chargeInfo.charge = -40; //charge penalty
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if(!isServer())
	{
		return;
	}

	if (cmd == this.getCommandID("addMaterializing"))
	{
		this.Tag("materializing");
	}

	if (cmd == this.getCommandID("removeMaterializing"))
	{
		this.Untag("materializing");
	}

	if (cmd == this.getCommandID("makeBarrier"))
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
