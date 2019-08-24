//Status Effects
#include "RunnerCommon.as"

void onTick( CBlob@ this)
{
	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars))
	{
		return;
	}

	//FREEZE
	bool isFrozen = this.get_bool("frozen");
	bool isInIce = this.isAttachedToPoint("PICKUP2");

	if ( isFrozen && !isInIce )
		this.set_bool("frozen", false);	
	else if ( isInIce )
	{
		this.set_bool("frozen", true);
	
		u16 takekeys;
		takekeys = key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3 | key_pickup;

		this.DisableKeys(takekeys);
		this.DisableMouse(true);
	}
	else
	{
		this.DisableKeys(0);
		this.DisableMouse(false);
	}
	
	//SLOW	
	u16 slowed = this.get_u16("slowed");

	if (slowed > 0)
	{
		slowed--;
		this.set_u16("slowed", slowed);
		
		Vec2f thisVel = this.getVelocity();
		this.setVelocity( Vec2f(thisVel.x*0.85f, thisVel.y) );
		

		//makeSmokeParticle(this, Vec2f(), "Smoke");
		if ( slowed % 2 == 0 )
		{
			for (int i = 0; i < 1; i++)
			{		
				if(getNet().isClient())
				{
					const f32 rad = 6.0f;
					Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
					CParticle@ p = ParticleAnimated( "MissileFire1.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.2f, false );
					if ( p !is null)
					{
						p.bounce = 0;
    					p.fastcollision = true;
						if ( XORRandom(2) == 0 )
							p.Z = 10.0f;
						else
							p.Z = -10.0f;
					}
				}
			}
		}
		
		if ( slowed == 1 )
		{
			this.getSprite().PlaySound("SlowOff.ogg", 0.8f, 1.0f + XORRandom(1)/10.0f);
			this.Sync("slowed", true);
		}
	}
	
	//HASTE
	u16 hastened = this.get_u16("hastened");

	if (hastened > 0)
	{
		hastened--;
		this.set_u16("hastened", hastened);
		
		Vec2f thisVel = this.getVelocity();
		moveVars.walkFactor *= 1.5f;
		moveVars.jumpFactor *= 1.1f;		

		//makeSmokeParticle(this, Vec2f(), "Smoke");
		if ( hastened % 2 == 0 )
		{
			for (int i = 0; i < 1; i++)
			{		
				if(getNet().isClient()) 
				{
					const f32 rad = 6.0f;
					Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
					CParticle@ p = ParticleAnimated( "MissileFire4.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.2f, false );
					if ( p !is null)
					{
						p.bounce = 0;
    					p.fastcollision = true;
						if ( XORRandom(2) == 0 )
							p.Z = 10.0f;
						else
							p.Z = -10.0f;
					}
				}
			}
		}
		
		if ( hastened == 1 )
		{
			this.getSprite().PlaySound("HasteOff.ogg", 0.8f, 1.0f + XORRandom(1)/10.0f);
			this.Sync("hastened", true);
		}
	}
}
