#include "Hitters.as";
#include "ArcherCommon.as";
#include "SpellCommon.as";

const f32 arrowMediumSpeed = 8.0f;
const f32 arrowFastSpeed = 13.0f;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
	consts.bullet = false;
	this.Tag("projectile");
	this.Tag("counterable");
	shape.SetGravityScale( 0.05f );

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

    this.server_SetTimeToDie(10);
}

void onTick(CBlob@ this)
{
    CShape@ shape = this.getShape();

    f32 angle;
	//prevent leaving the map
	
	Vec2f pos = this.getPosition();
	if (
		pos.x < 0.1f ||
		pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f
	) {
		this.server_Die();
		return;
	}
        angle = (this.getVelocity()).Angle();
		this.setAngleDegrees(-angle);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	if (blob !is null && this !is null)
	{
		float blastStr = this.get_f32("blastStr");
		if (isEnemy(this, blob))
		{
			if (blob.hasTag("barrier"))
			{
				//Vec2f selfPos = this.getPosition();
				//Vec2f othPos = blob.getPosition();
				//Vec2f kickDir = othPos - selfPos;
				Vec2f kickDir = this.getVelocity();
				kickDir.Normalize();
				kickDir *= (2500.0f * blastStr);
				kickDir += Vec2f(0,-1);
				blob.AddForceAtPosition(kickDir, this.getPosition());
				this.getSprite().PlaySound("bunkerbust.ogg", 100.0f);
				
				if ( isClient() ) //temporary Counterspell effect
				{
					CParticle@ pb = ParticleAnimated( "Shockwave3WIP.png",
						this.getPosition(),
						Vec2f(0,0),
						float(XORRandom(360)),
						0.25f, 
						2, 
						0.0f, true );    
					if ( pb !is null)
					{
						pb.bounce = 0;
    					pb.fastcollision = true;
						pb.Z = -10.0f;
					}
				}
				this.server_Die();
			}
		}
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return 
	(
		(
			target.hasTag("barrier") ||
			(
				target.hasTag("flesh") 
				&& !target.hasTag("dead") 
				&& (friend is null
					|| friend.getTeamNum() != this.getTeamNum()
					)
			)
		)
		&& target.getTeamNum() != this.getTeamNum() 
	);
}