#include "/Entities/Common/Attacks/Hitters.as";	   
#include "/Entities/Common/Attacks/LimitedAttacks.as";
#include "SpellCommon.as";

const int LIFETIME = 10;
const f32 SEARCH_RADIUS = 128.0f;
const f32 HOMING_FACTOR = 2.1f;
//const f32 CORRECTION_FACTOR = 0.1f;
const int HOMING_DELAY = 15; // before first tick
const int SEARCH_DELAY = 5; // how often to tick to try search for new targets


void onInit(CBlob@ this)
{
	this.Tag("phase through spells");
    this.Tag("counterable");
	this.set_f32("damage", 1.0f);
    this.getShape().SetGravityScale(0);
	this.SetMapEdgeFlags( u8(CBlob::map_collide_none) | u8(CBlob::map_collide_nodeath) ); //dont collide with edge of the map

    if (isServer())
    {
		this.server_SetTimeToDie(LIFETIME);
	}
    
	//burning sound	    
	if (isClient())
	{
		CSprite@ sprite = this.getSprite();

    	sprite.SetEmitSound("MolotovBurning.ogg");
    	sprite.SetEmitSoundVolume(5.0f);
    	sprite.SetEmitSoundPaused(false);
		sprite.getConsts().accurateLighting = false;
	}

	this.getCurrentScript().tickFrequency = HOMING_DELAY; // when we first load, dont tick for 15 ticks
}

void onTick(CSprite@ this) // note to glitch - this only runs on client, onTick is never called if blob is null
{
	CBlob@ blob = this.getBlob();
	if (blob.getTickSinceCreated() % 2 == 0)
	{
		makeSmokeParticle(blob);
	}

	this.ResetTransform();
    this.RotateBy(blob.getVelocity().getAngle() * -1,Vec2f_zero);
}

void onTick(CBlob@ this)
{
	/// Delay check
	ScriptData@ script = this.getCurrentScript();
	Vec2f pos = this.getPosition();

	if (script.tickFrequency == HOMING_DELAY)
	{
		script.tickFrequency = SEARCH_DELAY;
		this.Tag("searching");
	}

	/// Chase target if it exists
	if (this.exists("target"))
	{
		uint16 netid = this.get_netid("target");
		CBlob@ target = getBlobByNetworkID(netid);

		if (netid == 0 || target is null)
		{
			script.tickFrequency = SEARCH_DELAY;
			this.Tag("searching");
			this.set_netid("target", 0);
		}
		else 
		{
			script.tickFrequency = 1;
			
			/// note (vam) - I'm not touching this, looks confusing and spooky
			Vec2f pos = this.getPosition();
			Vec2f thisVelNorm = this.getVelocity();
			Vec2f thisVel = thisVelNorm;
			thisVelNorm.Normalize();
			Vec2f targetPos = target.getPosition();
			Vec2f targetVel = target.getVelocity();
			Vec2f predictedTrajectory = targetPos+targetVel;
			Vec2f norm = predictedTrajectory - pos;

			//Trajectory correction algorithm
			float direcAngle = norm.getAngle();
			float targetAngle = thisVel.getAngle();
			float difference = targetAngle-direcAngle;
			difference = Maths::Abs(difference);
			float CORRECTION_FACTOR = difference/500;
			
			//collision deterrant algorithm
			CMap@ map = getMap();
			if(map.rayCastSolidNoBlobs(pos, pos+(thisVelNorm*10)))
			{
				CORRECTION_FACTOR += 0.6f;
			}

			norm.Normalize();
			norm -= (thisVel * CORRECTION_FACTOR);

			this.getShape().setDrag(1.0f);
			this.AddForce(norm*HOMING_FACTOR);
			/// end note (vam)
		}

	}


	/// Searching for target
	if (!this.hasTag("searching")) { return; }

	CBlob@[] list;
	if (getMap().getBlobsInRadius(pos, SEARCH_RADIUS, @list))
	{
		CBlob@ targetBlob = ClosestBlob(this, list);
		if (targetBlob is null) { return; }

		this.Untag("searching");
		this.set_netid("target", targetBlob.getNetworkID());
	}
}

/// Want to optimize this? use kd-tree
CBlob@ ClosestBlob(CBlob@ this, CBlob@[]@ blobs)
{
	float distanceToClosestTarget = 10000000;
	Vec2f pos = this.getPosition();
	CBlob@ target = null;

	for (int a = 0; a < blobs.length; a++)
	{
		CBlob@ blob = blobs[a];
		if (blob is null) { continue; }
		if (this.getTeamNum() == blob.getTeamNum() || !blob.hasTag("flesh") ||  blob.hasTag("dead")) { continue; }

		float distance = (blob.getPosition() - pos).LengthSquared();
		if (distance < distanceToClosestTarget)
		{
			distanceToClosestTarget = distance;
			@target = blob;
		}
	}

	return target;
}

/// note (vam) -> I'm not touching these
void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{
    if (solid && (this.getTickSinceCreated() > (HOMING_DELAY * 2) ))
    {
		blast(this, 4);
        this.server_Die();
		return;
    }

	if (blob is null) { return; }

	//hit detection
    if(blob.getTeamNum() != this.getTeamNum())
    {
		float damage = this.get_f32("damage");

		if (blob.hasTag("barrier"))
		{
			damage = 2.5f;
		}
		else if (blob.getName() == "knight")
		{
    		damage = 0.8f;
            if (blob.hasTag("shielded"))
            {
                if(isClient())
                {this.getSprite().PlaySound("ShieldHit.ogg");}
                damage = 0.2;
            }
        }
		else if (!blob.hasTag("flesh")){ return; }

        this.server_Hit(blob,blob.getPosition(),this.getVelocity()*4,damage,Hitters::explosion);
		blast(this, 4);
        this.server_Die();
    }
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
	if(b is null){return false;}

	return 
	(
		b.getTeamNum() != this.getTeamNum()
		&& b.hasTag("barrier")//collides with enemy barriers
	); 
}


void makeSmokeParticle( CBlob@ this )
{
	if (this is null)
	{ return; }

	const f32 rad = 1.0f;
	Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
	CParticle@ p = ParticleAnimated( "MissileFire1.png", this.getPosition()+random, Vec2f(0,0), float(XORRandom(360)), 0.5f, 6, 0.0f, false );
	if ( p !is null)
	{
		p.bounce = 0;
    	p.fastcollision = true;
		p.Z = 300.0f;
	}
}


Random _blast_r(0x10002);
void blast( CBlob@ this , int amount)
{
	if ( !isClient() )
		return;
	if ( this is null )
		return;

	this.getSprite().PlaySound("GenericExplosion1.ogg", 0.8f, 0.8f + XORRandom(10)/10.0f);

	Vec2f pos = this.getPosition();

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_blast_r.NextFloat() * 2.5f, 0);
        vel.RotateBy(_blast_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated("GenericBlast6.png", 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) continue; //bail if we stop getting particles
		
    	p.fastcollision = true;
        p.scale = 0.5f + _blast_r.NextFloat()*0.5f;
        p.damping = 0.85f;
		p.Z = 200.0f;
		p.lighting = false;
    }
}
/// end (vam note)