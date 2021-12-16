// Fighter Movement

#include "SmallshipCommon.as"
#include "SpaceshipVars.as"
#include "MakeDustParticle.as";
#include "KnockedCommon.as";

void onInit(CMovement@ this)
{
	this.getBlob().set_u32("accelSoundDelay",0);

	this.getCurrentScript().removeIfTag = "dead";

	this.getBlob().set_s32("rightTap",0);
	this.getBlob().set_s32("leftTap",0);
	this.getBlob().set_s32("upTap",0);
	this.getBlob().set_s32("downTap",0);
}

void onTick(CMovement@ this)
{
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null)
	{ return; }

	CMap@ map = getMap(); //standard map check
	if (map is null)
	{ return; }

	SpaceshipVars@ moveVars;
	if (!thisBlob.get("moveVars", @moveVars))
	{ return; }

	SmallshipInfo@ ship;
	if (!thisBlob.get( "smallshipInfo", @ship )) 
	{ return; }
	/*
	const bool left		= thisBlob.isKeyPressed(key_left);
	const bool right	= thisBlob.isKeyPressed(key_right);
	const bool up		= thisBlob.isKeyPressed(key_up);
	const bool down		= thisBlob.isKeyPressed(key_down);
	*/
	
	const bool[] allKeys =
	{
		up = thisBlob.isKeyPressed(key_up),
		down = thisBlob.isKeyPressed(key_down),
		left = thisBlob.isKeyPressed(key_left),
		right = thisBlob.isKeyPressed(key_right)
	};

	u8 keysPressedAmount = 0;
	for (uint i = 0; i < allKeys.length; i ++)
	{
		bool currentKey = allKeys[i];
		if (currentKey)
		{ keysPressedAmount++; }
	}
	
	const bool isknocked = isKnocked(thisBlob) || (thisBlob.get_bool("frozen") == true);
	const bool is_client = isClient();

	Vec2f vel = thisBlob.getVelocity();
	Vec2f pos = thisBlob.getPosition();
	f32 blobAngle = thisBlob.getAngleDegrees();

	Vec2f aimPos = thisBlob.getAimPos();
	f32 aimAngle = aimPos.getAngleDegrees();

	if (blobAngle != aimAngle)
	{
		f32 turnSpeed = ship.ship_turn_speed * moveVars.turnSpeedFactor;

		f32 angleDiff = blobAngle - aimAngle;
		angleDiff = (angleDiff + 180) % 360 - 180;

		if (angleDiff < turnSpeed && angleDiff > -turnSpeed) //if turn difference is smaller than turn speed, snap to it
		{
			thisBlob.setAngleDegrees(aimAngle);
		}
		else
		{
			turnAngle = aimAngle > angleDiff ? turnSpeed : -turnSpeed; //either left or right turn
			thisBlob.setAngleDegrees(blobAngle + turnAngle);
		}
		blobAngle.thisBlob.getAngleDegrees();
	}
	
	
	CShape@ shape = thisBlob.getShape();
	if (shape != null)
	{
		shape.SetGravityScale(0.0f);
		shape.setDrag(ship.ship_drag * moveVars.dragFactor);
	}

	const f32 vellen = shape.vellen;
	const bool onground = thisBlob.isOnGround() || thisBlob.isOnLadder();

	if (keysPressedAmount != 0)
	{
		Vec2f[] deltaV =
		{
			forward = Vec2f_zero,
			backward = Vec2f_zero,
			board = Vec2f_zero,
			starboard = Vec2f_zero
		};

		if(allKeys.up)
		{
			Vec2f thrustVel = Vec2f(ship.main_engine_force, 0);
			thrustVel.RotateByDegrees(blobAngle);
			deltaV.forward += thrustVel;
		}
		if(allKeys.down)
		{
			Vec2f thrustVel = Vec2f(ship.secondary_engine_force, 0);
			thrustVel.RotateByDegrees(blobAngle);
			deltaV.backward += thrustVel;
		}
		if(allKeys.left)
		{
			Vec2f thrustVel = Vec2f(ship.rcs_force, 0);
			thrustVel.RotateByDegrees(blobAngle);
			deltaV.board += thrustVel;
		}
		if(allKeys.right)
		{
			Vec2f thrustVel = Vec2f(ship.rcs_force, 0);
			thrustVel.RotateByDegrees(blobAngle);
			deltaV.starboard += thrustVel;
		}

		Vec2f addedVel = Vec2f_zero;
		for (uint i = 0; i < deltaV.length; i ++)
		{
			Vec2f@ currentVec = deltaV[i];
			addedVel += currentVec / float(keysPressedAmount); //divide thrust between multiple sides
		}

		if (thisBlob.getPosition().y/8 >=  getMap().tilemapheight - 2)
		{
			vel = Vec2f(vel.x,-1);
		}
		else if (thisBlob.getPosition().y <= 2)
		{
			vel = Vec2f(vel.x,1);
		}

		thisBlob.setVelocity(vel + (addedVel * moveVars.engineFactor));
	}
	
	CleanUp(this, thisBlob, moveVars);
}