
//script for a LandCritter - attach to:
// blob
// movement
// 		vars:		f32 swimspeed f32 swimforce


#define SERVER_ONLY

#include "Hitters.as";

shared class CritterVars
{
	Vec2f walkForce;  
	Vec2f runForce;
	Vec2f slowForce;
	Vec2f jumpForce;
	f32 maxVelocity;
};

//blob
void onInit(CBlob@ this)
{
	CritterVars vars;
	//walking vars
	float difficulty = getRules().get_f32("difficulty")/4.0;
	if (difficulty<1.0) difficulty=1.0;
	if (difficulty>4.0) difficulty=4.0;
	vars.walkForce.Set(12.0f,0.0f);
	vars.runForce.Set(12.0f,0.0f);
	vars.slowForce.Set(6.0f,0.0f);
	vars.jumpForce.Set(0.0f,-1.2f);
	vars.maxVelocity = difficulty;
	this.set( "vars", vars );

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag	= "dead";
}

//movement
void onInit( CMovement@ this )
{
	//this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	//this.getCurrentScript().runProximityTag = "player";
	//this.getCurrentScript().runProximityRadius = 120.0f;
	this.getCurrentScript().removeIfTag	= "dead";   
}

void onTick( CMovement@ this )
{
    CBlob@ blob = this.getBlob();

	CritterVars@ vars;
	if (!blob.get( "vars", @vars ))
		return;
	if (blob.getHealth() <= 0.0) return; // dead
	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	bool up = blob.isKeyPressed(key_up);

	Vec2f vel = blob.getVelocity();
	if (left) {
		blob.AddForce(Vec2f( -1.0f * vars.walkForce.x, vars.walkForce.y));
	}
	if (right) {
		blob.AddForce(Vec2f( 1.0f * vars.walkForce.x, vars.walkForce.y));
	}

	// jump if blocked

	if (left || right || up)
	{
		Vec2f pos = blob.getPosition();
		CMap@ map = blob.getMap();
		const f32 radius = blob.getRadius();
		bool rightsolid = map.isTileSolid( Vec2f( pos.x + (radius+1.0f), pos.y )) ;
		bool leftsolid = map.isTileSolid( Vec2f( pos.x - (radius+1.0f), pos.y ));
		if ((blob.isOnGround() || blob.isInWater()) && (up || (right && rightsolid) || (left && leftsolid)))
		{ 
			f32 mod = blob.isInWater() ? 0.23f : 1.0f;
			blob.AddForce(Vec2f( mod*vars.jumpForce.x*blob.getMass(), mod*vars.jumpForce.y*blob.getMass()));
		}
	}

	CShape@ shape = blob.getShape();

	// too fast - slow down
	if (shape.vellen > vars.maxVelocity)
	{		  
		Vec2f vel = blob.getVelocity();
		blob.AddForce( Vec2f(-vel.x * vars.slowForce.x, -vel.y * vars.slowForce.y) );
	}
}
