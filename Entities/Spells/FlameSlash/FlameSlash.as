//There is no cfg file associated with this because it isn't a blob :D
#include "Hitters.as"//we need this so we can use the enums which allows for more readable code
#include "SpellHashDecoder.as"

void onTick(CBlob@ this)
{
	if(!this.exists("setupDone") || !this.get_bool("setupDone"))//this is done instead of using onInit becuase onInit only runs once even if this script is removed and added again
	{
		this.set_u32("endTime",(1*30) + getGameTime());//1 second from now
		this.set_u32("timePassed", 0); //counter system
		this.getSprite().AddScript("FlameSlash.as");//need to do this to get the sprite hooks to run

		this.set_bool("setupDone",true);
	}

	if(this !is null)
	{
		if(this.hasTag("dead") ) //removes script if user dies
		{
			cleanUp(this);
			return;
		}
		if(this.get_u32("endTime") < getGameTime())
		{
			cleanUp(this);
			return;
		}

		uint32 time_passed = this.get_u32("timePassed");
		this.set_u32("timePassed",time_passed+1);

		if( time_passed == 6 )
		{
			float damage = 0.2f;
			if(this.hasTag("super_flame_slash"))
			{
				damage = 1.0f;
				this.Untag("super_flame_slash");
			}

			CMap@ map = getMap();
			if(map is null)
			{return;}
			HitInfo@[] hitsInRay;
			CBlob@[] blobsHit;

			Vec2f thisPos = this.getPosition();
			Vec2f blobAimPos = this.get_Vec2f("flame_slash_aimpos");
			Vec2f aimDir = blobAimPos-thisPos;
			float aimAngle = aimDir.getAngleDegrees();
			aimAngle *= -1;
			aimDir.Normalize();
			
			map.getHitInfosFromRay(thisPos, aimAngle-90, 10.0f, this, @hitsInRay);
			map.getHitInfosFromRay(thisPos, aimAngle+90, 10.0f, this, @hitsInRay);
			map.getHitInfosFromRay(thisPos, aimAngle-70, 15.0f, this, @hitsInRay);
			map.getHitInfosFromRay(thisPos, aimAngle+70, 15.0f, this, @hitsInRay);
			map.getHitInfosFromRay(thisPos, aimAngle-50, 20.0f, this, @hitsInRay);
			map.getHitInfosFromRay(thisPos, aimAngle+50, 20.0f, this, @hitsInRay);
			map.getHitInfosFromRay(thisPos, aimAngle-25, 35.0f, this, @hitsInRay);
			map.getHitInfosFromRay(thisPos, aimAngle+25, 35.0f, this, @hitsInRay);
			map.getHitInfosFromRay(thisPos, aimAngle-10, 65.0f, this, @hitsInRay);
			map.getHitInfosFromRay(thisPos, aimAngle+10, 65.0f, this, @hitsInRay);
			map.getHitInfosFromRay(thisPos, aimAngle, 70.0f, this, @hitsInRay);

			for (uint i = 0; i < hitsInRay.length; i++)
			{
				HitInfo@ hi = hitsInRay[i];
				CBlob@ b = hi.blob;
				if (b is null)
				{continue;}

				if(b.hasTag("flameSlashChecked"))
				{continue;}
				b.Tag("flameSlashChecked");
				blobsHit.push_back(b);

				if(this.getTeamNum() == b.getTeamNum())
				{continue;}
				
				b.server_Hit(b,this.getPosition(), Vec2f_zero , damage , Hitters::fire , false);
				b.AddForce(aimDir*800);
			}
			
			for (uint i = 0; i < blobsHit.length; i++)
			{
				CBlob@ b = blobsHit[i];
				if (b is null)
				{continue;}

				if(b.hasTag("flameSlashChecked"))
				{
					b.Untag("flameSlashChecked");
				}
			}

			if(isClient())
			{
				for (int i = 0; i < 60; i++) //woosh
   				{
					Vec2f pixelPos = Vec2f( XORRandom(50)-5,XORRandom(26)-13 );
					pixelPos.RotateByDegrees(aimAngle);
    		    	pixelPos += thisPos;

					Vec2f pixelVel = (aimDir*XORRandom(10));

    		   		CParticle@ p = ParticlePixel( pixelPos , pixelVel , SColor( 255, 255, 255, 0) , true , XORRandom(7)+3);
    		    	if(p !is null)
    		    	{
    		    	    p.fastcollision = true;
						p.lighting = true;
						p.timeout = XORRandom(60);
						p.damping = 0.95;
						p.gravity = Vec2f_zero;
    		    	}
    			}
			}
		}
		this.setVelocity(Vec2f_zero);
	}
}

void onTick(CSprite@ this)
{
	CBlob@ b = this.getBlob();
	
	if(!b.exists("slashSetupDone") || !b.get_bool("slashSetupDone"))
	{
		CSpriteLayer@ layer = this.addSpriteLayer("slash","fire_slash_effect.png",100,45);

		Vec2f thisPos = b.getPosition();
		Vec2f blobAimPos = b.get_Vec2f("flame_slash_aimpos");
		Vec2f aimDir = blobAimPos-thisPos;
		float aimAngle = aimDir.getAngleDegrees();

		Vec2f blobVel = b.getVelocity();
		
		Vec2f layerOffset = Vec2f(-25.0f,0);
		layerOffset.RotateByDegrees(aimAngle);
		layer.SetOffset(layerOffset);

		b.set_bool("slashSetupDone",true);
		layer.ScaleBy(Vec2f(1.05f,1.05f));
		layer.RotateBy(-aimAngle,Vec2f_zero);
		layer.SetFrame(0);
	}
	
	/*
	CSpriteLayer@ layer = this.getSpriteLayer("slash");
	layer.ResetTransform();
	{
		layer.SetFrame(layer.getFrame()+1);
	}
	layer.ScaleBy(Vec2f(1.01f,1.01f));
	*/

	if(!b.get_bool("slashSetupDone"))
	{
		return;
	}

	CSpriteLayer@ slashLayer = this.getSpriteLayer("slash");
	slashLayer.SetFacingLeft(false);

	uint16 currentFrame = slashLayer.getFrame();
	if(currentFrame != 13)
	{
		slashLayer.SetFrame(currentFrame+1);
	}
	else
	{
		cleanUp(b);
	}
}

void cleanUp(CBlob@ this)//because we don't use onInit we need to cleanup so that the script is ready for when it is added again
{
	if(this is null || this.getSprite() is null)
	{
		return;
	}

	if(this.getSprite().getSpriteLayer("slash") !is null)
	{
		this.getSprite().RemoveSpriteLayer("slash");
	}

	this.set_bool("setupDone",false);
	this.set_bool("slashSetupDone",false);
	this.getSprite().RemoveScript("FlameSlash.as");
	this.RemoveScript("FlameSlash.as");
}

bool tagCheck( CBlob@ target )
{
	return 
	(
		target.hasTag("barrier")
		||
		target.hasTag("flesh") 
		||
		target.hasTag("counterable") 
	);
}