// thanks to Chrispin
#define CLIENT_ONLY
#include "HoverMessageWW.as";
int oldPlatinum = 0;

void onTick( CRules@ this )
{
	CPlayer@ player = getLocalPlayer();
	
	if ( player is null || !player.isMyPlayer() ) return;
	
	string userName = player.getUsername();
	u16 currentPlatinum = this.get_u32("platinum"+userName);
	
	int diff = currentPlatinum - oldPlatinum;
	oldPlatinum = currentPlatinum;

	if ( diff > 0 )
		platinumIncrease( player, diff );//set message
	else if ( diff < 0 )
		platinumDecrease( player, diff );//set message
	
    HoverMessageWW[]@ messages;
    if (player.get("messages",@messages))
	{
        for (uint i = 0; i < messages.length; i++)
		{
            HoverMessageWW @message = messages[i];
            message.draw( Vec2f( 64 , 140) );

            if (message.isExpired()) 
			{
                messages.removeAt(i);
            }
        }
    }
}

void onRender( CRules@ this )
{
	CPlayer@ player = getLocalPlayer();
	if ( player is null )
		return;

	HoverMessageWW[]@ messages;	
	if (player.get("messages",@messages))
	{
		for (uint i = 0; i < messages.length; i++)
		{
			HoverMessageWW @message = messages[i];
			message.draw( Vec2f( 64 , 140) + Vec2f( 1, 0)*message.ticksSinceCreated() );
			
			if (message.isExpired()) 
			{
                messages.removeAt(i);
            }
		}
	}
}

void platinumIncrease(CPlayer@ this, int ammount )
{
	if (this.isMyPlayer())
	{
		if (!this.exists("messages")) 
		{
			HoverMessageWW[] messages;
			this.set( "messages", messages);
		}

		//this.clear( "messages" );
		HoverMessageWW m( "", ammount, SColor(255,0,255,0), 150, 2, false, "+" );
		this.push("messages",m);
		
		Sound::Play("Money1.ogg");
		if ( ammount > 10 )
			Sound::Play("Money2.ogg");
	}
}

void platinumDecrease(CPlayer@ this, int ammount )
{
	if (this.isMyPlayer())
	{
		if (!this.exists("messages")) 
		{
			HoverMessageWW[] messages;
			this.set( "messages", messages);
		}

		//this.clear( "messages" );
		HoverMessageWW m( "", ammount, SColor(255,255,0,0), 150, 2 );
		this.push("messages",m);
	}
}