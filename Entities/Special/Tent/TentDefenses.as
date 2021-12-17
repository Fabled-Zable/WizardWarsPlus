// Flag logic

#include "CTF_FlagCommon.as"
#include "CTF_Structs.as"
#include "TeamColour.as";

Random _tent_defenses_r(94712); //with the seed, I extract a float ranging from 0 to 1 for random events
const string tent_player_push_ID = "tent_player_push";

void onInit(CBlob@ this)
{
	this.addCommandID(tent_player_push_ID);
	this.Tag("TeleportCancel");
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap(); //standard map check
	if (map is null)
	{return;}

	int teamNum = this.getTeamNum();

	if ( isServer() && getGameTime() % 30 == 0 ) //Barrier spawn code
	{
		bool owningBarrier = false;
		bool owningAura = false;
		u16 ThisNetID = this.getNetworkID();

		CBlob@[] barriersByName;
		getBlobsByName("air_barrier", @barriersByName);

		if (barriersByName.length > 0)
		{
			for (uint i = 0; i < barriersByName.length; i++)
			{
				CBlob@ b = barriersByName[i];
				if (b is null)
				{ continue; }

				if (b.get_u16("ownerNetID") == ThisNetID)
				{
					owningBarrier = true;
					break;
				}
			}
		}

		CBlob@[] aurasByName;
		getBlobsByName("anti_teleport_aura_large", @aurasByName);

		if (aurasByName.length > 0)
		{
			for (uint i = 0; i < aurasByName.length; i++)
			{
				CBlob@ b = aurasByName[i];
				if (b is null)
				{ continue; }

				if (b.get_u16("ownerNetID") == ThisNetID)
				{
					owningAura = true;
					break;
				}
			}
		}

		/*AttachmentPoint@[] attachmentPoints;
		this.getAttachmentPoints(attachmentPoints);

		if (attachmentPoints.length > 0)
		{
			for (uint i = 0; i < attachmentPoints.length; i++)
			{
				AttachmentPoint@ thisPoint = attachmentPoints[i];
				if (thisPoint is null)
				{ continue; }

				if (thisPoint.name != "DEFENSE")
				{ continue; }

				CBlob@ attachedBlob = thisPoint.getBlob();

				if (attachedBlob != null)
				{
					print(attachedBlob.getName() + " is attached to Flag.");
					owningAura = true;
					break;
				}
			}
		}*/

		if (!owningBarrier)
		{
			//print("Creating Barrier");
			CBlob@ barrier = server_CreateBlob( "air_barrier" ); //creates "supershield"
			if (barrier !is null)
			{
				barrier.set_u16("ownerNetID", ThisNetID); //<<important
				barrier.server_setTeamNum( teamNum );
				barrier.setPosition( Vec2f_zero );
				barrier.setAngleDegrees(0);
			}
		}

		if (!owningAura)
		{
			//print("Creating Aura");
			CBlob@ aura = server_CreateBlob( "anti_teleport_aura_large" ); 
			if (aura !is null)
			{
				aura.set_u16("ownerNetID", ThisNetID); //<<important
				aura.server_setTeamNum( teamNum );
				aura.setPosition( Vec2f_zero );
				aura.setAngleDegrees(0);

				//aura.server_AttachTo(this, "DEFENSE");
			}
		}
	}

	Vec2f thisPos = this.getPosition();
	u32 gameTime = getGameTime();
	CBitStream params;

	CBlob@[] enemiesInRadius;
	map.getBlobsInRadius(thisPos, 100.0f, @enemiesInRadius); //tent aura push
	for (uint i = 0; i < enemiesInRadius.length; i++)
	{
		CBlob@ b = enemiesInRadius[i];
		if (b is null)
		{ continue; }

		if (b.getTeamNum() == teamNum)
		{ continue; }

		if (!b.hasTag("hull") && !b.hasTag("flesh") && !b.hasTag("counterable"))
		{ continue; }

		bool isZombie = b.hasTag("zombie");

		Vec2f blobPos = b.getPosition();
		Vec2f kickDir = blobPos - thisPos;
		kickDir.Normalize();
		Vec2f kickVel = kickDir * 50.0f; //push force

		CPlayer@ targetPlayer = b.getPlayer();
		if (targetPlayer == null)
		{
			b.AddForce(kickVel);
		}
		else
		{
			if (isServer())
			{
				params.write_Vec2f(kickVel);
				params.write_u16(b.getNetworkID());
				this.server_SendCommandToPlayer(this.getCommandID(tent_player_push_ID), params, targetPlayer);
			}
		}

		if (!isClient()) // push ray particles
		{ continue; }

		Vec2f rayVec = blobPos - thisPos;
		int steps = rayVec.getLength();

		Vec2f rayNorm = rayVec;
		rayNorm.Normalize();

		Vec2f rayDeviation = rayNorm;
		rayDeviation.RotateByDegrees(90);
		rayDeviation *= 4.0f; //perpendicular particle deviation

		SColor color = getTeamColor(teamNum);

		for(int i = 0; i < steps; i++)
   		{
			f32 chance = _tent_defenses_r.NextFloat(); //chance to not spawn particle
			if (chance > 0.3f)
			{ continue; }

			f32 waveTravel = i - gameTime; //forward and backwards wave travel
			f32 sinInput = waveTravel * 0.2f;
			f32 stepDeviation = Maths::Sin(sinInput); //particle deviation multiplier

			if (i < 8)
			{
				f32 deviationReduction = float(i) / 8.0f;
				stepDeviation *= deviationReduction;
			}
			if (i > (steps - 8))
			{
				f32 deviationReduction = -1.0f * ((float(i) - float(steps)) / 8.0f);
				stepDeviation *= deviationReduction;
			}

			Vec2f finalRayDeviation = rayDeviation * stepDeviation;

			Vec2f pPos = (rayNorm * i) + finalRayDeviation;
			pPos += thisPos;

 	    	CParticle@ p = ParticlePixelUnlimited(pPos, Vec2f_zero, color, true);
 	    	if(p !is null)
  	    	{
				p.collides = false;
				p.gravity = Vec2f_zero;
				p.bounce = 0;
				p.Z = 8;
				p.timeout = 3;
			}

			if (isZombie)
			{ i++; }
		}
		// push ray particles end
		
	} //for loop end

	if (!isClient())
	{ return; }

	u16 particleNum = 50;

	SColor color = getTeamColor(teamNum);

	for(int i = 0; i < particleNum; i++)
    {
		u8 alpha = 40 + (170.0f * _tent_defenses_r.NextFloat()); //randomize alpha
		color.setAlpha(alpha);

		f32 randomDeviation = (i*0.3f) * _tent_defenses_r.NextFloat(); //random pixel deviation
		Vec2f prePos = Vec2f(102.0f - randomDeviation, 0); //distance
		prePos.RotateByDegrees(360.0f * _tent_defenses_r.NextFloat()); //random 360 rotation

		Vec2f pPos = thisPos + prePos;
		Vec2f pGrav = -prePos * 0.005f; //particle gravity

		prePos.Normalize();
		prePos *= 2.0f;

        CParticle@ p = ParticlePixelUnlimited(pPos, prePos, color, true);
        if(p !is null)
        {
            p.collides = false;
            p.gravity = pGrav;
            p.bounce = 0;
            p.Z = 7;
            p.timeout = 12;
			p.setRenderStyle(RenderStyle::light);
        }
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
    if(this.getCommandID(tent_player_push_ID) == cmd)
    {
		if (!isClient())
		{ return; }

		Vec2f kickVel = params.read_Vec2f();
		CBlob@ targetBlob = getBlobByNetworkID(params.read_u16());

		if (targetBlob != null)
		{
			targetBlob.AddForce(kickVel);
		}
    }
}