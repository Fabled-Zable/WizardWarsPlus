const string knocked_tag = "knockable";

//make sure to use this in onInit if needed

void setKnockable( CBlob@ this )
{
	this.set_u8("knocked", 0);
	this.Tag(knocked_tag);
	this.set_u32("last smoke puff", 0 );
}

u8 Knocked( CBlob@ this )
{
	if(this.hasTag("invincible"))
	{
        this.DisableKeys(0);
        this.DisableMouse(false);
		return 0;
	}
	
    u8 knocked = this.get_u8("knocked");

    if (knocked > 0)
    {
        knocked--;
        this.set_u8("knocked", knocked);
		u16 takekeys;
		if (knocked < 2 || (this.hasTag("dazzled") && knocked < 30)) 
		{ 
			takekeys = key_action1 | key_action2 | key_action3;

			if (this.isOnGround())	{
				this.AddForce( this.getVelocity() * -10.0f );
			}
		}
		else {
			takekeys = key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3;
		}

        this.DisableKeys( takekeys);
        this.DisableMouse(true);

		if (knocked == 0)
		{
			this.Untag("dazzled");
		}
		
		this.getShape().getConsts().collidable = false;
		if (this.getVelocity().getLength() > 1)
		{
			const u32 gametime = getGameTime();
			u32 lastSmokeTime = this.get_u32("last smoke puff");
			int ticksTillSmoke = 1;
			int diff = gametime - (lastSmokeTime + ticksTillSmoke);
			if (diff > 0)
			{
				ParticleAnimated( "WhitePuff2.png",
								this.getPosition(),
								Vec2f(0, 0),
								1.0f, 0.5f + this.getVelocity().getLength()*0.1f, 
								2, 
								0.0f, true );
		
				lastSmokeTime = gametime;
				this.set_u32("last smoke puff", lastSmokeTime);
			}			
		}
		
		const f32 bounceFactor = 1.0f;
		if (this.isOnGround())
		{
			this.AddForce( Vec2f(0, -Maths::Abs(this.getOldVelocity().y) - 200)*bounceFactor );
			
			if (this.getOldVelocity().y > 5)
			{
				XORRandom(2) == 1 ? Sound::Play( "Whack2.ogg", this.getPosition() ) :
				Sound::Play( "Whack3.ogg", this.getPosition() ); 
				ParticleAnimated( "WhitePuff.png",
								this.getPosition(),
								Vec2f(0, 0),
								1.0f, 1.0f, 
								2, 
								0.0f, true );
			}
		}
		if (this.isOnCeiling())
		{
			this.AddForce( Vec2f(0, Maths::Abs(this.getOldVelocity().y) + 200)*bounceFactor );
			
			if (this.getOldVelocity().y < 5)
			{
				XORRandom(2) == 1 ? Sound::Play( "Whack2.ogg", this.getPosition() ) :
				Sound::Play( "Whack3.ogg", this.getPosition() ); 
				ParticleAnimated( "WhitePuff.png",
								this.getPosition(),
								Vec2f(0, 0),
								1.0f, 1.0f, 
								2, 
								0.0f, true );
			}
		}
		
		//check solid tiles
		CMap@ map = getMap();
		Vec2f pos = this.getPosition();
		const f32 ts = map.tilesize;
		const f32 y_ts = ts * 0.2f;
		const f32 x_ts = ts * 1.4f;
		
		bool surface_left = map.isTileSolid(pos + Vec2f(-x_ts, y_ts-map.tilesize)) || map.isTileSolid(pos + Vec2f(-x_ts, y_ts));
		//TODO: fix flags sync and hitting so we dont have to do this
		if(!surface_left)
		{
			surface_left = checkForSolidMapBlob( map, pos + Vec2f(-x_ts, y_ts-map.tilesize)) ||
							checkForSolidMapBlob( map, pos + Vec2f(-x_ts, y_ts));
		}
		
		bool surface_right = map.isTileSolid(pos + Vec2f(x_ts, y_ts-map.tilesize)) || map.isTileSolid(pos + Vec2f(x_ts, y_ts));
		//TODO: fix flags sync and hitting so we dont have to do this
		if(!surface_right)
		{
			surface_right = checkForSolidMapBlob( map, pos + Vec2f(x_ts, y_ts-map.tilesize)) ||
							checkForSolidMapBlob( map, pos + Vec2f(x_ts, y_ts));
		}
		
		if (this.isOnWall() && surface_left)
		{
			this.AddForce( Vec2f( Maths::Abs(this.getOldVelocity().x) + 200, 0 )*2.0f*bounceFactor );
		
			if (this.getOldVelocity().getLength() > 5)
				{
					XORRandom(2) == 1 ? Sound::Play( "Whack2.ogg", this.getPosition() ) :
					Sound::Play( "Whack3.ogg", this.getPosition() ); 
					ParticleAnimated( "WhitePuff.png",
								this.getPosition(),
								Vec2f(0, 0),
								1.0f, 1.0f, 
								2, 
								0.0f, true );
				}
		}
		if (this.isOnWall() && surface_right)
		{
			this.AddForce( Vec2f( -Maths::Abs(this.getOldVelocity().x) - 200, 0 )*2.0f*bounceFactor );
		
			if (this.getOldVelocity().getLength() > 5)
				{
					XORRandom(2) == 1 ? Sound::Play( "Whack2.ogg", this.getPosition() ) :
					Sound::Play( "Whack3.ogg", this.getPosition() ); 
					ParticleAnimated( "WhitePuff.png",
								this.getPosition(),
								Vec2f(0, 0),
								1.0f, 1.0f, 
								2, 
								0.0f, true );
				}
		}
    }
    else
    {
        this.DisableKeys(0);
        this.DisableMouse(false);
		this.set_u32("last smoke puff", 0 );
		this.getShape().getConsts().collidable = true;
    }
	return knocked;
}

bool isKnockable( CBlob@ blob )
{
	return blob.hasTag(knocked_tag);
}

void setKnocked( CBlob@ blob, int ticks, bool sync = false )
{
	if(blob.hasTag("invincible") && ticks != 0)
		return; //do nothing
	
    blob.set_u8("knocked", Maths::Max( blob.get_u8("knocked"), ticks));
	if (sync)
	{			
		blob.Sync("knocked", true );
	}
}

bool checkForSolidMapBlob( CMap@ map, Vec2f pos)
{
	CBlob@ _tempBlob; CShape@ _tempShape;
	@_tempBlob = map.getBlobAtPosition( pos );
	if(_tempBlob !is null && _tempBlob.isCollidable())
	{
		@_tempShape = _tempBlob.getShape();
		if(_tempShape.isStatic())
		{
			return true;
		}
	}
	
	return false;
}
