#include "Hitters.as";
#include "ArcherCommon.as";
#include "SpellCommon.as";

const f32 arrowMediumSpeed = 8.0f;
const f32 arrowFastSpeed = 13.0f;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;	 // we have our own map collision
	consts.bullet = false;
	consts.net_threshold_multiplier = 4.0f;
	this.Tag("projectile");
	this.Tag("counterable");
	this.set_bool("following", false);
	this.set_u16("attached",0);
	shape.SetGravityScale( 0.0f );

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

    this.server_SetTimeToDie(5);
}

void onTick(CBlob@ this)
{
    CShape@ shape = this.getShape();

    f32 angle;
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
		if(this.hasTag("primed"))
		{
    	    angle = (this.getVelocity()).Angle();
			Pierce(this);   //Pierce call
			this.setAngleDegrees(-angle);
		}
		
		this.Sync("following", true);
		if(this.get_bool("following"))
		{
			u16 targetid = this.get_u16("attached"); //finds target ID
			CBlob@ target = getBlobByNetworkID(targetid);
			if(target !is null && !target.hasTag("dead"))
			{
				this.setVelocity(Vec2f_zero);
				this.setPosition(target.getPosition());
			}
			else
			{
				this.server_Die();
			}
		}
    }
}

void Pierce(CBlob@ this, CBlob@ blob = null)
{
	Vec2f end;
	CMap@ map = this.getMap();
	Vec2f position = blob is null ? this.getPosition() : blob.getPosition();

	if (map.rayCastSolidNoBlobs(this.getShape().getVars().oldpos, position, end))
	{
		ArrowHitMap(this, end, this.getOldVelocity(), 0.5f, Hitters::arrow);
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
	norm *= (1.5f);
	Vec2f lock = worldPoint - norm;
	this.set_Vec2f("lock", lock);

	this.Sync("lock", true);
	this.Sync("angle", true);

	this.setVelocity(Vec2f(0, 0));
	this.setPosition(lock);
	//this.getShape().server_SetActive( false );

	this.Tag("collided");
	this.Untag("primed");

}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	float expundamage = this.get_f32("damage");

	if (blob !is null)
	{
		if (isEnemy(this, blob))
		{
			if (blob.hasTag("barrier"))
			{
				this.server_Die();
			}
			else
			{
				u16 targetid = this.get_u16("attached"); //finds target ID
				CBlob@ target = getBlobByNetworkID(targetid);
				if(target !is null && !target.hasTag("dead") && target is blob)
				{
					this.server_Hit(blob, blob.getPosition(), this.getVelocity(), 0.1f, Hitters::arrow, true);
				}
				else
				{
					this.server_Hit(blob, blob.getPosition(), this.getVelocity(), expundamage, Hitters::arrow, true);
				}

				if(this.hasTag("primed"))
				{
					if(blob !is null)
					{
					this.getSprite().PlaySound("ImpStuck.ogg", 100.0f);
					this.setVelocity(Vec2f(0,0));
					this.server_SetTimeToDie(15);
					u16 netid = blob.getNetworkID();
					this.set_u16("attached",netid);
					this.set_bool("following", true);
					this.Untag("primed");
					}
				}
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