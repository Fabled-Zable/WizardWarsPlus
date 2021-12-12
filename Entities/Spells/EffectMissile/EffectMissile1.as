#include "/Entities/Common/Attacks/Hitters.as";	   
#include "/Entities/Common/Attacks/LimitedAttacks.as";
#include "SpellCommon.as";
#include "Hitters.as";


const int LIFETIME = 3.6;
const int EXTENDED_LIFETIME = 5.4;
const f32 SEARCH_RADIUS = 48.0f;
const f32 HOMING_FACTOR = 1.4f;
const int HOMING_DELAY = 10;	

const int INIT_DELAY = 2;	//prevents initial seg pos to be at (0,0)
const int min_detonation_time = 8;

void onInit( CBlob @ this )
{
	this.Tag("counterable");
	
    //this.server_setTeamNum(1);
	this.Tag("medium weight");

	CShape@ shape = this.getShape();
	shape.SetGravityScale( 0.0f );
	shape.getConsts().bullet = true;
	shape.SetRotationsAllowed(false);
	
    //burning sound	    
	CSprite@ thisSprite = this.getSprite();
	thisSprite.getConsts().accurateLighting = false;
	
	this.set_bool("initialized", false);
	this.set_bool("segments updating", false);
	this.set_u32("dead segment", 0);
	
	this.set_bool("target found", false);
	
	this.set_bool("dead", false);
	
	this.set_bool("onCollision triggered", false);
	this.set_netid("onCollision blob", 0);
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
						this.server_Hit(b, bPos, bPos-thisPos, 0.3f, Hitters::drill, false);
				}
			}
		}
	}
}

