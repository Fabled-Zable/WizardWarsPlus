﻿
//script for a bison

#include "AnimalConsts.as";

const u8 DEFAULT_PERSONALITY = AGGRO_BIT;
const s16 GRAB_TIME = 100;
const s16 MAD_TIME = 600;
const s16 STARVE_TIME = 100;

const string chomp_tag = "chomping";

//sprite

void onInit(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
    this.ReloadSprites(blob.getTeamNum(),0); 
	
    this.SetEmitSound("Wings.ogg");
    this.SetEmitSoundVolume(1.0f);
    this.SetEmitSoundPaused(false);
	
	if ( XORRandom(2) == 0 )
		this.PlaySound( "GregCry.ogg" );
	else
		this.PlaySound( "GregRoar.ogg" );
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
		{
			if (!this.isAnimation("fly")) {
				this.SetAnimation("fly");
			}
		}
	}
	else 
	{
		if (!this.isAnimation("dead"))
		{
			this.SetAnimation("dead");
			this.PlaySound( "/SkeletonBreak1" );
		}
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}

//blob
void onInit(CBrain@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_attached;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags = 0;
}

void onInit(CBlob@ this)
{
	//for EatOthers
	string[] tags = {"player"};
	this.set("tags to eat", tags);
	
	this.set_f32("bite damage", 0.125f);
	
	//brain
	this.set_u8(personality_property, DEFAULT_PERSONALITY);
	this.set_u8("random move freq",8);
	this.set_f32(target_searchrad_property, 560.0f);
	this.set_f32(terr_rad_property, 185.0f);
	this.set_u8(target_lose_random,34);
	
	//for steaks
	//this.set_u8("number of steaks", 1);
	
	//for shape
	this.getShape().SetRotationsAllowed(false);
	
	//for flesh hit
	this.set_f32("gib health", -0.0f);
	
	this.Tag("flesh");
	this.Tag("zombie");
	this.Tag("Greg");
	this.Tag("freezable");
	this.set_s16("mad timer", 0);
	this.set_s16("grab timer", 0);

//	this.getShape().SetOffset(Vec2f(0,8));
	
//	this.getCurrentScript().runFlags = Script::tick_blob_in_proximity;
//	this.getCurrentScript().runProximityTag = "player";
//	this.getCurrentScript().runProximityRadius = 320.0f;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags |= Script::tick_attached;
	this.getCurrentScript().runFlags = 0;
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false; //maybe make a knocked out state? for loading to cata?
}

