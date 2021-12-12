#include "/Entities/Common/Attacks/Hitters.as";
#include "/Entities/Common/Attacks/LimitedAttacks.as";
#include "KnockedCommon.as";

const int pierce_amount = 8;

const f32 MIN_FROZEN_TIME = 1.0f;
const f32 MAX_FROZEN_TIME = 5;

void onInit( CBlob @ this )
{
	this.Tag("kill other spells");
	this.Tag("counterable");
	this.Tag("exploding");
	
    this.set_u8("launch team",255);
	this.set_f32("freeze_power", 0.0f);
	this.set_f32("damage", 1.0f);
    //this.server_setTeamNum(1);
	this.Tag("medium weight");
    
    LimitedAttack_setup(this);
    
    this.set_u8( "blocks_pierced", 0 );
    u32[] tileOffsets;
    this.set( "tileOffsets", tileOffsets );

	CShape@ shape = this.getShape();
	shape.getConsts().collideWhenAttached = true;
	shape.SetGravityScale( 0.0f );
	shape.getConsts().bullet = true;
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	
    //sparkle sound	    
	CSprite@ thisSprite = this.getSprite();
    thisSprite.SetEmitSound("ChimeLoop.ogg");
    thisSprite.SetEmitSoundVolume(2.5f);
    thisSprite.SetEmitSoundPaused(false);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick( CBlob@ this)
{
	CSprite@ thisSprite = this.getSprite();
	if (this.getTickSinceCreated() < 1)
	{
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		this.SetLightColor(SColor(255, 255, 255, 0));
		this.set_string("custom_explosion_sound", "FireBlast2.ogg");
		thisSprite.PlaySound("IceShoot.ogg", 0.5f, 1.5f + XORRandom(5)/10.0f);
		thisSprite.SetZ(50.0f);
	}
	
	//prevent leaving the map
	Vec2f pos = this.getPosition();
	if (pos.x < 0.1f 
			|| pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f
			|| pos.y < 0.1f
			|| pos.y > (getMap().tilemapheight * getMap().tilesize) - 0.1f )
	{
		Boom( this );
		return;
	}
	

    SColor lightColor = SColor( 255, 255, 150, 0);
    this.SetLightColor( lightColor );
	//rock and roll mode
	if (!this.getShape().getConsts().collidable)
	{
		Vec2f vel = this.getVelocity();
		f32 angle = vel.Angle();
		Slam( this, angle, vel, this.getShape().vellen * 1.5f );
	}

	makeSmokePuff(this);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	bool spellDeath = false;

	if ( solid || (blob !is null && blob.hasTag("barrier") && blob.getTeamNum() != this.getTeamNum()) )
	{
		this.getSprite().PlaySound("IceImpact" + (XORRandom(3)+1) + ".ogg", 0.8f, 1.0f);
		spellDeath = true;
	}
	
	if (blob !is null)
	{
		if ( (blob.hasTag("player") || blob.hasTag("freezable")) && isEnemy(this, blob) )
		{
			this.server_Hit(blob, blob.getPosition(), this.getVelocity(), 0.2f, Hitters::water, true);
			
			f32 freezeRatio = this.get_f32("freeze_power");
			Freeze( blob, Maths::Max( MIN_FROZEN_TIME, MAX_FROZEN_TIME*freezeRatio ) );
			
			spellDeath = true;
		}
	}
	else
	{
		if(isServer())
		{
			CBlob@ icePrison = server_CreateBlob( "ice_prison", this.getTeamNum(), this.getPosition() );
			if ( icePrison !is null )
			{
				icePrison.AddScript("CheapFakeRolling.as");
			}
		}
	}

	if(spellDeath)
	{
		Boom( this );
	}
}

void Freeze(CBlob@ blob, f32 frozenTime)
{	
	blob.getShape().getConsts().collideWhenAttached = false;

	Vec2f blobPos = blob.getPosition();
	if(isServer())
	{
		CBlob@ icePrison = server_CreateBlob( "ice_prison", blob.getTeamNum(), blobPos );
		if ( icePrison !is null )
		{
			AttachmentPoint@ ap = icePrison.getAttachments().getAttachmentPointByName("PICKUP2");
			if ( ap !is null )
			{
				icePrison.server_AttachTo(blob, "PICKUP2");
			}
			
			//CSpriteLayer@ iceLayer = icePrison.getSprite().getSpriteLayer( "IcePrison" );
			//if(iceLayer !is null)
			//{			
			//	iceLayer.ScaleBy(Vec2f( (blobRadius + 4.0f)/prisonRadius, (blobRadius + 4.0f)/prisonRadius));
			//}
			
			icePrison.server_SetTimeToDie(frozenTime);
		}
	}

}

void onDie(CBlob@ this)
{
	if(this.hasTag("exploding"))
	{
    	ExplodeWithIce(this);
	}
}

void ExplodeWithIce(CBlob@ this)
{
    CMap@ map = getMap();
	Vec2f thisPos = this.getPosition();
    if (map is null)   return;
	
	CBlob@[] blobsInRadius;
	if (map.getBlobsInRadius(thisPos, 24.0f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b !is null)
			{
				Vec2f bPos = b.getPosition();
				float damage = this.get_f32("damage");
				if(this.getTeamNum() == b.getTeamNum() && !isOwnerBlob(this,b))
				{
					damage = 0.0f;
				}
				this.server_Hit(b, bPos, bPos-thisPos, damage, Hitters::water, true);
			}
		}
	}
}

