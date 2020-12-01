#include "Hitters.as"
#include "NecromancerCommon.as";
#include "WizardCommon.as";
#include "DruidCommon.as";
#include "SwordCasterCommon.as";
#include "EntropistCommon.as";
#include "TeamColour.as";

#include "FireCommon.as"

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	shape.getConsts().mapCollisions = false;

	this.set_netid("owner",0);
	this.set_s8("shardID",-1);
	this.set_u32("deadTimer",0);
}

void onTick( CBlob@ this )
{
	CBlob@ ownerBlob = getBlobByNetworkID(this.get_netid("owner"));
	if(ownerBlob is null || ownerBlob.hasTag("dead"))
	{
		this.server_Die();
		return;
	}

	CSprite@ sprite = this.getSprite();

	if (this.getTickSinceCreated() < 1)
	{		
		this.getSprite().PlaySound("discharge1.ogg", 1.0f, 1.0f);	
		this.server_SetTimeToDie(3000);
		
		sprite.getConsts().accurateLighting = false;
		sprite.setRenderStyle(RenderStyle::additive);
		sprite.SetRelativeZ(1000);
	}

	u32 deadTimer = this.get_u32("deadTimer");
	if(deadTimer > 0)
	{
		if(sprite.isVisible())
		{
			sprite.SetVisible(false);
		}
		
		this.set_u32("deadTimer", deadTimer-1);
	}
	else if(!sprite.isVisible())
	{
		sprite.SetVisible(true);
	}

	
	CMap@ map = this.getMap();
	Vec2f thisPos = this.getPosition();

	u8 shardAmount = ownerBlob.get_u8("shard_amount");
	if(shardAmount < this.get_s8("shardID"))
	{
		this.server_Die();
	}

}

void onDie(CBlob@ this)
{
	//counterSpell( this );
	
	shieldSparks(this.getPosition(), 30, this.getAngleDegrees(), this.getTeamNum());
	
	if(isClient())
	{
		this.getSprite().PlaySound("EnergySound2.ogg", 0.5f, 1.0f);
	}
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{
	CBlob@ ownerBlob = getBlobByNetworkID(this.get_netid("owner"));
	if(ownerBlob is null || ownerBlob.hasTag("dead"))
	{
		this.server_Die();
		return;
	}

	if(this.get_u32("deadTimer") > 0)
	{return;}

	if(ownerBlob.get_bool("attack"))
	{
		if(blob !is null && blob.hasTag("player") && !blob.hasTag("dead") && isEnemy(this, blob))
		{
			ManaInfo@ manaInfoBlob;
			if (!blob.get( "manaInfo", @manaInfoBlob )) {
				return;
			}

			ManaInfo@ manaInfoCaster;
			if (!ownerBlob.get( "manaInfo", @manaInfoCaster )) {
				return;
			}

			if(manaInfoCaster.mana + 2 > manaInfoCaster.maxMana)
			{
				manaInfoCaster.mana = manaInfoCaster.maxMana;
			}
			else
			{
				manaInfoCaster.mana += 2;
			}

			manaInfoBlob.mana -= 2;
		}
	}
	else
	{
		if(blob !is null && blob.hasTag("counterable") && isEnemy(this, blob))
		{
			Vec2f blobVel = blob.getVelocity();
			blob.setVelocity(-blobVel);
			this.set_u32("deadTimer", 120);
		}
	}
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
	return ( !target.hasTag("dead") 
		&& target.getTeamNum() != this.getTeamNum() 
	);
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
	CBlob@ ownerBlob = getBlobByNetworkID(this.get_netid("owner"));
	if(ownerBlob is null || ownerBlob.hasTag("dead"))
	{
		this.server_Die();
		return false;
	}

	return !ownerBlob.get_bool("attack");
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
