
//script for a bison

#include "AnimalConsts.as";
#include "MakeScroll.as";
const u8 DEFAULT_PERSONALITY = AGGRO_BIT;
const s16 MAD_TIME = 600;
const string chomp_tag = "chomping";

//sprite

void onInit(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
    this.ReloadSprites(blob.getTeamNum(),0); 
	
	this.PlaySound( "ZombieKnightGrowl.ogg" );
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
    if (this.isAnimation("revive") && !this.isAnimationEnded()) return;
	if (this.isAnimation("bite") && !this.isAnimationEnded()) return;
    if (blob.getHealth() > 0.0)
    {
		f32 x = blob.getVelocity().x;
		
		if (this.isAnimation("dead"))
		{
			this.SetAnimation("revive");
		}
		else
		if (Maths::Abs(x) > 0.1f)
		{
			if (!this.isAnimation("walk")) {
				this.SetAnimation("walk");
			}
		}
		else
		{
			if (XORRandom(500)==0)
			{
				this.PlaySound( "/ZombieKnightBreath" );
			}
			if (!this.isAnimation("idle")) {
			this.SetAnimation("idle");
			}
		}
	}
	else 
	{
		if (!this.isAnimation("dead"))
		{
			this.SetAnimation("dead");
			this.PlaySound( "/ZombieKnightDie" );
			blob.getShape().setFriction( 0.75f );
			blob.getShape().setElasticity( 0.2f );					
		}
//		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}



void onGib(CSprite@ this)
{
    if (g_kidssafe) {
        return;
    }
	
	if ( !getNet().isClient() )
		return;

    CBlob@ blob = this.getBlob();
    Vec2f pos = blob.getPosition();
    Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
    f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	const u8 team = blob.getTeamNum();
	/*
    CParticle@ Body     = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp , 80 ),       1, 0, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    CParticle@ Arm1     = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp - 0.2 , 80 ), 1, 1, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    CParticle@ Arm2     = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp - 0.2 , 80 ), 1, 2, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    CParticle@ Shield   = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp , 80 ),       1, 3, Vec2f (8,8), 2.0f, 0, "/BodyGibFall", team );
    CParticle@ Sword    = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp + 1 , 80 ),   1, 4, Vec2f (8,8), 2.0f, 0, "/BodyGibFall", team );
	*/
}



//blob
void onInit(CBrain@ this)
{
	this.getCurrentScript().runFlags = Script::tick_not_attached;
}
void onInit(CBlob@ this)
{
	//for EatOthers
	string[] tags = {"player","lantern"};
	this.set("tags to eat", tags);
	this.set_f32("gib health", -3.0f);	
	float difficulty = getRules().get_f32("difficulty")/4.0;
	if (difficulty<1.0) difficulty=1.0;
	this.set_f32("bite damage", 1.0f);
	int bitefreq = 45;//-difficulty;
	if (bitefreq<5) bitefreq=5;
	this.set_u16("bite freq", bitefreq);

	//brain
	this.set_u8(personality_property, DEFAULT_PERSONALITY);
	this.set_u8("random move freq",4);
	this.set_f32(target_searchrad_property, 360.0f);
	this.set_f32(terr_rad_property, 185.0f);
	this.set_u8(target_lose_random,34);
	
	this.getBrain().server_SetActive( true );
	
	//for steaks
	//this.set_u8("number of steaks", 1);
	
	//for shape
	this.getShape().SetRotationsAllowed(false);
	
	
	this.Tag("flesh");
	this.Tag("zombie");
	this.Tag("freezable");
	this.set_s16("mad timer", 0);

	this.getShape().SetOffset(Vec2f(0,0));
	
//	this.getCurrentScript().runFlags = Script::tick_blob_in_proximity;
//	this.getCurrentScript().runProximityTag = "player";
//	this.getCurrentScript().runProximityRadius = 320.0f;
	this.getCurrentScript().runFlags = Script::tick_not_attached;
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return this.getHealth()<0.0 || this.getTeamNum() == byBlob.getTeamNum(); //maybe make a knocked out state? for loading to cata?
}

void onTick(CBlob@ this)
{
	f32 x = this.getVelocity().x;
	
	if (this.getHealth()<0.0 && (this.getTickSinceCreated() - this.get_u16("death ticks")) > 300)
	{
		this.server_SetHealth(0.5);
		this.getShape().setFriction( 0.3f );
		this.getShape().setElasticity( 0.1f );
	}
	if (this.getHealth()<0.0) return;
	
	float difficulty = getRules().get_f32("difficulty");
	int break_chance = 30 - 2*(difficulty-1.0);	
	if (break_chance<2) break_chance=2;
	if (getGameTime() % 30 == 0 && (XORRandom(break_chance)==0))
	{	
		this.Tag(chomp_tag);
		string name = this.getName();
		CBlob@[] blobs;
		this.getMap().getBlobsInRadius( this.getPosition(), 16.0, @blobs );
		for (uint step = 0; step < blobs.length; ++step)
		{
			//TODO: sort on proximity? done by engine?
			CBlob@ other = blobs[step];
			if (other is this) continue; //lets not run away from / try to eat ourselves...
			if (other.hasTag("flesh")) continue;
			if (other.getName() == "lantern" || other.getName() == "stone_door" || other.getName() == "wooden_door" || other.getName() == "wooden_platform"  || other.getName() == "GoldBrick" || other.getTeamNum()!=this.getTeamNum())
			{
				Vec2f vel(0,0);
				this.server_Hit(other,other.getPosition(),vel,0.3,Hitters::saw, false);
				break;				
			}
		}	
	}
	if (getNet().isServer() && this.hasTag(chomp_tag))
	{
		u16 lastbite = this.get_u16("lastbite");
		u16 bitefreq = this.get_u16("bite freq");
		if (bitefreq<0) bitefreq=15;
		if (lastbite > bitefreq)
		{
			float aimangle=0;
			if(this.get_u8(state_property) == MODE_TARGET )
			{
				CBlob@ b = getBlobByNetworkID(this.get_netid(target_property));
				Vec2f vel;
				if(b !is null)
				{
					vel = b.getPosition()-this.getPosition();
					
				}
				else vel = Vec2f(1,0);
				{
					vel.Normalize();
					HitInfo@[] hitInfos;
					CMap @map = getMap();
					if (map.getHitInfosFromArc( this.getPosition()- Vec2f(2,0).RotateBy(-vel.Angle()), -vel.Angle(), 90, this.getRadius() + 8.0f, this, @hitInfos ))
					{
						//HitInfo objects are sorted, first come closest hits
						for (uint i = 0; i < hitInfos.length; i++)
						{
							HitInfo@ hi = hitInfos[i];
							CBlob@ other = hi.blob;	  
							if (other !is null)
							{
								if (other.hasTag("flesh") && other.getTeamNum() != this.getTeamNum())
								{
									f32 power = this.get_f32("bite damage");
									this.server_Hit(other,other.getPosition(),vel,power,Hitters::bite, false);
									
									this.getSprite().PlaySound( "/ZombieKnightAttack" );
									this.getSprite().SetAnimation("bite");
			
									this.set_u16("lastbite",0);
								}
								else
								{
									const bool large = other.hasTag("blocks sword") && other.isCollidable();
									if (other.hasTag("large") || large || other.getTeamNum() == this.getTeamNum())
									{
										break;
									}
								}
							}
							else
							{
								break;
							}
						}
					}
				}		
			}
		}
		else
		{
			this.set_u16("lastbite",this.get_u16("lastbite")+1);
		}
	}	
	if (Maths::Abs(x) > 1.0f)
	{
		this.SetFacingLeft( x < 0 );
	}
	else
	{
		if (this.isKeyPressed(key_left)) {
			this.SetFacingLeft( true );
		}
		if (this.isKeyPressed(key_right)) {
			this.SetFacingLeft( false );
		}
	}

	// relax the madness

	if (getGameTime() % 65 == 0)
	{
		s16 mad = this.get_s16("mad timer");
		if (mad > 0)
		{
			mad -= 65;
			if (mad < 0 ) {
				this.set_u8(personality_property, DEFAULT_PERSONALITY);
//				this.getSprite().PlaySound("/BisonBoo");
			}
			this.set_s16("mad timer", mad);
		}

//		if (XORRandom(mad > 0 ? 3 : 12) == 0)
//			this.getSprite().PlaySound("/BisonBoo");
	}

	// footsteps

	if (this.isOnGround() && (this.isKeyPressed(key_left) || this.isKeyPressed(key_right)) )
	{
		if (XORRandom(break_chance)==0)
		{
			this.Tag(chomp_tag);
			Vec2f dir = Vec2f( XORRandom(16)-8, XORRandom(16)-8 )/8.0;
			dir.Normalize();
			Vec2f tp = this.getPosition() + (dir)*(this.getRadius() + 4.0f);
			TileType tile = this.getMap().getTile( tp ).type;
			if ( !this.getMap().isTileGroundStuff( tile ) ) {		
			this.getMap().server_DestroyTile(tp, 0.2);
			}
		}
		if ((this.getNetworkID() + getGameTime()) % 9 == 0)
		{
			f32 volume = Maths::Min( 0.1f + Maths::Abs(this.getVelocity().x)*0.1f, 1.0f );
			TileType tile = this.getMap().getTile( this.getPosition() + Vec2f( 0.0f, this.getRadius() + 4.0f )).type;

			if (this.getMap().isTileGroundStuff( tile )) {
				this.getSprite().PlaySound("/EarthStep", volume, 0.75f );
			}
			else {
				this.getSprite().PlaySound("/StoneStep", volume, 0.75f );
			}
		}
	}
	
	if(getNet().isServer() && getGameTime() % 10 == 0)
	{
		if(this.get_u8(state_property) == MODE_TARGET )
		{
			CBlob@ b = getBlobByNetworkID(this.get_netid(target_property));
			if(b !is null && this.getDistanceTo(b) < 106.0f)
			{
				this.Tag(chomp_tag);
			}
			else
			{
				this.Untag(chomp_tag);
			}
		}
		else
		{
			this.Untag(chomp_tag);
		}
		this.Sync(chomp_tag,true);
	}
	
}

void MadAt( CBlob@ this, CBlob@ hitterBlob )
{
	const u16 damageOwnerId = (hitterBlob.getDamageOwnerPlayer() !is null && hitterBlob.getDamageOwnerPlayer().getBlob() !is null) ? 
		hitterBlob.getDamageOwnerPlayer().getBlob().getNetworkID() : 0;

	const u16 friendId = this.get_netid(friend_property);
	if (friendId == hitterBlob.getNetworkID() || friendId == damageOwnerId) // unfriend
		this.set_netid(friend_property, 0);
	else // now I'm mad!
	{
//		if (this.get_s16("mad timer") <= MAD_TIME/8)
//			this.getSprite().PlaySound("/BisonMad");
		this.set_s16("mad timer", MAD_TIME);
		this.set_u8(personality_property, DEFAULT_PERSONALITY | AGGRO_BIT);
		this.set_u8(state_property, MODE_TARGET);
		if (hitterBlob.hasTag("player"))
			this.set_netid(target_property, hitterBlob.getNetworkID() );
		else
			if (damageOwnerId > 0) {
				this.set_netid(target_property, damageOwnerId );
			}
	}
}

f32 getGibHealth( CBlob@ this )
{
    if (this.exists("gib health")) {
        return this.get_f32("gib health");
    }

    return 0.0f;
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{		
	MadAt( this, hitterBlob );

	if (this.getHealth()>0 && this.getHealth() <= damage)
	{
		if (getNet().isServer())
		this.set_u16("death ticks",this.getTickSinceCreated());
		this.Sync("death ticks",true);
	}
	if (customData == Hitters::arrow) damage*=2.0;
    this.Damage( damage, hitterBlob );
    // Gib if health below gibHealth
    f32 gibHealth = getGibHealth( this );
	
	//printf("ON HIT " + damage + " he " + this.getHealth() + " g " + gibHealth );
    // blob server_Die()() and then gib

	
	//printf("gibHealth " + gibHealth + " health " + this.getHealth() );
    if (this.getHealth() <= gibHealth)
    {
        this.getSprite().Gib();
		if (hitterBlob.hasTag("player"))
		{
			CPlayer@ player = hitterBlob.getPlayer();
		} else
		if(hitterBlob.getDamageOwnerPlayer() !is null)
		{
			CPlayer@ player = hitterBlob.getDamageOwnerPlayer();
		}
		if (getNet().isServer())
		{
			
			warn("SS: "+getRules().get_bool("scrolls_spawn"));
			int r = XORRandom(30);
			if (r<3 && getRules().get_bool("scrolls_spawn"))
			{
				if (r == 0)
					server_MakePredefinedScroll( hitterBlob.getPosition() + Vec2f(0,-3.0f), "carnage" );
				else
				if (r == 1)
					server_MakePredefinedScroll( hitterBlob.getPosition() + Vec2f(0,-3.0f), "midas" );				
				else
				if (r == 2)
					server_MakePredefinedScroll( hitterBlob.getPosition() + Vec2f(0,-3.0f), "tame" );				
			}
			else
			{
				//server_DropCoins(hitterBlob.getPosition() + Vec2f(0,-3.0f), 50);
			}
		}
        this.server_Die();
    }
		
    return 0.0f; //done, we've used all the damage	
	
}														

#include "Hitters.as";

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	if ( blob.hasTag("dead") || (this.getTeamNum() == blob.getTeamNum() && !blob.hasTag("zombie")) )
		return false;
	
	if (blob.hasTag("zombie") && blob.getHealth()<0.0) return false;
	return true;
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1 )
{
	if (this.getHealth() <= 0.0) return; // dead
	if (blob is null)
		return;

	const u16 friendId = this.get_netid(friend_property);
	CBlob@ friend = getBlobByNetworkID(friendId);
	if (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("flesh") && (!blob.hasTag("dead") || blob.hasTag("zombie")))
	{
		MadAt( this, blob );
	}
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
/*	if (hitBlob !is null)
	{
		Vec2f force = velocity * this.getMass() * 0.35f ;
		force.y -= 1.0f;
		hitBlob.AddForce( force);
	}*/
}
