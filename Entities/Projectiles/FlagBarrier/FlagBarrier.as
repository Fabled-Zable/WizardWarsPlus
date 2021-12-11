#include "Hitters.as"
#include "SpellCommon.as";
#include "TeamColour.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	shape.getConsts().mapCollisions = false;
	
	this.Tag("barrier");
}

void onTick( CBlob@ this )
{
	if (this is null)
	{return;}

	if (this.getTickSinceCreated() < 1)
	{		
		this.getSprite().PlaySound("EnergySound1.ogg", 1.0f, 1.0f);	
		this.server_SetTimeToDie(9999);
		
		CSprite@ sprite = this.getSprite();
		sprite.getConsts().accurateLighting = false;
		sprite.setRenderStyle(RenderStyle::additive);
		sprite.SetRelativeZ(888);
	}

	f32 maxHealth = this.getInitialHealth();
	if (this.getHealth() < maxHealth)
	{
		this.server_SetHealth(maxHealth);
	}

	CBlob@ ownerBlob = getBlobByNetworkID(this.get_u16("ownerNetID"));

	if (ownerBlob is null)
	{
		this.server_Die();
		return;
	}

	CMap@ map = getMap(); //standard map check
	if (map is null)
	{return;}

	Vec2f blobPos = ownerBlob.getPosition() + Vec2f(0.0f,-2.0f);
	
	f32 barrierHeight = (blobPos.y - (8 * 15));
	f32 maxBarrierHeight = (map.tilemapheight * 0.15f); //max height is basically 85% of the map's height

	if (barrierHeight < maxBarrierHeight) //do not let it go to space, aiight
	{
		barrierHeight = maxBarrierHeight;
	}

	Vec2f targetPos = Vec2f(blobPos.x, barrierHeight); //position over the flag

	this.setPosition( targetPos );
	this.setAngleDegrees(0);

	this.setVelocity(Vec2f_zero);
	this.setAngularVelocity(0);
}

void onDie(CBlob@ this)
{
	//counterSpell( this );
	
	shieldSparks(this.getPosition(), 30, this.getAngleDegrees(), this.getTeamNum());
	
	this.getSprite().PlaySound("EnergySound2.ogg", 1.0f, 1.0f);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;

	this.getSprite().PlaySound("/build_wood.ogg");
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return
	(	
		!target.hasTag("dead") 
		&& target.getTeamNum() != this.getTeamNum() 
	);
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
	return ( isEnemy( this, b ) );
}

Random _sprk_r(32432);
void shieldSparks(Vec2f pos, int amountPerFan, f32 orientation, int teamNum)
{
	if ( !getNet().isClient() )
		return;
	
	f32 fanAngle = 10.0f;
	for (int i = 0; i < amountPerFan; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 4.0f, 0);
        vel.RotateBy(orientation - fanAngle/2.0f + _sprk_r.NextFloat()*fanAngle);
		
		SColor col = getTeamColor(teamNum);
		
        CParticle@ p = ParticlePixel( pos, vel, col, true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(30);
        p.scale = 1.0f + _sprk_r.NextFloat();
        p.damping = 0.97f;
		p.gravity = Vec2f(0,0);
		p.collides = false;
		p.Z = 510.0f;
    }
	for (int i = 0; i < amountPerFan; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 4.0f, 0);
        vel.RotateBy(orientation + 180.0f - fanAngle/2.0f + _sprk_r.NextFloat()*fanAngle);
		
		SColor col = getTeamColor(teamNum);
		
        CParticle@ p = ParticlePixel( pos, vel, col, false );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(30);
        p.scale = 1.0f + _sprk_r.NextFloat();
        p.damping = 0.97f;
		p.gravity = Vec2f(0,0);
		p.collides = false;
		p.Z = 510.0f;
    }
}