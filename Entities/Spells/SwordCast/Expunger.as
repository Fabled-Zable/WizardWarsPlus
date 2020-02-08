#include "Hitters.as";
#include "ArcherCommon.as";
#include "SpellCommon.as";

const s32 bomb_fuse = 120;
const f32 arrowMediumSpeed = 8.0f;
const f32 arrowFastSpeed = 13.0f;


//maximum is 15 as of 22/11/12 (see ArcherCommon.as)

const s32 FIRE_IGNITE_TIME = 5;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;	 // weh ave our own map collision
	consts.bullet = false;
	consts.net_threshold_multiplier = 4.0f;
	this.Tag("projectile");

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

    this.server_SetTimeToDie(20);

}

void onTick(CBlob@ this)
{
	u32 shooTime = this.get_u32("shooTime"); //base for timer system
	bool allowStick = this.get_bool("allowStick"); //base for sticking delay

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
		Pierce(this);   //map
		this.setAngleDegrees(-angle);
    }
	//start of sword launch logic
	u32 lTime = getGameTime();

		if (this.hasTag("soundProducer"))
	{
		this.getSprite().PlaySound("swordsummon.ogg");
		this.Untag("soundProducer");
	}

	if (!this.hasTag("canStickNow"))
	{
		u32 fTime = shooTime + 30;
		if (lTime > fTime)  //timer system for collision with walls
		{
		allowStick = true;
		this.Tag("canStickNow");
		}
		else
		{
		allowStick = false;
		}
	}

	if (!this.hasTag("cruiseMode"))
	{
		if (lTime > shooTime)  //timer system for roboteching
		{
			shape.setDrag(0.0f);
			Vec2f swordVel = this.get_Vec2f("targetto");
			float swordSpeed = this.get_f32("speeddo");
			swordVel.Normalize();
			swordVel *= swordSpeed;
			this.setVelocity(swordVel);
			this.getSprite().PlaySound("swordlaunch.ogg");
			this.Tag("cruiseMode"); //as to not set the drag every tick
		}
	}
}

void Pierce(CBlob@ this, CBlob@ blob = null)
{
	Vec2f end;
	CMap@ map = this.getMap();
	Vec2f position = blob is null ? this.getPosition() : blob.getPosition();
	
	if (this.hasTag("canStickNow"))
	{
		if (map.rayCastSolidNoBlobs(this.getShape().getVars().oldpos, position, end))
		{
			ArrowHitMap(this, end, this.getOldVelocity(), 0.5f, Hitters::arrow);
		}
	}
	
}

void ArrowHitMap(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, u8 customData)
{
	if (velocity.Length() > arrowFastSpeed)
	{
		this.getSprite().PlaySound("ArrowHitGroundFast.ogg");
	}
	else
	{
		this.getSprite().PlaySound("ArrowHitGround.ogg");
	}

	f32 radius = this.getRadius();

	f32 angle = velocity.Angle();

	this.set_u8("angle", Maths::get256DegreesFrom360(angle));

	Vec2f norm = velocity;
	norm.Normalize();
	norm *= (1.5f * radius);
	Vec2f lock = worldPoint - norm;
	this.set_Vec2f("lock", lock);

	this.Sync("lock", true);
	this.Sync("angle", true);

	this.setVelocity(Vec2f(0, 0));
	this.setPosition(lock);
	//this.getShape().server_SetActive( false );

	this.Tag("collided");

	//kill any grain plants we shot the base of
	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius(worldPoint, this.getRadius() * 1.3f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b.getName() == "grain_plant")
			{
				this.server_Hit(b, worldPoint, Vec2f(0, 0), velocity.Length() / 7.0f, Hitters::arrow);
				break;
			}
		}
	}
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	
	if (blob !is null)
	{
		if (isEnemy(this, blob))
		{
		float expundamage = this.get_f32("damage");
		this.server_Hit(blob, blob.getPosition(), this.getVelocity(), expundamage, Hitters::arrow, true);
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