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

	//SIDEWIND
	u16 sidewinding = this.get_u16("sidewinding");

	if (sidewinding > 0)
	{
		sidewinding--;
		this.getSprite().SetVisible(false);
		this.getShape().getConsts().collidable = false;
		
		Vec2f thisVel = this.getVelocity();
		moveVars.walkFactor *= 2.5f;
		moveVars.jumpFactor *= 2.5f;		

		//makeSmokeParticle(this, Vec2f(), "Smoke");
		if ( sidewinding % 2 == 0 )
		{
			if(isClient()) 
			{
				u16 frame = this.getSprite().getFrameIndex();
				bool lookingLeft = this.getSprite().isFacingLeft();

				Vec2f pos = this.getPosition() + Vec2f(3,-2);
				string afterimageFile = "afterimages.png";
				if (lookingLeft)
				{
					afterimageFile = "afterimagesleft.png";
					pos -= Vec2f(6,0);
				}
				CParticle@ p = ParticleAnimated(afterimageFile, pos, Vec2f_zero, 0, 1.0f, 5, 0.0f, false);
				if ( p !is null)
				{
					p.bounce = 0;
					p.Z = -10.0f;
					p.collides = false;
					p.fastcollision = true;
					p.setRenderStyle(RenderStyle::additive);
				}
			}
		}
		
		if ( sidewinding == 0 )
		{
			if(isClient())
			{this.getSprite().PlaySound("sidewind_exit.ogg", 3.0f, 1.0f + XORRandom(1)/10.0f);}
			this.Sync("sidewinding", true);
			this.getSprite().SetVisible(true);
			this.getShape().getConsts().collidable = true;

			SColor color = SColor(255,255,0,XORRandom(191));
			for(int i = 0; i < 100; i ++)
			{
				Vec2f particleVel = Vec2f( 1.5f ,0).RotateByDegrees(XORRandom(361));
				CParticle@ p = ParticlePixel( this.getPosition() , particleVel , color , false , XORRandom(11) + 5 );
				if(p !is null)
				{
					p.gravity = Vec2f_zero;
					p.damping = 1.0;
					p.collides = false;
					p.fastcollision = true;
					p.bounce = 0;
					p.lighting = false;
				}
			}
		}
		this.set_u16("sidewinding", sidewinding);
	}
}
