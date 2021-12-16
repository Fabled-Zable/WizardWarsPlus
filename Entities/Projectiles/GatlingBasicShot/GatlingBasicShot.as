// Blame Fuzzle.

#include "Hitters.as";
#include "ShieldCommon.as";
#include "Explosion.as";
#include "CommonFX.as";

Random _gatling_basicshot_r(67521);

const string oldPosString = "old_pos";
const string newPosString = "new_pos";

void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(5);

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
	this.set_Vec2f(newPosString, Vec2f_zero);

	this.getSprite().SetFrame(0);

	this.SetMapEdgeFlags(CBlob::map_collide_up | CBlob::map_collide_down | CBlob::map_collide_sides);
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap(); //standard map check
	if (map is null)
	{ return; }

	Vec2f thisOldPos = this.get_Vec2f(oldPosString);
	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();

	f32 travelDist = thisVel.getLength();
	Vec2f futurePos = thisPos + thisVel;

	doTrailParticles(thisOldPos, thisPos);
	this.set_Vec2f(oldPosString, thisPos);
	
	CBlob@[] blobsAtPos;
	map.getBlobsAtPosition(thisPos, @blobsAtPos);

	for (uint i = 0; i < blobsAtPos.length; i++)
	{
		CBlob@ b = blobsAtPos[i];
		if (b is null)
		{ continue; }

		if (!doesCollideWithBlob(this, b))
		{ continue; }

		this.server_Hit(b, thisPos, thisVel, 0.2f, Hitters::arrow, false);
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
	if (hasHit)
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
			this.server_Hit(b, thisPos, thisVel, 0.2f, Hitters::arrow, false);
			this.server_Die();
			return;
		}
	}
	
	if (hitWall) //if there was no hit, but there is a wall, move bullet there and die
	{
		this.setPosition(futurePos);
		this.server_Die();
	}
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

	for(int i = 0; i < steps; i++)
   	{
		u8 alpha = 40 + (170.0f * _gatling_basicshot_r.NextFloat()); //randomize alpha
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
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	int thisTeamNum = this.getTeamNum();
	int blobTeamNum = blob.getTeamNum();

	return
	(
		thisTeamNum != blobTeamNum ||
		blob.hasTag("dead")
	);
}

int closestBlobIndex(CBlob@ this, CBlob@[] blobs, bool friendly)
{
    f32 bestDistance = 99999999;
    int bestIndex = -1;

	if(friendly)
	{
		for(int i = 0; i < blobs.length; i++)
		{
			CBlob@ currentBlob = blobs[i];
    	    if(currentBlob is null || currentBlob is this || currentBlob.getTeamNum() != this.getTeamNum())
			{continue;}

    		//f32 dist = this.getDistanceTo(currentBlob);
			f32 dist = Vec2f( currentBlob.getPosition() - this.getAimPos() ).getLength();
    		if(bestDistance > dist)
    		{
    	    	bestDistance = dist;
    	        bestIndex = i;
    	    }
    	}
	}
	else
	{
		for(int i = 0; i < blobs.length; i++)
		{
			CBlob@ currentBlob = blobs[i];
    	    if(currentBlob is null || currentBlob is this || currentBlob.getTeamNum() == this.getTeamNum())
			{continue;}

    		//f32 dist = this.getDistanceTo(currentBlob);
			f32 dist = Vec2f( currentBlob.getPosition() - this.getAimPos() ).getLength();
    		if(bestDistance > dist)
    		{
    	    	bestDistance = dist;
    	        bestIndex = i;
    	    }
    	}
	}
    
    return bestIndex;
}