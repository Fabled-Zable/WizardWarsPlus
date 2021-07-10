//Disruption Wave Spell Event Sequence
#include "Hitters.as";
const int CAST_TIME = 25;

void onInit( CBlob@ this)
{
	this.set_u16("DW cast moment", 0);
	this.set_Vec2f("spell aim vec", Vec2f_zero);
	
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick( CBlob@ this)
{	
	bool casting = this.hasTag("in spell sequence");
	if ( casting == false )
		return;

	int currentTime = getGameTime();
	int lastCastTime = this.get_u16("DW cast moment");
	int timeElapsed = currentTime - lastCastTime;
	
	Vec2f thisPos = this.getPosition();
	Vec2f aimVec = this.get_Vec2f("spell aim vec");
	Vec2f aimNorm = aimVec;
	aimNorm.Normalize();
	
	if ( timeElapsed < CAST_TIME )
	{
		this.setVelocity(Vec2f(0,0));
		
		u16 takekeys;
		takekeys = key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3 | key_taunts | key_pickup;

		this.DisableKeys(takekeys);
		this.DisableMouse(true);

		//effects
		if ( isClient() && currentTime % 8 == 0 )
			makeDWParticle( this, this.getPosition() );
	}
	else if ( timeElapsed >= CAST_TIME )
	{
		if(isServer())
		{
			CBlob@ orb = server_CreateBlob( "disruption_point" );
			if (orb !is null)
			{
				orb.set_f32("DW_blob_damage", this.get_f32("DW_damage")); //sets damage for the wave
				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.setPosition( thisPos );
				orb.setVelocity( Vec2f_zero );
				orb.server_setTeamNum(this.getTeamNum());
				orb.set_Vec2f("boomDir", aimNorm);
			}
		}

		CMap@ map = this.getMap();
		if (map is null)
		{return;}

		CBlob@[] blobsInRadius;
		if (map.getBlobsInRadius((thisPos + (aimNorm*4)), 8, @blobsInRadius))
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b is null)
			{continue;}
			if (this.getTeamNum() == b.getTeamNum())
			{continue;}

			Vec2f hitVec = b.getPosition() - thisPos;
			hitVec.Normalize();

			float damage = 2.0f;
			if(b.hasTag("counterable"))
			{damage = 4.0f;}
			this.server_Hit(b, b.getPosition(), hitVec*8, damage, Hitters::explosion, true);
		}

		this.Untag("in spell sequence");
		this.DisableKeys(0);
		this.DisableMouse(false);				
	}
}

void makeDWParticle(CBlob@ this, Vec2f pos )
{
	if (isClient())
	{
	
		Vec2f random = Vec2f( XORRandom(5)-2, XORRandom(5)-2 );
		Vec2f newPos = pos + random;
	
		CParticle@ p = ParticleAnimated( "caster_disruption.png", newPos, Vec2f_zero, XORRandom(361), 1.0f, 1, 0.0f, true );
		if(p !is null)
		{
			p.Z = 1.0f;
			p.bounce = 0.0f;
    		p.fastcollision = true;
			p.gravity = Vec2f_zero;
		}
	}
}