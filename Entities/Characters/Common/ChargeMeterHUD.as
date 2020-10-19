#include "ChargeCommon.as"

void DrawChargeMeter(CBlob@ this, Vec2f origin)
{
	ChargeInfo@ chargeInfo;
    if (!this.get( "chargeInfo", @chargeInfo )) 
	{
        return;
    }
    string manaFile = "GUI/ManaBar.png";
	int barLength = 4;
    int segmentWidth = 24;
    GUI::DrawIcon("GUI/jends.png", 0, Vec2f(8,16), origin+Vec2f(-8,0));
    s32 maxCharge = chargeInfo.maxCharge;
    s32 currCharge = chargeInfo.charge;
	
	f32 chargePerSegment = maxCharge/barLength;
	
	f32 fourthManaSeg = chargePerSegment*(1.0f/4.0f);
	f32 halfManaSeg = chargePerSegment*(1.0f/2.0f);
	f32 threeFourthsManaSeg = chargePerSegment*(3.0f/4.0f);
	
	int CHARGE = 0;
    for (int step = 0; step < barLength; step += 1)
    {
        GUI::DrawIcon("GUI/ManaBack.png", 0, Vec2f(12,16), origin+Vec2f(segmentWidth*CHARGE,0));
        f32 thisCHARGE = currCharge - step*chargePerSegment;
        if (thisCHARGE > 0)
        {
            Vec2f manapos = origin+Vec2f(segmentWidth*CHARGE-1,0);
            if (thisCHARGE <= fourthManaSeg) { GUI::DrawIcon(manaFile, 4, Vec2f(16,16), manapos); }
            else if (thisCHARGE <= halfManaSeg) { GUI::DrawIcon(manaFile, 3, Vec2f(16,16), manapos); }
            else if (thisCHARGE <= threeFourthsManaSeg) { GUI::DrawIcon(manaFile, 2, Vec2f(16,16), manapos); }
            else if (thisCHARGE > threeFourthsManaSeg) { GUI::DrawIcon(manaFile, 1, Vec2f(16,16), manapos); }
            else { GUI::DrawIcon(manaFile, 0, Vec2f(16,16), manapos); }
        }
        CHARGE++;
    }
    GUI::DrawIcon("GUI/jends.png", 1, Vec2f(8,16), origin+Vec2f(segmentWidth*CHARGE,0));
	GUI::DrawText(currCharge+"%", origin+Vec2f(-42,8), color_white );
}