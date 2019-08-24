//Platinum related functions. mostly server-side that sync to clients

void SetupPlatinum( CRules@ this )
{
	if ( getNet().isServer() )
	{
		dictionary@ current_pSet;
		if ( !this.get( "PlatinumSet", @current_pSet ) )
		{
			print( "** Setting Platinum Dictionary" );
			dictionary pSet;
			this.set( "PlatinumSet", pSet );
		}
	}
}
 
dictionary@ getPlatinumSet()
{
	dictionary@ pSet;
	getRules().get( "PlatinumSet", @pSet );
	
	return pSet;
}

void setStartingPlatinum( CRules@ this )
{
	//reset properties
	print( "** SetStartingPlatinum routine" );
	dictionary@ platinumSet = getPlatinumSet();
	/*//causes seg faults
	string[]@ bKeys = platinumSet.getKeys();
	for ( u8 i = 0; i < bKeys.length; i++ )
	{
		print( bKeys[i] );
		this.set_u32( bKeys[i], 0 );
	}*/
	
	//platinumSet.deleteAll();//clear platinum
	dictionary pSet;
	this.set( "PlatinumSet", pSet );

	print( "** Setting Starting Player Platinum ");


	if ( getNet().isServer() )
	{		
		ConfigFile cfg;
		if ( cfg.loadFile("../Cache/WW_PlatinumAccounts.cfg") )
		{
			for ( u8 p = 0; p < getPlayersCount(); ++p )
			{
				CPlayer@ player = getPlayer(p);
				if ( player is null )
					continue;
				
				string playerName = player.getUsername();	
				
				if ( cfg.exists( playerName ) )
				{
					u32 platinum = cfg.read_u32(playerName);
					
					server_setPlayerPlatinum( playerName, platinum );
				}
				else
					server_setPlayerPlatinum( playerName, 0 );
			}
		}
		else
		{
			for ( u8 p = 0; p < getPlayersCount(); ++p )
			{
				CPlayer@ player = getPlayer(p);
				if ( player is null )
					continue;
				
				string playerName = player.getUsername();	
				
				server_setPlayerPlatinum( playerName, 0 );
			}	
		}
	}
}

//player
u32 server_getPlayerPlatinum( string name )
{
	if ( getNet().isServer() )
	{
		u32 platinum;
		if ( getPlatinumSet().get( "platinum" + name, platinum ) )
			return platinum;
	}
	
	return 0;
}

u32 client_getPlayerPlatinum( string name )
{
	if ( getNet().isClient() )
	{
		CRules@ rules = getRules();
		u32 platinum = rules.get_u32( "platinum" + name );
			return platinum;
	}
	
	return 0;
}
 
void server_setPlayerPlatinum( string name, u32 platinum )
{
	if (getNet().isServer())
	{
		getPlatinumSet().set( "platinum" + name, platinum );
		//sync to clients
		CRules@ rules = getRules();
		rules.set_u32( "platinum" + name, platinum );
		rules.Sync( "platinum" + name, true );
		CPlayer@ player = getPlayerByUsername( name );
		
		ConfigFile cfg;
		cfg.loadFile("../Cache/WW_PlatinumAccounts.cfg");
		
		cfg.add_u32(name, platinum);
		
		cfg.saveFile( "WW_PlatinumAccounts.cfg" );
	}
}