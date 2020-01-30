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

    f32 speed = 0.2;
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
        deltaV += Vec2f(vel.x < 2 ? speed*acellBoost : speed,0);
    }
    if(b.isKeyPressed(key_left))
    {
        deltaV += Vec2f(vel.x > -2 ? speed * -1 * acellBoost : -1 * speed,0);
    }

    if(b.isKeyPressed(key_up))
    {
        deltaV += Vec2f(0,vel.y > -2 ? speed * -1 * acellBoost : -1 * speed);
    }
    if(b.isKeyPressed(key_down))
    {
        deltaV += Vec2f(0,vel.y < 2 ? speed * acellBoost : speed);
    }

    if(b.getPosition().y/8 >=  getMap().tilemapheight - 2)
    {
        vel = Vec2f(vel.x,-1);
    }

    b.setVelocity(vel + deltaV);

    if((vel + deltaV).x > 0)//two if statements instead of boolean operators so that when the velocity is at 0 the sprite will face the last position
    {
        b.SetFacingLeft(false);
    }
    else if((vel + deltaV).x < 0)
    {
        b.SetFacingLeft(true);
    }


    CControls@ controls = getControls();
    if(controls.isKeyJustPressed(KEY_KEY_V))
    {
        b.set_bool("noclip",!b.get_bool("noclip"));

        b.Sync("noclip", false);
    }
    if(controls.isKeyJustPressed(KEY_KEY_G))
    {
        b.set_bool("gravity",!b.get_bool("gravity"));
        b.Sync("gravity", false);
    }
}