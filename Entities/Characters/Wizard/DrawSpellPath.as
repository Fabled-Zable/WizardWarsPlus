// Wizard logic

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	CMap@ map = blob.getMap();
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is blob)
	{
		// show spell path
		if ( blob.get_bool("casting") )
		{
			Vec2f pos = blob.getPosition();
			Vec2f myPos =  blob.getScreenPos();
			Vec2f aimPos2D = getDriver().getScreenPosFromWorldPos(blob.getAimPos());

			Vec2f blockedPos2D = getDriver().getScreenPosFromWorldPos( blob.get_Vec2f("spell blocked pos") );
			GUI::DrawArrow2D(myPos, blockedPos2D, SColor(255, 158, 58, 187));
		}
	}
}