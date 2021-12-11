// Flag logic

#include "CTF_FlagCommon.as"
#include "CTF_Structs.as"

void onInit(CBlob@ this)
{

}

void onTick(CBlob@ this)
{
	CMap@ map = getMap(); //standard map check
	if (map is null)
	{return;}

	if ( getGameTime() % 30 == 0 ) //Barrier spawn code
	{
		bool owningBarrier = false;
		u16 FlagNetID = this.getNetworkID();

		CBlob@[] blobsByName;
		getBlobsByName("flag_barrier", @blobsByName);

		if (blobsByName.length > 0)
		{
			for (uint i = 0; i < blobsByName.length; i++)
			{
				CBlob@ b = blobsByName[i];
				if (b is null)
				{ continue; }

				if (b.get_u16("ownerNetID") == FlagNetID)
				{
					owningBarrier = true;
					break;
				}
			}
		}

		if (!owningBarrier)
		{
			CBlob@ barrier = server_CreateBlob( "flag_barrier" ); //creates "supershield"
			if (barrier !is null)
			{
				barrier.set_u16("ownerNetID", FlagNetID); //<<important
				barrier.server_setTeamNum( this.getTeamNum() );
				barrier.setPosition( Vec2f_zero );
				barrier.setAngleDegrees(0);
			}
		}
	}


}