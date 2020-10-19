#include "/Entities/Common/Attacks/Hitters.as";

const f32 hit_amount_ground = 0.6f;
const f32 hit_amount_air = 3.0f;

const int bomb_timer = 70;
const int min_detonation_time = 18;

void onInit( CBlob @ this )
{
	this.Tag("kill other spells");
	this.Tag("counterable");

	this.Tag("medium weight");
	this.Tag("ignore fall");
    
    // damage
	this.set_f32("map dmg modifier", 0.0f); //handled in this script
	this.set_u8("hurtoncollide hitter", Hitters::boulder);

	CShape@ shape = this.getShape();
	shape.getConsts().collideWhenAttached = true;
	shape.SetGravityScale( 0.25f );
	shape.getConsts().bullet = true;
	shape.SetRotationsAllowed(false);
	
	this.set_f32("explosive_radius",16.0f);
	this.set_f32("explosive_damage",2.0f);
	this.set_string("custom_explosion_sound", "Entities/Items/Explosives/KegExplosion.ogg");
	this.set_f32("map_damage_radius", 16.0f);
	this.set_f32("map_damage_ratio", 1.0f);
	this.set_bool("map_damage_raycast", true);
	this.set_bool("explosive_teamkill", false);
    this.Tag("exploding");
	
	this.set_bool("bomb armed", false);
	this.set_f32("bomb timer", bomb_timer);
	
    //burning sound	    
	CSprite@ thisSprite = this.getSprite();
    thisSprite.SetEmitSound("MolotovBurning.ogg");
    thisSprite.SetEmitSoundVolume(5.0f);
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
		this.SetLightColor(SColor( 255, 255, 150, 0));
		this.set_string("custom_explosion_sound", "FireBlast2.ogg");
		thisSprite.PlaySound("FireBlast4.ogg", 0.8f, 1.0f + XORRandom(20)/10.0f);
		thisSprite.SetZ(1000.0f);
	}
	
	//face towards target like a ballista bolt
	Vec2f velocity = this.getVelocity();
	f32 angle = velocity.Angle();	
	thisSprite.ResetTransform();
	thisSprite.RotateBy( -angle, Vec2f(0,0) );
	
	makeSmokePuff(this);

	if ( this.get_bool("bomb armed") )
	{
		f32 bombTimer = this.get_f32("bomb timer");
		if ( bombTimer <= 0 )
		{
			this.getSprite().SetEmitSoundPaused(true);
			Boom( this );
		}
		else
			this.set_f32("bomb timer", bombTimer - 1);
	}
	
	if ( velocity.getLength() == 0 && this.getTickSinceCreated() > min_detonation_time )
		Boom( this );
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	if (blob !is null)
	{
		if( blob.hasTag("zombie") && isEnemy(this, blob))
		{
			this.server_Hit(blob, blob.getPosition(), this.getVelocity(), 2.0f, Hitters::fire, true);
		}
		else if ( (blob.hasTag("player") && isEnemy(this, blob)) && this.getTickSinceCreated() > min_detonation_time )
		{
			if (!this.isOnGround() && !this.isInWater() && !this.get_bool("bomb armed"))
			{
				if(blob.get_u16("fireProt") > 0)
				{
					this.server_Hit(blob, blob.getPosition(), this.getVelocity(), 0.0f, Hitters::fire, true);
				}
				else
				{
					this.server_Hit(blob, blob.getPosition(), this.getVelocity(), hit_amount_air, Hitters::fire, true);
				}
			}
			else
			{
				if(blob.get_u16("fireProt") > 0)
				{
					this.server_Hit(blob, blob.getPosition(), this.getVelocity(), 0.0f, Hitters::fire, true);
				}
				else
				{
					this.server_Hit(blob, blob.getPosition(), this.getVelocity(), hit_amount_ground, Hitters::fire, true);
				}
			}
			Boom( this );
		}
	}
	if(this is null){return;}
	if ( solid )
	{
		this.set_bool("bomb armed", true);
		this.getSprite().PlaySound("FireBlast11.ogg", 0.8f, 1.0f + XORRandom(20)/10.0f);
	}
}

void ExplodeWithFire(CBlob@ this)
{
    CMap@ map = getMap();
	Vec2f thisPos = this.getPosition();
    if (map is null)   return;
    for (int doFire = 0; doFire <= 3 * 8; doFire += 1 * 8) //8 - tile size in pixels
    {
        map.server_setFireWorldspace(Vec2f(thisPos.x, thisPos.y + doFire), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x, thisPos.y - doFire), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x + doFire, thisPos.y), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x - doFire, thisPos.y), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x + doFire, thisPos.y + doFire), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x - doFire, thisPos.y - doFire), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x + doFire, thisPos.y - doFire), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x - doFire, thisPos.y + doFire), true);
    }
	
	CBlob@[] blobsInRadius;
	if (map.getBlobsInRadius(thisPos, 48.0f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b !is null)
			{
				Vec2f bPos = b.getPosition();
				if ( !map.rayCastSolid(thisPos, bPos) )
				{
					if(b.get_u16("fireProt") > 0)
					{
						this.server_Hit(b, bPos, bPos-thisPos, 0.0f, Hitters::fire, isOwnerBlob(this,b));
					}
					else
					{
						this.server_Hit(b, bPos, bPos-thisPos, 0.5f, Hitters::fire, isOwnerBlob(this,b));
					}
				}
			}
		}
	}
	
    this.getSprite().PlaySound("MolotovExplosion.ogg", 1.6f, 1.0f);
}

bool isOwnerBlob(CBlob@ this, CBlob@ target)
{
	//easy check
	return (this.getDamageOwnerPlayer() is target.getPlayer());
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
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
	if( !getNet().isClient() ) 
		return;
	//warn("making smoke");

	const f32 rad = 4.0f;
	Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
	CParticle@ p = ParticleAnimated( "RocketFire1.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.0f, false );
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

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_blast_r.NextFloat() * 6.0f, 0);
        vel.RotateBy(_blast_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericBlast5.png").getFirst(), 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.scale = 0.75f + _blast_r.NextFloat()*0.5f;
        p.damping = 0.85f;
		p.Z = 200.0f;
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
        Vec2f vel(6.0f + _smoke_r.NextFloat() * 6.0f, 0);
        vel.RotateBy(_smoke_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke2.png").getFirst(), 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									4 + XORRandom(8), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.scale = 1.0f + _smoke_r.NextFloat()*0.5f;
        p.damping = 0.8f;
		p.Z = 200.0f;
		p.lighting = false;
    }
}

void Boom( CBlob@ this )
{
	ExplodeWithFire(this);
	smoke(this.getPosition(), 5);	
	blast(this.getPosition(), 10);	
	
    this.server_Die();
}

/*sprite

void onInit( CSprite@ this )
{
    this.animation.frame = (this.getBlob().getNetworkID()%4);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
*/

