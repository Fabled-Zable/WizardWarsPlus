#include "Hitters.as";
#include "MagicCommon.as";
#include "CommonFX.as";

const f32 PULL_RADIUS = 256.0f;
const f32 MAX_FORCE = 128.0f;
const int LIFETIME = 15;

void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(LIFETIME);
	this.getShape().SetGravityScale(0.0);
	this.Tag("counterable");
	this.Tag("black hole");
	
	this.server_setTeamNum(-1);
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

	CMap@ map = getMap();
	if (map is null)
	return;

	if (this.getTickSinceCreated() < 1)
	{		
		this.getSprite().PlaySound("BlackHoleMake.ogg", 1.0f, 0.5f);	
	}

	CBlob@[] attracted;
	map.getBlobsInRadius( thisPos, PULL_RADIUS, @attracted );
	for (uint i = 0; i < attracted.size(); i++)
	{
		CBlob@ attractedblob = attracted[i];
		if (attractedblob is null)
		continue;

		Vec2f blobPos = attractedblob.getPosition();
		
		if ( !attractedblob.hasTag("dead") )
		{
			Vec2f pullVec = thisPos - blobPos;
			Vec2f pullNorm = pullVec;
			pullNorm.Normalize();
			
			Vec2f forceVec = pullNorm*MAX_FORCE;
			Vec2f finalForce = forceVec*(1.0f-pullVec.Length()/PULL_RADIUS);

			attractedblob.AddForce(finalForce);
			
			ManaInfo@ manaInfo;
			if ( (getGameTime() % 24 == 0) && attractedblob.get("manaInfo", @manaInfo) && !map.rayCastSolidNoBlobs(thisPos, blobPos) )
			{
				s32 MANA_DRAIN = attractedblob.get_s32("mana regen rate") + 1;

				/*if (attractedblob.getName() == "entropist")
				{
					if(manaInfo.mana > 2)
					{
						manaInfo.mana -= 2;
					}
					else
					{
						manaInfo.mana = 0;
					}
				}
				else*/

				if (MANA_DRAIN < 1) //normalizer
				{
					MANA_DRAIN = 1;
				}

				if (manaInfo.mana > MANA_DRAIN)
				{
					manaInfo.mana -= MANA_DRAIN;
					
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
	
	if ( this.getTickSinceCreated() > LIFETIME*getTicksASecond() - 15 )
	this.Tag("dead");
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{
	if(this is null || blob is null)
	return;

	if(this.hasTag("dead") || blob.hasTag("dead"))
	return;

	if ( blob.hasTag("black hole") ) //combine with other black holes
	{
		Vec2f thisPos = this.getPosition();
		this.Tag("dead");
		blob.Tag("dead");
		this.server_Die();
		blob.server_Die();

		server_CreateBlob( "black_hole_big", -1, thisPos ); // moved down here so we dont accidently make a blob before killing the last 2
	}
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	if ( !isClient() )
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

Random _sprk_r(2354);
void sparks(Vec2f pos, int amount)
{
	if ( !isClient() )
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