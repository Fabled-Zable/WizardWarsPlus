
void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
    shape.SetGravityScale(0.0f);
	shape.getConsts().mapCollisions = false;
    shape.SetVelocity(Vec2f(0, 1.0f));
    shape.getConsts().collidable = false;
    this.addCommandID("clientdeath");	
    this.addCommandID("message");
	
}

void onTick( CBlob@ this )
{
	if (this.getTickSinceCreated() < 1)
	{		
		this.getSprite().PlaySound("EnergySound1.ogg", 1.0f, 1.0f);	
		
		CSprite@ sprite = this.getSprite();
		sprite.getConsts().accurateLighting = false;
		sprite.SetRelativeZ(1001);
	}
    Vec2f pos = this.getPosition();
	
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
    return false;
}


void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{
    if(!isServer())//Don't run on client
    {
        return;
    }

    if(blob.hasTag("player") && !blob.hasTag("extra_damage") && blob.getConfig() != "knight")//Rip knights
    {
        this.SendCommand(this.getCommandID("clientdeath"));//kill serverside
        
        CPlayer@ player = blob.getPlayer();//get blobs player
        if(player != null)//if the player isn't null
        {
            this.server_SendCommandToPlayer(this.getCommandID("message"), player);//send the player a message
        }
        blob.Tag("extra_damage");
        blob.Sync("extra_damage", true);//Sync this tag to clients as well, true means "sync from the server", false would mean to "sync from client"
        this.server_Die();
    }
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if(!isClient())//Don't ever run on the server
    {
        return;
    }

    if(cmd == this.getCommandID("clientdeath") )//If this is the clientdeath command
    {
        ParticleAnimated( "Flash1.png",
                this.getPosition(),//pos
                Vec2f(0,0),//vecloity
                0.0f,//angle
                1.0f,//scale
                3,//animated speed
                0.0f, true );//gravity // selflit
        this.getSprite().PlaySound("snes_coin.ogg", 0.8f, 1.0f);
        
        if(this != null)//Confirm the server hasn't already killed it, if so.
        {
            this.SetVisible(false);//Make it go away for the client
        }
    }
    else if(cmd == this.getCommandID("message") )
    {
        client_AddToChat("Your offensive spells are more powerful for the remainder of this life.", SColor(255, 255, 0, 0));
    }
}