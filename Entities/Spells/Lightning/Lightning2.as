#include "/Entities/Common/Attacks/Hitters.as";	   
#include "/Entities/Common/Attacks/LimitedAttacks.as";
#include "SpellCommon.as";
#include "LightningPositionUpdate.as";

const f32 RANGE = 2000.0f;
const f32 DAMAGE = 0.6f;

const int MAX_LASER_POSITIONS = 30;
const int LASER_UPDATE_TIME = 10;

const f32 TICKS_PER_SEG_UPDATE = 2;
const f32 LASER_WIDTH = 1.0f;

Random _laser_r(45354);

void onInit( CBlob @ this )
{
	this.Tag("phase through spells");
	this.Tag("counterable");

	//dont collide with edge of the map
	this.SetMapEdgeFlags( u8(CBlob::map_collide_none) | u8(CBlob::map_collide_nodeath) );
	
	CShape@ shape = this.getShape();
	//shape.SetStatic(true);
	shape.SetGravityScale( 0.0f );
	shape.SetRotationsAllowed(false);
	
	ShapeConsts@ consts = shape.getConsts();
	consts.bullet = false;
	  
	CSprite@ thisSprite = this.getSprite();
	thisSprite.getConsts().accurateLighting = false;
	
	this.set_bool("initialized", false);
	
	this.server_SetTimeToDie(1);
}

void onTick( CBlob@ this)
{
	if(this is null)
	{return;}
	
	CSprite@ thisSprite = this.getSprite();
	CPlayer@ player = this.getDamageOwnerPlayer();
	if (player is null)
	{return;}
	CBlob@ caster = player.getBlob();
	if (caster is null)
	{return;}
	if(this.hasTag("stick"))
	{
		this.setPosition(caster.getPosition());
	}
	Vec2f thisPos = this.getPosition();
	
	if ( this.get_bool("initialized") == false && this.getTickSinceCreated() > 1 )
	{
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		SColor lightColor = SColor( 255, 255, 150, 0);
		if (this.get_bool("repelled")) //changes to red light if incompatible blob
		{
			lightColor = SColor( 255, 0, 0, 0);
		}
		this.SetLightColor( lightColor );
		thisSprite.SetZ(500.0f);
		thisSprite.SetVisible(false);
		
		updateLaserPositions(this);
		
		Vec2f aimPos = this.get_Vec2f("aim pos");
		Vec2f aimVec = aimPos - thisPos;
		Vec2f aimNorm = aimVec;
		aimNorm.Normalize();
		
		Vec2f shootVec = aimNorm*RANGE;
		
		Vec2f destination = thisPos+shootVec;
		
		Vec2f normal = (Vec2f(aimVec.y, -aimVec.x));
		normal.Normalize();
		
		Sound::Play("lightning1.ogg", aimPos, 0.3f, 1.0f + XORRandom(5)/10.0f);
		
		this.server_SetTimeToDie(this.get_f32("lifetime"));

		this.set_bool("initialized", true);
	}
	
	//laser effects	
	if ( this.getTickSinceCreated() > 1 && getGameTime() % TICKS_PER_SEG_UPDATE == 0 )	//delay to prevent rendering lasers leading from map origin
	{
		Vec2f[]@ laser_positions;
		this.get( "laser positions", @laser_positions );
		
		Vec2f[]@ laser_vectors;
		this.get( "laser vectors", @laser_vectors );
		
		if ( laser_positions is null || laser_vectors is null )
			return; 
			
		updateLaserPositions(this);
		
		int laserPositions = laser_positions.length;
		
		f32 ticksTillUpdate = getGameTime() % TICKS_PER_SEG_UPDATE;
		
		int lastPosArrayElement = laser_positions.length-1;
		int lastVecArrayElement = laser_vectors.length-1;
		
		for (int i = 0; i < laser_positions.length; i++)
		{
			thisSprite.RemoveSpriteLayer("laser"+i);
		}
		
		string laserType = "LightningLaser.png";  //changes to red laser if incompatible blob
		if(this.get_bool("repelled"))
		{laserType = "LeechLaser.png";}

		if ( true )
		{
			Vec2f currSegPos = laser_positions[lastPosArrayElement-1];			
			Vec2f nextSegPos = laser_positions[lastPosArrayElement];
			Vec2f followVec = currSegPos - nextSegPos;
			Vec2f followNorm = followVec;
			followNorm.Normalize();
			
			f32 followDist = followVec.Length();
			
			Vec2f netTranslation = nextSegPos - thisPos;
					
			CSpriteLayer@ laser = thisSprite.addSpriteLayer( "laser" + (lastPosArrayElement-1), laserType, 16, 16 );
			if (laser !is null)
			{
				Animation@ anim = laser.addAnimation( "default", 1, true );
				int[] frames = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15};
				anim.AddFrames(frames);				
				laser.SetFrameIndex(15 - (getGameTime() % 15)); 
				
				laser.SetVisible(true);
				
				f32 laserLength = (followDist+1.0f) / 16.0f;						
				laser.ResetTransform();							
				laser.ScaleBy( Vec2f(laserLength, LASER_WIDTH) );							
				laser.TranslateBy( Vec2f(laserLength*8.0f, 0.0f) );							
				laser.RotateBy( -followNorm.Angle(), Vec2f());
				laser.TranslateBy( netTranslation );
				laser.setRenderStyle(RenderStyle::additive);
				laser.SetRelativeZ(1);
			}
		}
		
		for (int i = laser_positions.length - laserPositions; i < lastVecArrayElement; i++)
		{
			Vec2f currSegPos = laser_positions[i];				
			Vec2f prevSegPos = laser_positions[i+1];
			Vec2f followVec = currSegPos - prevSegPos;
			Vec2f followNorm = followVec;
			followNorm.Normalize();
			
			f32 followDist = followVec.Length();
			
			Vec2f netTranslation = Vec2f(0,0);
			for (int t = i+1; t < lastVecArrayElement; t++)
			{	
				netTranslation = netTranslation - laser_vectors[t]; 
			}
			
			Vec2f movementOffset = laser_positions[lastPosArrayElement-1] - thisPos;
					
			CSpriteLayer@ laser = thisSprite.addSpriteLayer( "laser"+i, laserType, 16, 16 );
			if (laser !is null)
			{
				Animation@ anim = laser.addAnimation( "default", 1, true );
				int[] frames = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15};
				anim.AddFrames(frames);				
				laser.SetFrameIndex(15 - (getGameTime() % 15));
				
				laser.SetVisible(true);
				
				f32 laserLength = (followDist+1.0f) / 16.0f;					
				laser.ResetTransform();			
				laser.ScaleBy( Vec2f(laserLength, LASER_WIDTH) );	
				laser.TranslateBy( Vec2f(laserLength*8.0f, 0.0f) );	
				laser.RotateBy( -followNorm.Angle(), Vec2f() );	
				laser.TranslateBy( netTranslation + movementOffset );	
				laser.setRenderStyle(RenderStyle::additive);
				laser.SetRelativeZ(1);
			}
		}
	}
}