#include "spiritCommon.as";

void onInit(CSprite@ this)
{
    CBlob@ b = this.getBlob();
    b.set_Vec2f("lastScale",Vec2f(1,1));
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

void onRender(CSprite@ this)//
{
    Energy@ e;
    this.getBlob().get("energy",@e);
    if(e !is null)
    {
        e.drawHud(this);
    }
}

void onTick(CSprite@ this)
{
    getHUD().SetCursorImage("arrow_cursor.png");

    CSpriteLayer@ glow = this.getSpriteLayer("glow");

    glow.setRenderStyle(RenderStyle::Style::light);//done every tick so that it doesn't break on team change, probably bad /shrug

    CBlob@ b = this.getBlob();
    Energy@ e;
    b.get("energy",@e);

    u32 power = e.energy;
    u32 maxPower = e.maxEnergy;

    if(power >= maxPower)
    {
        f32 size = b.add_f32("size",b.hasTag("reverse") ? -0.03 : 0.03);

        if(size < 1)
        {
            b.Untag("reverse");
        }
        else if(size > 2)
        {
            b.Tag("reverse");
        }
        b.set_Vec2f("lastScale",Scale(glow,Vec2f(size,size),this.getBlob().get_Vec2f("lastScale"))); //wowie this feels bad
    }
    else
    {
        f32 size = (float(power)/maxPower) * 2;//2 is max size

        b.set_Vec2f("lastScale",Scale(glow,Vec2f(size,size),this.getBlob().get_Vec2f("lastScale"))); //wowie this feels bad
    }

    this.SetFrame(getGameTime()%8);
    this.RotateBy(15,Vec2f_zero);
}


Vec2f Scale(CSpriteLayer@ s, Vec2f scale, Vec2f lastScale)
{
    f32 x = lastScale.x;
    f32 y = lastScale.y;
    if(x == 0 || y == 0) return scale;
    x = 1 / x;
    y = 1 / y;

    s.ScaleBy(Vec2f(x,y));
    s.ScaleBy(scale);
    
    return scale;
}