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
	
	sparks(this.getPosition(), 1, this);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	this.getSprite().PlaySound("forceofnature_bounce.ogg", 0.6f, 1.0f + XORRandom(3)/10.0f);
	sparks(this.getPosition(), 20, this);
	
	if( blob !is null )
	{
		Vec2f bPos = blob.getPosition();
		this.server_Hit(blob, bPos, bPos-this.getPosition(), 40.0f, Hitters::explosion, true);
	} 
}

void onDie(CBlob@ this)
{
	sparks(this.getPosition(), 30,this);
}

Random _sprk_r(1265);
void sparks(Vec2f Pos, int amount, CBlob@ this)
{
	if ( !getNet().isClient() )
		return;

	CParticle@[] particleList;
	this.get("ParticleList",particleList);
	for(int a = 0; a < 3; a++)
	{	
		CParticle@ p = ParticlePixelUnlimited(-getRandomVelocity(0,10,360) + Pos, Vec2f(0,0),SColor(255,0,255,0),
			true);
		if(p !is null)
		{
			p.fastcollision = true;
			p.gravity = Vec2f(0,0);
			p.bounce = 1;
			p.lighting = false;
			p.timeout = 90;

			particleList.push_back(p);
		}
	}
	for(int a = 0; a < particleList.length(); a++)
	{
		CParticle@ particle = particleList[a];
		//check
		if(particle.timeout < 1)
		{
			particleList.erase(a);
			a--;
			continue;
		}

		//Gravity
		Vec2f tempGrav = Vec2f(0,0);
		tempGrav.x = -(particle.position.x - Pos.x);
		tempGrav.y = -(particle.position.y - Pos.y);


		//Colour
		SColor col = particle.colour;
		col.setGreen(col.getGreen() - 1);
		col.setBlue(col.getBlue() + 1);

		//set stuff
		particle.colour = col;
		particle.forcecolor = col;
		particle.gravity = tempGrav / 20;//tweak the 20 till your heart is content

		//particleList[a] = @particle;

	}
	this.set("ParticleList",particleList);
}
