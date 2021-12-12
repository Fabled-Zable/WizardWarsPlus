#include "EntropistCommon.as"

void onTick( CBlob@ this )
{
	if(!this.get_bool("burnState"))
	{
		return;
	}

	ManaInfo@ manaInfo;
	if (!this.get( "manaInfo", @manaInfo )) 
	{
		return;
	}
	
	manaInfo.mana -= 1;
	
	if(manaInfo.mana < 1)
	{
		s32 OG_manaRegen = this.get_s32("OG_manaRegen");

		if(OG_manaRegen > 0)
		{
			this.set_s32("OG_manaRegen",OG_manaRegen - 1);
		}

		this.set_bool("burnState", false);
	}
}

void onInit( CSprite@ this )
{
	this.SetEmitSound("burnSpellSound.ogg");
	this.SetEmitSoundPaused(true);
}

void onTick( CSprite@ this )
{
	CBlob@ b = this.getBlob();
	if(b is null)
	{
		return;
	}

	if(!b.exists("burnSpriteSetupDone") || !b.get_bool("burnSpriteSetupDone"))
	{
		CSpriteLayer@ layerFront = this.addSpriteLayer("fireFront","frontBurn2.png",25,25,b.getTeamNum(),0);
        layerFront.SetRelativeZ(1.0f);
		CSpriteLayer@ layerBack = this.addSpriteLayer("fireBack","backBurn2.png",25,25,b.getTeamNum(),0);
        layerBack.SetRelativeZ(-1.0f);
		b.set_bool("burnSpriteSetupDone",true);
	}

	CSpriteLayer@ layerFront = this.getSpriteLayer("fireFront");
	CSpriteLayer@ layerBack = this.getSpriteLayer("fireBack");
	Vec2f thisPos = b.getPosition();

	if(b.get_bool("burnState"))
	{
		if(!layerFront.isVisible() || !layerBack.isVisible())
		{
			layerFront.SetVisible(true);
			layerBack.SetVisible(true);
			this.SetEmitSoundPaused(false);
			this.PlaySound("burnIgnition.ogg", 3.0f);
			for(int i = 0; i < 5; i ++)
			{
				float randomPos = XORRandom(8);
				Vec2f particlePos = Vec2f( randomPos ,0).RotateByDegrees(XORRandom(360));
				particlePos += thisPos;
				
				ParticleAnimated( "Flash1.png",
                particlePos,//pos
                Vec2f(0,0),//vecloity
                90.0f,//angle
                1.5f,//scale
                5,//animated speed
                0.0f, true );//gravity // selflit
			}
		}
    	
		u8 frame = getGameTime() % 10;
		layerFront.SetFrame(frame);
    	layerBack.SetFrame(frame);

		for(int i = 0; i < 4; i ++)
		{
			float randomPos2 = XORRandom(8);
			Vec2f particlePos2 = Vec2f( randomPos2 ,0).RotateByDegrees(XORRandom(360));
			particlePos2 += thisPos;

    		CParticle@ p = ParticlePixelUnlimited(particlePos2, Vec2f_zero, SColor(255,255,255,0), true);
   			if(p !is null)
		 	{
    		    p.collides = true;
				p.bounce = 0;
    		    p.gravity = Vec2f(0,-2.0f);
    		    p.lighting = true;
    		    p.timeout = XORRandom(6)+6;
    		}
		}
	}
	else
	{
		if(layerFront.isVisible() || layerBack.isVisible())
		{
			layerFront.SetVisible(false);
			layerBack.SetVisible(false);
			this.SetEmitSoundPaused(true);
		}
	}
	
	//this.SetEmitSoundVolume(float volume);
	//getEmitSoundVolume()
}