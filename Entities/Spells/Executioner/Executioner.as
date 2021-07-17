#include "Hitters.as";
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
	
	this.set_f32("lifetime",0);
    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	this.addCommandID("aimpos sync");
	
    this.server_SetTimeToDie(25);
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
		if (!this.hasTag("aimMode"))
		{
        	angle = (this.getVelocity()).Angle();
			Pierce(this);   //Pierce call
			this.setAngleDegrees(-angle);
		}
    }
	//start of sword launch logic
	this.Sync("lifetime", true);
	f32 lifetime = this.get_f32("lifetime");		//base for timer system

	if (!this.hasTag("aimMode") && !this.hasTag("cruiseMode"))
	{
		if (this.getTickSinceCreated() > lifetime)  //timer system for sentry mode
		{
			this.setVelocity(Vec2f(0,0));
			this.Tag("aimMode"); //stops
			if(isClient())
			{this.getSprite().PlaySound("exepause.ogg");}
		}
	}

	if (!this.hasTag("cruiseMode") && this.hasTag("aimMode")) //Aims sword to caster's cursor
	{
		CPlayer@ p = this.getDamageOwnerPlayer();
		if( p !is null) {
			CBlob@ caster = p.getBlob();
			if( caster !is null) {
				if( p.isMyPlayer() )
				{
					Vec2f aimPos1 = caster.getAimPos() + Vec2f(0.0f,-2.0f);
					CBitStream params;
					params.write_Vec2f(aimPos1);
					this.SendCommand(this.getCommandID("aimpos sync"), params);
				}
				Vec2f aimPos2 = this.get_Vec2f("aimpos");
				Vec2f aimDir = aimPos2 - this.getPosition();
				angle = aimDir.Angle();
				this.setAngleDegrees(-angle);
				if (caster.get_bool("shifting") && this.getTickSinceCreated() > (lifetime + 30) )  //shift system for roboteching
				{
					aimDir.Normalize();
					Vec2f swordSpeed = aimDir * 15;
					this.setVelocity(swordSpeed);
					this.getSprite().PlaySound("execruise.ogg");
					this.Tag("cruiseMode"); //stops the loop
					this.Untag("aimMode");
				}
			}
		}
	}
}

void Pierce(CBlob@ this, CBlob@ blob = null)
{
	Vec2f end;
	CMap@ map = this.getMap();
	Vec2f position = blob is null ? this.getPosition() : blob.getPosition();
	
	if (this.hasTag("cruiseMode"))  //doesn't do raycasts until needed
	{
		if (map.rayCastSolidNoBlobs(this.getShape().getVars().oldpos, position, end))
		{
			ArrowHitMap(this, end, this.getOldVelocity(), 0.5f, Hitters::arrow);
		}
	}
	
}

void ArrowHitMap(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, u8 customData)
{

	this.getSprite().PlaySound("exehit.ogg");

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
	
	this.getShape().SetStatic(true);
	this.getCurrentScript().tickFrequency = 0;
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	if (blob !is null)
	{
		if (isEnemy(this, blob) && !this.hasTag("aimMode"))
		{
			float expundamage = this.get_f32("damage");
			if (!this.hasTag("collided"))
			{
				this.server_Hit(blob, blob.getPosition(), this.getVelocity(), expundamage, Hitters::arrow, true);
				if (blob.hasTag("barrier"))
				{
					this.server_Die();
				}
			}
			else
			{
				this.server_Hit(blob, blob.getPosition(), this.getVelocity(), 0.2f , Hitters::arrow, true);
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

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("aimpos sync"))
    {
        this.set_Vec2f("aimpos", params.read_Vec2f());
    }
}