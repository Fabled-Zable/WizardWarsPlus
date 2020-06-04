#include "/Entities/Common/Attacks/Hitters.as";
#include "/Entities/Common/Attacks/LimitedAttacks.as";

const int pierce_amount = 8;

const f32 hit_amount_ground = 0.5f;
const f32 hit_amount_air = 1.0f;
const f32 hit_amount_air_fast = 3.0f;
const f32 hit_amount_cata = 10.0f;

void onInit(CBlob @ this)
{
	this.set_u8("launch team", 255);
	this.set_bool("initialized", false);
	this.set_u16("tile num", 0);
	
	this.server_setTeamNum(-1);
	this.Tag("medium weight");
	this.Tag("debris blob");

	LimitedAttack_setup(this);

	this.set_u8("blocks_pierced", 0);
	u32[] tileOffsets;
	this.set("tileOffsets", tileOffsets);
	
	this.getSprite().SetZ(500.0f);
	
	this.getShape().SetGravityScale(0.6f);

	// damage
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBlob@ this)
{
	int tickSinceCreated = this.getTickSinceCreated();
	bool initialized = this.get_bool("initialized");
	if ( initialized == false && tickSinceCreated > 1 )
	{
		CSprite@ thisSprite = this.getSprite();
		CMap@ map = this.getMap();
		u16 tileNum = this.get_u16("tile num");
		
		if ( map.isTileCastle(tileNum) )
		{
			thisSprite.SetFrame(0);
		}
		else if ( map.isTileWood(tileNum) )
		{
			thisSprite.SetFrame(1);
		}
		else if ( map.isTileGroundStuff(tileNum) )
		{
			thisSprite.SetFrame(2);
		}
	
		this.set_bool("initialized", true);
	}

	//settling code
	const bool onground = this.isOnGround();
	Vec2f thisVel = this.getVelocity();
	f32 velLength = thisVel.getLength();
	if ( (onground && tickSinceCreated > 20) || (velLength < 1.0f && tickSinceCreated > 200) )
	{
		Settle( this );
	}
	
	//rock and roll mode
	if (!this.getShape().getConsts().collidable)
	{
		Vec2f vel = this.getVelocity();
		f32 angle = vel.Angle();
		Slam(this, angle, vel, this.getShape().vellen * 1.5f);
	}
	
	if ( getGameTime() % 2 == 0 )
		makeSmokeParticle(this, Vec2f(0,0));
}

void Settle(CBlob @this)
{
	Vec2f tilepos = this.getPosition() + Vec2f(0, 4);
	CMap@ map = this.getMap();
	u16 tileNum = this.get_u16("tile num");
	
	if ( map.isTileCastle(tileNum) )
	{
		map.server_SetTile(tilepos, CMap::tile_castle);
	}
	else if ( map.isTileWood(tileNum) )
	{
		map.server_SetTile(tilepos, CMap::tile_wood);
	}
	else if ( map.isTileGroundStuff(tileNum) )
	{
		map.server_SetTile(tilepos, CMap::tile_ground);
	}	
	this.getSprite().PlaySound("Impact01.ogg");
	
	this.server_Die();
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if ( blob.isCollidable() == false || blob.hasTag("projectile") )
	{
		return false;
	}

	return true;
}

void makeSmokeParticle(CBlob@ this, const Vec2f vel, const string filename = "Smoke")
{
	if(isServer()) 
		return;
	//warn("making smoke");

	const f32 rad = 4.0f;
	Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
	CParticle@ p = ParticleAnimated( "GenericSmoke4.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.0f, false );
	if ( p !is null)
	{
		p.bounce = 0;
    	p.fastcollision = true;
		p.Z = 0.0f;
	}
	
	//warn("smoke made");
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached.getName() == "catapult") // rock n' roll baby
	{
		this.getShape().getConsts().mapCollisions = false;
		this.getShape().getConsts().collidable = false;
	}
	this.set_u8("launch team", detached.getTeamNum());
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached.getName() != "catapult") // end of rock and roll
	{
		this.getShape().getConsts().mapCollisions = true;
		this.getShape().getConsts().collidable = true;
	}
	this.set_u8("launch team", attached.getTeamNum());
}

