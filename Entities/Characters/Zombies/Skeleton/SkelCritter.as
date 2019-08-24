
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
	vars.walkForce.Set(difficulty*4.0f,0.0f);
	vars.runForce.Set(difficulty*4.0f,0.0f);
	vars.slowForce.Set(difficulty*1.5f,0.0f);
	vars.jumpForce.Set(0.0f,-1.0f);
	vars.maxVelocity = difficulty*2.0f;
	this.set( "vars", vars );

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag	= "dead";
	this.set_s32("climb",0);
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
		
		if (blob.isOnGround()) blob.set_s32("climb",1);
		
		if (
		(blob.isOnGround() || blob.isInWater()) && 
		(up || (right && map.isTileSolid( Vec2f( pos.x + (radius+1.0f), pos.y ))) || (left && map.isTileSolid( Vec2f( pos.x - (radius+1.0f), pos.y )))))
		{ 
			f32 mod = blob.isInWater() ? 0.23f : 1.0f;
			blob.AddForce(Vec2f( mod*vars.jumpForce.x*blob.getMass(), mod*vars.jumpForce.y*blob.getMass()));
			blob.set_s32("climb",1);
		} else
		if (( (right && map.isTileSolid( Vec2f( pos.x + (radius+1.0f), pos.y ))) || (left && map.isTileSolid( Vec2f( pos.x - (radius+1.0f), pos.y )))))
		{
			s32 climb = blob.get_s32("climb");
			if ((climb>0))
			{
				f32 mod = blob.isInWater() ? 0.23f : 1.0f;
				blob.AddForce(Vec2f( mod*vars.jumpForce.x*blob.getMass()/1.9, mod*vars.jumpForce.y*blob.getMass()/1.9));
				climb++;
				if (XORRandom(10) == 0) climb=0;
				blob.set_s32("climb",climb);
				
			}
		}
		blob.Sync("climb",true);
	}

	CShape@ shape = blob.getShape();

	// too fast - slow down
	if (shape.vellen > vars.maxVelocity)
	{		  
		Vec2f vel = blob.getVelocity();
		blob.AddForce( Vec2f(-vel.x * vars.slowForce.x, -vel.y * vars.slowForce.y) );
	}
}
