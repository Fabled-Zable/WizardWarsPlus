
const string tagname = "played fanfare";

void onRestart(CRules@ this)
{
	this.set_bool(tagname, false);
}

void onTick(CRules@ this)
{
	int winteamIndex = this.getTeamWon();
	if (this.isGameOver() && winteamIndex >= 0 && !this.get_bool(tagname))
	{
		// only play for winners
		CPlayer@ localplayer = getLocalPlayer();
		if (localplayer !is null)
		{	
			int randomInt = XORRandom(4);
			if (randomInt == 0)
					Sound::Play( "/Victorious1.ogg" );
			else if (randomInt == 1)
					Sound::Play( "/Victorious2.ogg" );
			else if (randomInt == 2)
					Sound::Play( "/Victorious3.ogg" );
			else
					Sound::Play( "/Victorious4.ogg" );			
		}

		this.set_bool(tagname, true);
		// no sound played on spectator or tie
	}
}
