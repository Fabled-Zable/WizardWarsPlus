#include "SmallshipCommon.as"

void onInit( CBlob@ this )
{
    this.addCommandID( shot_command_ID );
	this.addCommandID( hit_command_ID );
	this.addCommandID( "pulsed" );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID(shot_command_ID)) // 1 shot instance
    {
		if (!isServer())
		{ return; }
		
		u16 ownerID;
		if (!params.saferead_u16(ownerID)) return;

		u8 shotType;
		if (!params.saferead_u8(shotType)) return;

		Vec2f blobPos;
		Vec2f blobVel;
		if (!params.saferead_Vec2f(blobPos)) return;
		if (!params.saferead_Vec2f(blobVel)) return;

		CBlob@ ownerBlob = getBlobByNetworkID(ownerID);
		if (ownerBlob == null || ownerBlob.hasTag("dead"))
		{ return; }
		
		if (blobPos == Vec2f_zero || blobVel == Vec2f_zero)
		{ return; }

		string blobName = "orb";
		switch (shotType)
		{
			case 0:
			{
				blobName = "orb";
			}
			break;

			case 1:
			{
				blobName = "gatling_basicshot";
			}
			break;

			case 2:
			{
				blobName = "bee";
			}
			break;
			default: return;
		}

		CBlob@ blob = server_CreateBlob( blobName , ownerBlob.getTeamNum(), blobPos);
		if (blob !is null)
		{
			blob.IgnoreCollisionWhileOverlapped( ownerBlob );
			blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
			blob.setVelocity( blobVel );
		}
	}
	else if (cmd == this.getCommandID(hit_command_ID)) // if a shot hits, this gets sent
    {
		
	}
}