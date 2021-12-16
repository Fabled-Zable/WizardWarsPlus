// brain

#include "/Entities/Common/Emotes/EmotesCommon.as"

namespace Strategy
{
	enum strategy_type
	{
		idle = 0,
		chasing,
		attacking,
		retreating
	}
}

void InitBrain(CBrain@ this)
{
	CBlob @blob = this.getBlob();
	blob.set_Vec2f("last pathing pos", Vec2f_zero);
	blob.set_u8("strategy", Strategy::idle);
	this.getCurrentScript().removeIfTag = "dead";   //won't be removed if not bot cause it isnt run
}

CBlob@ getNewTarget(CBrain@ this, CBlob @blob, const bool seeThroughWalls = false, const bool seeBehindBack = false)
{
	CBlob@[] players;
	getBlobsByTag("player", @players);
	Vec2f thisPos = blob.getPosition();
	for (uint i = 0; i < players.length; i++)
	{
		CBlob@ potential = players[i];
		Vec2f pos2 = potential.getPosition();

		if 
		(	blob.getTeamNum() != potential.getTeamNum()
		    && (pos2 - thisPos).getLength() < 2000.0f
		    && (seeBehindBack || Maths::Abs(thisPos.x - thisPos.x) < 40.0f || (blob.isFacingLeft() && thisPos.x > pos2.x) || (!blob.isFacingLeft() && thisPos.x < pos2.x))
		    && (seeThroughWalls || isVisible(blob, potential))
		    && !potential.hasTag("dead") && !potential.hasTag("migrant")
		)
		{
			blob.set_Vec2f("last pathing pos", potential.getPosition());
			return potential;
		}
	}
	return null;
}

void Repath(CBrain@ this)
{
	this.SetPathTo(this.getTarget().getPosition(), false);
}

bool isVisible(CBlob@blob, CBlob@ target)
{
	Vec2f col;
	return !getMap().rayCastSolid(blob.getPosition(), target.getPosition(), col);
}

bool isVisible(CBlob@ blob, CBlob@ target, f32 &out distance)
{
	Vec2f col;
	bool visible = !getMap().rayCastSolid(blob.getPosition(), target.getPosition(), col);
	distance = (blob.getPosition() - col).getLength();
	return visible;
}

bool JustGo(CBlob@ thisBlob, CBlob@ targetBlob)
{
	Vec2f thisPos = thisBlob.getPosition();
	Vec2f targetPos = targetBlob.getPosition();

	if (targetPos.x > 0 && targetPos.y > 0)
	{
		Vec2f targetVector = targetPos - thisPos;
		Vec2f targetNorm = targetVector;
		targetNorm.Normalize();

		Vec2f blobVel = thisBlob.getVelocity();
		thisBlob.setVelocity(blobVel + (targetNorm * 0.3f));

		return true;
	}

	return false;
}

bool FollowPath(CBlob@ thisBlob, CBrain@ brain, CBlob@ targetBlob)
{
	Vec2f thisPos = thisBlob.getPosition();
	Vec2f targetPos = targetBlob.getPosition();
	Vec2f pathPos = brain.getNextPathPosition();

	if (pathPos.x > 0 && pathPos.y > 0)
	{
		Vec2f pathVector = pathPos - thisPos;
		Vec2f pathNorm = pathVector;
		pathNorm.Normalize();

		Vec2f blobVel = thisBlob.getVelocity();
		thisBlob.setVelocity(blobVel + (pathNorm * 0.3f));

		return true;
	}

	return false;
}

void DefaultChaseBlob(CBlob@ blob, CBlob @target)
{
	CBrain@ brain = blob.getBrain();
	Vec2f targetPos = target.getPosition();
	Vec2f myPos = blob.getPosition();
	Vec2f targetVector = targetPos - myPos;
	f32 targetDistance = targetVector.Length();
	// check if we have a clear area to the target
	bool justGo = false;

	if (targetDistance < 120.0f)
	{
		Vec2f col;
		if (isVisible(blob, target))
		{
			justGo = true;
		}
	}

	// repath if no clear path after going at it
	if (XORRandom(10) == 0 && (blob.get_Vec2f("last pathing pos") - targetPos).getLength() > 20.0f)
	{
		print ("repathing");
		Repath(brain);
		blob.set_Vec2f("last pathing pos", targetPos);
	}

	const bool stuck = brain.getState() == CBrain::stuck;

	const CBrain::BrainState state = brain.getState();
	{
		if (state == CBrain::has_path)
		{
			//brain.SetSuggestedKeys();  // set walk keys here
			FollowPath(blob, brain, target);
		}
		else
		{
			JustGo(blob, target);
		}

		// printInt("state", this.getState() );
		switch (state)
		{
			case CBrain::idle:
				Repath(brain);
				break;

			case CBrain::searching:
				//if (sv_test)
				//	set_emote( blob, Emotes::dots );
				break;

			case CBrain::stuck:
				Repath(brain);
				break;

			case CBrain::wrong_path:
				Repath(brain);
				break;
		}
	}

	// face the enemy
	blob.setAimPos(target.getPosition());

}

void SearchTarget(CBrain@ this, const bool seeThroughWalls = false, const bool seeBehindBack = true)
{
	CBlob @blob = this.getBlob();
	CBlob @target = this.getTarget();

	// search target if none

	if (target is null)
	{
		CBlob@ oldTarget = target;
		@target = getNewTarget(this, blob, seeThroughWalls, seeBehindBack);
		this.SetTarget(target);

		if (target !is oldTarget)
		{
			onChangeTarget(blob, target, oldTarget);
		}
	}
}

void onChangeTarget(CBlob@ blob, CBlob@ target, CBlob@ oldTarget)
{
	// !!!
	if (oldTarget is null)
	{
		set_emote(blob, Emotes::attn, 1);
	}
}

bool LoseTarget(CBrain@ this, CBlob@ target)
{
	if (XORRandom(5) == 0 && target.hasTag("dead"))
	{
		@target = null;
		this.SetTarget(target);
		return true;
	}
	return false;
}

void Chase(CBlob@ blob, CBlob@ target)
{
	Vec2f mypos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	blob.setKeyPressed(key_left, false);
	blob.setKeyPressed(key_right, false);
	if (targetPos.x < mypos.x)
	{
		blob.setKeyPressed(key_left, true);
	}
	else
	{
		blob.setKeyPressed(key_right, true);
	}

	if (targetPos.y + getMap().tilesize < mypos.y)
	{
		blob.setKeyPressed(key_up, true);
	}
}

bool isFriendAheadOfMe(CBlob @blob, CBlob @target, const f32 spread = 50.0f)
{
	// optimization
	if ((getGameTime() + blob.getNetworkID()) % 10 > 0 && blob.exists("friend ahead of me"))
	{
		return blob.get_bool("friend ahead of me");
	}

	string thisBlobName = blob.getName();

	CBlob@[] sameNames;
	getBlobsByName(thisBlobName, @sameNames);
	Vec2f pos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	for (uint i = 0; i < sameNames.length; i++)
	{
		CBlob@ potential = sameNames[i];
		if (potential == null)
		{ continue; }

		f32 thisDistToTarget = blob.getDistanceTo(target);
		f32 friendDistToTarget = potential.getDistanceTo(target);

		if
		(	potential !is blob && blob.getTeamNum() == potential.getTeamNum()
		    && blob.getDistanceTo(potential) < spread
		    && friendDistToTarget < thisDistToTarget
		)
		{
			blob.set_bool("friend ahead of me", true);
			return true;
		}
	}
	blob.set_bool("friend ahead of me", false);
	return false;
}
