bool isTeleCancelInRange (CMap@ map, Vec2f pos, int teamNum)
{
	if (sv_gamemode == "CTF")
	{
		CBlob@[] blobsAtPos;
		map.getBlobsAtPosition(pos, @blobsAtPos);

		for (uint i = 0; i < blobsAtPos.length; i++)
		{
			CBlob@ b = blobsAtPos[i];
			if (b is null)
			{ continue; }

			if (b.getTeamNum() == teamNum)
			{ continue; }

			if (b.hasTag("TeleportCancel"))
			{ return true; }
		}
	}

	return false;
}