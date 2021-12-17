// Blame Fuzzle.

#include "Hitters.as";
#include "ShieldCommon.as";
#include "CommonFX.as";

Random _gatling_basicshot_r(67521);

const string oldPosString = "old_pos";
const string firstTickString = "first_tick";

const f32 damage = 0.4f;

void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(1);

	CShape@ shape = this.getShape();
	if (shape != null)
	{
		shape.getConsts().mapCollisions = false;
		shape.getConsts().bullet = true;
		shape.getConsts().net_threshold_multiplier = 4.0f;
		shape.SetGravityScale(0.0f);
	}

	this.Tag("projectile");

	this.set_Vec2f(oldPosString, Vec2f_zero);
	this.set_bool(firstTickString, true);

	this.getSprite().SetFrame(0);
	this.SetMapEdgeFlags(CBlob::map_collide_up | CBlob::map_collide_down | CBlob::map_collide_sides);
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap(); //standard map check
	if (map is null)
	{ return; }

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	
	f32 travelDist = thisVel.getLength();
	Vec2f futurePos = thisPos + thisVel;

	if (isClient()) //muzzle flash
	{
		if (this.get_bool(firstTickString))
		{
			doMuzzleFlash(thisPos, thisVel);
			this.set_bool(firstTickString, false);
		}

		Vec2f thisOldPos = this.get_Vec2f(oldPosString);
		doTrailParticles(thisOldPos, thisPos);
		this.set_Vec2f(oldPosString, thisPos);
	}
	
	
	CBlob@[] blobsAtPos;
	map.getBlobsAtPosition(thisPos, @blobsAtPos); //check to see if inside an enemy blob
	for (uint i = 0; i < blobsAtPos.length; i++)
	{
		CBlob@ b = blobsAtPos[i];
		if (b is null)
		{ continue; }

		if (!doesCollideWithBlob(this, b))
		{ continue; }

		this.server_Hit(b, thisPos, thisVel, damage, Hitters::arrow, false);
		this.server_Die();
		return;
	}

	Vec2f wallPos = Vec2f_zero;
	bool hitWall = map.rayCastSolidNoBlobs(thisPos, futurePos, wallPos); //if there's a wall, end the travel early
	if (hitWall)
	{
		futurePos = wallPos;
		Vec2f fixedTravel = futurePos - thisPos;
		travelDist = fixedTravel.getLength();
	}

	HitInfo@[] hitInfos;
	bool hasHit = map.getHitInfosFromRay(thisPos, -thisVel.getAngleDegrees(), travelDist, this, @hitInfos);
	if (hasHit) //hitray scan
	{
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b == null) // check
			{ continue; }
			
			if (!doesCollideWithBlob(this, b))
			{ continue; }

			thisPos = hi.hitpos;
			this.setPosition(thisPos);
			this.server_Hit(b, thisPos, thisVel, damage, Hitters::arrow, false);
			this.server_Die();
			return;
		}
	}
	
	if (hitWall) //if there was no hit, but there is a wall, move bullet there and die
	{
		this.setPosition(futurePos);
		if (isClient())
		{
			Sound::Play("dig_dirt2.ogg", futurePos, 1.5f + (0.2f * _gatling_basicshot_r.NextFloat()), 1.0f + (0.2f * _gatling_basicshot_r.NextFloat()));
		}
		this.server_Die();
	}
}

void onDie( CBlob@ this )
{
	Vec2f thisOldPos = this.get_Vec2f(oldPosString);
	Vec2f thisPos = this.getPosition();

	doTrailParticles(thisOldPos, thisPos); //do one last trail particle on death
	this.set_Vec2f(oldPosString, thisPos);
}

void doTrailParticles(Vec2f oldPos = Vec2f_zero, Vec2f newPos = Vec2f_zero)
{
	if (!isClient())
	{ return; }

	if (oldPos == Vec2f_zero || newPos == Vec2f_zero)
	{ return; }

	Vec2f trailVec = newPos - oldPos;
	int steps = trailVec.getLength();
	Vec2f trailNorm = trailVec;
	trailNorm.Normalize();

	SColor color = SColor(255,255,255,255);

	for(int i = 0; i <= steps; i++)
   	{
		u8 alpha = (210.0f * _gatling_basicshot_r.NextFloat()); //randomize alpha
		color.setAlpha(alpha);

		Vec2f pPos = (trailNorm * i) + oldPos;

    	CParticle@ p = ParticlePixelUnlimited(pPos, Vec2f_zero, color, true);
    	if(p !is null)
    	{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 8;
			p.timeout = 2;
			p.setRenderStyle(RenderStyle::light);
		}
	}
}

void doMuzzleFlash(Vec2f thisPos = Vec2f_zero, Vec2f flashVec = Vec2f_zero)
{
	if (!isClient())
	{ return; }

	if (thisPos == Vec2f_zero || flashVec == Vec2f_zero)
	{ return; }
	
	Vec2f flashNorm = flashVec;
	flashNorm.Normalize();

	const int particleNum = 20; //particle amount

	SColor color = SColor(255,255,255,255);

	for(int i = 0; i < particleNum; i++)
   	{
		u8 alpha = 40 + (170.0f * _gatling_basicshot_r.NextFloat()); //randomize alpha
		color.setAlpha(alpha);

		Vec2f pPos = thisPos;
		Vec2f pVel = flashNorm;
		pVel *= 0.2f + _gatling_basicshot_r.NextFloat();

		f32 randomDegrees = 20.0f;
		randomDegrees *= 1.0f - (2.0f * _gatling_basicshot_r.NextFloat());
		pVel.RotateByDegrees(randomDegrees);
		pVel *= 2.5; //final speed multiplier

    	CParticle@ p = ParticlePixelUnlimited(pPos, pVel, color, true);
    	if(p !is null)
    	{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 8;
			p.timeout = 2.0f + (6.0f * _gatling_basicshot_r.NextFloat());
		}
	}
	
	Sound::Play("BasicShotSound.ogg", thisPos, 0.3f , 1.3f + (0.1f * _gatling_basicshot_r.NextFloat()));
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	int thisTeamNum = this.getTeamNum();
	int blobTeamNum = blob.getTeamNum();

	return
	(
		(
			thisTeamNum != blobTeamNum ||
			blob.hasTag("dead")
		)
		&&
		(
			blob.hasTag("flesh") ||
			blob.hasTag("hull")
		)
	);
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ targetBlob, u8 customData )
{
	if (!isClient())
	{ return; }

	if (targetBlob.hasTag("hull"))
	{
		Sound::Play("dry_hit.ogg", worldPoint, 1.0f + (0.2f * _gatling_basicshot_r.NextFloat()), 1.0f + (0.2f * _gatling_basicshot_r.NextFloat()));
	}
	else if (targetBlob.hasTag("flesh"))
	{
		Sound::Play("ArrowHitFlesh.ogg", worldPoint, 2.0f + (0.1f * _gatling_basicshot_r.NextFloat()), 1.2f );
	}

}