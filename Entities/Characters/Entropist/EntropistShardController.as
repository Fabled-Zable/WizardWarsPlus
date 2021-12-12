#include "EntropistCommon.as"

void onInit( CBlob@ this )
{
	this.set_u8("shard_amount",0);
	this.set_u16("shiftTimer", 0);
	this.set_f32("oldAngle", 0.0f);
	this.set_bool("attack", true);

	CBlob@[] entropistAmount;
	getBlobsByName("entropist", @entropistAmount);
	string thisNameTag = "entroNum" + entropistAmount.length;
	string shardOwnerTag = thisNameTag+"Shard";
	this.Tag(thisNameTag);

	this.set_string("casterBlobTag", thisNameTag);
	this.set_string("casterShardTag", shardOwnerTag);
}

void onTick( CBlob@ this )
{
	u8 shardAmount = this.get_u8("shard_amount"); //get shards
	if(shardAmount == 0) //if none, do nothing
	{return;}

	if(this.hasTag("dead"))
	{
		this.getCurrentScript().tickFrequency = 0;
	}

	bool burnState = this.get_bool("burnState");

	string casterBlobTag = this.get_string("casterBlobTag");
	string casterShardTag = this.get_string("casterShardTag");
	
	Vec2f thisPos = this.getPosition();
	Vec2f aimPos = this.getAimPos();

	float spinMult = burnState ? 12 : 2;
	float anglePerShard = 360/shardAmount;
	float shardWheelRot = (getGameTime()*spinMult) % 360;
	float radius = 18.0f;

	u16 shiftTimer = this.get_u16("shiftTimer");

	if(this.get_bool("shifting"))
	{
		if(shiftTimer < 30)
		{
			this.set_u16("shiftTimer", shiftTimer+1);
		}
	}
	else
	{
		if(shiftTimer > 0)
		{
			this.set_u16("shiftTimer", shiftTimer-1);
		}
	}

	if(radius > 6.0f)
	{
		radius -= (0.4*shiftTimer);
	}

	Vec2f aimVec = aimPos - thisPos;
	float aimAngle = aimVec.getAngleDegrees();
	float oldAngle = this.get_f32("oldAngle");

	float angleDiff = oldAngle - aimAngle;
	angleDiff = (angleDiff + 540) % 360 - 180;

	float aimSpeed = burnState ? 4.0f : 1.0f;
	if(shiftTimer == 0)
	{
		oldAngle = aimAngle;
	}
	else if( angleDiff > aimSpeed )
	{
		oldAngle -= aimSpeed; 
	}
	else if( angleDiff < -aimSpeed )
	{
		oldAngle += aimSpeed;
	}
	else
	{
		oldAngle -= angleDiff;
	}

	this.set_f32("oldAngle", oldAngle);

	Vec2f deviation = Vec2f(2*shiftTimer,0);
	deviation.RotateBy(-oldAngle);

	Vec2f shardPos = thisPos + Vec2f(radius,0);

	CBlob@[] casterShards;
	getBlobsByTag(casterShardTag, @casterShards);

	for (int i = 0; i < shardAmount; i++)
	{
		Vec2f shardMovePos = shardPos;
		shardMovePos.RotateBy(shardWheelRot + anglePerShard*i, thisPos);
		shardMovePos += deviation;

		if(casterShards.length <= i)
		{
			CBlob@ orb = server_CreateBlob( "shard" );
			if (orb !is null)
			{
				orb.server_SetTimeToDie(60);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( shardMovePos );
				orb.setVelocity( Vec2f_zero );
				orb.Tag(casterShardTag);
				orb.set_netid("owner",this.getNetworkID());
				orb.set_s8("shardID",(i+1) );
			}
			break;
		}

		CBlob@ b = casterShards[i];
		if(b is null)
		{
			CBlob@ orb = server_CreateBlob( "shard" );
			if (orb !is null)
			{
				orb.server_SetTimeToDie(60);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( shardMovePos );
				orb.setVelocity( Vec2f_zero );
				orb.Tag(casterShardTag);
				orb.set_netid("owner",this.getNetworkID());
				orb.set_s8("shardID",(i+1) );
			}
		}
		else
		{
			b.setPosition( shardMovePos );
			b.setVelocity( Vec2f_zero );

			if(isClient())
			{
				CSprite@ bSprite = b.getSprite();
				if(bSprite is null)
				{continue;}
				Vec2f shardDir = shardMovePos - thisPos;
				float spriteAngle = shardDir.getAngleDegrees();
				bSprite.ResetTransform();
				float polarityAngle = this.get_bool("attack") ? 90.0f : -90.0f;
				bSprite.RotateBy((-spriteAngle)+polarityAngle, Vec2f_zero);
			}
		}
	}
}