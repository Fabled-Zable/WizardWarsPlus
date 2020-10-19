//Burn and spread fire

#include "Hitters.as";
#include "FireCommon.as";

void onInit(CBlob@ this)
{
	this.getShape().getConsts().isFlammable = true;

	if (!this.exists(burn_duration))
		this.set_s16(burn_duration , 400);
	if (!this.exists(burn_hitter))
		this.set_u8(burn_hitter, Hitters::burn);

	if (!this.exists(burn_timer))
		this.set_s16(burn_timer , 0);

	this.getCurrentScript().tickFrequency = fire_wait_ticks;
	this.getCurrentScript().runFlags |= Script::tick_infire;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if ((isIgniteHitter(customData) && damage > 0.0f) ||					 	   // Fire arrows
	        (this.isOverlapping(hitterBlob) &&
	         hitterBlob.isInFlames() && !this.isInFlames()))	   // Flaming enemy
	{
		server_setFireOn(this);
	}

	if (isWaterHitter(customData))	  // buckets of water
	{
		server_setFireOff(this);
		this.getSprite().PlaySound("/ExtinguishFire.ogg");
	}

	return damage;
}

void onTick(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	CMap@ map = this.getMap();
	if (map is null)
		return;

	s16 burn_time = this.get_s16(burn_timer);
	//check if we should be getting set on fire or put out
	if (burn_time < (burn_thresh / fire_wait_ticks) && this.isInFlames())
	{
		server_setFireOn(this);
		burn_time = this.get_s16(burn_timer);
	}

	//check if we're extinguished
	if (burn_time == 0 || this.isInWater())
	{
		server_setFireOff(this);
	}

	//burnination
	else if (burn_time > 0)
	{
		//burninating the other tiles
		if ((burn_time % 8) == 0 && this.hasTag(spread_fire_tag))
		{
			Vec2f p = pos + Vec2f(XORRandom(16) - 8, XORRandom(16) - 8);
			getMap().server_setFireWorldspace(p, true);
		}
		
		//burninating the actor
		if ((burn_time % 5) == 0)
		{
			f32 damage = 0.5f;
			if(this.get_u16("fireProt") > 0)
			{damage = 0.0f;}
			this.server_Hit(this, pos, Vec2f(0, 0), damage, this.get_u8("burn hitter"), true);
		}

		//burninating the burning time
		if(this.get_u16("fireProt") > 0)
		{burn_time = 0;}
		else
		{burn_time--;}

		//and making sure it's set correctly!
		this.set_s16(burn_timer, burn_time);
	}

	// (flax roof cottages!)
}
