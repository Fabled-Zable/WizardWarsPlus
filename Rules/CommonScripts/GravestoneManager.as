
void onTick(CRules@ this)
{
	if  ( getGameTime() % 200 == 0 && getNet().isServer() && !this.isWarmup() )
	{
		for (int player_step = 0; player_step < getPlayersCount(); ++player_step)
		{
			CPlayer@ player = getPlayer(player_step);
			if ( player !is null )
			{
				CBlob@ playerBlob = player.getBlob();
				if ( playerBlob is null )
				{
					spawnGraveAtBase( player );
					
					CBlob@ gravestone = getBlobByNetworkID( player.get_u16("gravestone ID") );
					if ( gravestone !is null )
						gravestone.server_setTeamNum(player.getTeamNum());
				}
			}
		}	
	}
}


void onBlobDie(CRules@ this, CBlob@ blob)
{
	if ( blob is null )
		return;
	
	if ( !getNet().isServer() )
		return;
	
	CPlayer@ victimPlayer = blob.getPlayer(); 	
	if ( victimPlayer !is null )
	{
		spawnGraveAtPlayerBlob( victimPlayer );	
	}
}

void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
	if ( !getNet().isServer() )
		return;

	this.set_bool("join",true);
	this.SyncToPlayer("join", player);
	
	if ( player !is null )
	{
		spawnGraveAtBase( player );		
	}
}

void spawnGraveAtBase( CPlayer@ player )
{
	if (player is null)
		return;

	CBlob@ playerGrave = getBlobByNetworkID( player.get_u16("gravestone ID") );
	if ( playerGrave !is null )
		return;

	//spawn grave at the base
	Vec2f spawnLocation = Vec2f( 32, 32 );
	spawnLocation = getSpawnLocation( player );
	
	CBlob@ gravestone = server_CreateBlob("gravestone", player.getTeamNum(), spawnLocation);
	if (gravestone !is null)
	{
		gravestone.setVelocity(Vec2f(XORRandom(12) - 6, -6));
		gravestone.set_u16( "owner_player", player.getNetworkID() );	
		player.set_u16("gravestone ID", gravestone.getNetworkID());
	}
}

void spawnGraveAtPlayerBlob( CPlayer@ player )
{
	if (player is null)
		return;
		
	CBlob@ playerBlob = player.getBlob();
	if (playerBlob is null)
		return;

	CBlob@ playerGrave = getBlobByNetworkID( player.get_u16("gravestone ID") );
	if ( playerGrave !is null )
		return;

	//spawn grave at the base
	Vec2f spawnLocation = Vec2f( 32, 32 );
	spawnLocation = playerBlob.getPosition();
	
	CBlob@ gravestone = server_CreateBlob("gravestone", player.getTeamNum(), spawnLocation);
	if (gravestone !is null)
	{
		gravestone.setVelocity(Vec2f(XORRandom(12) - 6, -6));
		gravestone.set_u16( "owner_player", player.getNetworkID() );	
		player.set_u16("gravestone ID", gravestone.getNetworkID());
	}
}

Vec2f getSpawnLocation( CPlayer@ player )
{
	CBlob@[] spawns;
	CBlob@[] teamspawns;

	if (getBlobsByName("tdm_spawn", @spawns))
	{
		for (uint step = 0; step < spawns.length; ++step)
		{
			if (spawns[step].getTeamNum() == player.getTeamNum())
			{
				teamspawns.push_back(spawns[step]);
			}
		}
	}

	if (teamspawns.length > 0)
	{
		int spawnindex = XORRandom(997) % teamspawns.length;
		return teamspawns[spawnindex].getPosition();
	}

	return Vec2f(0, 0);
}
