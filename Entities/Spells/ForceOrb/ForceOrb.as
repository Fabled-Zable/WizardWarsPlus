#include "/Entities/Common/Attacks/Hitters.as";	   
#include "/Entities/Common/Attacks/LimitedAttacks.as";
const int pierce_amount = 11118;

const f32 hit_amount_ground = 1000.0f;
const f32 hit_amount_air = 3000.0f;
const f32 hit_amount_cata = 1000.0f;
void onInit(CBlob@ this)
{
	this.Tag("kill other spells");
	this.Tag("counterable");
	this.Tag("exploding");
	this.set_f32("explosive_radius", 40.0f);
	this.set_f32("explosive_damage", 0.0f);
	this.set_f32("map_damage_radius", 4.0f);
	this.set_f32("map_damage_ratio", -1.0f); //heck no!
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	
	this.getShape().getConsts().bullet = true;
}

void onTick(CBlob@ this)
{
	if (this.getCurrentScript().tickFrequency == 1)
	{
		this.getShape().SetGravityScale(0.0f);
		this.server_SetTimeToDie(3);
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		this.SetLightColor(SColor(255, 211, 121, 224));
		this.set_string("custom_explosion_sound", "ForceOrbExplosion.ogg");
		this.getSprite().PlaySound("WizardShoot.ogg", 2.0f);
		this.getSprite().SetZ(1000.0f);

		//makes a stupid annoying sound
		//ParticleZombieLightning( this.getPosition() );

		// done post init
		this.getCurrentScript().tickFrequency = 10;
	}

	{
		u16 id = this.get_u16("target");
		if (id != 0xffff && id != 0)
		{
			CBlob@ b = getBlobByNetworkID(id);
			if (b !is null)
			{
				Vec2f vel = this.getVelocity();
				if (vel.LengthSquared() < 9.0f)
				{
					Vec2f dir = b.getPosition() - this.getPosition();
					dir.Normalize();


					this.setVelocity(vel + dir * 3.0f);
				}
			}
		}
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return 
	(
		( target.getTeamNum() != this.getTeamNum() && (target.hasTag("kill other spells") || target.hasTag("door") || target.getName() == "trap_block") )
		||
		(
			target.hasTag("flesh") 
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
			&& ( friend is null || friend.getTeamNum() != this.getTeamNum() )
		)
	);	
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	CMap@ map = this.getMap();
	Vec2f pos = this.getPosition();
    HitInfo@[] hitInfos;
	for (uint i = 0; i < hitInfos.length; i++)
	{	
		HitInfo@ hi = hitInfos[i];
		f32 dmg = 1111.5f;
		if (solid || blob.hasTag("kill other spells"))
		{
			this.getSprite().PlaySound("EnergyBounce" + (XORRandom(2)+1) + ".ogg", 0.3f, 1.0f + XORRandom(3)/10.0f);
			sparks(this.getPosition(), 4);
			//this.server_Hit( hi.blob, pos, 100, dmg, Hitters::ram, true);
			this.server_Die();
			
			
		
		}
	}
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

	return stuck;
}

void onDie(CBlob@ this)
{
	sparks(this.getPosition(), 10);
}

Random _sprk_r(325432);
void sparks(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixel( pos, vel, SColor( 255, 255, 128+_sprk_r.NextRanged(128), _sprk_r.NextRanged(128)), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    }
}
