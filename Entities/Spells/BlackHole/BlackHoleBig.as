#include "Hitters.as";
#include "MagicCommon.as";

const f32 PULL_RADIUS = 256.0f;
const f32 MAX_FORCE = 128.0f;
const int LIFETIME = 14;
const f32 MANA_DRAIN = 4.0f;

const int PARTICLE_TICKS = 6;

void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(LIFETIME+1);
	this.getShape().SetGravityScale(0.0);
	this.Tag("counterable");
	this.Tag("black hole");
	
	this.server_setTeamNum(-1);
	
	if( !CustomEmitEffectExists( "blackHoleBigEmit" ) )
	{
		SetupCustomEmitEffect( "blackHoleBigEmit", "BlackHoleBig.as", "updateBlackHoleParticle", 10, 0, 120 );
		//SetupCustomEmitEffect( STRING name, STRING scriptfile, STRING scriptfunction, u8 hard_freq, u8 chance_freq, u16 timeout )
	}
}

void onInit(CSprite@ this)
{
	this.setRenderStyle(RenderStyle::subtractive);
	this.ScaleBy(Vec2f(2.0f, 2.0f));
	this.SetZ(-10.0f);
	this.SetEmitSound( "EnergyLoop1.ogg" );
	this.SetEmitSoundSpeed(0.5f);
	this.SetEmitSoundPaused( false );
}

void onTick(CSprite@ this)
{
	this.RotateBy(8.0, Vec2f_zero);
}

void onTick(CBlob@ this)
{
	Vec2f thisPos = this.getPosition();
	
	if (this.getTickSinceCreated() < 1)
	{		
		this.getSprite().PlaySound("BlackHoleMake.ogg", 1.0f, 0.5f);	
	}

	CBlob@[] attracted;
	this.getMap().getBlobsInRadius( thisPos, PULL_RADIUS, @attracted );
	for (uint i = 0; i < attracted.size(); i++)
	{
		CBlob@ attractedblob = attracted[i];
		if (attractedblob is null)
			continue;
		
		if ( !attractedblob.hasTag("dead")
				|| (attractedblob.hasTag("black hole")) )
		{
			Vec2f blobPos = attractedblob.getPosition();
			Vec2f pullVec = thisPos - blobPos;
			Vec2f pullNorm = pullVec;
			pullNorm.Normalize();
			
			Vec2f forceVec = pullNorm*MAX_FORCE;
			Vec2f finalForce = forceVec*(1.0f-pullVec.Length()/PULL_RADIUS);

			attractedblob.AddForce(finalForce);
			
			ManaInfo@ manaInfo;
			if (attractedblob.get("manaInfo", @manaInfo) && (getGameTime() % 24 == 0))
			{
				CMap@ map = this.getMap();
				if (map is null)
					return;
			
				if ( !map.rayCastSolid(thisPos, blobPos) )
				{
					if (manaInfo.mana > 0.0)
					{
						manaInfo.mana = manaInfo.mana - MANA_DRAIN;
						attractedblob.getSprite().PlaySound("ManaDraining.ogg", 0.5f, 1.0f + XORRandom(2)/10.0f);
						makeManaDrainParticles( blobPos, 30 );
					}
					else
					{
						manaInfo.mana = 0.0;
					}
				}
			}
		}
	}
	
	// combine with other black holes in random intervals
	if ( XORRandom(4) == 0 )
	{
		CBlob@[] touching;
		this.getMap().getBlobsInRadius( thisPos, 8.0f, @touching );
		for (uint i = 0; i < touching.size(); i++)
		{
			CBlob@ touchingBlob = touching[i];
			if (touchingBlob is null || touchingBlob is this)
				continue;
				
			if ( touchingBlob.hasTag("black hole") )
			{
				server_CreateBlob( "black_hole_big", this.getTeamNum(), thisPos );
				touchingBlob.server_Die();
				this.server_Die();
			}
		}
	}
	
	if ( this.getTickSinceCreated() > LIFETIME*30 + 15 )
		this.Tag("die");
	
	if ( getNet().isClient() && getGameTime() % PARTICLE_TICKS == 0 )
		makeBlackHoleParticle( thisPos, Vec2f(0,0) );
}

