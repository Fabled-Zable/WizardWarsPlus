//default actor hud
// a bar with hearts in the bottom left, bottom right free for actor specific stuff

void renderBackBar( Vec2f origin, f32 width, f32 scale)
{
    for (f32 step = 0.0f; step < width/scale - 64; step += 64.0f * scale)
    {
        GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(64,32), origin+Vec2f(step*scale,0), scale);
    }

    GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(64,32), origin+Vec2f(width - 128*scale,0), scale);
}

void renderFrontStone( Vec2f farside, f32 width, f32 scale)
{
    for (f32 step = 0.0f; step < width/scale - 16.0f*scale*2; step += 16.0f*scale*2)
    {
        GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16,32), farside+Vec2f(-step*scale - 32*scale,0), scale);
    }

    if (width > 16) {
        GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16,32), farside+Vec2f(-width, 0), scale);
    }

    GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16,32), farside+Vec2f(-width - 32*scale, 0), scale);
    GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16,32), farside, scale);
}

void renderHPBar( CBlob@ blob, Vec2f origin)
{
    string heartFile = "GUI/HPbar.png"; // "GUI/HeartNBubble.png"
	int barLength = 4;
    int segmentWidth = 24; // 32
    GUI::DrawIcon("GUI/jends.png", 0, Vec2f(8,16), origin+Vec2f(-8,0)); // ("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16,32), origin+Vec2f(-segmentWidth,0));
	f32 blobHealth = blob.getHealth();
	f32 blobInitHealth = blob.getInitialHealth();
	f32 healthPerSegment = blobInitHealth/barLength;
	
	f32 fourthHPSeg = healthPerSegment*(1.0f/4.0f);
	f32 halfHPSeg = healthPerSegment*(1.0f/2.0f);
	f32 threeFourthsHPSeg = healthPerSegment*(3.0f/4.0f);
	
    int HPs = 0;
    for (int step = 0; step < barLength; step += 1)
    {	
        GUI::DrawIcon("GUI/HPback.png", 0, Vec2f(12,16), origin+Vec2f(segmentWidth*HPs,0)); // ("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(16,32), origin+Vec2f(segmentWidth*HPs,0));
        f32 thisHP = blobHealth - step*healthPerSegment;
        if (thisHP > 0)
        {
            // Vec2f heartoffset = (Vec2f(2,10) * 2);
            Vec2f heartpos = origin+Vec2f(segmentWidth*HPs-1,0); // origin+Vec2f(segmentWidth*HPs,0)+heartoffset;
			if (thisHP <= fourthHPSeg) { GUI::DrawIcon(heartFile, 4, Vec2f(16,16), heartpos); } // Vec2f(12,12)
            else if (thisHP <= halfHPSeg) { GUI::DrawIcon(heartFile, 3, Vec2f(16,16), heartpos); } // Vec2f(12,12)
            else if (thisHP <= threeFourthsHPSeg) { GUI::DrawIcon(heartFile, 2, Vec2f(16,16), heartpos); } // Vec2f(12,12)
			else if (thisHP > threeFourthsHPSeg) { GUI::DrawIcon(heartFile, 1, Vec2f(16,16), heartpos); } // else { GUI::DrawIcon(heartFile, 1, Vec2f(12,12), heartpos); }
            else { GUI::DrawIcon(heartFile, 0, Vec2f(16,16), heartpos); }
        }
        HPs++;
    }
    GUI::DrawIcon("GUI/jends.png", 1, Vec2f(8,16), origin+Vec2f(segmentWidth*HPs,0)); // ("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16,32), origin+Vec2f(32*HPs,0));
	GUI::DrawText(""+Maths::Round(blobHealth*10)+"/"+blobInitHealth*10, origin+Vec2f(-42,8), color_white );
}

void onInit( CSprite@ this )
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
}

void onRender( CSprite@ this )
{
	if (g_videorecording)
		return;

    CBlob@ blob = this.getBlob();
    // Vec2f dim = Vec2f(320,64);
    // Vec2f ul( getScreenWidth()/2.0f - dim.x/2.0f, getScreenHeight() - dim.y + 12 );
    // Vec2f lr( ul.x + dim.x, ul.y + dim.y );
	// GUI::DrawPane(ul, lr);
    // renderBackBar(ul, dim.x, 1.0f);
    // u8 bar_width_in_slots = blob.get_u8("gui_HUD_slots_width");
    // f32 width = bar_width_in_slots * 32.0f;
    // renderFrontStone( ul+Vec2f(dim.x,0), width, 1.0f);
	Vec2f topleft(52,10);
	GUI::DrawIcon("GUI/jslot.png", 1, Vec2f(32,32), Vec2f(2,2));
	renderHPBar( blob, topleft); // ( blob, ul);
    // GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(128,32), topLeft);
}
