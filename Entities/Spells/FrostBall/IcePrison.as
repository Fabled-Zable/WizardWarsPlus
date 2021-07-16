#include "/Entities/Common/Attacks/Hitters.as";
#include "/Entities/Common/Attacks/LimitedAttacks.as";

const int pierce_amount = 8;

const f32 hit_amount_ground = 0.2f;
const f32 hit_amount_air = 3.0f;
const f32 hit_amount_cata = 10.0f;

void onInit(CBlob @ this)
{
	this.getSprite().PlaySound("IceCracking.ogg");
	
	this.Tag("kill other spells");
	this.Tag("counterable");

	this.set_u8("launch team", 255);
	this.server_setTeamNum(-1);
	this.Tag("super heavy weight");
	this.set_bool("inprisoning", false);

	LimitedAttack_setup(this);

	this.set_u8("blocks_pierced", 0);
	u32[] tileOffsets;
	this.set("tileOffsets", tileOffsets);

	// damage
	this.set_f32("hit dmg modifier", hit_amount_ground);
	this.set_f32("map dmg modifier", 0.0f); //handled in this script
	this.set_u8("hurtoncollide hitter", Hitters::boulder);
	
	this.getShape().getConsts().collideWhenAttached = false;

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().tickFrequency = 3;
	
	//this.getShape().getConsts().radius = 32.0f;
	
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(100.0f);
	this.set_bool("frozen target detected", false);
}

void onTick(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	CShape@ shape = this.getShape();

	if ( !this.get_bool("frozen target detected") && this.getTickSinceCreated() > 2 )
	{
		CBlob@ blob = this.getAttachments().getAttachedBlob( "PICKUP2" );
		if (blob !is null)
		{
			this.set_bool("inprisoning", true);
			shape.setFriction(0.5f);

			f32 blobRadius = blob.getRadius();
			f32 prisonRadius = this.getRadius();
			
			shape.getConsts().radius = blobRadius + 2.0f;
			sprite.SetVisible(false);
			
			CSpriteLayer@ layer = sprite.addSpriteLayer( "IcePrison", 16, 16 );
			if (layer !is null)
			{
				layer.SetRelativeZ(200.0f);
				layer.ScaleBy( Vec2f( ((blobRadius + 12.0f)/prisonRadius)*0.5f, ((blobRadius + 12.0f)/prisonRadius)*0.5f ) );
				layer.setRenderStyle(RenderStyle::light);
				Animation@ anim = layer.addAnimation( "default", 1, false );
				anim.AddFrame(0);
				layer.SetAnimation("default");  
			}
			
			this.set_bool("frozen target detected", true);
		}
	}

	//rock and roll mode
	if (!shape.getConsts().collidable)
	{
		Vec2f vel = this.getVelocity();
		f32 angle = vel.Angle();
		Slam(this, angle, vel, shape.vellen * 1.5f);
	}
	//normal mode
	else if (!this.isOnGround())
	{
		this.set_f32("hit dmg modifier", hit_amount_air);
	}
	else
	{
		this.set_f32("hit dmg modifier", hit_amount_ground);
	}
}

void onDie(CBlob@ this)
{
	CBlob@ blob = this.getAttachments().getAttachedBlob( "PICKUP2" );
	if (blob !is null)
	{
		blob.getSprite().setRenderStyle(RenderStyle::normal);
	}
	
	this.getSprite().PlaySound("IceImpact4.ogg", 0.8f, 1.0f);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached.getName() == "catapult") // rock n' roll baby
	{
		this.getShape().getConsts().mapCollisions = false;
		this.getShape().getConsts().collidable = false;
		this.getCurrentScript().tickFrequency = 3;
		this.set_f32("hit dmg modifier", hit_amount_cata);
		this.set_u8("hurtoncollide hitter", Hitters::cata_boulder);
	}
	this.set_u8("launch team", detached.getTeamNum());
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached.getName() != "catapult") // end of rock and roll
	{
		this.getShape().getConsts().mapCollisions = true;
		this.getShape().getConsts().collidable = true;
		this.getCurrentScript().tickFrequency = 1;
		this.set_f32("hit dmg modifier", hit_amount_ground);
		this.set_u8("hurtoncollide hitter", Hitters::boulder);
	}
	this.set_u8("launch team", attached.getTeamNum());
}

void Slam(CBlob @this, f32 angle, Vec2f vel, f32 vellen)
{
	if (vellen < 0.1f)
		return;

	CMap@ map = this.getMap();
	Vec2f pos = this.getPosition();
	HitInfo@[] hitInfos;
	u8 team = this.get_u8("launch team");

	if (map.getHitInfosFromArc(pos, -angle, 30, vellen, this, false, @hitInfos))
	{
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			f32 dmg = 2.0f;

			if (hi.blob is null) // map
			{
				if (BoulderHitMap(this, hi.hitpos, hi.tileOffset, vel, dmg, Hitters::cata_boulder))
					return;
			}
			else if (team != u8(hi.blob.getTeamNum()))
			{
				this.server_Hit(hi.blob, pos, vel, dmg, Hitters::cata_boulder, true);
				this.setVelocity(vel * 0.9f); //damp

				// die when hit something large
				if (hi.blob.getRadius() > 32.0f)
				{
					this.server_Hit(this, pos, vel, 10, Hitters::cata_boulder, true);
				}
			}
		}
	}

	// chew through backwalls

	Tile tile = map.getTile(pos);
	if (map.isTileBackgroundNonEmpty(tile))
	{
		if (map.getSectorAtPosition(pos, "no build") !is null)
		{
			return;
		}
		map.server_DestroyTile(pos + Vec2f(7.0f, 7.0f), 10.0f, this);
		map.server_DestroyTile(pos - Vec2f(7.0f, 7.0f), 10.0f, this);
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

		map.server_DestroyTile(tpos, 100.0f, this);
		Vec2f vel = this.getVelocity();
		this.setVelocity(vel * 0.8f); //damp
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

	if (stuck)
	{
		this.server_Hit(this, worldPoint, velocity, 10, Hitters::crush, true);
	}

	return stuck;
}

//sprite

void onInit(CSprite@ this)
{
	this.animation.frame = (this.getBlob().getNetworkID() % 4);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.get_bool("inprisoning");
}