void updateBlackHoleParticle( CParticle@ p )
{
	if ( !getNet().isClient() )
		return;

	CBlob@[] blackHoles;
	if (getBlobsByName("black_hole_big", @blackHoles))
	{
		f32 extRadius = PULL_RADIUS*2;
	
		f32 best_dist = 99999999;
		for (uint step = 0; step < blackHoles.length; ++step)
		{
			CBlob@ bHole = blackHoles[step];
			if ( bHole is null )
				continue;
				
			Vec2f bPos = bHole.getPosition();
			Vec2f pPos = p.position;
			Vec2f forceVec = bPos - pPos;
			
			f32 dist = forceVec.getLength();			
			if (dist < best_dist)
			{
				best_dist=dist;
				
				Vec2f forceNorm = forceVec;
				forceNorm.Normalize();
				p.gravity = forceNorm*(2.0f/(dist+1)^2);
				
				Vec2f pVelNorm = p.velocity;
				pVelNorm.Normalize();
				p.rotation = -pVelNorm;
				//p.velocity *= 0.5f;
			}
			
			if ( dist < 16.0f || bHole.hasTag("die") )
			{
				p.frame = 7;
				sparks(p.position, 2);
			}
		}
	}
	else
		p.frame = 7;
}

Random _sprk_r(2354);
void makeBlackHoleParticle( Vec2f pos, Vec2f vel )
{
	if ( !getNet().isClient() )
		return;

	u8 emitEffect = GetCustomEmitEffectID( "blackHoleBigEmit" );
	
	const f32 rad = 16.0f;
	Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
	//Vec2f newPos = pos + random;
	Vec2f newPos = pos + Vec2f(rad,0).RotateBy(_sprk_r.NextRanged(360));
	Vec2f dirVec = newPos - pos;
	Vec2f dirNorm = dirVec;
	dirNorm.Normalize();
	Vec2f newVel = vel + dirNorm.RotateBy(60.0f)*12.0f;
	
	//CParticle@ p = ParticlePixel( newPos, newVel, SColor( 255, 0, 0, 0), true );
	CParticle@ p = ParticleAnimated( "BlackStreak1.png", newPos, newVel, -newVel.getAngleDegrees(), 1.0f, 20, 0.0f, true );
	if(p !is null)
	{
		p.scale = 2.0f;
		p.Z = 500.0f;
		p.bounce = 0.1f;
		p.gravity = Vec2f(0,0);
    	p.fastcollision = true;
		p.emiteffect = emitEffect;
	}
}

Random _sprk_r2(12432);
void makeManaDrainParticles( Vec2f pos, int amount )
{
	if ( !getNet().isClient() )
		return;

	u8 emitEffect = GetCustomEmitEffectID( "blackHoleBigEmit" );
	
	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r2.NextFloat() * 6.0f, 0);
        vel.RotateBy(_sprk_r2.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixel( pos, vel, SColor( 255, 120+XORRandom(40), 0, 255), true );
        if(p is null) return; //bail if we stop getting particles

        p.timeout = 10 + _sprk_r2.NextRanged(30);
        p.scale = 1.0f + _sprk_r2.NextFloat();
        p.damping = 0.6f;
    	p.fastcollision = true;
		p.gravity = Vec2f(0,0);
		p.emiteffect = emitEffect;
    }
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_blast_r.NextFloat() * 14.0f, 0);
        vel.RotateBy(_blast_r.NextFloat() * 360.0f);
		Vec2f velNorm = vel;
		velNorm.Normalize();

        CParticle@ p = ParticleAnimated( "BlackStreak2.png", 
									pos, 
									vel, 
									-velNorm.Angle(), 
									1.0f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles
		
        p.scale = 1.0f + _blast_r.NextFloat()*1.0f;
        p.damping = 0.9f;
    	p.fastcollision = true;
		p.Z = 200.0f;
		p.lighting = false;
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
        CParticle@ p = ParticlePixel( pos, vel, SColor( 255, colorShade, colorShade, colorShade), true );
        if(p is null) return; //bail if we stop getting particles

        p.timeout = 40 + _sprk_r.NextRanged(20);
        p.scale = 1.0f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    	p.fastcollision = true;
		p.gravity = Vec2f(0,0);
    }
}

void onDie(CBlob@ this)
{
	blast(this.getPosition(), 20);
	this.getSprite().PlaySound("BlackHoleDie.ogg", 1.0f, 0.5f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
	return false;
}