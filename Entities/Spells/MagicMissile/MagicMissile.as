#include "/Entities/Common/Attacks/Hitters.as";	   
#include "/Entities/Common/Attacks/LimitedAttacks.as";
#include "SpellCommon.as";

const int LIFETIME = 4;
const int EXTENDED_LIFETIME = 6;
const f32 SEARCH_RADIUS = 128.0f;
const f32 HOMING_FACTOR = 2.0f;
const int HOMING_DELAY = 15;	


void onInit( CBlob @ this )
{

	this.Tag("phase through spells");
	this.Tag("counterable");
	
    //this.server_setTeamNum(1);
	this.Tag("medium weight");

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
	this.set_bool("segments updating", false);
	this.set_u32("dead segment", 0);
	
	this.set_bool("target found", false);
	
	this.set_bool("death triggered", false);
	this.set_bool("dead", false);
}

void onTick( CBlob@ this)
{
	CSprite@ thisSprite = this.getSprite();
	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	
	bool deathTriggered = this.get_bool("death triggered");	//used to sync server and client onCollision 
	bool isDead = this.get_bool("dead");
	
	if ( this.get_bool("initialized") == false && this.getTickSinceCreated() > 1 )
	{
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		SColor lightColor = SColor( 255, 255, 150, 0);
		this.SetLightColor( lightColor );
		thisSprite.SetZ(500.0f);
		
		this.set_bool("initialized", true);
	}
	
	//targetting 
	CBlob@ target = getBlobByNetworkID(this.get_netid("target"));
	if ( this.getTickSinceCreated() > HOMING_DELAY )
	{	
		// try to find player target	
		if ( target is null )
		{
			CBlob@[] blobs;
			this.getMap().getBlobsInRadius( thisPos, SEARCH_RADIUS, @blobs );
			f32 best_dist = 99999999;
			for (uint step = 0; step < blobs.length; ++step)
			{
				//TODO: sort on proximity? done by engine?
				CBlob@ other = blobs[step];

				if (other is this) continue; //lets not run away from / try to eat ourselves...
				
				//TODO: flags for these...
				if (other.getTeamNum() != this.getTeamNum() && (other.hasTag("player") || other.hasTag("zombie")) && !other.hasTag("dead")) //home in on enemies
				{
					Vec2f tpos = other.getPosition();									  
					f32 dist = (tpos - thisPos).getLength();
					if (dist < best_dist)
					{
						this.set_netid("target", other.getNetworkID());
						best_dist=dist;
						this.getShape().setDrag(1.0f);
					}
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
	if ( !isDead )
	{
		if ( this.get_bool("target found") && this.getTickSinceCreated() > (LIFETIME + EXTENDED_LIFETIME)*30 )
		{
			Die( this );
		}
		else if ( !this.get_bool("target found") && this.getTickSinceCreated() > LIFETIME*30 )
		{
			Die( this );
		}
	}
	
	//activate death event if triggered
	if ( deathTriggered == true && !isDead )
	{
		Explode( this );
		Die( this );
	}
	
	//random motion
	if ( (getGameTime() % 4 == 0) )
		randomForce(this);
	
	//face towards target like a ballista bolt
	f32 angle = thisVel.Angle();	
	thisSprite.ResetTransform();
	thisSprite.RotateBy( -angle, Vec2f(0,0) );
	this.AddForce( Vec2f(1,0).RotateBy(-angle)*0.25f );
	
	if(!getNet().isClient()) 
		return;	
	//particle smoke
	if ( getGameTime() % 2 == 0 )
		makeSmokePuff(this);
}

bool followsDeadAllies( CBlob@ this )
{		
	string effectType = this.get_string("effect");
	
	return ( effectType == "revive" );
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	bool isDead = this.get_bool("dead");
	if ( isDead )
		return;

	if ( solid && this.getTickSinceCreated() > HOMING_DELAY )
	{
		this.set_bool("death triggered", true);
	}
	
	if (blob !is null)
	{
		if ( ((blob.hasTag("player") || blob.hasTag("zombie") || blob.hasTag("kill other spells") || blob.hasTag("barrier")) && isEnemy(this, blob)))
		{
			this.server_Hit(blob, blob.getPosition(), this.getVelocity(), 0.25f, Hitters::water, true);
			this.set_bool("death triggered", true);
		}
	}
	this.Sync("death triggered", true);
}

bool isOwnerBlob(CBlob@ this, CBlob@ target)
{
	if ( target is null )
		return true;

	//easy check
	if (this.getDamageOwnerPlayer() is target.getPlayer())
		return true;

	if (!this.exists("explosive_parent")) { return false; }

	return (target.getNetworkID() == this.get_u16("explosive_parent"));
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return 
	(
		(
			target.hasTag("barrier") ||
			(
				target.hasTag("flesh") 
				&& !target.hasTag("dead") 
				&& (friend is null
					|| friend.getTeamNum() != this.getTeamNum()
					)
			)
		)
		&& target.getTeamNum() != this.getTeamNum() 
	);
}

void makeSmokeParticle(CBlob@ this, const Vec2f vel, const string filename = "Smoke")
{
	if(!getNet().isClient()) return;
	//warn("making smoke");

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
	
	//warn("smoke made");
}

void makeSmokePuff(CBlob@ this, const f32 velocity = 1.0f, const int smallparticles = 10, const bool sound = true)
{
	if ( !getNet().isClient() )
		return;
		
	//makeSmokeParticle(this, Vec2f(), "Smoke");
	//for (int i = 0; i < smallparticles; i++)
	{
		f32 randomness = (XORRandom(32) + 32)*0.015625f * 0.5f + 0.75f;
		Vec2f vel = getRandomVelocity( -90, velocity * randomness, 360.0f );
		makeSmokeParticle(this, vel);
	}
}

void randomForce( CBlob@ this )
{
	this.AddForce( this.get_Vec2f("rVel") );

	f32 randomness = (XORRandom(32) + 32)*0.015625f * 0.5f + 0.75f;
	Vec2f vel = getRandomVelocity( -90, randomness*4.0f, 360.0f );
	this.set_Vec2f("rVel", vel);
	SyncMissile( this );
}

void SyncMissile( CBlob@ this )
{
	Vec2f rVel = this.get_Vec2f("rVel");	
	CBitStream bt;
	bt.write_Vec2f( rVel );	
	this.SendCommand( this.getCommandID("sync missile"), bt );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if( cmd == this.getCommandID("sync missile") )
    {
		Vec2f rVel;	
		rVel = params.read_Vec2f();	
		this.set_Vec2f( "rVel", rVel );
	}
}

void Explode( CBlob@ this )
{
    CMap@ map = getMap();
	Vec2f thisPos = this.getPosition();
    if (map !is null)   
	{
		CBlob@[] blobsInRadius;
		if (map.getBlobsInRadius(thisPos, 24.0f, @blobsInRadius))
		{
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob @b = blobsInRadius[i];
				if (b !is null)
				{
					Vec2f bPos = b.getPosition();
					
					if ( !map.rayCastSolid(thisPos, bPos) )
                    {
                        float extraDamage = this.hasTag("extra_damage") ? 1.2f : 1.0f;
						this.server_Hit(b, bPos, bPos-thisPos, 0.75f * extraDamage, Hitters::water, false);
                    }
                }
			}
		}
	}
	
	blast(this.getPosition(), 5);		
	this.getSprite().PlaySound("GenericExplosion1.ogg", 0.8f, 0.8f + XORRandom(10)/10.0f);
}

void Die(CBlob@ this)
{
	this.shape.SetStatic(true);
	this.getSprite().SetVisible(false);
	this.getSprite().SetEmitSoundPaused(true);
	
	this.server_SetTimeToDie(3);	
	
	this.set_bool("dead", true);
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
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