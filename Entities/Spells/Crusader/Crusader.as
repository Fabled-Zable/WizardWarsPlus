#include "Hitters.as";
#include "ArcherCommon.as";
#include "SpellCommon.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;	 // we have our own map collision
	consts.bullet = false;
	consts.net_threshold_multiplier = 0.1f;
	this.Tag("projectile");
	this.Tag("counterable");
	shape.SetGravityScale( 0.0f );

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	this.set_u16("lifetime", 20);
    this.server_SetTimeToDie(20);
	
	this.setAngleDegrees(90);
}

void onTick(CBlob@ this)
{
    CShape@ shape = this.getShape();

	if (this.getTickSinceCreated() < 1)
	{
		this.server_SetTimeToDie(this.get_u16("lifetime"));
	}

    f32 angle;
    bool processSticking = true;
	if (!this.hasTag("collided")) //we haven't hit anything yet!
	{
		//prevent leaving the map
		{
			Vec2f pos = this.getPosition();
			if (
				pos.x < 0.1f ||
				pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f
			) {
				this.server_Die();
				return;
			}
		}
        angle = (this.getVelocity()).Angle();
		Pierce(this);   //Pierce call
    }

	//start of sword launch logic
	u32 shooTime = this.get_u32("shooTime"); 		//base for timer system
	u32 lTime = getGameTime();						//clock

	if (!this.hasTag("canStickNow"))
	{
		u32 fTime = shooTime + 14;
		if (lTime > fTime)  //timer system for collision with walls
		{
		this.Tag("canStickNow"); //stops
		}
	}

	if (!this.hasTag("cruiseMode"))
	{
		if (lTime > shooTime)  //timer system for roboteching
		{
			shape.SetGravityScale(2);
			shape.SetStatic(false);
			this.Tag("cruiseMode"); //stops
		}
	}
}

void Pierce( CBlob@ this )
{
	Vec2f end;
	CMap@ map = this.getMap();
	Vec2f position = this.getPosition() + Vec2f(0,20);
	
	if (this.hasTag("canStickNow"))  //doesn't do raycasts until needed
	{
		if (map.rayCastSolidNoBlobs(this.getShape().getVars().oldpos, position, end))
		{
			ArrowHitMap(this, end, this.getOldVelocity(), 0.5f, Hitters::arrow);
		}
	}
}

void ArrowHitMap(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, u8 customData)
{
	if(isClient())
	{
		this.getSprite().PlaySound("bling.ogg");
	}

	this.Tag("collided");

	f32 radius = this.getRadius();

	f32 angle = velocity.Angle();

	this.set_u8("angle", Maths::get256DegreesFrom360(angle));

	Vec2f norm = velocity;
	norm.Normalize();
	norm *= (1.5f * radius);
	Vec2f lock = worldPoint + Vec2f(0,-20);
	this.set_Vec2f("lock", lock);

	this.Sync("lock", true);
	this.Sync("angle", true);

	this.setVelocity(Vec2f(0, 0));
	this.setPosition(lock);

	this.getShape().SetStatic(true);
	this.getCurrentScript().tickFrequency = 0;
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	if (blob !is null)
	{
		if (isEnemy(this, blob))
		{
			float expundamage = this.get_f32("damage");
			if (!blob.hasTag("barrier"))
			{
				if(!blob.hasTag("zombie"))
				{
					if(this.hasTag("collided"))
					{this.server_Hit(blob, blob.getPosition(), this.getVelocity(), expundamage, Hitters::arrow, true);}
				}
				else
				{
					this.server_Hit(blob, blob.getPosition(), this.getVelocity(), 0.4, Hitters::arrow, true);
				}
				
			}
			else
			{
				this.server_Hit(blob, blob.getPosition(), this.getVelocity(), expundamage , Hitters::arrow, true);
				this.server_Die();
			}
		}
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return 
	(
		(
			target.hasTag("barrier") ||
			(
				target.hasTag("flesh") 
				&& !target.hasTag("dead") 
				&& (friend is null
					|| friend.getTeamNum() != this.getTeamNum()
					)
			)
		)
		&& target.getTeamNum() != this.getTeamNum() 
	);
}