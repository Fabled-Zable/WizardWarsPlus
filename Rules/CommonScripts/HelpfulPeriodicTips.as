#define CLIENT_ONLY

string[] tips;
u32 SHOW_FREQUENCY = 3 * 60 * 30;

void onRestart( CRules@ this )
{
	LoadTips();
}

void onInit( CRules@ this )
{
	onRestart( this );
}

void onTick( CRules@ this )
{
	if ( getGameTime() % SHOW_FREQUENCY == 0 && tips.length > 0 )
		client_AddToChat( ">TIP: " + tips[XORRandom(tips.length)] );
}

void LoadTips()
{
	tips.clear();

	ConfigFile cfg;
	if(cfg.loadFile("HelpfulDeathTips.cfg"))
		cfg.readIntoArray_string( tips, "tips" );
}