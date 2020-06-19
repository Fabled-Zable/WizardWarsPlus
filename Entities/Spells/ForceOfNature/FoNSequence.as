//Force of Nature Spell Event Sequence
const int CAST_TIME = 80;

void onInit( CBlob@ this)
{
	this.set_u16("FoN cast time", 0);
	
	bool emitEffectCreated = false;
	if( !CustomEmitEffectExists( "FoNEmit" ) )
	{
		SetupCustomEmitEffect( "FoNEmit", "FoNSequence.as", "updateFoNParticle", 10, 0, 120 );
		//SetupCustomEmitEffect( STRING name, STRING scriptfile, STRING scriptfunction, u8 hard_freq, u8 chance_freq, u16 timeout )
		emitEffectCreated = true;
	}
	
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick( CBlob@ this)
{	
	bool casting = this.hasTag("in spell sequence");
	if ( casting == false )
		return;

	int currentTime = getGameTime();
	int lastCastTime = this.get_u16("FoN cast time");
	int timeElapsed = currentTime - lastCastTime;
	
	Vec2f thisPos = this.getPosition();
	Vec2f aimVec = this.get_Vec2f("spell aim vec");
	Vec2f aimNorm = aimVec;
	aimNorm.Normalize();
	
	if ( timeElapsed < CAST_TIME )
	{
		this.setVelocity(Vec2f(0,0));
		
		u16 takekeys;
		takekeys = key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3 | key_taunts | key_pickup;

		this.DisableKeys(takekeys);
		this.DisableMouse(true);
		
		//effects
		if ( getNet().isClient() && currentTime % 4 == 0 )
			makeFoNParticle( this, this.getPosition(), Vec2f(0,0) );
	}
	else if ( timeElapsed >= CAST_TIME )
	{
		CBlob@ orb = server_CreateBlob( "force_of_nature" );
		if (orb !is null)
		{
			orb.IgnoreCollisionWhileOverlapped( this );
			orb.SetDamageOwnerPlayer( this.getPlayer() );
			//orb.server_setTeamNum( this.getTeamNum() );
			orb.setPosition( thisPos );
			orb.setVelocity( aimNorm*3.0f );
		}

		this.Untag("in spell sequence");
		this.DisableKeys(0);
		this.DisableMouse(false);				
	}
}

void updateFoNParticle( CParticle@ p )
{
	if ( !getNet().isClient() )
		return;

	CBlob@[] FoNCasters;
	if (getBlobsByTag("in spell sequence", @FoNCasters))
	{
		f32 best_dist = 99999999;
		for (uint step = 0; step < FoNCasters.length; ++step)
		{
			CBlob@ blob = FoNCasters[step];
			if ( blob is null )
				continue;
				
			Vec2f bPos = blob.getPosition();
			Vec2f pPos = p.position;
			Vec2f forceVec = bPos - pPos;
			
			f32 dist = forceVec.getLength();			
			if (dist < best_dist)
			{
				best_dist=dist;
				
				Vec2f forceNorm = forceVec;
				forceNorm.Normalize();
				p.gravity = forceNorm*(2.0f/(dist+1)^2)*0.1f;
				
				Vec2f pVelNorm = p.velocity;
				pVelNorm.Normalize();
				p.rotation = -pVelNorm;
				//p.velocity *= 0.5f;
			}
			
			if ( dist < 8.0f )
			{
				p.frame = 7;
				sparks(p.position, 2);
			}
		}
	}
	else
		p.frame = 7;
}

Random _sprk_r(12345);
void makeFoNParticle(CBlob@ this, Vec2f pos, Vec2f vel )
{
	if (isServer())
		return;

	u8 emitEffect = GetCustomEmitEffectID( "FoNEmit" );
	
	const f32 rad = 48.0f;
	Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
	Vec2f newPos = pos + random;
	//Vec2f newPos = pos + Vec2f(rad,0).RotateBy(_sprk_r.NextRanged(360));
	Vec2f dirVec = newPos - pos;
	Vec2f dirNorm = dirVec;
	dirNorm.Normalize();
	Vec2f newVel = vel + dirNorm.RotateBy(60.0f)*12.0f;
	
	//CParticle@ p = ParticlePixel( newPos, newVel, SColor( 255, 0, 0, 0), true );
	CParticle@ p = ParticleAnimated( "GreenBlob.png", newPos, Vec2f(0,0), -newVel.getAngleDegrees(), 1.0f, 3+XORRandom(3), 0.0f, true );
	if(p !is null)
	{
		p.Z = 500.0f;
		p.bounce = 0.1f;
    	p.fastcollision = true;
		p.gravity = Vec2f(0,0);
		p.emiteffect = emitEffect;
	}
}

void sparks(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 0.5f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);
		
		int colorShade = _sprk_r.NextRanged(128);
        CParticle@ p = ParticlePixel( pos, vel, SColor( 255, colorShade, 255, colorShade), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 40 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
		p.gravity = Vec2f(0,0);
    }
}
