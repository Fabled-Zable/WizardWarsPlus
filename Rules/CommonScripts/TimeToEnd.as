//Rules timer!

// Requires game_end_time set originally

void onInit(CRules@ this)
{
	if (!this.exists("no timer"))
		this.set_bool("no timer", false);
	if (!this.exists("game_end_time"))
		this.set_u32("game_end_time", 0);
	if (!this.exists("end_in"))
		this.set_u32("end_in", 0);
    onReset(this);
}
void onRestart( CRules@ this )
{
    onReset(this);
}
void onReset( CRules@ this)
{
    if(isServer())
    {
        this.set_u8("spawnbuff", 3);
    }
}
void onTick(CRules@ this)
{
	if (!getNet().isServer() || !this.isMatchRunning() || this.get_bool("no timer"))
	{
		return;
	}

	u32 gameEndTime = this.get_u32("game_end_time");

	if (gameEndTime == 0) return; //-------------------- early out if no time.

	this.set_u32("end_in", (u32(gameEndTime) - u32(getGameTime())) / 30);
	this.Sync("end_in", true);
    u8 spawnbuff = this.get_u8("spawnbuff");

	if (getGameTime() > gameEndTime)
	{
		bool hasWinner = false;
		s8 teamWonNumber = -1;

		if (this.exists("team_wins_on_end"))
		{
			teamWonNumber = this.get_s8("team_wins_on_end");
		}

		if (teamWonNumber >= 0)
		{
			//ends the game and sets the winning team
			this.SetTeamWon(teamWonNumber);
			CTeam@ teamWon = this.getTeam(teamWonNumber);

			if (teamWon !is null)
			{
				hasWinner = true;
				this.SetGlobalMessage("Time is up!\n" + teamWon.getName() + " wins the game!");
			}
		}

		if (!hasWinner)
		{
			this.SetGlobalMessage("Time is up!\nIt's a tie!");
		}

        this.set_u8("spawnbuff", 3);

		//GAME OVER
		this.SetCurrentState(3);
	}
    else if(spawnbuff != 0 && getGameTime() > gameEndTime - 900 * spawnbuff)// 900 is 30 seconds
    {
        server_CreateBlob("damage_buff", 0, Vec2f(128 + XORRandom(getMap().getMapDimensions().x - 256), 0));//create damage buff at top of map 128 pixels away from the sides randomly
        this.set_u8("spawnbuff", spawnbuff - 1);
    }
}

void onRender(CRules@ this)
{
	if (!this.isMatchRunning() || this.get_bool("no timer") || !this.exists("end_in")) return;

	u32 end_in = this.get_u32("end_in");

	if (end_in > 0)
	{
		u32 timeToEnd = end_in;

		u32 secondsToEnd = timeToEnd % 60;
		u32 MinutesToEnd = timeToEnd / 60;
		drawRulesFont("Time left: " +
		              ((MinutesToEnd < 10) ? "0" + MinutesToEnd : "" + MinutesToEnd) +
		              ":" +
		              ((secondsToEnd < 10) ? "0" + secondsToEnd : "" + secondsToEnd),
		              SColor(255, 255, 255, 255), Vec2f(10, 140), Vec2f(getScreenWidth() - 20, 180), true, false);
	}
}
