#include "/Entities/Common/Attacks/Hitters.as";	   
#include "/Entities/Common/Attacks/LimitedAttacks.as";
#include "SpellCommon.as";

const int LIFETIME = 10;

void onInit( CBlob @ this )
{
	CShape@ shape = this.getShape();
	shape.SetGravityScale( 0.0f );
	shape.SetRotationsAllowed(false);
	
	this.server_SetTimeToDie(LIFETIME);
}

void onTick( CBlob@ this)
{
	CSprite@ thisSprite = this.getSprite();
	Vec2f thisPos = this.getPosition();
	
	if (this.getTickSinceCreated() < 1)
	{
	}
}
