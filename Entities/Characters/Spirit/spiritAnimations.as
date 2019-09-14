
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

void onTick(CSprite@ this)
{
    getHUD().SetCursorImage("arrow_cursor.png");

    CSpriteLayer@ glow = this.getSpriteLayer("glow");

    glow.setRenderStyle(RenderStyle::Style::light);//done every tick so that it doesn't break on team change, probably bad /shrug

    CBlob@ b = this.getBlob();

    this.SetFrame(getGameTime()%8);
    this.RotateBy(15,Vec2f_zero);
}
