#include "Hitters.as"
#include "SpellCommon.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	shape.getConsts().mapCollisions = false;
	
	this.Tag("TeleportBlocker");
	this.Tag("projectile");
	this.Tag("invincible");
	this.Tag("phasing");
}

void onTick( CBlob@ this )
{
	if (this.getTickSinceCreated() < 1)
	{		
		//this.getSprite().PlaySound("EnergySound1.ogg", 1.0f, 1.0f);	
		this.server_SetTimeToDie(9999);
		
		CSprite@ sprite = this.getSprite();
		sprite.getConsts().accurateLighting = false;
		sprite.setRenderStyle(RenderStyle::additive);
		sprite.SetRelativeZ(-6);
		return;
	}

	CBlob@ ownerBlob = getBlobByNetworkID(this.get_u16("ownerNetID"));

	if (ownerBlob is null)
	{
		this.server_Die();
		return;
	}

	Vec2f targetPos = ownerBlob.getPosition();

	this.setPosition( targetPos );
	this.setAngleDegrees(0);

	this.setVelocity(Vec2f_zero);
	this.setAngularVelocity(0);

	/*
	if (!this.isAttached())
	{
		print("I AM NOT ATTACHED");
		this.server_Die();
		return;
	}
	else if (getGameTime() % 60 == 0)
	{
		print("I AM ATTACHED AT: " + this.getPosition());
	}*/
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("EnergySound2.ogg", 0.3f, 1.0f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	//ignore all damage except from special hit
	if (customData == 0xfa)
	{
		this.server_SetHealth(-1.0f);
		this.server_Die();
	}
	return 0.0f;
}