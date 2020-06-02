#include "Hitters.as";

void onInit( CBlob@ this)
{
	this.set_u8("boomNum", 1);
	//this.getShape().SetStatic(true);
	this.getSprite().PlaySound("continuous_explosion.ogg", 3.0f, 1.5f);
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick( CBlob@ this)
{	
	int currentTime = this.getTickSinceCreated();

	u8 boomNum = this.get_u8("boomNum");
	if (boomNum >= 10)
	{
		this.server_Die();
		return;
	}

	if ( currentTime % 5 == 0 && boomNum <= 9)
	{
		u16 dist_const = 8*boomNum;

		CMap@ map = this.getMap();
		if (map is null)
		{return;}

		Vec2f thisPos = this.getPosition();
		Vec2f distance = this.get_Vec2f("boomDir")*(dist_const*1.5f);
		Vec2f hitPos = thisPos+distance;

		CBlob@[] blobsInRadius;
		if (map.getBlobsInRadius(hitPos, dist_const, @blobsInRadius))
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b is null)
			{continue;}
			if (this.getTeamNum() == b.getTeamNum())
			{continue;}

			Vec2f hitVec = b.getPosition() - thisPos;
			hitVec.Normalize();
			this.server_Hit(b, b.getPosition(), hitVec*5, 1.0f, Hitters::water, true);
		}
		makeBoomParticle( this , hitPos );

		this.set_u8("boomNum", boomNum+1);
	}
		
}

void makeBoomParticle( CBlob@ this , Vec2f pos )
{
	if (isClient())
	{
	
		Vec2f random = Vec2f( XORRandom(4)-2, XORRandom(4)-2 );
		Vec2f newPos = pos + random;
	
		CParticle@ p = ParticleAnimated( "caster_disruption.png", newPos, Vec2f_zero, XORRandom(360), 4.0f, 1, 0.0f, true );
		if(p !is null)
		{
			p.Z = 1.0f;
			p.bounce = 0.0f;
    		p.fastcollision = true;
			p.gravity = Vec2f_zero;
		}
	}
}