void onTick( CBlob@ this)
{
	CSprite@ thisSprite = this.getSprite();
	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	
	bool isDead = this.get_bool("dead");
	
	bool onCollisionTriggered = this.get_bool("onCollision triggered");	//used to sync server and client onCollision 
	
	if ( this.get_bool("initialized") == false && this.getTickSinceCreated() > INIT_DELAY )
	{
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		SColor lightColor = SColor( 255, 255, 150, 0);
		this.SetLightColor( lightColor );
		thisSprite.PlaySound("GenericProjectile11.ogg", 0.8f, 1.0f + XORRandom(3)/10.0f);
		thisSprite.SetZ(500.0f);
		
		this.set_bool("initialized", true);
	}
	
	//targetting 
	if ( this.getTickSinceCreated() > HOMING_DELAY )
	{	
		// try to find player target	
		CBlob@ target = getBlobByNetworkID(this.get_netid("target"));
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
				if ( followsAllies(this) )
				{		
					if (!isOwnerBlob(this, other) && other.hasTag("player") && !other.hasTag("dead")) //home in on living allies
					{
						Vec2f tpos = other.getPosition();									  
						f32 dist = (tpos - thisPos).getLength();
						if (dist < best_dist)
						{
							this.set_netid("target", other.getNetworkID());
							best_dist=dist;
							this.getShape().setDrag(2.0f);
						}
					}
				}
				else if ( followsDeadAllies(this) )
				{		
					if (other.getTeamNum() == this.getTeamNum() && other.hasTag("gravestone") ) //home in on gravestones
					{
						Vec2f tpos = other.getPosition();									  
						f32 dist = (tpos - thisPos).getLength();
						if (dist < best_dist)
						{
							this.set_netid("target", other.getNetworkID());
							best_dist=dist;
							this.getShape().setDrag(2.0f);
						}
					}
				}
				else	//follow enemies
				{
					if  (other.hasTag("player") && !other.hasTag("dead") && !isOwnerBlob(this, other) ) //home in on enemies
					{
						Vec2f tpos = other.getPosition();									  
						f32 dist = (tpos - thisPos).getLength();
						if (dist < best_dist)
						{
							this.set_netid("target", other.getNetworkID());
							best_dist=dist;
							this.getShape().setDrag(2.0f);
						}
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
	
	//activate onCollision events
	if ( onCollisionTriggered == true && !isDead )
	{
		CBlob@ blob = getBlobByNetworkID( this.get_netid("onCollision blob") );
		CBlob@ caller = getBlobByNetworkID( this.get_netid("onCollision blob") );
		
		if ( blob !is null )
		{	
				//{
					//if ( isEnemy(this, blob) && followsEnemies( this ) )	//curse status effects
					//	{
							//caller.server_Hit(Vec2f(0, 0), 10.0f, Hitters::name);            //this.server_Hit(blob, pos, Vec2f(0, 0), 1.0f);
							//															//this is the first one
						//	Die( this );
					//	}
				//}
			string effectType = this.get_u8("effect");
			
			if (blob.hasTag("player") && !blob.hasTag("dead"))
			{	
				if ( !isEnemy(this, blob) && !isOwnerBlob(this, blob) )	//buff status effects
				{
					if ( effectType == "heal" )
						Heal(blob, this.get_f32("heal_amount"));
					else if ( effectType == "haste" )
						Haste(blob, this.get_u16("haste_time"));
						
				
					Die( this );
				}
	
			}
			
			this.set_bool("onCollision triggered", false);
		}
	}
	
	if(!getNet().isClient()) 
		return;
	
	//face towards target like a ballista bolt
	f32 angle = thisVel.Angle();	
	thisSprite.ResetTransform();
	thisSprite.RotateBy( -angle, Vec2f(0,0) );
	
	//makeSmokePuff(this);
}

bool followsAllies( CBlob@ this )
{		
	string effectType = this.get_u8("effect");
	
	return ( effectType == "heal" || effectType == "haste" );
}

bool followsEnemies( CBlob@ this )
{		
	string effectType = this.get_u8("effect");
	
	return ( effectType == "heal" );
}

bool followsDeadAllies( CBlob@ this )
{		
	string effectType = this.get_u8("effect");
	
	return ( effectType == "revive" || effectType == "unholy_res" );
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid )
{	
	if ( blob is null )
		return;
	

	this.set_bool("onCollision triggered", true);
	this.set_netid("onCollision blob", blob.getNetworkID());
	
	this.Sync("onCollision triggered", true);
	this.Sync("onCollision blob", true);
	if (this.getTickSinceCreated() > min_detonation_time)
		{		
			if ( ((blob.hasTag("player") || blob.hasTag("zombie") || blob.hasTag("kill other spells") || blob.hasTag("barrier")) && isEnemy(this, blob)))
			{
				Explode( this );
				this.server_Die();
			}
		}
}

void Die(CBlob@ this)
{

	this.shape.SetStatic(true);
	this.getSprite().SetVisible(false);
	
	this.server_SetTimeToDie(3);	
	
	this.set_bool("dead", true);
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
	return (
		target.hasTag("flesh") 
		&& !target.hasTag("dead") 
		&& target.getTeamNum() != this.getTeamNum() 
		&& (friend is null
			|| friend.getTeamNum() != this.getTeamNum()
		)
	);
}

void makeSmokeParticle(CBlob@ this, const Vec2f vel, const string filename = "Smoke")
{
	if(!getNet().isClient()) 
		return;
	//warn("making smoke");

	const f32 rad = 2.0f;
	Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
	CParticle@ p = ParticleAnimated( "MissileFire1.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2, 0.0f, false );
	if ( p !is null)
	{
		p.bounce = 0;
    	p.fastcollision = true;
		p.Z = 300.0f;
	}
	
	//warn("smoke made");
}

void makeSmokePuff(CBlob@ this, const f32 velocity = 1.0f, const int smallparticles = 10, const bool sound = true)
{

	//makeSmokeParticle(this, Vec2f(), "Smoke");
	//for (int i = 0; i < smallparticles; i++)
	{
		f32 randomness = (XORRandom(32) + 32)*0.015625f * 0.5f + 0.75f;
		Vec2f vel = getRandomVelocity( -90, velocity * randomness, 360.0f );
		makeSmokeParticle(this, vel);
	}
}

Random _sprk_r(2342);
void sparks(CBlob@ this, Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 0.5f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);
		
		int colorShade = 255 - _sprk_r.NextRanged(128);
		CParticle@ p;
		if ( followsAllies( this ) )
		{
			CParticle@ p = ParticlePixel( pos, vel, SColor( 255, colorShade, colorShade, colorShade ), true );
			if(p !is null) //bail if we stop getting particles
			{
    			p.fastcollision = true;
				p.timeout = 40 + _sprk_r.NextRanged(20);
				p.scale = 0.5f + _sprk_r.NextFloat();
				p.damping = 0.95f;
				p.gravity = Vec2f(0,0);
			}
		}
		else if ( followsEnemies( this ) )
		{
			CParticle@ p = ParticlePixel( pos, vel, SColor( 255, colorShade, colorShade, 0 ), true );
			if(p !is null) //bail if we stop getting particles
			{
    			p.fastcollision = true;
				p.timeout = 40 + _sprk_r.NextRanged(20);
				p.scale = 0.5f + _sprk_r.NextFloat();
				p.damping = 0.95f;
				p.gravity = Vec2f(0,0);
			}
		}
    }
}

