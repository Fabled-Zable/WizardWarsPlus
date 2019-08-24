#include "/Entities/Common/Attacks/Hitters.as";	   
#include "/Entities/Common/Attacks/LimitedAttacks.as";

void onInit(CBlob@ this)
{
	this.Tag("kill other spells");
	//this.Tag("counterable");
	
	this.getShape().SetGravityScale(0.0f);
	this.server_SetTimeToDie(14);
	this.SetLight(true);
	this.SetLightRadius(24.0f);
	this.SetLightColor(SColor(255, 0, 255, 0));
	
	CSprite@ thisSprite = this.getSprite();
	thisSprite.SetZ(500.0f);
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	
	this.getShape().getConsts().bullet = true;
}

void onTick(CBlob@ this)
{
	if ( this.getTickSinceCreated() == 1 )
		this.getSprite().PlaySound("forceofnature_cast.ogg", 2.0f);

	/*
	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius(this.getPosition(), 8.0f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if ( b !is this )
				this.server_Hit(b, b.getPosition(), Vec2f(0,0), 20.0f, Hitters::explosion, true);
			
			if ( isEnemy(this, b) )
			{
				
			}
		}
	}
	*/
	
	sparks(this.getPosition(), 1);
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return 
	(
		( target.getTeamNum() != this.getTeamNum() && (target.hasTag("kill other spells") || target.hasTag("door") || target.getName() == "trap_block") )
		||
		(
			target.hasTag("flesh") 
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
			&& ( friend is null || friend.getTeamNum() != this.getTeamNum() )
		)
	);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	this.getSprite().PlaySound("forceofnature_bounce.ogg", 0.6f, 1.0f + XORRandom(3)/10.0f);
	sparks(this.getPosition(), 20);
	
	if( blob !is null )
	{
		Vec2f bPos = blob.getPosition();
		this.server_Hit(blob, bPos, bPos-this.getPosition(), 40.0f, Hitters::explosion, true);
	} 
}

void onDie(CBlob@ this)
{
	sparks(this.getPosition(), 30);
}

Random _sprk_r(1265);
void sparks(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 2.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixel( pos, vel, SColor( 255, 128+_sprk_r.NextRanged(128), 255, _sprk_r.NextRanged(128)), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.97f;
		p.gravity = Vec2f(0,0);
		p.Z = 510.0f;
    }
}
