#include "PlayerPrefsCommon.as";
#include "PlatinumCommon.as";
//#include "UnlocksCommon.as";

void onInit( CRules@ this )
{
	this.addCommandID("load playerPrefs");
	//this.addCommandID("unlock class");
	//this.addCommandID("buy unlock");
	
	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer is null)
	{
		return;
	}
	
	u16 callerID = localPlayer.getNetworkID();

	CBitStream params;
	params.write_u16(callerID);
	
	this.SendCommand(this.getCommandID("load playerPrefs"), params);
	
	setStartingPlatinum( this );
	//setStartingUnlocks( this );
}
bool security_reloaded = false;
void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
	//reload the seclevs shortly after a player joins once every new map to fix certain versions of windows preventing security to work
	if(security_reloaded == false )
	{
		getSecurity().reloadSecurity();
		security_reloaded = true;	
	}//Yes this is a bad way of doing it, i didn't want it every single next map so i settled for this. At least it works


	string pName = player.getUsername();
	u16 pPlatinum = server_getPlayerPlatinum( pName );
	
	if ( getNet().isServer() )
	{		
		ConfigFile platCFG;
		if ( platCFG.loadFile("../Cache/WW_PlatinumAccounts.cfg") )
		{
			if ( platCFG.exists( pName ) )
			{
				u32 platinum = platCFG.read_u32(pName);
				
				server_setPlayerPlatinum( pName, platinum );
			}
			else
				server_setPlayerPlatinum( pName, 0 );
		}
		/*
		ConfigFile unlockCFG;
		if ( unlockCFG.loadFile("../Cache/WW_UnlocksAccounts.cfg") )
		{
			if ( unlockCFG.exists( pName ) )
			{
				bool[] unlocks;
				unlockCFG.readIntoArray_bool(unlocks, pName);
				for ( u8 i = 0; i < unlocks.length; ++i )
				{
					print( "Setting starting unlock " + i + " as: " + unlocks[i] );
				}
				
				server_setPlayerUnlocks( pName, unlocks );
			}
			else
				server_setPlayerUnlocks( pName, getDefaultUnlocks() );
		}
		*/
	}
}

void onRestart( CRules@ this )
{
	setStartingPlatinum( this );
	//setStartingUnlocks( this );
}

void onTick(CRules@ this)
{
	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer is null)
	{
		return;
	}
	
	PlayerPrefsInfo@ playerPrefsInfo;
	if ( !localPlayer.get("playerPrefsInfo", @playerPrefsInfo) )
	{
		u16 callerID = localPlayer.getNetworkID();

		CBitStream params;
		params.write_u16(callerID);
		
		this.SendCommand(this.getCommandID("load playerPrefs"), params);
	}
	else if ( playerPrefsInfo.infoLoaded == false )
	{
		loadHotbarAssignments( localPlayer, "wizard" );
		loadHotbarAssignments( localPlayer, "druid" );
		loadHotbarAssignments( localPlayer, "necromancer" );
		loadHotbarAssignments( localPlayer, "swordcaster" );
		loadHotbarAssignments( localPlayer, "entropist" );
		loadHotbarAssignments( localPlayer, "frigate" );
		
		playerPrefsInfo.infoLoaded = true;
	}
	else
		ManageCooldowns(playerPrefsInfo);
}

void ManageCooldowns(PlayerPrefsInfo@ playerPrefsInfo)
{
	for (uint i = 0; i < MAX_SPELLS; ++i)
	{
		s32 currCooldown = playerPrefsInfo.spell_cooldowns[i];
		
		if ( currCooldown > 0 )
			playerPrefsInfo.spell_cooldowns[i] = Maths::Max( currCooldown - 1, 0 );
	}
}

void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
	if (this.getCommandID("load playerPrefs") == cmd)
	{
		u16 playerID = params.read_u16();
		
		CPlayer@ player = getPlayerByNetworkId(playerID);
		if ( player is null )
			return;
			
		PlayerPrefsInfo playerPrefsInfo;
		player.set( "playerPrefsInfo", @playerPrefsInfo );
		
		print("playerPrefs set");
	}
	/*
	else if (this.getCommandID("unlock class") == cmd)
	{
		string playerName = params.read_string();
		u16 unlockID = params.read_u16();
		
		ConfigFile cfg;
		if ( cfg.loadFile( "ClassVars.cfg" ) ) 
		{		
			bool[] unlocks = server_getPlayerUnlocks(playerName);
			print("unlocks length: "+unlocks.length);
			print("button number: "+unlockID);
			if ( unlockID < unlocks.length )
			{
				unlocks[unlockID] = true;
				server_setPlayerUnlocks(playerName, unlocks);
			}
		}
		
		CPlayer@ player = getPlayerByUsername( playerName );
		if ( player !is null && player.isMyPlayer() )
		{
			client_AddToChat("Class unlocked!", SColor(255,0,200,200));
			Sound::Play( "ChaChing.ogg" );
		}
	}
	else if (this.getCommandID("buy unlock") == cmd)
	{
		string playerName = params.read_string();
		u16 unlockID = params.read_u16();
		
		bool purchaseMade = false;
		
		u32 serverPlatinum = server_getPlayerPlatinum(playerName);
		u32 clientPlatinum = client_getPlayerPlatinum(playerName);
		ConfigFile cfg;
		if ( cfg.loadFile( "ClassVars.cfg" ) ) 
		{
			u32[] classCosts;
			cfg.readIntoArray_u32(classCosts, "class_costs");
			u32 cost = classCosts[unlockID];
			
			if ( serverPlatinum >= cost )
			{
				bool[] unlocks = server_getPlayerUnlocks(playerName);
				print("unlocks length: "+unlocks.length);
				print("button number: "+unlockID);
				if ( unlockID < unlocks.length )
				{
					unlocks[unlockID] = true;
					server_setPlayerUnlocks(playerName, unlocks);
					
					server_setPlayerPlatinum( playerName, serverPlatinum - cost );	
				}
			}
			
			if ( clientPlatinum >= cost )
				purchaseMade = true;
		}
		
		CPlayer@ player = getPlayerByUsername( playerName );
		if ( player !is null && player.isMyPlayer() )
		{
			if ( purchaseMade )
			{
				client_AddToChat("Purchase successful!", SColor(255,0,200,200));
				Sound::Play( "ChaChing.ogg" );
			}
			else
			{
				client_AddToChat("You do not have enough platinum to unlock this class.", SColor(255,0,200,200));
				Sound::Play( "MenuSelect5.ogg" );
			}
		}
		
	}
	*/
}