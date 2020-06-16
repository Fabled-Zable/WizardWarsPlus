

//Numan tried and failed to make a good trail
//
//
//Welcome to the terrible code that i made
#include "TextureCreation.as";

const f32 TICKS_PER_SEG_UPDATE = 3;
const bool IS_FUZZY = true;



void onInit( CBlob @ this )
{
	SColor ImageColor;

	if(this.getName() == "magic_missile")
	{
		this.set_u16("TRAIL_SEGMENTS", 60);
		this.set_f32("x_size", 2.0f);
	}
	else if(this.getName() == "effect_missile")//Heal, slow, and haste
	{	
		this.set_u16("TRAIL_SEGMENTS", 60);
		this.set_f32("x_size", 1.0f);
	}
	else //if(this.getName() == "effect_missile1")//Bees
	{
		this.set_u16("TRAIL_SEGMENTS", 30);
		this.set_f32("x_size", 0.6f);
	}//AHH THE BEES!
	
	Setup(SColor(220, 255, 254, 73), "rend1", IS_FUZZY);//Magic missles
	Setup(SColor(220, 237, 237, 237), "rend2", IS_FUZZY);//Heal, slow, and haste

	if(!this.get_bool("silent"))
	{
		int cb_id = Render::addBlobScript(Render::layer_objects, this, "RenderTrail.as", "RenderTrailFunction");
	}
	
	this.set_bool("initialized", false);
	
}
void RenderTrailFunction(CBlob@ this, int id)
{

	/*if(!getNet().isClient()) 
		return;	*/ //not needed, servers dont run render stuff, they only run onTick
	
	CSprite@ thisSprite = this.getSprite();
	Vec2f thisPos = this.getPosition();
	Vec2f p = this.getInterpolatedPosition();
	Vec2f thisVel = this.getVelocity();
	
	string render_texture_name = "rend2";
	
	if(this.getName() == "magic_missile" || this.get_string("effect") == "slow")
		render_texture_name = "rend1";
	

	f32 x_size = this.get_f32("x_size");
	u16 TRAIL_SEGMENTS = this.get_u16("TRAIL_SEGMENTS");
	
	if ( this.get_bool("initialized") == false && this.getTickSinceCreated() > 1 )
	{
		array<Vec2f> trail_positions(TRAIL_SEGMENTS, p);
		this.set("trail positions", trail_positions);
		
		this.set_bool("initialized", true);
	

	}
	
	Vec2f[]@ trail_positions;
	this.get( "trail positions", @trail_positions );
		
	if ( trail_positions is null )
		return; 
			
			
	
	
	//Just need some space here, it makes a warm feeling to have this space
	
	


	int lastPosArrayElement = trail_positions.length-1;
	
	f32 ticksTillUpdate = getGameTime() % TICKS_PER_SEG_UPDATE;
	if ( ticksTillUpdate == 0 )
	{
		trail_positions.push_back(p);
	}
	
	
	//render just behind our character
	f32 z = thisSprite.getZ() - 0.1f;
	
	
	Vec2f currSegPos = trail_positions[lastPosArrayElement-1];				
	Vec2f nextSegPos = trail_positions[lastPosArrayElement];
	Vec2f followVec = currSegPos - nextSegPos;
	Vec2f followNorm = followVec;
	followNorm.Normalize();
	
	f32 followDist = followVec.Length();
		
	Vec2f[] v_pos;
	Vec2f[] v_uv;
	
	f32 trailLength = (followDist+2.0f) / 16.0f;

	f32 lineWidth = x_size*((TRAIL_SEGMENTS-1.0f)/TRAIL_SEGMENTS)
				*((TICKS_PER_SEG_UPDATE-ticksTillUpdate*(1.0f/TRAIL_SEGMENTS))/TICKS_PER_SEG_UPDATE);
		
	v_pos.push_back(currSegPos + Vec2f(-followDist * trailLength,-lineWidth).RotateBy(-followNorm.Angle(), Vec2f())	); v_uv.push_back(Vec2f(0,0));//Top left?
	v_pos.push_back(currSegPos + Vec2f( followDist * trailLength,-lineWidth).RotateBy(-followNorm.Angle(), Vec2f())	); v_uv.push_back(Vec2f(1,0));//Top right?
	v_pos.push_back(currSegPos + Vec2f( followDist * trailLength, lineWidth).RotateBy(-followNorm.Angle(), Vec2f())	); v_uv.push_back(Vec2f(1,1));//Bottom right?
	v_pos.push_back(currSegPos + Vec2f(-followDist * trailLength, lineWidth).RotateBy(-followNorm.Angle(), Vec2f())	); v_uv.push_back(Vec2f(0,1));//Bottom left?
		
	Render::SetAlphaBlend(true);
		
	Render::Quads(render_texture_name, z, v_pos, v_uv);
	
	v_pos.clear();
	v_uv.clear();
	
	for (int i = trail_positions.length - TRAIL_SEGMENTS; i < lastPosArrayElement; i++)
	{
		currSegPos = trail_positions[i];				
		Vec2f prevSegPos = trail_positions[i+1];
		followVec = currSegPos - prevSegPos;
		followNorm = followVec;
		followNorm.Normalize();
		
		followDist = followVec.Length();

	
		f32 addToFollowDist = 2.0f;
		
		if(followDist < 6.0f)//THIS IS TEMPORARY AND BAD
			addToFollowDist = 8.0f;
		else if(followDist < 10.0f)//THIS IS TEMPORARY AND BAD
			addToFollowDist = 8.0f;
		
		trailLength = (followDist+addToFollowDist) / 16.0f;
	
		lineWidth = x_size*((i*1.0f-(trail_positions.length-TRAIL_SEGMENTS))/TRAIL_SEGMENTS)
					*((TICKS_PER_SEG_UPDATE-ticksTillUpdate*(1.0f/TRAIL_SEGMENTS))/TICKS_PER_SEG_UPDATE);
			
		v_pos.push_back(currSegPos + Vec2f(-followDist * trailLength,-lineWidth).RotateBy(-followNorm.Angle(), Vec2f())	); v_uv.push_back(Vec2f(0,0));//Top left?
		v_pos.push_back(currSegPos + Vec2f( followDist * trailLength,-lineWidth).RotateBy(-followNorm.Angle(), Vec2f())	); v_uv.push_back(Vec2f(1,0));//Top right?
		v_pos.push_back(currSegPos + Vec2f( followDist * trailLength, lineWidth).RotateBy(-followNorm.Angle(), Vec2f())	); v_uv.push_back(Vec2f(1,1));//Bottom right?
		v_pos.push_back(currSegPos + Vec2f(-followDist * trailLength, lineWidth).RotateBy(-followNorm.Angle(), Vec2f())	); v_uv.push_back(Vec2f(0,1));//Bottom left?
			
		Render::Quads(render_texture_name, z, v_pos, v_uv);
		
		v_pos.clear();
		v_uv.clear();
	}	
}