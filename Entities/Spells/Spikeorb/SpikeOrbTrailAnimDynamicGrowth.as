//Orb trail animation
const f32 initialSize = 1.0f;
const f32 scaleFactor = 0.5f;
const u8 maxScale = 4;

void onInit( CSprite@ this )
{
	this.SetZ( 500.0f );
    CSpriteLayer@ trail = this.addSpriteLayer( "trail", "SpikeOrbTrail.png", 11, 7 );
	if (trail !is null)
    {
		Animation@ anim = trail.addAnimation( "default", 0, false );
		anim.AddFrame(0);
		trail.ScaleBy( Vec2f( initialSize, initialSize ) );
		trail.SetRelativeZ( -1.0f );
    }
}

void onTick( CSprite@ this )
{
	CBlob@ blob = this.getBlob();
	Vec2f vel = blob.getVelocity();
	vel.y *= -1;
	f32 velLength = vel.getLength();
	
	CSpriteLayer@ trail = this.getSpriteLayer( "trail" );
	if ( this.isAnimation( "static" ) )//set by GooBall.as
	{
		f32 scale = Maths::Min( maxScale, initialSize + velLength*scaleFactor );
		this.ScaleBy( Vec2f( scale * 2.0f, scale ) );
		//this.SetOffset( Vec2f( 0, 0.3f ) );
		trail.SetVisible( false );
		this.PlaySound( "/wetfall2.ogg" );//or: WaterBubble
		this.getCurrentScript().runFlags |= Script::remove_after_this;
		return;
	}
	
	if ( trail is null )	return;

	f32 trailOffset = Maths::Min( maxScale, initialSize + velLength*scaleFactor ) + 2.0f;
	//print( "trailOffset: " + trailOffset );

	trail.ResetTransform();
	trail.SetOffset( Vec2f( trailOffset, 0 ) );
	trail.RotateBy( vel.Angle(), Vec2f( -trailOffset, 0 ) );	
	trail.SetVisible( true );
	
	
	if ( (initialSize + velLength*scaleFactor) < maxScale )
	{
		trail.ScaleBy( Vec2f( scaleFactor, scaleFactor ) );
	}
}