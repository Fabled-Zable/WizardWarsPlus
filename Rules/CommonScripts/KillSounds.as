
void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (blob !is null && blob.getPlayer() !is null)
	{
		Sound::Play("LoseDrums.ogg");
		CPlayer@ localplayer = getLocalPlayer();
		if (localplayer !is null)
		{
			CBlob@ localBlob = getLocalPlayerBlob();
			int teamNum = localBlob !is null ? localBlob.getTeamNum() : localplayer.getTeamNum() ; // bug fix (cause in singelplayer player team is 255)
			if ( teamNum == blob.getTeamNum() )
			{
				Sound::Play("LoseDrums.ogg");
			}
			else
			{
				Sound::Play("VictoryDrums.ogg");
			}
		}
	}
}
