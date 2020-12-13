
#include "Hitters2.as";
#include "TeamColour.as";
#include "MakeDustParticle.as";

const float STANDARD_SPEED = 32.0f;

void onInit( CBlob@ this )
{
    this.set_u8("custom_hitter", Hitters2::orb);
	this.Tag("exploding");
	
	CSprite@ thisSprite = this.getSprite();
	thisSprite.AddScript("Nova.as");
	thisSprite.SetZ(500.0f);
	thisSprite.ScaleBy(0.2f, 0.2f);
	
	this.Tag("counterable");
	
	this.set_f32("explosive_radius", 60.0f );
	this.set_f32("explosive_damage", 3.0f);
	this.set_f32("map_damage_radius", 30.0f);
	this.set_f32("map_damage_ratio", -1.0f); //heck no!
	this.set_u32("last smoke puff", 0 );

	this.addCommandID("aimpos sync");
}	

void onTick( CBlob@ this )
{     
	if(!this.exists("initialized"))
	{
		this.getShape().SetGravityScale( 0.0f );
		this.server_SetTimeToDie(5);
		this.SetLight( true );
		this.SetLightRadius( 32.0f );
		this.SetLightColor( getTeamColor(this.getTeamNum()) );
		this.set_string("custom_explosion_sound", "OrbExplosion.ogg");
		this.getSprite().PlaySound("SpriteFire1.ogg", 0.2f, 1.5f + XORRandom(10)/10.0f);
		this.getSprite().SetZ(1000.0f);
		this.Tag("fire bolt");
		
		// done post init
		this.set_bool("initialized", true);
	}
	
	const u32 gametime = getGameTime();
	u32 lastSmokeTime = this.get_u32("last smoke puff");
	int ticksTillSmoke = 2;
	int diff = gametime - (lastSmokeTime + ticksTillSmoke);
	if (diff > 0)
	{
		MakeParticle( this.getPosition(),
							"SmallSmoke1.png", 50.0 );
	
		lastSmokeTime = gametime;
		this.set_u32("last smoke puff", lastSmokeTime);
	}
	
	
	Vec2f target;
	bool targetSet = false;
	
	CPlayer@ p = this.getDamageOwnerPlayer();
	if( p !is null)	{
		CBlob@ b = p.getBlob();
		if( b !is null)	{
			if( p.isMyPlayer() )
			{
				Vec2f aimPos = b.getAimPos();
				CBitStream params;
				params.write_Vec2f(aimPos);
				this.SendCommand(this.getCommandID("aimpos sync"), params);
			}
			target = this.get_Vec2f("aimpos");
			targetSet = true;
		}
	}
	
	if(targetSet)
	{
		Vec2f thisPos = this.getPosition();
		Vec2f moveDir = target - thisPos;
		float dist = moveDir.Length();

		Vec2f finalSpeed = moveDir;
		finalSpeed.Normalize();
		finalSpeed *= STANDARD_SPEED;

		if( dist > STANDARD_SPEED )
		{
			this.setVelocity(finalSpeed); //if farther away, use standard speed
			dist = STANDARD_SPEED;
		}
		else
		{
			this.setVelocity(moveDir); //if closer than needed, jump to that spot
		}
		
		if(isClient())
		{
			Vec2f pPos = thisPos;
			Vec2f pVector = moveDir;
			pVector.Normalize();

			for(int i = 0; i < dist; i += 2)
			{
				CParticle@ p = ParticleAnimated( "Flash2.png",
						pPos + pVector*i,
						Vec2f_zero,
						float(XORRandom(360)),
						0.7f, 
						1, 
						0.0f, true );
			}
		}
	}
	else
	{
		this.server_Die();
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		( target.getTeamNum() != this.getTeamNum() && target.hasTag("barrier") )
		||
		(
			target.hasTag("flesh") 
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum()
		)
	);
}	

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
	return (
		isEnemy(this, b) 
		|| b.hasTag("door") 
		|| (b.getPlayer() !is null 
			&& this.getDamageOwnerPlayer() !is null
			&& b.getPlayer() is this.getDamageOwnerPlayer()
		|| b.getName() == this.getName()
		)
	); 
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	this.getSprite().PlaySound("SpriteFire3.ogg", 0.05f, 0.5f + XORRandom(10)/20.0f);
	
	if(blob !is null )
	{
		if(isEnemy(this, blob))
		{
			this.server_Die();
			return;
		}
	}
	else
	{
		this.server_Die();
		return;
	}

	if(solid)
	{
		this.server_Die();
	}
	
}

void onTick(CSprite@ this)
{
	CBlob@ b = this.getBlob();
	if(!b.exists("spriteSetupDone") || !b.get_bool("spriteSetupDone"))
	{
		CSpriteLayer@ layer = this.addSpriteLayer("shine","nova_shine.png",150,150,b.getTeamNum(),0);
        layer.SetRelativeZ(-100.0f);
		layer.ScaleBy(0.22f, 0.22f);
		b.set_bool("spriteSetupDone",true);
	}

    CSpriteLayer@ layer = this.getSpriteLayer("shine");

    layer.RotateByDegrees(1,Vec2f_zero);
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("aimpos sync"))
    {
        this.set_Vec2f("aimpos", params.read_Vec2f());
    }
}