
//script for a LandCritter - attach to:
// blob
// movement
// 		vars:		f32 swimspeed f32 swimforce

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
	vars.walkForce.Set(8.0f,0.0f);
	vars.runForce.Set(8.0f,0.0f);
	vars.slowForce.Set(4.0f,0.0f);
	vars.jumpForce.Set(0.0f,-10.0f);
	vars.maxVelocity = 5.0f;
	this.set( "vars", vars );
	this.set_s32("flymod",0);
	
	this.getShape().SetGravityScale(0.5f);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag	= "dead";
}

//movement
void onInit( CMovement@ this )
{
	//this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().runFlags = 0;
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

	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	bool up = blob.isKeyPressed(key_up);
	bool down = blob.isKeyPressed(key_down);
	Vec2f vel = blob.getVelocity();
	if (left) {
		blob.AddForce(Vec2f( -1.0f * vars.walkForce.x, vars.walkForce.y));
	}
	if (right) {
		blob.AddForce(Vec2f( 1.0f * vars.walkForce.x, vars.walkForce.y));
	}

	// jump if blocked
	s32 flymod = blob.get_s32("flymod");
		
	Vec2f pos = blob.getPosition();
	CMap@ map = blob.getMap();
	const f32 radius = blob.getRadius();
	
	f32 x = pos.x;
	Vec2f top = Vec2f(x, map.tilesize);
	Vec2f bottom = Vec2f(x, map.tilemapheight * map.tilesize);
	Vec2f end;
	
	blob.AddForce(Vec2f( vars.jumpForce.x, 0.0f));
	
	if ( up )
	{
		blob.AddForce(Vec2f( 0.0f, vars.jumpForce.y));
	}
		
	flymod++;
	if (flymod>28) flymod=0;
	blob.set_s32("flymod",flymod);
	CShape@ shape = blob.getShape();	
}
