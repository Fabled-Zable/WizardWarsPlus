
#include "Hitters.as"

const string burn_duration = "burn duration";
const string burn_hitter = "burn hitter";

const string burn_timer = "burn timer";

const string burning_tag = "burning";
const string spread_fire_tag = "spread fire";

const int fire_wait_ticks = 4;
const int burn_thresh = 70;

/**
 * Start this's fire and sync everything important
 */
void server_setFireOn(CBlob@ this)
{
	if (!getNet().isServer())
		return;
	
	this.Tag(burning_tag);
	this.Sync(burning_tag, true);

	this.set_s16(burn_timer, this.get_s16(burn_duration) / fire_wait_ticks);
	this.Sync(burn_timer, true);	

	if ((this.getCurrentScript().runFlags & Script::tick_infire) != 0)
		this.Tag("had only fire flag");
		
	this.getCurrentScript().runFlags &= ~Script::tick_infire;
}

/**
 * Put out this's fire and sync everything important
 */
void server_setFireOff(CBlob@ this)
{
	if (!getNet().isServer())
		return;
	this.Untag(burning_tag);
	this.Sync(burning_tag, true);

	this.set_s16(burn_timer, 0);
	this.Sync(burn_timer, true);

	if (this.hasTag("had only fire flag"))
		this.getCurrentScript().runFlags |= Script::tick_infire;
}

/**
 * Hitters that should start something burning when hit
 */
bool isIgniteHitter(u8 hitter)
{
	return hitter == Hitters::fire;
}

/**
 * Hitters that should put something out when hit
 */
bool isWaterHitter(u8 hitter)
{
	return hitter == Hitters::water ||
	       hitter == Hitters::water_stun;
}
