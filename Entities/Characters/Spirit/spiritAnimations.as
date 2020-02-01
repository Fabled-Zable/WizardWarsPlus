
void onInit(CSprite@ this)
{
    CBlob@ b = this.getBlob();
    b.set_f32("size",0);
    b.SetLightRadius(32);
    b.SetLight(true);

    SColor color;
    switch(b.getTeamNum())
    {
        case 0:
        color = SColor(255,0,0,255);
        break;
        case 1:
        color = SColor(255,255,0,0);
        break;
        default:
        color = SColor(255,0,0,0);
        break;
    }
    b.SetLightColor(color);

    this.SetZ(1450);// draw over ground
    CSpriteLayer@ s = this.addSpriteLayer("glow","team_color_circle",100,100);
    s.ScaleBy(Vec2f(0.1,0.1));
    s.SetRelativeZ(-1);
    b.set_f32("soft_frame",0);


}

void onChangeTeam( CBlob@ this, const int oldTeam )
{
    SColor color;
    switch(this.getTeamNum())
    {
        case 0:
        color = SColor(255,0,0,255);
        break;
        case 1:
        color = SColor(255,255,0,0);
        break;
        default:
        color = SColor(255,0,0,0);
        break;
    }
    this.SetLightColor(color);
}

const f32 speedConst = 0.1; //this is a arbitrary value :D

void onTick(CSprite@ this)
{
    if(this.getBlob().getPlayer() is getLocalPlayer())
    {
        getHUD().SetCursorImage("arrow_cursor.png");
    }

    CSpriteLayer@ glow = this.getSpriteLayer("glow");

    glow.setRenderStyle(RenderStyle::Style::light);//done every tick so that it doesn't break on team change, probably bad /shrug

    CBlob@ b = this.getBlob();
    if(b is null) return;
    Vec2f vel = b.getVelocity();
    f32 speed = Maths::Abs(vel.x) + Maths::Abs(vel.y) + 1; //const is to keep it moving when hovering
    speed = speed > 6 ? 6 : speed;//cap it

    f32 softframe = b.add_f32("soft_frame", speed * speedConst);

    if(softframe > 4)
    {
        b.set_f32("soft_frame",0);
    }

    this.SetFrame(softframe);
}
