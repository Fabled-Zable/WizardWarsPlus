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

    FighterInfo@ frigate;
	if (!this.get( "fighterInfo", @frigate )) 
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
	CShape@ shape = thisBlob.getShape();
    if (shape != null)
    {
        shape.SetGravityScale(0.0f);
	    shape.setDrag(moveVars.dragMult);
    }

	const f32 vellen = shape.vellen;
	const bool onground = thisBlob.isOnGround() || thisBlob.isOnLadder();

    f32 speed = 0.05*moveVars.flySpeed;
    f32 acellBoost = moveVars.flyFactor;
    f32 dashSpeed = 8;
    s32 dashRate = 30/4;

    
    //Vec2f deltaV = Vec2f_zero;
    deltaV *= 1.0f / float(keysPressedAmount); //divide thrust between multiple sides

    Vec2f[] deltaV =
	{
		forward = Vec2f_zero,
		backward = Vec2f_zero,
        board = Vec2f_zero,
		starboard = Vec2f_zero
	};

    if(allKeys.up)
    {
        deltaV.forward += Vec2f(0,-speed*0.8);
    }
    if(allKeys.down)
    {
        deltaV.backward += Vec2f(0,speed*0.8);
    }
    if(allKeys.left)
    {
        deltaV.board += Vec2f(speed,0);
    }
    if(allKeys.right)
    {
        deltaV.starboard += Vec2f(-speed,0);
    }

    for (uint i = 0; i < allKeys.length; i ++)
    {
        bool currentKey = allKeys[i];
        if (currentKey)
        { keysPressedAmount++; }
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