void onTick(CBlob@ this)
{
	CPlayer@ thisPlayer = this.getPlayer();
	if ( this.getTickSinceCreated() == 10 && thisPlayer is null )
		this.getBrain().server_SetActive( true );

	if ( getGameTime() % STARVE_TIME == 0 )
		this.server_Hit( this, this.getPosition(), Vec2f(0,0), 0.5f, Hitters::bite, true);
		
	if ( this.isKeyJustPressed(key_action1) )
	{
		this.server_DetachAll();
	}

	f32 x = this.getVelocity().x;
	if (this.hasAttached())
	{
		s16 grabTimer = this.get_s16("grab timer");
	
		Vec2f pos = this.getPosition();
		CMap@ map = this.getMap();
		const f32 radius = this.getRadius();
		
		f32 x = pos.x;
		Vec2f top = Vec2f(x, map.tilesize);
		Vec2f bottom = Vec2f(x, map.tilemapheight * map.tilesize);
		Vec2f end;
		
		if (map.rayCastSolid(top,bottom,end))
		{
			f32 y = end.y;
			
			if ( grabTimer > GRAB_TIME )
			{	
				this.server_DetachAll();
			}
		}
		
		this.set_s16("grab timer", grabTimer+1);
	}
	else
		this.set_s16("grab timer", 0);

	if (Maths::Abs(x) > 1.0f)
	{
		this.SetFacingLeft( x > 0 );
	}
	else
	{
		if (this.isKeyPressed(key_left)) {
			this.SetFacingLeft( false );
		}
		if (this.isKeyPressed(key_right)) {
			this.SetFacingLeft( true );
		}
	}

	// footsteps

	if (this.isOnGround() && (this.isKeyPressed(key_left) || this.isKeyPressed(key_right)) )
	{
		if (XORRandom(20)==0)
		{
			Vec2f tp = this.getPosition() + (Vec2f( XORRandom(16)-8, XORRandom(16)-8 )/8.0)*(this.getRadius() + 4.0f);
			TileType tile = this.getMap().getTile( tp ).type;
			if ( this.getMap().isTileWood( tile ) ) {		
			//this.getMap().server_DestroyTile(tp, 0.1);
			}
		}	
		if (this.isKeyPressed(key_right))
		{
			TileType tile = this.getMap().getTile( this.getPosition() + Vec2f( this.getRadius() + 4.0f, 0.0f )).type;
			if (this.getMap().isTileCastle( tile )) {		
			//this.getMap().server_DestroyTile(this.getPosition() + Vec2f( this.getRadius() + 4.0f, 0.0f ), 0.1);
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

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{		
	if (damage>this.getHealth() && this.getHealth()>0)
	{
		if (hitterBlob.hasTag("player"))
		{
			CPlayer@ player = hitterBlob.getPlayer();
		} else
		if(hitterBlob.getDamageOwnerPlayer() !is null)
		{
			CPlayer@ player = hitterBlob.getDamageOwnerPlayer();
		}
		//server_DropCoins(hitterBlob.getPosition() + Vec2f(0,-3.0f), 25);
	}
	
	MadAt( this, hitterBlob );
	
	if ( this !is hitterBlob )
		this.server_DetachAll();
	
	return damage;
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	this.set_s16("grab timer", 0);
}														

#include "Hitters.as";

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	if ( blob.hasTag("dead") || (this.getTeamNum() == blob.getTeamNum() && !blob.hasTag("zombie")) )
		return false;
	
	return true;
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1 )
{
	if (this.getHealth() <= 0.0) return; // dead
	
	if (blob is null)
		return;

	if ( blob.hasTag("flesh") && !blob.hasTag("dead") && blob.getName() != "Wraith" )
	{
		const f32 vellen = this.getShape().vellen;
		f32 power = this.get_f32("bite damage");
		if (vellen > 0.1f)
		{
			Vec2f pos = this.getPosition();
			Vec2f vel = this.getVelocity();
			Vec2f other_pos = blob.getPosition();
			Vec2f direction = other_pos - pos;		
			direction.Normalize();
			vel.Normalize();
			//if (vel * direction > 0.33f)
			if ( getNet().isServer() && !(this.getTeamNum() == blob.getTeamNum()) && !blob.isAttached() )
			{
				f32 power = 1.0;
				
				CSprite@ thisSprite = this.getSprite();
				thisSprite.PlaySound( "/SkeletonAttack" );
				thisSprite.SetAnimation("bite");
					
				this.server_Hit( blob, point1, vel, power, Hitters::bite, false);
				
				if ( !blob.hasTag("Greg") )
				{
					this.server_AttachTo(blob,"PICKUP");
				}
				
				this.server_Heal(power*0.9f);
				
				//this.getShape().getConsts().collideWhenAttached = true;
				//blob.getShape().getConsts().collideWhenAttached = true;
			}
		}	

		MadAt( this, blob );
	}
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	if (hitBlob !is null && customData == Hitters::flying)
	{
		Vec2f force = velocity * this.getMass() * 0.35f ;
		force.y -= 7.0f;
		hitBlob.AddForce( force);
	}
}

void onDie( CBlob@ this )
{
	CSprite@ thisSprite = this.getSprite();
	
	if ( thisSprite !is null )
		thisSprite.Gib();
}