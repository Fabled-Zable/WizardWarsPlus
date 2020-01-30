//#include "GUICommon.as"
#include "godCommon.as"

void onRender( CSprite@ this )
{
    f32 scale = 1;

    CBlob@ blob = this.getBlob();
    if(getLocalPlayer() is blob.getPlayer())
    {
        int width = 93;//it seems that you need to * 2 in order for it to be accurate
        int height = 44;
        int teamNum = blob.getTeamNum();

        Vec2f checkbox1 = Vec2f(57,8) * scale;
        Vec2f checkbox2 = Vec2f(57,26) * scale;

        Vec2f mainPos = Vec2f(20, 20);
        GUI::DrawIcon("MainGui.png",0, Vec2f(width,height), mainPos, scale, teamNum);

        if(!blob.get_bool("noclip"))
        {
            GUI::DrawIcon("CheckBoxUnchecked.png",0, Vec2f(11,11),mainPos + checkbox1*2,scale);
        }
        if(!blob.get_bool("gravity"))
        {
            GUI::DrawIcon("CheckBoxUnchecked.png",0, Vec2f(11,11), mainPos + checkbox2*2,scale);
        }
        
    }

    IEffectMode@ mode;
    blob.get("mode",@mode);
    mode.render(this,scale);
}