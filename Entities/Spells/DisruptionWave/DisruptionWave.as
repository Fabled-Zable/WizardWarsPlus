#include "Hitters.as";

void onInit( CBlob@ this)
{
	this.set_u8("boomNum", 1);
	this.getShape().SetGravityScale(0);
	
	this.getCurrentScript().removeIfTag = "dead";

	this.set_f32("DW_blob_damage", 0.8f); //default damage if variable is non-existant
}

void onTick( CBlob@ this)
{	
	int currentTime = this.getTickSinceCreated();

	u8 boomNum = this.get_u8("boomNum");
	if (boomNum >= 11)
	{
		this.server_Die();
		return;
	}
	if ( currentTime < 1)
	{
		if (isClient())
		{this.getSprite().PlaySound("continuous_explosion.ogg", 3.0f, 1.5f);}
		this.getShape().SetStatic(true);
	}

	u16 dist_const = 8*boomNum;

	Vec2f thisPos = this.getPosition();
	Vec2f distance = this.get_Vec2f("boomDir")*(dist_const*1.5f);
	Vec2f hitPos = thisPos+distance;

	if ( currentTime % 4 == 0 && boomNum <= 10)
	{
		CMap@ map = this.getMap();
		if (map is null)
		{return;}

		CBlob@[] blobsInRadius;
		if (map.getBlobsInRadius(hitPos, dist_const/1.5f, @blobsInRadius))
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b is null)
			{continue;}
			if (this.getTeamNum() == b.getTeamNum())
			{continue;}

			Vec2f hitVec = b.getPosition() - thisPos;
			hitVec.Normalize();

			float damage = this.get_f32("DW_blob_damage"); //damage carried over from DWSequence
			if(b.hasTag("counterable"))
			{damage = 3.0f;}
			print("damage: " +damage);
			this.server_Hit(b, b.getPosition(), hitVec*6, damage, Hitters::explosion, true);
		}

		this.set_u8("boomNum", boomNum+1);
	}

	if (isClient())
	{
		for (uint i = 0; i < 2; i++)
		{
			Vec2f random = Vec2f( XORRandom(dist_const/1.7f)+1 , 0 ).RotateByDegrees(XORRandom(361));
			Vec2f particlePos = hitPos + random;
			makeElectricParticle( this , particlePos );
		}

		if (XORRandom(3) == 2)
		{
			Vec2f random = Vec2f( XORRandom(dist_const/1.7f)+1 , 0 ).RotateByDegrees(XORRandom(361));
			Vec2f particlePos = hitPos + random;
			makeBoomParticle( this, particlePos );
			this.getSprite().PlaySound("individual_boom.ogg", 3.0f);
		}
	}
}

void makeElectricParticle( CBlob@ this , Vec2f pos )
{
	if (isClient())
	{
		CParticle@ p = ParticleAnimated( "caster_disruption.png", pos, Vec2f_zero, XORRandom(361), 0.8f, 1, 0.0f, true );
		if(p !is null)
		{
			p.Z = 1.0f;
			p.bounce = 0.0f;
    		p.fastcollision = true;
			p.gravity = Vec2f_zero;
		}
	}
}

void makeBoomParticle( CBlob@ this , Vec2f pos )
{
	if (isClient())
	{
		CParticle@ p = ParticleAnimated( "small_boom.png", pos, Vec2f_zero, XORRandom(361), 1.0f, 1, 0.0f, true );
		if(p !is null)
		{
			p.Z = 1.0f;
			p.bounce = 0.0f;
    		p.fastcollision = true;
			p.gravity = Vec2f_zero;
		}
	}
}