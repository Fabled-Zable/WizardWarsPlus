#include "PlayerPrefsCommon.as";
#include "PlatinumCommon.as";


void onInit(CRules@ this)
{

}

void onRender(CRules@ this)
{
	CPlayer@ p = getLocalPlayer();

	if (p is null || !p.isMyPlayer()) { return; }
	string pName = p.getUsername();
	
	u32 platinum = this.get_u32( "platinum" + pName );
	
	Vec2f mainPos = Vec2f(0.0f,128.0f);
	
	GUI::DrawRectangle(mainPos, mainPos + Vec2f(96,32), SColor(100, 0, 0, 0));
	GUI::DrawText("Platinum:\n   $" + platinum, mainPos, SColor(255, 255, 255, 255));
}
 