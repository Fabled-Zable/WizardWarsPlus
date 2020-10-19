
void onInit(CBlob@ this)
{
    this.set_s32("rightTap",0);
    this.set_s32("leftTap",0);
    this.set_s32("upTap",0);
    this.set_s32("downTap",0);
}

void onTick(CMovement@ this)
{
    CBlob@ b = this.getBlob();

    f32 speed = 0.05;
    f32 acellBoost = 4;
    f32 dashSpeed = 8;
    s32 dashRate = 30/4;

    Vec2f deltaV = Vec2f_zero;
    Vec2f vel = b.getVelocity();

    

    if(b.isKeyJustPressed(key_right))
    {
        s32 lastTap = b.get_s32("rightTap");
        if(getGameTime() - lastTap < dashRate)
        {
            vel.x = dashSpeed;
        }
        b.set_s32("rightTap",getGameTime());
    }
    if(b.isKeyJustPressed(key_left))
    {
        s32 lastTap = b.get_s32("leftTap");
        if(getGameTime() - lastTap < dashRate)
        {
            vel.x = -dashSpeed;
        }
        b.set_s32("leftTap",getGameTime());
    }
    if(b.isKeyJustPressed(key_up))
    {
        s32 lastTap = b.get_s32("upTap");
        if(getGameTime() - lastTap < dashRate)
        {
            vel.y = -dashSpeed;
        }
        b.set_s32("upTap",getGameTime());
    }
    if(b.isKeyJustPressed(key_down))
    {
        s32 lastTap = b.get_s32("downTap");
        if(getGameTime() - lastTap < dashRate)
        {
            vel.y = dashSpeed;
        }
        b.set_s32("downTap",getGameTime());
    }
    


    if(b.isKeyPressed(key_right))
    {
        deltaV += Vec2f(speed,0);
    }
    if(b.isKeyPressed(key_left))
    {
        deltaV += Vec2f(-speed,0);
    }

    if(b.isKeyPressed(key_up))
    {
        deltaV += Vec2f(0,-speed/2);
    }
    if(b.isKeyPressed(key_down))
    {
        deltaV += Vec2f(0,speed/2);
    }

    if(b.getPosition().y/8 >=  getMap().tilemapheight - 2)
    {
        vel = Vec2f(vel.x,-1);
    }

    b.setVelocity(vel + (deltaV*1));

}