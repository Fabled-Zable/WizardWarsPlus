// Spaceship Movement

#include "SpaceshipCommon.as"
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
	CBlob@ blob = this.getBlob();
	SpaceshipMoveVars@ moveVars;
	if (!blob.get("moveVars", @moveVars))
	{
		return;
	}

	const bool left		= blob.isKeyPressed(key_left);
	const bool right	= blob.isKeyPressed(key_right);
	const bool up		= blob.isKeyPressed(key_up);
	const bool down		= blob.isKeyPressed(key_down);

	const bool isknocked = isKnocked(blob) || (blob.get_bool("frozen") == true);

	const bool is_client = getNet().isClient();

	CMap@ map = blob.getMap();
	Vec2f vel = blob.getVelocity();
	Vec2f pos = blob.getPosition();
	CShape@ shape = blob.getShape();

	const f32 vellen = shape.vellen;
	const bool onground = blob.isOnGround() || blob.isOnLadder();

	if (is_client && getGameTime() % 3 == 0)
	{
		const string acceltag = "engine_is_accelerating";
		if (blob.isKeyPressed(key_left) || blob.isKeyPressed(key_right))
		{
			if (vel.x < 0.4f && vel.x > -0.4f)
			{
				if (!blob.hasTag(acceltag))
				{
					blob.Tag(acceltag);
					Sound::Play("engine_accel.ogg", pos, 3.0f);
					blob.set_u32("accelSoundDelay", getGameTime() + 200);
				}
			}
		}
		else if(getGameTime() > blob.get_u32("accelSoundDelay"))
		{
			blob.Untag(acceltag);
		}
	}

	shape.SetGravityScale(0.0f);
	shape.setDrag(0.5f*moveVars.stoppingFactor);


    f32 speed = 0.05*moveVars.flySpeed;
    f32 acellBoost = moveVars.flyFactor;
    f32 dashSpeed = 8;
    s32 dashRate = 30/4;

    Vec2f deltaV = Vec2f_zero;
/*
    if(blob.isKeyJustPressed(key_right))
    {
        s32 lastTap = blob.get_s32("rightTap");
        if(getGameTime() - lastTap < dashRate)
        {
            vel.x = dashSpeed;
        }
        blob.set_s32("rightTap",getGameTime());
    }
    if(blob.isKeyJustPressed(key_left))
    {
        s32 lastTap = blob.get_s32("leftTap");
        if(getGameTime() - lastTap < dashRate)
        {
            vel.x = -dashSpeed;
        }
        blob.set_s32("leftTap",getGameTime());
    }
    if(blob.isKeyJustPressed(key_up))
    {
        s32 lastTap = blob.get_s32("upTap");
        if(getGameTime() - lastTap < dashRate)
        {
            vel.y = -dashSpeed;
        }
        blob.set_s32("upTap",getGameTime());
    }
    if(blob.isKeyJustPressed(key_down))
    {
        s32 lastTap = blob.get_s32("downTap");
        if(getGameTime() - lastTap < dashRate)
        {
            vel.y = dashSpeed;
        }
        blob.set_s32("downTap",getGameTime());
    }
*/


    if(blob.isKeyPressed(key_right))
    {
        deltaV += Vec2f(speed,0);
    }
    if(blob.isKeyPressed(key_left))
    {
        deltaV += Vec2f(-speed,0);
    }

    if(blob.isKeyPressed(key_up))
    {
        deltaV += Vec2f(0,-speed*0.8);
    }
    if(blob.isKeyPressed(key_down))
    {
        deltaV += Vec2f(0,speed*0.8);
    }

    if(blob.getPosition().y/8 >=  getMap().tilemapheight - 2)
    {
        vel = Vec2f(vel.x,-1);
    }

    if(blob.getPosition().y <= 2)
    {
        vel = Vec2f(vel.x,1);
    }

    blob.setVelocity(vel + (deltaV*acellBoost));

	CleanUp(this, blob, moveVars);
}




//cleanup all vars here - reset clean slate for next frame

void CleanUp(CMovement@ this, CBlob@ blob, SpaceshipMoveVars@ moveVars)
{
	//reset all the vars here
	moveVars.flySpeed = 1.0f;
	moveVars.flyFactor = 1.0f;
	moveVars.stoppingFactor = 1.0f;
}