bool isOwnerBlob(CBlob@ this, CBlob@ target)
{
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
		( target.getTeamNum() != this.getTeamNum() && (target.getName() == this.getName() || target.hasTag("door") || target.getName() == "trap_block") )
		||
		(
			target.hasTag("flesh") 
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
			&& ( friend is null || friend.getTeamNum() != this.getTeamNum() )
		)
	);
}

void makeSmokeParticle(CBlob@ this, const Vec2f vel, const string filename = "Smoke")
{
	if(!getNet().isClient()) 
		return;
	//warn("making smoke");

	const f32 rad = 4.0f;
	f32 freezeRatio = this.get_f32("freeze_power");
	freezeRatio++;
	float freezeParticlePos = freezeRatio*64;
	Vec2f random = Vec2f( XORRandom(freezeParticlePos*2)-freezeParticlePos, XORRandom(freezeParticlePos*2)-freezeParticlePos ) * 0.015625f * rad;
	CParticle@ p = ParticleAnimated( "Sparkle" + (XORRandom(3)+1) + ".png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), freezeRatio, 2 + XORRandom(3), 0.0f, false );
	if ( p !is null)
	{
		p.bounce = 0;
    	p.fastcollision = true;
		p.Z = 400.0f;
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

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {									
		const f32 rad = 16.0f;
		Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
        CParticle@ p = ParticleAnimated( "IceBlast" + (XORRandom(3)+1) + ".png", 
									pos + random, 
									Vec2f(0,0), 
									0.0f, 
									1.0f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.damping = 0.85f;
		p.Z = 500.0f;
		p.lighting = false;
    }
}

Random _smoke_r(0x10001);
void smoke(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(4.0f + _smoke_r.NextFloat() * 4.0f, 0);
        vel.RotateBy(_smoke_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( "GenericSmoke2.png", 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									4 + XORRandom(8), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles
		

    	p.fastcollision = true;
        p.scale = 0.5f + _smoke_r.NextFloat()*0.5f;
        p.damping = 0.8f;
		p.Z = 200.0f;
		p.lighting = false;
    }
}

void Boom( CBlob@ this )
{
	blast(this.getPosition(), 5);
	this.getSprite().SetEmitSoundPaused(true);
    this.server_Die();
}

void Slam( CBlob @this, f32 angle, Vec2f vel, f32 vellen )
{
	if(vellen < 0.1f)
		return;

	CMap@ map = this.getMap();
	Vec2f pos = this.getPosition();
    HitInfo@[] hitInfos;
	u8 team = this.get_u8("launch team");

    if (map.getHitInfosFromArc( pos, -angle, 30, vellen, this, false, @hitInfos ))
    {
        for (uint i = 0; i < hitInfos.length; i++)
        {
            HitInfo@ hi = hitInfos[i];
            f32 dmg = 0.5f;

            if (hi.blob is null) // map
            {
            	if (BoulderHitMap( this, hi.hitpos, hi.tileOffset, vel, dmg, Hitters::cata_boulder ))
					return;
            }
			else if(team != u8(hi.blob.getTeamNum()))
			{
				this.server_Hit( hi.blob, pos, vel, dmg, Hitters::cata_boulder, true);
				this.setVelocity(vel*0.9f); //damp

				// die when hit something large
				if (hi.blob.getRadius() > 32.0f) {
					this.server_Hit( this, pos, vel, 0.5f, Hitters::cata_boulder, true);
				}
			}
        }
    }

	// chew through backwalls

	Tile tile = map.getTile( pos );	 
	if (map.isTileBackgroundNonEmpty( tile ) )
	{			   
		if (map.getSectorAtPosition( pos, "no build") !is null) {
			return;
		}
		map.server_DestroyTile( pos + Vec2f( 7.0f, 7.0f), 10.0f, this );
		map.server_DestroyTile( pos - Vec2f( 7.0f, 7.0f), 10.0f, this );
	}
}

bool BoulderHitMap( CBlob@ this, Vec2f worldPoint, int tileOffset, Vec2f velocity, f32 damage, u8 customData )
{
    //check if we've already hit this tile
    u32[]@ offsets;
    this.get( "tileOffsets", @offsets );

    if( offsets.find(tileOffset) >= 0 ) { return false; }

    this.getSprite().PlaySound( "ArrowHitGroundFast.ogg" );
    f32 angle = velocity.Angle();
    CMap@ map = getMap();
    TileType t = map.getTile(tileOffset).type;
    u8 blocks_pierced = this.get_u8( "blocks_pierced" );
    bool stuck = false;

    if ( map.isTileCastle(t) || map.isTileWood(t) )
    {
		Vec2f tpos = this.getMap().getTileWorldPosition(tileOffset);
		if (map.getSectorAtPosition( tpos, "no build") !is null) {
			return false;
		}

		//make a shower of gibs here
		
        map.server_DestroyTile( tpos, 100.0f, this );
        Vec2f vel = this.getVelocity();
        this.setVelocity(vel*0.8f); //damp
        this.push( "tileOffsets", tileOffset );

        if (blocks_pierced < pierce_amount)
        {
            blocks_pierced++;
            this.set_u8( "blocks_pierced", blocks_pierced );
        }
        else {
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
       this.server_Hit( this, worldPoint, velocity, 1.0f, Hitters::crush, true);
    }

	return stuck;
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
	return ( isEnemy(this, b) );
}


//sprite

void onInit( CSprite@ this )
{
    this.animation.frame = (this.getBlob().getNetworkID()%4);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}


