#include "Hitters.as";
#include "SpellCommon.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = true;
	consts.bullet = false;

	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("exploding");
	shape.SetGravityScale( 0.0f );

	this.set_f32("damage", 1.0f);

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

    this.server_SetTimeToDie(10);
}

void onTick(CBlob@ this)
{
    f32 angle;
	//prevent leaving the map
	
	Vec2f pos = this.getPosition();
	if ( pos.x < 0.1f ||
	pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f)
	{
		this.server_Die();
		return;
	}

    angle = (this.getVelocity()).Angle();
	this.setAngleDegrees(-angle);

	if(!isClient())
	{return;}

	for(int i = 0; i < 5; i ++)
	{
		float randomPVel = XORRandom(10) / 10.0f;
		Vec2f particleVel = Vec2f( randomPVel ,0).RotateByDegrees(XORRandom(360));
		particleVel += this.getVelocity();

    	CParticle@ p = ParticlePixelUnlimited(this.getPosition(), particleVel, SColor(255,10,5,5), true);
   		if(p !is null)
    	{
    	    p.collides = false;
    	    p.gravity = Vec2f_zero;
    	    p.bounce = 1;
    	    p.lighting = false;
    	    p.timeout = 60;
			p.damping = 0.95;
    	}
	}
}

void onTick(CSprite@ this) //rotating sprite
{
	CBlob@ b = this.getBlob();
	if(!b.exists("spriteSetupDone") || !b.get_bool("spriteSetupDone"))
	{
		CSpriteLayer@ layer = this.addSpriteLayer("shine","spriteback_alpha.png",150,150,b.getTeamNum(),0);
        layer.SetRelativeZ(-1.0f);
		layer.setRenderStyle(RenderStyle::additive);
		layer.ScaleBy(0.3f, 0.3f);
		b.set_bool("spriteSetupDone",true);
	}

    CSpriteLayer@ layer = this.getSpriteLayer("shine");
	
    layer.RotateByDegrees(7,Vec2f_zero);

	this.RotateByDegrees(-7,Vec2f_zero);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	if (blob !is null && this !is null)
	{
		if (isEnemy(this, blob))
		{
			this.server_Die();
		}
	}
}

void onDie( CBlob@ this )
{
	if(!this.hasTag("exploding"))
	{return;}

	Vec2f thisPos = this.getPosition();
	//Vec2f othPos = blob.getPosition();
	//Vec2f kickDir = othPos - selfPos;

			
	this.getSprite().PlaySound("bunkerbust.ogg", 100.0f);

	float damage = this.get_f32("damage");

	CMap@ map = getMap();
	if (map is null)
	{return;}

	CPlayer@ p = this.getDamageOwnerPlayer();
	CBlob@ owner = null;
	if (p !is null)
	{
		CBlob@ owner = p.getBlob();
	}

	CBlob@[] blobsInRadius;
	map.getBlobsInRadius(this.getPosition(), 64.0f, @blobsInRadius);
	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		if(blobsInRadius[i] is null)
		{continue;}

		CBlob@ radiusBlob = blobsInRadius[i];

		if (owner !is null && radiusBlob is owner)
		{
			this.server_Hit(radiusBlob, radiusBlob.getPosition(), Vec2f_zero, damage, Hitters::fire, true);
			continue;
		}

		if (radiusBlob.getTeamNum() == this.getTeamNum())
		{continue;}

		this.server_Hit(radiusBlob, radiusBlob.getPosition(), Vec2f_zero, damage, Hitters::fire, false);
	}
			
	if ( isClient() ) //temporary Counterspell effect
	{
		CParticle@ pb = ParticleAnimated( "Shockwave3WIP.png",
			this.getPosition(),
			Vec2f(0,0),
			float(XORRandom(360)),
			0.25f, 
			2, 
			0.0f, true );    
		if ( pb !is null)
		{
			pb.bounce = 0;
    		pb.fastcollision = true;
			pb.Z = -10.0f;
		}
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		(
			target.hasTag("barrier") || (target.hasTag("flesh") && !target.hasTag("dead") )
		)
		&& target.getTeamNum() != this.getTeamNum() 
	);
}