void Slam(CBlob @this, f32 angle, Vec2f vel, f32 vellen)
{
	if (vellen < 0.1f)
		return;

	CMap@ map = this.getMap();
	if (map is null)
	{return;}
	Vec2f pos = this.getPosition();
	HitInfo@[] hitInfos;
	u8 team = this.get_u8("launch team");

	if (map.getHitInfosFromArc(pos, -angle, 30, vellen, this, false, @hitInfos))
	{
		if (hitInfos is null)
		{return;}
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			f32 dmg = 2.0f;

			if (hi is null)
			{return;}

			if (hi.blob is null) // map
			{
				if (BoulderHitMap(this, hi.hitpos, hi.tileOffset, vel, dmg, Hitters::crush))
					return;
			}
			else if (team != u8(hi.blob.getTeamNum()))
			{
				if(hi.blob.getName() == "knight") //less damage for knights
				{dmg *= 0.1f;}
				this.server_Hit(hi.blob, pos, vel, dmg, Hitters::crush, true);
				this.setVelocity(vel * 0.9f); //damp
			}
		}
	}
}

bool BoulderHitMap(CBlob@ this, Vec2f worldPoint, int tileOffset, Vec2f velocity, f32 damage, u8 customData)
{
	//check if we've already hit this tile
	u32[]@ offsets;
	this.get("tileOffsets", @offsets);

	if (offsets.find(tileOffset) >= 0) { return false; }

	f32 angle = velocity.Angle();
	CMap@ map = getMap();
	TileType t = map.getTile(tileOffset).type;
	u8 blocks_pierced = this.get_u8("blocks_pierced");
	bool stuck = false;

	if (map.isTileCastle(t) || map.isTileWood(t))
	{
		Vec2f tpos = this.getMap().getTileWorldPosition(tileOffset);
		if (map.getSectorAtPosition(tpos, "no build") !is null)
		{
			return false;
		}

		//make a shower of gibs here
		
		Vec2f vel = this.getVelocity();
		this.push("tileOffsets", tileOffset);

		if (blocks_pierced < pierce_amount)
		{
			blocks_pierced++;
			this.set_u8("blocks_pierced", blocks_pierced);
		}
		else
		{
			stuck = true;
		}
	}
	else
	{
		stuck = true;
	}

	if (velocity.LengthSquared() < 5)
		stuck = true;

	return stuck;
}


void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (solid && blob !is null)
	{
		Vec2f hitvel = this.getOldVelocity();
		Vec2f hitvec = point1 - this.getPosition();
		f32 coef = hitvec * hitvel;

		if (coef < 0.706f) // check we were flying at it
		{
			return;
		}

		f32 vellen = hitvel.Length();

		//fast enough
		if (vellen < 1.0f)
		{
			return;
		}

		u8 tteam = this.get_u8("launch team");
		CPlayer@ damageowner = this.getDamageOwnerPlayer();

		//not teamkilling (except self)
		if (damageowner is null || damageowner !is blob.getPlayer())
		{
			if (
			    (blob.getName() != this.getName() &&
			     (blob.getTeamNum() == this.getTeamNum() || blob.getTeamNum() == tteam))
			)
			{
				return;
			}
		}

		//not hitting static stuff
		if (blob.getShape() !is null && blob.getShape().isStatic())
		{
			return;
		}

		//hitting less or similar mass
		if (this.getMass() < blob.getMass() - 1.0f)
		{
			return;
		}

		//get the dmg required
		hitvel.Normalize();
		f32 dmg = vellen > 8.0f ? 5.0f : (vellen > 4.0f ? 1.5f : 0.5f);

		//bounce off if not gibbed
		if(dmg < 4.0f)
		{
			this.setVelocity(blob.getOldVelocity() + hitvec * -Maths::Min(dmg * 0.33f, 1.0f));
		}

		//hurt
		if(blob.getName() == "knight") //less damage for knights
		{dmg *= 0.1f;}
		this.server_Hit(blob, point1, hitvel, dmg, Hitters::crush, true);
		this.server_Hit(this, point1, -hitvel, dmg*8.0f, Hitters::crush, true);

		return;

	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if ( this.getTickSinceCreated() <= 6 )
	{
		damage = 0.0f;
	}
	
	if (customData == Hitters::sword || customData == Hitters::arrow)
	{
		return damage *= 0.5f;
	}	

	return damage;
}
