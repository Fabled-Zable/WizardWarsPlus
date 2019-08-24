// Game Music

#define CLIENT_ONLY

enum GameMusicTags
{
	world_intro,
	world_home,
	world_calm,
	world_battle,
	world_battle_2,
	world_outro,
	world_quick_out,
};

void onInit(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	this.set_bool("initialized game", false);
}

void onTick(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	if (s_gamemusic && s_musicvolume > 0.0f)
	{
		if (!this.get_bool("initialized game"))
		{
			AddGameMusic(this, mixer);
		}

		GameMusicLogic(this, mixer);
	}
	else
	{
		mixer.FadeOutAll(0.0f, 2.0f);
	}
}

//sound references with tag
void AddGameMusic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	this.set_bool("initialized game", true);
	mixer.ResetMixer();
	mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/CBoyarde.ogg", world_home);
	mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/MarioKart.ogg", world_home);
	mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/LogHorizon1.ogg", world_home);
	mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/LogHorizon2.ogg", world_home);
	mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/Corneria.ogg", world_home);
	mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/Cornered.ogg", world_home);
	mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/Guile.ogg", world_home);
	mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/KingDedede.ogg", world_home);
	mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/MetaKnight.ogg", world_home);
	mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/MuteCity.ogg", world_home);
	mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/Targets.ogg", world_home);
	mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/TheTouch.ogg", world_home);
	//mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/music_ssbu.ogg", world_home);
	//mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/RainbowRoad.ogg", world_home);
	//mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/Hyrule.ogg", world_home);
	//mixer.AddTrack("../Mods/WizardWars_Music/Sounds/Music/GreenHills.ogg", world_home);
}

uint timer = 0;

void GameMusicLogic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	//warmup
	CRules @rules = getRules();

	if (rules.isWarmup() || rules.isMatchRunning())
	{
		if (mixer.getPlayingCount() == 0)
		{
			mixer.FadeInRandom(world_home , 0.0f);
		}
	}
	else
	{
		mixer.FadeOutAll(0.0f, 1.0f);
	}
}
