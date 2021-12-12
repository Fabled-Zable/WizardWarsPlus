#include "EntropistCommon.as"

void onInit( CBlob@ this )
{
	this.set_bool("negentropyStart",false);
	this.set_u16("ticks",0);
}

void onTick( CBlob@ this )
{
	if(!this.get_bool("negentropyStart"))
	{
		return;
	}

	u16 ticksCounter = this.get_u16("ticks");

	if(ticksCounter >= 60)
	{
		this.set_bool("negentropyStart", false);
		this.set_u16("ticks",0);

		return;
	}
	
	if(ticksCounter == 33)
	{
		s32 OG_manaRegen = this.get_s32("OG_manaRegen");
		this.set_s32("OG_manaRegen",OG_manaRegen + 1);
	}

	this.set_u16("ticks",ticksCounter + 1);
}

void onTick( CSprite@ this )
{
	CBlob@ b = this.getBlob();
	if(b is null)
	{
		return;
	}

	if(!b.exists("negentropySpriteSetupDone") || !b.get_bool("negentropySpriteSetupDone"))
	{
		CSpriteLayer@ negenStart = this.addSpriteLayer("negentropyStart","Shockwave3WIP.png",128,128,b.getTeamNum(),0);
        negenStart.SetRelativeZ(-1.0f);
		CSpriteLayer@ negenEnd = this.addSpriteLayer("negentropyEnd","Flash2.png",32,32,b.getTeamNum(),0);
        negenEnd.SetRelativeZ(1.0f);
		negenEnd.ScaleBy(1.2f, 1.2f);
		b.set_bool("negentropySpriteSetupDone",true);
	}

	u16 ticksCounter = b.get_u16("ticks");
	CSpriteLayer@ negenStart = this.getSpriteLayer("negentropyStart");
	CSpriteLayer@ negenEnd = this.getSpriteLayer("negentropyEnd");
	Vec2f thisPos = b.getPosition();

	if(b.get_bool("negentropyStart"))
	{
		if(!negenStart.isVisible() || !negenEnd.isVisible())
		{
			negenStart.SetVisible(true);
			negenEnd.SetVisible(true);

			negenStart.SetFrame(12);
			negenEnd.SetFrame(4);
			
			this.PlaySound("negentropySound.ogg", 3.0f);
		}

		if(ticksCounter < 33)
		{
			s16 frame = 14 - (ticksCounter / 2);
			if(frame < 0 || frame > 12)
			{
				frame = 12;
			}
			negenStart.SetFrame(frame);
		}
		else if(ticksCounter == 33)
		{
			for(int i = 0; i < 50; i ++)
			{
				Vec2f particleVel = Vec2f( XORRandom(8) ,0).RotateByDegrees(XORRandom(360));
				particleVel += thisPos;

				CParticle@ p = ParticlePixelUnlimited(thisPos, particleVel, SColor(255,0,0,0), true);
				if(p !is null)
		 		{
                	p.collides = true;
					p.bounce = 0;
					p.gravity = Vec2f_zero;
					p.lighting = true;
					p.timeout = XORRandom(6)+6;
				}
			}
		}
		else
		{
			u8 frame2 = (ticksCounter-33) / 3;
			if(frame2 > 4)
			{
				frame2 = 4;
			}
    		negenEnd.SetFrame(frame2);
		}
	}
	else
	{
		if(negenStart.isVisible() || negenEnd.isVisible())
		{
			negenStart.SetVisible(false);
			negenEnd.SetVisible(false);
		}
	}
}