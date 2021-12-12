// Flag logic

#include "CTF_FlagCommon.as"
#include "CTF_Structs.as"

Random _flag_defenses_r(94217); //with the seed, I extract a float ranging from 0 to 1 for random events

void onInit(CBlob@ this)
{

}

void onTick(CBlob@ this)
{
	CMap@ map = getMap(); //standard map check
	if (map is null)
	{return;}

	if ( isServer() && getGameTime() % 30 == 0 ) //Barrier spawn code
	{
		bool owningBarrier = false;
		bool owningAura = false;
		u16 FlagNetID = this.getNetworkID();

		CBlob@[] barriersByName;
		getBlobsByName("air_barrier", @barriersByName);

		if (barriersByName.length > 0)
		{
			for (uint i = 0; i < barriersByName.length; i++)
			{
				CBlob@ b = barriersByName[i];
				if (b is null)
				{ continue; }

				if (b.get_u16("ownerNetID") == FlagNetID)
				{
					owningBarrier = true;
					break;
				}
			}
		}

		CBlob@[] aurasByName;
		getBlobsByName("anti_teleport_aura", @aurasByName);

		if (aurasByName.length > 0)
		{
			for (uint i = 0; i < aurasByName.length; i++)
			{
				CBlob@ b = aurasByName[i];
				if (b is null)
				{ continue; }

				if (b.get_u16("ownerNetID") == FlagNetID)
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
				barrier.set_u16("ownerNetID", FlagNetID); //<<important
				barrier.server_setTeamNum( this.getTeamNum() );
				barrier.setPosition( Vec2f_zero );
				barrier.setAngleDegrees(0);
			}
		}

		if (!owningAura)
		{
			//print("Creating Aura");
			CBlob@ aura = server_CreateBlob( "anti_teleport_aura" ); 
			if (aura !is null)
			{
				aura.set_u16("ownerNetID", FlagNetID); //<<important
				aura.server_setTeamNum( -1 );
				aura.setPosition( Vec2f_zero );
				aura.setAngleDegrees(0);

				//aura.server_AttachTo(this, "DEFENSE");
			}
		}
	}


	if (!isClient())
	{ return; }

	Vec2f thisPos = this.getPosition();
	u16 particleNum = 40;

	for(int i = 0; i < particleNum; i++)
    {
		SColor color = randomFlagParticleColor(); //randomize alpha

		f32 randomDeviation = (i*0.3f) * _flag_defenses_r.NextFloat(); //random pixel deviation
		Vec2f prePos = Vec2f(66.0f - randomDeviation, 0);
		prePos.RotateByDegrees(360.0f * _flag_defenses_r.NextFloat()); //random 360 rotation

		Vec2f pPos = thisPos + prePos;
		Vec2f pGrav = (pPos - thisPos) * -0.01f;

        CParticle@ p = ParticlePixelUnlimited(pPos, Vec2f_zero, color, true);
        if(p !is null)
        {
            p.collides = false;
            p.gravity = pGrav;
            p.bounce = 0;
            p.Z = 7;
            p.timeout = 4;
        }
    }
}

SColor randomFlagParticleColor()
{
	u8 alpha = 40 + (170.0f * _flag_defenses_r.NextFloat());
    u8 red = 255;
    u8 green = 255;
    u8 blue = 255;
    return SColor( alpha , red , green , blue );
}