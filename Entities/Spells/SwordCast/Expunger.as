#include "Hitters.as";
#include "ArcherCommon.as";
#include "SpellCommon.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;	 // we have our own map collision
	consts.bullet = false;
	consts.net_threshold_multiplier = 4.0f;
	this.Tag("projectile");
	this.Tag("counterable");
	shape.SetGravityScale( 0.0f );

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

    this.server_SetTimeToDie(20);

}

void onTick(CBlob@ this)
{
    CShape@ shape = this.getShape();

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
		this.setAngleDegrees(-angle);
    }
	//start of sword launch logic
	u32 shooTime = this.get_u32("shooTime"); 		//base for timer system
	u32 lTime = getGameTime();						//clock

	if (!this.hasTag("canStickNow"))
	{
		u32 fTime = shooTime + 18;
		if (lTime > fTime)  //timer system for collision with walls
		{
		this.Tag("canStickNow"); //stops
		}
	}

	if (!this.hasTag("cruiseMode"))
	{
		if (lTime > shooTime)  //timer system for roboteching
		{
			shape.setDrag(0.000000001f);
			Vec2f swordVel = this.get_Vec2f("targetto");
			float swordSpeed = this.get_f32("speeddo");
			swordVel.Normalize();
			swordVel *= swordSpeed;
			this.setVelocity(swordVel);
			this.getSprite().PlaySound("swordlaunch.ogg");
			this.Tag("cruiseMode"); //stops
		}
	}
}

void Pierce(CBlob@ this, CBlob@ blob = null)
{
	Vec2f end;
	CMap@ map = this.getMap();
	Vec2f position = blob is null ? this.getPosition() : blob.getPosition();
	
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

	this.getSprite().PlaySound("ArrowHitGroundFast.ogg");

	//f32 radius = this.getRadius(); keeping this for future reference

	f32 angle = velocity.Angle();
	this.set_u8("angle", Maths::get256DegreesFrom360(angle));

	Vec2f norm = velocity;
	norm.Normalize();
	norm *= 1.5f; //norm *= (1.5f * radius); (same as above)
	Vec2f lock = worldPoint - norm;
	this.set_Vec2f("lock", lock);

	this.Sync("lock", true);
	this.Sync("angle", true);

	this.setVelocity(Vec2f(0, 0));
	this.setPosition(lock);
	//this.getShape().server_SetActive( false );

	this.Tag("collided");

	this.getShape().SetStatic(true);

}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	bool swordDeath = false;

	if (blob !is null)
	{
		if (isEnemy(this, blob))
		{
			float expunDamage = this.get_f32("damage");
			if (!this.hasTag("collided"))
			{
				if (this.hasTag("cruiseMode"))
				{
					if (blob.hasTag("barrier"))
					{
						expunDamage += 0.2f;
						swordDeath = true;
					}
					this.server_Hit(blob, blob.getPosition(), this.getVelocity(), expunDamage, Hitters::arrow, true);
				}
			}
			else
			{
				swordDeath = true;
			}
		}
	}

	if ( swordDeath )
	{ this.server_Die(); }
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