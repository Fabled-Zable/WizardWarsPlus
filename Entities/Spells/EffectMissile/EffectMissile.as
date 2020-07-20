#include "Hitters.as";	   
#include "LimitedAttacks.as";
#include "SpellCommon.as";

const int LIFETIME = 4;
const int EXTENDED_LIFETIME = 6;
const f32 SEARCH_RADIUS = 64.0f;
const f32 HOMING_FACTOR = 6.0f;
const int HOMING_DELAY = 15;	

const int INIT_DELAY = 2;	//prevents initial seg pos to be at (0,0)

void onInit( CBlob @ this )
{
	this.Tag("phase through spells");
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
	this.set_bool("setupDone",false);
}

void onTick( CBlob@ this)
{
	CSprite@ thisSprite = this.getSprite();
	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();

	if(!this.exists("setupDone") || !this.get_bool("setupDone"))//this is done instead of using onInit becuase onInit only runs once even if this script is removed and added again
	{
		string effect = this.get_string("effect");
		if(effect == "heal")
		{
			thisSprite.SetFrame(1);
		}
		else if(effect == "haste")
		{
			thisSprite.SetFrame(0);
		}
		else if(effect == "slow"){
			thisSprite.SetFrame(3);
		}
		else if(effect == "revive")
		{
			thisSprite.SetFrame(2);
		}
		else if(effect == "mana")
		{
			thisSprite.SetFrame(4);
		}
		else if(effect == "airblastShield")
		{
			thisSprite.SetFrame(5);
		}
		else if(effect == "fireProt")
		{
			thisSprite.SetFrame(6);
		}
		else if(effect == "stoneSkin")
		{
			thisSprite.SetFrame(7);
		}
		this.set_bool("setupDone",true);
	}
	
	bool isDead = this.get_bool("dead");
	
	bool onCollisionTriggered = this.get_bool("onCollision triggered");	//used to sync server and client onCollision 
	
	if ( this.get_bool("initialized") == false && this.getTickSinceCreated() > INIT_DELAY )
	{
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		SColor lightColor = SColor( 255, 255, 150, 0);
		this.SetLightColor( lightColor );
		if(!this.get_bool("silent"))
		{
			thisSprite.PlaySound("GenericProjectile1.ogg", 0.8f, 1.0f + XORRandom(3)/10.0f);
		}
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
					if (other.getTeamNum() == this.getTeamNum() && !isOwnerBlob(this, other) && other.hasTag("player") && !other.hasTag("dead")) //home in on living allies
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
					if (other.getTeamNum() != this.getTeamNum() && other.hasTag("player") && !other.hasTag("dead")) //home in on enemies
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
		
		if ( blob !is null )
		{	
			string effectType = this.get_string("effect");
			
			if (blob.hasTag("player") && !blob.hasTag("dead"))
			{	
				if ( !isEnemy(this, blob) && followsAllies( this ) && !isOwnerBlob(this, blob) )	//buff status effects
				{
					if ( effectType == "heal" )
						Heal(blob, this.get_f32("heal_amount"));
					else if ( effectType == "haste" )
						Haste(blob, this.get_u16("effect_time"));
					else if ( effectType == "mana" )
						manaShot(blob, this.get_u8("mana_used"), this.get_u8("caster_mana"), this.get_bool("silent"));
					else if ( effectType == "airblastShield" )
						AirblastShield(blob, this.get_u16("effect_time"));
					else if ( effectType == "fireProt" )
						FireWard(blob, this.get_u16("effect_time"));
					else if ( effectType == "stoneSkin" )
						StoneSkin(blob, this.get_u16("effect_time"));
					Die( this );
				}
				else if ( isEnemy(this, blob) && followsEnemies( this ) )	//curse status effects
				{
					if ( effectType == "slow" )
						Slow(blob, this.get_u16("effect_time"));
						
					Die( this );
				}
			}
			else if ( blob.getName() == "gravestone" && blob.getTeamNum() == this.getTeamNum() && followsDeadAllies( this ) )	//ally revive spells
			{
				if ( effectType == "revive" )
					Revive(blob);
					
				if ( effectType == "unholy_res" )
					UnholyRes(blob);
					
				Die( this );
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
	string effectType = this.get_string("effect");
	
	return ( 
		effectType == "heal"
	 || effectType == "haste" 
	 || effectType == "mana" 
	 || effectType == "airblastShield"
	 || effectType == "fireProt"
	 || effectType == "stoneSkin");
}

bool followsEnemies( CBlob@ this )
{		
	string effectType = this.get_string("effect");
	
	return ( effectType == "slow" );
}

bool followsDeadAllies( CBlob@ this )
{		
	string effectType = this.get_string("effect");
	
	return ( effectType == "revive" || effectType == "unholy_res" );
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return ( blob.hasTag("solidblob") );
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	if ( blob is null )
		return;
		
	this.set_bool("onCollision triggered", true);
	this.set_netid("onCollision blob", blob.getNetworkID());
	
	this.Sync("onCollision triggered", true);
	this.Sync("onCollision blob", true);
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

Random _sprk_r(2345);
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
				p.timeout = 40 + _sprk_r.NextRanged(20);
				p.scale = 0.5f + _sprk_r.NextFloat();
    			p.fastcollision = true;
				p.damping = 0.95f;
				p.gravity = Vec2f(0,0);
			}
		}
		else if ( followsEnemies( this ) )
		{
			CParticle@ p = ParticlePixel( pos, vel, SColor( 255, colorShade, colorShade, 0 ), true );
			if(p !is null) //bail if we stop getting particles
			{
				p.timeout = 40 + _sprk_r.NextRanged(20);
				p.scale = 0.5f + _sprk_r.NextFloat();
    			p.fastcollision = true;
				p.damping = 0.95f;
				p.gravity = Vec2f(0,0);
			}
		}
    }
}

