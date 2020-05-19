
#include "Hitters2.as";
#include "TeamColour.as";
#include "MakeDustParticle.as";

void onInit( CBlob@ this )
{
    this.set_u8("custom_hitter", Hitters2::orb);
	this.Tag("exploding");
	
	this.Tag("kill other spells");
	this.Tag("counterable");
	
	this.set_f32("explosive_radius", 20.0f );
	this.set_f32("explosive_damage", 3.0f);
	this.set_f32("map_damage_radius", 15.0f);
	this.set_f32("map_damage_ratio", -1.0f); //heck no!
	this.set_u32("last smoke puff", 0 );
}	

void onTick( CBlob@ this )
{     
	if(this.getCurrentScript().tickFrequency == 1)
	{
		this.getShape().SetGravityScale( 0.0f );
		this.server_SetTimeToDie(7);
		this.SetLight( true );
		this.SetLightRadius( 32.0f );
		this.SetLightColor( getTeamColor(this.getTeamNum()) );
		this.set_string("custom_explosion_sound", "OrbExplosion.ogg");
		this.getSprite().PlaySound("SpriteFire1.ogg", 0.2f, 1.5f + XORRandom(10)/10.0f);
		this.getSprite().SetZ(1000.0f);
		this.Tag("fire bolt");
		
		//makes a stupid annoying sound
		//ParticleZombieLightning( this.getPosition() );
		
		// done post init
		this.getCurrentScript().tickFrequency = 3;
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
	bool targetSet;
	bool brake;
	
	CPlayer@ p = this.getDamageOwnerPlayer();
	if( p !is null)	{
		CBlob@ b = p.getBlob();
		if( b !is null)	{
			target = b.getAimPos();
			targetSet = true;
			brake = b.isKeyPressed( key_action3 );
		}
	}
	
	if(targetSet)
	{
		Vec2f vel = this.getVelocity();
		Vec2f dir = target-this.getPosition();
		if(!brake)
		{
			dir.Normalize();
			vel += dir * 1.4f;
		}
		
		this.setVelocity(vel);
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return 
	(
		( target.getTeamNum() != this.getTeamNum() && (target.hasTag("kill other spells") || target.hasTag("door") || target.getName() == "trap_block") || target.hasTag("barrier") )
		||
		(
			target.hasTag("flesh") 
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
			&& ( friend is null || friend.getTeamNum() != this.getTeamNum() )
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
	if (solid || blob.hasTag("kill other spells"))
	{
		this.getSprite().PlaySound("SpriteFire3.ogg", 0.05f, 0.5f + XORRandom(10)/20.0f);
		if(blob !is null && (isEnemy(this, blob) || blob.hasTag("barrier")) )
		{
			this.server_Die();
		} 
	}
}
