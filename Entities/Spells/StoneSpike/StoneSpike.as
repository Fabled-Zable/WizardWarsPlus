const f32 DAMAGE = 0.4f;
const f32 AOE = 12.0f;//radius
const int min_detonation_time = 6;
void onInit(CBlob@ this)
{
	this.Tag("standingup");
	this.Tag("counterable");
	//this.Tag("alwayscounter");
	//this.set_f32("explosive_radius", 2.0f);
	//this.set_f32("explosive_damage", 10.0f);
	//this.set_f32("map_damage_radius", 4.0f);
	//this.set_f32("map_damage_ratio", -1.0f); //heck no!
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	
	this.getShape().getConsts().bullet = true;
	
	this.getShape().SetGravityScale(0.0f);
	this.getShape().SetStatic(true);
	this.SetFacingLeft(XORRandom(2) == 0);
	this.server_SetTimeToDie(25);
	
}

void onInit(CSprite@ this)
{
	this.SetFrame(XORRandom(4));
	this.PlaySound("Rubble" + (XORRandom(2) + 1) + ".ogg", 2.0f);
	makeGibParticle("GenericGibs", this.getBlob().getPosition(), getRandomVelocity(0, 3.0f, 360.0f) + Vec2f(0.0f, -2.0f),
		                2, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
	this.SetZ(100.0f);
	
	this.SetOffset(Vec2f(0, 5));
}

void onTick(CSprite@ this)
{
	if(this.getBlob().getTickSinceCreated() < 5)
	{
		this.SetOffset(Vec2f(0, 5.0 + -1.0 * this.getBlob().getTickSinceCreated()));
	}
	else
	{
		this.SetOffset(Vec2f_zero);
		this.getCurrentScript().tickFrequency = 0;
	}
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 2)
	{
		if(this.get_u8("spikesleft") > 0 && isServer())
		{
			CMap@ map = getMap();
			Vec2f dir = (this.get_bool("leftdir") ? -Vec2f(8, 0) : Vec2f(8, 0));
			Vec2f pos = this.getPosition();
			/*
			if(!map.isTileSolid(pos + dir) && map.isTileSolid(pos + dir + Vec2f(0, 8)))
			{
				continueSpikes(this, pos + dir);
			}
			else if(!map.isTileSolid(pos + dir + Vec2f(0, -8)) && map.isTileSolid(pos + dir))
			{
				continueSpikes(this, pos + dir + Vec2f(0, -8));
			}
			else if(!map.isTileSolid(pos + dir + Vec2f(0, 8)) && map.isTileSolid(pos + dir + Vec2f(0, 16)))
			{
				continueSpikes(this, pos + dir + Vec2f(0, 8));
			}*/
			for(int i = 0; i < 5; i++)
			{
				if(!map.isTileSolid(pos + Vec2f(0, i * 8) + dir) && map.isTileSolid(pos + Vec2f(0, i * 8 + 8) + dir))
				{
					continueSpikes(this, pos + Vec2f(0, i * 8) + dir, map);
					break;
				}	
				else if(!map.isTileSolid(pos + Vec2f(0, i * -8) + dir) && map.isTileSolid(pos + Vec2f(0, i * -8 + 8) + dir))
				{
					continueSpikes(this, pos + Vec2f(0, i * -8) + dir, map);
					break;
				}
			}
		}
		this.getCurrentScript().tickFrequency = 0;
	}
}

void continueSpikes(CBlob@ this, Vec2f pos, CMap@ map)
{
	if(map.getBlobAtPosition(pos) !is null && map.getBlobAtPosition(pos).getName() == "stone_spike")
		return;
	CBlob@ new = server_CreateBlob("stone_spike", this.getTeamNum(), pos);
	new.set_u8("spikesleft", this.get_u8("spikesleft") - 1);
	new.set_bool("leftdir", this.get_bool("leftdir"));
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return 
	(
		target.hasTag("flesh") 
		&& target.getTeamNum() != this.getTeamNum() 
		&& ( friend is null || friend.getTeamNum() != this.getTeamNum() )
	);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if(blob is null)
		return;
	if (!blob.hasTag("counterable"))
	{
		if (/*isEnemy(this, blob) &&*/ blob.getVelocity().y > 0)
		{
			this.server_Hit(blob, blob.getPosition(), Vec2f_zero, DAMAGE, 29, false);//29 is spikes damage type
		}
		else
		{
			this.server_Hit(blob, blob.getPosition(), Vec2f_zero, DAMAGE / 4, 41, false);
		}
	}
}

void onDie( CBlob@ this )
{
	/*Vec2f pos = this.getPosition();
	CBlob@[] aoeBlobs;
	CMap@ map = getMap();
	
	if ( getNet().isServer() )
	{
		map.getBlobsInRadius( pos, AOE, @aoeBlobs );
		for ( u8 i = 0; i < aoeBlobs.length(); i++ )
		{
			CBlob@ blob = aoeBlobs[i];
			if ( !getMap().rayCastSolidNoBlobs( pos, blob.getPosition() ) )
				this.server_Hit( blob, pos, Vec2f_zero, DAMAGE, 40, blob.getName() == "sporeshot" );
		}
	}
	sparks(this.getPosition(), 10);
	*/
}

Random _sprk_r(21324);
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
