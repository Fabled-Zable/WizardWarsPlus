// default startup functions for autostart scripts

void RunServer()
{
	if (getNet().CreateServer())
	{
		LoadRules("Rules/" + sv_gamemode + "/gamemode" + sv_gamemode + ".cfg");
		//LoadRules("Rules/" + "CTF" + "/gamemodeCTF.cfg");

		if (sv_mapcycle.size() > 0)
		{
			LoadMapCycle(sv_mapcycle);
		}
		else
		{
			LoadMapCycle("Rules/" + sv_gamemode + "/mapcycle" + sv_gamemode + ".cfg");
			//LoadMapCycle("Rules/" + "CTF" + "/mapcycleCTF.cfg");
		}

		LoadNextMap();
	}
}

void ConnectLocalhost()
{
	getNet().Connect("localhost", sv_port);
}

void RunLocalhost()
{
	RunServer();
	ConnectLocalhost();
}

void LoadDefaultMenuMusic()
{
	if (s_menumusic)
	{
		CMixer@ mixer = getMixer();
		if (mixer !is null)
		{
			mixer.ResetMixer();
			mixer.AddTrack("Sounds/Music/world_intro.ogg", 0);
			mixer.PlayRandom(0);
		}
	}
}
