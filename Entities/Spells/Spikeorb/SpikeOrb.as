#include "Hitters.as"

const f32 AOE = 12.0f;//radius
const int min_detonation_time = 30;
void onInit(CBlob@ this)
{
	this.Tag("standingup");
	this.Tag("counterable");
	this.Tag("exploding"); //doesn't have the Explode script
	this.set_f32("damage", 0.4f);
	//this.set_f32("explosive_radius", 2.0f);
	//this.set_f32("explosive_damage", 10.0f);
	//this.set_f32("map_damage_radius", 4.0f);
	//this.set_f32("map_damage_ratio", -1.0f); //heck no!
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	
	this.getShape().getConsts().bullet = true;
}

void onTick(CBlob@ this)
{
	if(this is null)
	{return;}

	if (this.getCurrentScript().tickFrequency == 1)
	{
		this.getShape().SetGravityScale(1.0f);
		this.server_SetTimeToDie(54);
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		this.SetLightColor(SColor(255, 211, 121, 224));
		this.set_string("custom_explosion_sound", "SpikeOrbExplosion.ogg");
		this.getSprite().PlaySound("WizardShoot.ogg", 2.0f);
		this.getSprite().SetZ(1000.0f);

		//makes a stupid annoying sound
		//ParticleZombieLightning( this.getPosition() );

		// done post init
		this.getCurrentScript().tickFrequency = 10;
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		target.getTeamNum() != this.getTeamNum()
		&&
		(
			target.hasTag("standingup")
			||
			target.hasTag("kill other spells") 
			||
			(
				target.hasTag("flesh") 
				&& !target.hasTag("dead")
			)
		)
	);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if(this is null || blob is null)
	{return false;}

	return 
	( 
		blob.hasTag("standingup")
		||
		(
			blob.hasTag("barrier") && blob.getTeamNum() != this.getTeamNum()
		)
	);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if(this is null)
	{return;}

	bool causeSparks = false;
	bool blobDeath = false;

	if (solid)
	{
		causeSparks = true;
	}

	if( blob !is null && isEnemy(this, blob) )
	{
		causeSparks = true;
		if (this.getTickSinceCreated() > min_detonation_time)	
		{
			blobDeath = true;
		}
	}

	if(causeSparks)
	{sparks(this.getPosition(), 4);}
	if(blobDeath)
	{this.server_Die();}
}

void onDie( CBlob@ this )
{
	if(this is null)
	{return;}
	if(!this.hasTag("exploding"))
	{return;}

	Vec2f pos = this.getPosition();
	
	if ( isServer() )
	{
		CMap@ map = getMap();
		if(map is null)
		{return;}

		CBlob@[] aoeBlobs;

		map.getBlobsInRadius( pos, AOE, @aoeBlobs );
		for ( u8 i = 0; i < aoeBlobs.length(); i++ )
		{
			CBlob@ b = aoeBlobs[i]; //standard null check for blobs in radius
			if (b is null)
			{continue;}

			if ( !map.rayCastSolidNoBlobs( pos, b.getPosition() ) )
			{
				this.server_Hit( b, pos, Vec2f_zero, this.get_f32("damage") , Hitters::explosion, isOwnerBlob(this, b) );
			}
		}
	}
	sparks(pos, 10);
}

bool isOwnerBlob(CBlob@ this, CBlob@ target)
{
	//easy check
	if (this.getDamageOwnerPlayer() is target.getPlayer())
	{
		return true;
	}
	return false;
}

Random _sprk_r(13424);
void sparks(Vec2f pos, int amount)
{
	if ( !isClient() )
	{return;}

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
