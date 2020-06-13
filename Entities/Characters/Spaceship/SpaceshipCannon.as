// Spaceship Main Cannon

float BULLET_SPEED_FACTOR = 5.0f; //bullet speed amplifier
float RECOIL_FACTOR = 80.0f; //recoil amplifier

void onInit(CBlob@ this)
{
    this.set_u8("reload timer",0); //naming it timer instead of cooldown because of planned heat mechanic
    this.getSprite().AddScript("SpaceshipCannon.as"); //need to do this to get the sprite hooks to run
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
    if (this.get_u8("reload timer") > 0) //counts down reload
    {
        this.set_u8("reload timer", (this.get_u8("reload timer")-1) );
        return;
    }
    
    bool mouse1 = this.isKeyPressed(key_action1); //checks for M1 click, do nothing if not pressed
    if (!mouse1)
    {return;}

    this.set_u8("reload timer",30); //starts reload of 1 second

    const bool is_client = isClient();
    const bool is_server = isServer();

    CMap@ map = this.getMap();
    Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();
    Vec2f aimPos = this.getAimPos();
    Vec2f aimVec = aimPos - pos;
    float aimAngle = aimVec.AngleDegrees();
    aimAngle *= -1; //inverts it for future use

    //gets aim direction, and then amplifies it to get projectile speed. Also takes into account Ship speed.
    Vec2f projectileDir = Vec2f(1,0).RotateByDegrees(aimAngle);
    projectileDir *= BULLET_SPEED_FACTOR;
    projectileDir += vel;
    if(is_server)
    {
        CBlob@ orb = server_CreateBlob( "orb" );
		if (orb !is null)
		{
            orb.IgnoreCollisionWhileOverlapped( this );
            orb.SetDamageOwnerPlayer( this.getPlayer() );
            orb.server_setTeamNum( this.getTeamNum() );
            orb.setPosition( pos );
			orb.setVelocity( projectileDir );
        }
    }

    //"recoil" system
    this.AddForce(-projectileDir*RECOIL_FACTOR);
    
}

void onTick(CSprite@ this)
{
	CBlob@ b = this.getBlob();
	if(!b.exists("spriteSetupDone") || !b.get_bool("spriteSetupDone"))
	{
		CSpriteLayer@ layer = this.addSpriteLayer("cannon","Knife.png",13,4,b.getTeamNum(),0);
        layer.SetRelativeZ(500.0f);
		b.set_bool("spriteSetupDone",true);
	}

    CSpriteLayer@ layer = this.getSpriteLayer("cannon");

    Vec2f pos = b.getPosition();
    Vec2f aimPos = b.getAimPos();
    Vec2f aimVec = aimPos - pos;
    float aimAngle = aimVec.AngleDegrees();
    aimAngle *= -1; //inverts it for future use
    layer.ResetTransform();
    layer.RotateByDegrees(this.isFacingLeft() ? (aimAngle + 180) : aimAngle,Vec2f_zero);
}