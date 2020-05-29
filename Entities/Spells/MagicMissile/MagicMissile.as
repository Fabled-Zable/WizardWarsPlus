#include "/Entities/Common/Attacks/Hitters.as";	   
#include "/Entities/Common/Attacks/LimitedAttacks.as";
#include "SpellCommon.as";

const int LIFETIME = 8;
const int EXTENDED_LIFETIME = 12;
const f32 SEARCH_RADIUS = 128.0f;
const f32 HOMING_FACTOR = 2.0f;
const int HOMING_DELAY = 15;	


void onInit( CBlob @ this )
{

	this.Tag("phase through spells");
	this.Tag("counterable");

	//dont collide with edge of the map
	this.SetMapEdgeFlags( u8(CBlob::map_collide_none) | u8(CBlob::map_collide_nodeath) );
	
	CShape@ shape = this.getShape();
	shape.SetGravityScale( 0.0f );
	shape.getConsts().bullet = true;
	shape.SetRotationsAllowed(false);
	
    //burning sound	    
	CSprite@ thisSprite = this.getSprite();
    thisSprite.SetEmitSound("MolotovBurning.ogg");
    thisSprite.SetEmitSoundVolume(5.0f);
    thisSprite.SetEmitSoundPaused(false);
	thisSprite.getConsts().accurateLighting = false;
	
	this.addCommandID("sync missile");
	
	this.set_bool("initialized", false);
	
	this.set_bool("target found", false);
}

void onTick( CBlob@ this)
{
	if(this is null)
	{return;}

	CSprite@ thisSprite = this.getSprite();
	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	
	if ( this.get_bool("initialized") == false && this.getTickSinceCreated() > 1 )
	{
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		SColor lightColor = SColor( 255, 255, 150, 0);
		this.SetLightColor( lightColor );
		thisSprite.SetZ(500.0f);
		
		this.set_bool("initialized", true);
	}

	//face towards target like a ballista bolt
	f32 angle = thisVel.Angle();	
	thisSprite.ResetTransform();
	thisSprite.RotateBy( -angle, Vec2f(0,0) );
	this.AddForce( Vec2f(1,0).RotateBy(-angle)*0.25f );
	
	if(isClient()) 
	{	//particle smoke
		if ( getGameTime() % 2 == 0 )
		makeSmokePuff(this);
	}
	
	//targetting 
	CBlob@ target = getBlobByNetworkID(this.get_netid("target"));
	if ( this.getTickSinceCreated() > HOMING_DELAY )
	{	
		// try to find player target	
		if ( target is null )
		{
			CBlob@[] blobs;
			CMap@ map = getMap();
			if (map is null) {return;}
			map.getBlobsInRadius( thisPos, SEARCH_RADIUS, @blobs );
			for (uint step = 0; step < blobs.length; ++step)
			{
				//TODO: sort on proximity? done by engine?
				CBlob@ other = blobs[step];
				if (other is null) continue;
				if (other is this) continue; //lets not run away from / try to eat ourselves...
				
				//TODO: flags for these...
				if (other.getTeamNum() != this.getTeamNum() && other.getPlayer() !is null) //home in on enemy players
				{
					this.set_netid("target", other.getNetworkID());
					this.getShape().setDrag(1.0f);
				}
			}
		}
		else
		{
			this.set_bool("target found", true);
		
			Vec2f tpos = target.getPosition();
			Vec2f targetNorm = tpos - thisPos;
			targetNorm.Normalize();
			
			this.AddForce( targetNorm*HOMING_FACTOR );
		}
	}
		
	//delayed death
	if ( this !is null )
	{
		if ( this.get_bool("target found") && this.getTickSinceCreated() > (LIFETIME + EXTENDED_LIFETIME)*30 )
		{
			this.server_Die();
		}
		else if ( !this.get_bool("target found") && this.getTickSinceCreated() > LIFETIME*30 )
		{
			this.server_Die();
		}
	}
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	if ( this is null )
	{return;}

	if ( solid && this.getTickSinceCreated() > (HOMING_DELAY*3) )
	{
		Explode( this );
		this.server_Die();
	}
	
	if (blob !is null)
	{
		if ( (blob.hasTag("flesh") || blob.hasTag("kill other spells") || blob.hasTag("barrier")) && isEnemy(this, blob) )
		{
			f32 finalDamage = 1.0f;
			f32 extraDamage = 0.0f;
			if(blob.hasScript("BladedShell.as"))
			{finalDamage = 0.0f;}
			if(this.hasTag("extra_damage"))
			{extraDamage = 0.4f;}
			this.server_Hit(blob, blob.getPosition(), this.getVelocity(), (finalDamage + extraDamage) , Hitters::water, true);
			Explode( this );
			this.server_Die();
		}
	}
}

/* unused
bool isOwnerBlob(CBlob@ this, CBlob@ target)
{
	if ( target is null )
		return true;

	//easy check
	if (this.getDamageOwnerPlayer() is target.getPlayer())
		return true;

	if (!this.exists("explosive_parent")) { return false; }

	return (target.getNetworkID() == this.get_u16("explosive_parent"));
}*/

bool isEnemy( CBlob@ this, CBlob@ target )
{
	if (target is null)
	{ return false; }
	if (this is null)
	{ return false; }

	return 
	(
		(
			target.hasTag("barrier") ||
			(
				target.hasTag("flesh") 
				&& !target.hasTag("dead") 
			)
		)
		&& target.getTeamNum() != this.getTeamNum() 
	);
}

void makeSmokeParticle(CBlob@ this, const Vec2f vel, const string filename = "Smoke")
{
	if (this is null)
	{ return; }
	if(!isClient()) return;

	const f32 rad = 1.0f;
	Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
	CParticle@ p = ParticleAnimated( "MissileFire1.png", this.getPosition()+random, Vec2f(0,0), float(XORRandom(360)), 0.5f, 6, 0.0f, false );
	if ( p !is null)
	{
		p.bounce = 0;
    	p.fastcollision = true;
		p.Z = 300.0f;
		p.growth = -0.01f;
	}
}

void makeSmokePuff(CBlob@ this, const f32 velocity = 1.0f, const int smallparticles = 10, const bool sound = true)
{
	if (this is null)
	{ return; }
	if ( !isClient() )
		return;
	
		f32 randomness = (XORRandom(32) + 32)*0.015625f * 0.5f + 0.75f;
		Vec2f vel = getRandomVelocity( -90, velocity * randomness, 360.0f );
		makeSmokeParticle(this, vel);
}

void Explode( CBlob@ this )
{
	if (this is null) {return;}
	blast(this.getPosition(), 5);		
	this.getSprite().PlaySound("GenericExplosion1.ogg", 0.8f, 0.8f + XORRandom(10)/10.0f);
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	if ( !isClient() )
		return;

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
									
        if(p is null) return; //bail if we stop getting particles
		
    	p.fastcollision = true;
        p.scale = 0.5f + _blast_r.NextFloat()*0.5f;
        p.damping = 0.85f;
		p.Z = 200.0f;
		p.lighting = false;
    }
}