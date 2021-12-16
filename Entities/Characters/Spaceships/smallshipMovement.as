// Fighter Movement

#include "FighterCommon.as"
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
    /*
	const bool left		= thisBlob.isKeyPressed(key_left);
	const bool right	= thisBlob.isKeyPressed(key_right);
	const bool up		= thisBlob.isKeyPressed(key_up);
	const bool down		= thisBlob.isKeyPressed(key_down);
    */
    
    const bool[] allKeys =
	{
		left = thisBlob.isKeyPressed(key_left),
		right = thisBlob.isKeyPressed(key_right),
		up = thisBlob.isKeyPressed(key_up),
		down = thisBlob.isKeyPressed(key_down)
	};

    u8 keysPressedAmount = 0;
    for (uint i = 0; i < allKeys.length; i ++)
    {
        if (allKeys[i])
        { keysPressedAmount++; }
    }
    

	const bool isknocked = isKnocked(thisBlob) || (thisBlob.get_bool("frozen") == true);

	const bool is_client = isClient();


	Vec2f vel = thisBlob.getVelocity();
	Vec2f pos = thisBlob.getPosition();
	CShape@ shape = thisBlob.getShape();
    if (shape != null)
    {
        shape.SetGravityScale(0.0f);
	    shape.setDrag(moveVars.dragMult);
    }

	const f32 vellen = shape.vellen;
	const bool onground = thisBlob.isOnGround() || thisBlob.isOnLadder();

	if (is_client && getGameTime() % 3 == 0)
	{
		const string acceltag = "engine_is_accelerating";
		if (thisBlob.isKeyPressed(key_left) || thisBlob.isKeyPressed(key_right))
		{
			if (vel.x < 0.4f && vel.x > -0.4f)
			{
				if (!thisBlob.hasTag(acceltag))
				{
					thisBlob.Tag(acceltag);
					Sound::Play("engine_accel.ogg", pos, 3.0f);
					thisBlob.set_u32("accelSoundDelay", getGameTime() + 200);
				}
			}
		}
		else if(getGameTime() > thisBlob.get_u32("accelSoundDelay"))
		{
			thisBlob.Untag(acceltag);
		}
	}

	


    f32 speed = 0.05*moveVars.flySpeed;
    f32 acellBoost = moveVars.flyFactor;
    f32 dashSpeed = 8;
    s32 dashRate = 30/4;


    Vec2f deltaV = Vec2f_zero;

    if(thisBlob.isKeyPressed(key_right))
    {
        deltaV += Vec2f(speed,0);
    }
    if(thisBlob.isKeyPressed(key_left))
    {
        deltaV += Vec2f(-speed,0);
    }

    if(thisBlob.isKeyPressed(key_up))
    {
        deltaV += Vec2f(0,-speed*0.8);
    }
    if(thisBlob.isKeyPressed(key_down))
    {
        deltaV += Vec2f(0,speed*0.8);
    }

    if(thisBlob.getPosition().y/8 >=  getMap().tilemapheight - 2)
    {
        vel = Vec2f(vel.x,-1);
    }

    if(thisBlob.getPosition().y <= 2)
    {
        vel = Vec2f(vel.x,1);
    }

    thisBlob.setVelocity(vel + (deltaV*acellBoost));

	CleanUp(this, thisBlob, moveVars);
}