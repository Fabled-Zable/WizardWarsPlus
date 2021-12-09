void onInit(CBlob@ this)
{
	this.Tag("phase through spells");
    this.Tag("counterable");

	//default values
	this.set_u16("lifetime", 10);
	this.set_f32("move_Speed", 4.0f);
	this.set_Vec2f("target", Vec2f_zero);
	//^

	CShape@ thisShape = this.getShape();
    thisShape.SetGravityScale(0);
	thisShape.getConsts().mapCollisions = false;

	this.SetMapEdgeFlags( u8(CBlob::map_collide_none) | u8(CBlob::map_collide_nodeath) ); //dont collide with edge of the map

    if (isServer())
    {
		this.server_SetTimeToDie(10);
	}
    
	//burning sound	    
	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		sprite.getConsts().accurateLighting = false;
	}
}

void onTick(CSprite@ this) // note to glitch - this only runs on client, onTick is never called if blob is null
{
	this.ResetTransform();
    this.RotateBy(this.getBlob().getVelocity().getAngle() * -1,Vec2f_zero);
}

void onTick(CBlob@ this)
{
	Vec2f targetPos = this.get_Vec2f("target");
	if(targetPos == Vec2f_zero)
	{
		print("Plant shot target is 0,0");
		this.set_Vec2f("target", Vec2f(1,1));
	}

	if(isClient())
	{
		makeSmokeParticle(this, targetPos);
	}

	Vec2f thisPos = this.getPosition();
	float standardSpeed = this.get_f32("move_Speed");

	Vec2f moveDir = targetPos - thisPos;
	float dist = moveDir.Length();

	Vec2f finalSpeed = moveDir;
	finalSpeed.Normalize();
	finalSpeed *= standardSpeed;

	if( dist > standardSpeed )
	{
		this.setVelocity(finalSpeed); //if farther away, use standard speed
	}
	else
	{
		this.setVelocity(moveDir); //if closer than needed, jump to that spot
	}

	if( dist < 1.0f )
	{
		this.server_Die();
	}
}

void onDie( CBlob@ this )
{
	Vec2f thisPos = this.getPosition();

	u16 lifetime = this.get_u16("lifetime");

	CBlob@ plant = server_CreateBlob( "plant_aura", this.getTeamNum(), thisPos);
	if (plant !is null)
	{
		plant.set_u16("lifetime", lifetime);
		plant.SetDamageOwnerPlayer( this.getDamageOwnerPlayer() );
	}
	blast( thisPos , 10);
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
	return false;
}

void makeSmokeParticle( CBlob@ this , Vec2f targetPos )
{
	if (this is null)
	{ return; }

	u8 teamNum = this.getTeamNum();
	Vec2f random = Vec2f(0,2.0f);
	random.RotateBy(XORRandom(360));

	string particleName = "MissileFire2.png";

	CParticle@ p1 = ParticleAnimated( particleName , this.getPosition(), random/10, float(XORRandom(360)), 0.5f, 6, 0.0f, false );
	if ( p1 !is null)
	{
		p1.bounce = 0;
    	p1.fastcollision = true;
		p1.Z = 300.0f;
	}

	CParticle@ p2 = ParticleAnimated( particleName , targetPos, Vec2f_zero, float(XORRandom(360)), 0.5f, 6, 0.0f, false );
	if ( p2 !is null)
	{
		p2.bounce = 0;
    	p2.fastcollision = true;
		p2.Z = 300.0f;
		p2.frame = 3;
		p2.scale = 1.3f;
	}
}


Random _blast_r(0x10002);
void blast( Vec2f pos , int amount)
{
	if(!isClient())
	{return;}

	Sound::Play("PlantShotHit.ogg", pos, 3.0f, 0.8f + XORRandom(10)/10.0f);

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_blast_r.NextFloat() * 3.0f, 0);
        vel.RotateBy(_blast_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated("MissileFire2.png", 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.5f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) continue; //bail if we stop getting particles
		
    	p.fastcollision = true;
        p.damping = 0.85f;
		p.Z = 200.0f;
		p.lighting = false;
    }
}