#include "Hitters.as";
#include "ArcherCommon.as";
#include "SpellCommon.as";

const f32 arrowMediumSpeed = 8.0f;
const f32 arrowFastSpeed = 13.0f;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
	consts.bullet = false;
	this.Tag("projectile");
	this.Tag("counterable");
	shape.SetGravityScale( 0.05f );

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

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	if (blob !is null && this !is null)
	{
		float blastStr = this.get_f32("blastStr");
		if (isEnemy(this, blob))
		{
			Vec2f thisPos = this.getPosition();
			//Vec2f othPos = blob.getPosition();
			//Vec2f kickDir = othPos - selfPos;
			Vec2f kickDir = blob.getPosition() - thisPos;
			kickDir.Normalize();
			kickDir *= (2500.0f * blastStr);

			if(blob.hasTag("flesh"))
			{
				kickDir += Vec2f(0,-500);
				kickDir *= 0.5f;
				blob.AddForce(kickDir);
			}
			else
			{
				blob.AddForceAtPosition(kickDir, thisPos);
			}

			
			this.getSprite().PlaySound("bunkerbust.ogg", 100.0f);

			float damage = this.get_f32("damage");

			CMap@ map = getMap();
			if (map is null)
			{return;}

			CBlob@[] blobsInRadius;
			map.getBlobsInRadius(this.getPosition(), 18.0f, @blobsInRadius);
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				if(blobsInRadius[i] is null)
				{continue;}

				CBlob@ radiusBlob = blobsInRadius[i];

				if(!isEnemy(this, radiusBlob))
				{continue;}

				this.server_Hit(radiusBlob, radiusBlob.getPosition(), Vec2f_zero, damage, Hitters::explosion, false);
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
			this.server_Die();
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