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
	return 
	(
		( target.getTeamNum() != this.getTeamNum() && (target.hasTag("kill other spells") || target.hasTag("door") || target.getName() == "trap_block") )
		||
		(
			target.hasTag("flesh") 
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
		)
	);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return ( isEnemy(this, blob) || blob.hasTag("barrier") || blob.hasTag("standingup") );
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (solid || blob.hasTag("kill other spells"))
	{
		sparks(this.getPosition(), 4);
		
		if (this.getTickSinceCreated() > min_detonation_time)	
		{
			if(blob !is null && isEnemy(this, blob))
			{
				this.server_Die();
			}
		}
	}
}

void onDie( CBlob@ this )
{
	if(!this.hasTag("exploding"))
	{return;}

	Vec2f pos = this.getPosition();
	CBlob@[] aoeBlobs;
	CMap@ map = getMap();
	if(map is null)
	{return;}
	
	if ( isServer() )
	{
		map.getBlobsInRadius( pos, AOE, @aoeBlobs );
		for ( u8 i = 0; i < aoeBlobs.length(); i++ )
		{
			CBlob@ blob = aoeBlobs[i];
			if(blob is null)
			{continue;}
			if ( !getMap().rayCastSolidNoBlobs( pos, blob.getPosition() ) )
				this.server_Hit( blob, pos, Vec2f_zero, this.get_f32("damage") , 40, blob.getName() == "spikeorb" );
		}
	}
	sparks(this.getPosition(), 10);
}

Random _sprk_r(13424);
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
