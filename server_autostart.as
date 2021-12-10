void Configure()
{
    v_driver = 0;  // disable video
    s_soundon = 0; // disable audio
    sv_gamemode = "CTF";
	sv_gravity = 9;
	sv_visiblity_scale = 6.0f;
    AddMod("WizardWars");
}

void InitializeGame()
{
    RegisterFileExtensionScript( "LoadPNGMap.as", "png" );

	if (getNet().CreateServer())
	{
	    LoadRules(  "Rules/CTF/gamemode.cfg" );
	    LoadMapCycle( "Rules/CTF/mapcycle.cfg" );
	    LoadNextMap();
	}
}

