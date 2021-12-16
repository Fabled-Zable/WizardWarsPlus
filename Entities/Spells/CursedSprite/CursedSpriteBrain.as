// Cursed Sprite brain

#define SERVER_ONLY

#include "SpellBrainCommon.as"

void onInit(CBrain@ this)
{
	InitBrain(this);
}

void onTick(CBrain@ this)
{
	SearchTarget(this, true, true);
	CBlob @blob = this.getBlob();
	CBlob @target = this.getTarget();

	// logic for target

	this.getCurrentScript().tickFrequency = 29;
	if (target !is null)
	{
		this.getCurrentScript().tickFrequency = 1;

		u8 strategy = blob.get_u8("strategy");

		f32 distance;
		const bool visibleTarget = isVisible(blob, target, distance);
		if (visibleTarget && distance < 40.0f)
		{
			strategy = Strategy::attacking;
		}

		if (strategy == Strategy::idle)
		{
			strategy = Strategy::chasing;
		}
		else if (strategy == Strategy::chasing)
		{
			
		}
		else if (strategy == Strategy::attacking)
		{
			if (!visibleTarget || distance > 60.0f)
			{
				strategy = Strategy::chasing;
			}
		}

		UpdateBlob(blob, target, strategy);

		// lose target if its killed (with random cooldown)

		if (LoseTarget(this, target))
		{
			strategy = Strategy::idle;
		}

		blob.set_u8("strategy", strategy);
	}
}

void UpdateBlob(CBlob@ blob, CBlob@ target, const u8 strategy)
{
	Vec2f targetPos = target.getPosition();
	Vec2f myPos = blob.getPosition();
	if (strategy == Strategy::chasing)
	{
		DefaultChaseBlob(blob, target);
	}
	else if (strategy == Strategy::attacking)
	{
		AttackBlob(blob, target);
	}
}


void AttackBlob(CBlob@ blob, CBlob @target)
{
	Vec2f mypos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	Vec2f targetVector = targetPos - mypos;
	f32 targetDistance = targetVector.Length();

	if (targetDistance > 30.0f)
	{ return; }

	Vec2f blobVel = blob.getVelocity();
	Vec2f targetNorm = targetVector;
	targetNorm.Normalize();
	
	if (targetDistance > 30.0f || !isFriendAheadOfMe(blob, target)) //if too far away or no friends in the way, rush in
	{
		blob.setVelocity(blobVel + (targetNorm * 1.0f));
	}
	else //otherwise, retreat
	{
		blob.setVelocity(blobVel - (targetNorm * 1.0f));
	}


	// aim always at enemy
	//blob.setAimPos(targetPos);

	//const u32 gametime = getGameTime();
	
}

