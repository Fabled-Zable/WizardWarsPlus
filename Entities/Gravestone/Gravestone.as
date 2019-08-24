//Gravestone code

void onInit( CBlob@ this )
{
	this.Tag("gravestone");
	this.getSprite().SetZ(500.0f);
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags( u8(CBlob::map_collide_none) | u8(CBlob::map_collide_nodeath) );
	
    //this.setVelocity(Vec2f(XORRandom(8) - 4, -4)); This line is in RunnerDeath.as
}

void onTick( CBlob@ this )
{
	int playerId = this.get_u16( "owner_player" );
	CPlayer@ deadPlayer = getPlayerByNetworkId( playerId );
	
	//kill if player is null or a spectator	or owner alive
	if ( deadPlayer !is null )
	{
		if ( deadPlayer.getBlob() !is null || deadPlayer.getTeamNum() == getRules().getSpectatorTeamNum() )
			this.server_Die();
	}
	else
		this.server_Die();

	//set up grave text
	if (this.getTickSinceCreated() < 1)
	{		
		if( deadPlayer !is null )
		{
			if (!this.exists("text"))
			{
				this.set_string("text", "Here lies the soul of " + deadPlayer.getCharacterName() 
					+ ". May " + (deadPlayer.getSex() == 0 ? "he" : "she") + " rest in peace... or get revived by someone.");
			}
		}
		
		this.getSprite().SetZ(500.0f);
	}

    //stick to map
    if (!this.hasTag("on_map") && this.isOnMap()) 
    {
        int angle = this.getGroundNormal().Angle(); // to check if it's on ground
        if (angle >= 45 && angle <= 135)
        {
            StickToGround(this);
        }
    }    
	
	//prevent leaving the map
	Vec2f pos = this.getPosition();
	if (pos.x < 4.0f 
			|| pos.x > (getMap().tilemapwidth * getMap().tilesize) - 4.0f
			|| pos.y < 4.0f
			|| pos.y > (getMap().tilemapheight * getMap().tilesize) - 4.0f )
	{
		Vec2f spawnLocation = Vec2f( 32, 32 );
		CPlayer@ graveOwner = getPlayerByNetworkId( this.get_u16( "owner_player" ) );
		if (graveOwner !is null)
		{		
			spawnLocation = getSpawnLocation( graveOwner );
		}
		this.setVelocity(Vec2f(XORRandom(12) - 6, -6));
		this.setPosition( spawnLocation );
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

//sprite update
void onTick( CSprite@ this )
{
    //simple rotation
    CBlob@ blob = this.getBlob();
    Vec2f vel = blob.getVelocity();
    if (vel.y != 0)
        this.RotateAllBy(5 * vel.x, Vec2f_zero);	 		  
}

void StickToGround(CBlob@ this)
{
    //resetting sprite rotation by recreating a gravestone
    if (getNet().isServer())
    {
        this.server_Die();
        CBlob@ gravestone = server_CreateBlob("gravestone", this.getTeamNum(), this.getPosition());
        if (gravestone !is null) 
        {
            gravestone.Tag("on_map");
            gravestone.shape.SetStatic(true);
					
			u16 ownerPlayerID = this.get_u16( "owner_player" );
			gravestone.set_u16( "owner_player", ownerPlayerID );	
			
			CPlayer@ ownerPlayer = getPlayerByNetworkId( ownerPlayerID );
			if ( ownerPlayer !is null )
				ownerPlayer.set_u16( "gravestone ID", gravestone.getNetworkID() );
        }
    }

}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	if (getHUD().menuState != 0) return;

	Vec2f pos2d = blob.getScreenPos();
	
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob !is null)
	{
		if (
			((localBlob.getPosition() - blob.getPosition()).Length() < 0.5f * (localBlob.getRadius() + blob.getRadius())) &&
			(!getHUD().hasButtons()))
		{
			// draw drop time progress bar
			int top = pos2d.y - 2.5f * blob.getHeight() - 100.0f;
			int left = 0.0f;
			int margin = 4;
			Vec2f dim;
			string label = blob.get_string("text");
			label += "\n";
			GUI::GetTextDimensions(label , dim);
			dim.x = Maths::Min(dim.x, 200.0f);
			dim.x += margin;
			dim.y += margin;
			dim.y *= 1.0f;
			top += dim.y;
			Vec2f upperleft(pos2d.x - dim.x / 2 - left, top - Maths::Min(int(2 * dim.y), 250));
			Vec2f lowerright(pos2d.x + dim.x / 2 - left, top - dim.y);
			GUI::DrawText(label, Vec2f(upperleft.x + margin, upperleft.y + margin + margin),
						  Vec2f(upperleft.x + margin + dim.x, upperleft.y + margin + dim.y),
						  SColor(255, 0, 0, 0), false, false, true);
		}
	}
	
	CPlayer@ graveOwner = getPlayerByNetworkId( blob.get_u16( "owner_player" ) );
	CPlayer@ localPlayer = getLocalPlayer();
	if ( graveOwner is localPlayer )
	{
		Vec2f iconPos = Vec2f(pos2d.x - 17, pos2d.y - 40);
		Vec2f dim(16, 16);
		
		GUI::DrawIcon("GUI/PartyIndicator.png", 2, dim, iconPos + Vec2f(0, Maths::Sin(getGameTime() / 3.0f)*5.0f), 1.0f);
		GUI::DrawText("YOU", iconPos + Vec2f(0, Maths::Sin(getGameTime() / 3.0f)*5.0f - 4), SColor(255, 245, 245, 0));
	}
}