#include "PlayerPrefsCommon.as";

void onInit( CRules@ this )
{
	this.addCommandID("swap classes");
}

void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
	if (this.getCommandID("swap classes") == cmd)
	{
		u16 playerID = params.read_u16();
		string classConfig = params.read_string();
		
		CPlayer@ player = getPlayerByNetworkId(playerID);
		if ( player is null )
			return;
			
		PlayerPrefsInfo@ playerPrefsInfo;
		if (!player.get( "playerPrefsInfo", @playerPrefsInfo ))
		{
			return;
		}
		
		playerPrefsInfo.classConfig = classConfig;
		
		if ( player.isMyPlayer() )
			client_AddToChat("You will now be a " + classConfig + " the next time you respawn or get revived.", SColor(255,0,200,200));
	}
}