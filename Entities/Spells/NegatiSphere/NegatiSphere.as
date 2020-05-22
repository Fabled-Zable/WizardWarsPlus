#include "Hitters.as";
#include "MakeDustParticle.as";

void onInit( CBlob@ this )
{
	this.Tag("projectile");
	this.Tag("counterable");
	this.set_bool("launch", false);

    this.getShape().SetGravityScale( 0.0f );
	this.getShape().getConsts().mapCollisions = false;
	this.getSprite().SetZ(1450);// draw over ground
    this.server_SetTimeToDie(60);

    this.SetLight( true );
	this.SetLightRadius( 32.0f );
}	

void onTick( CBlob@ this )
{     
	if(this.getCurrentScript().tickFrequency == 1)
	{
		this.getSprite().PlaySound("SpriteFire1.ogg", 0.2f, 1.5f + XORRandom(10)/10.0f);
		// done post init
		this.getCurrentScript().tickFrequency = 2;
	}

	if(!this.get_bool("launch"))
	{
		CPlayer@ p = this.getDamageOwnerPlayer();
		if( p !is null)	{
			CBlob@ b = p.getBlob();
			if( b !is null)	{
				if(b.get_bool("shifting"))
				{
					this.set_Vec2f("target", b.getAimPos());
					this.set_bool("launch", true);
				}
				else
				{
					this.set_Vec2f("target", b.getPosition());
				}
			}
			else
			{
				this.server_Die();
			}
		}
	}
	
	
	Vec2f vel = this.getVelocity();
	
	if(this.get_bool("launch") && !this.hasTag("cruiseMode"))
	{
		Vec2f dir = this.get_Vec2f("target")-this.getPosition();
		dir.Normalize();
		this.setVelocity(Vec2f_zero);
		this.set_Vec2f("dir", dir);
		this.Tag("cruiseMode");
		this.server_SetTimeToDie(5);
	}

	if(!this.get_bool("launch"))
	{
		Vec2f dir = this.get_Vec2f("target")-this.getPosition();
		dir.RotateBy(30);
		dir.Normalize();
		this.set_Vec2f("dir", dir);
	}

	Vec2f finaldir = this.get_Vec2f("dir");
	float dirmult = this.hasTag("cruiseMode") ? 1.0f : 0.35;
	vel += finaldir * dirmult;
	this.setVelocity(vel);

}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		target != null
		&& target.hasTag("counterable") //all counterables
		&& !target.hasTag("dead") 
		&& target.getTeamNum() != this.getTeamNum() //as long as they're on the enemy side
		&& !target.hasTag("black hole")  //as long as it's not a black hole, go as normal.
	);
}	

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
	if(b is null){return false;}

	return 
	(
		isEnemy(this, b)
		|| b.getName() == this.getName()//collides with enemy counterable blobs and also itself.
	); 
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
		this.getSprite().PlaySound("SpriteFire3.ogg", 0.05f, 0.5f + XORRandom(10)/20.0f);
		if(blob is null){return;}
		if( isEnemy( this , blob ) ) //will not affect same team negatispheres
		{
			if ( isClient() ) //temporary Counterspell effect
			{
				Vec2f dispelPos = this.getPosition();
				CParticle@ p = ParticleAnimated( "Flash2.png",
						dispelPos,
						Vec2f(0,0),
						0,
						0.25f, 
						8, 
						0.0f, true ); 	
										
				if ( p !is null)
				{
					p.bounce = 0;
    				p.fastcollision = true;
					p.Z = 600.0f;
				}
				CParticle@ pb = ParticleAnimated( "Shockwave2.png",
						dispelPos,
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
				this.getSprite().PlaySound("CounterSpell.ogg", 0.8f, 1.0f);
			}

			decreaseLife( this , blob );

			blob.Untag("exploding");
			blob.server_Die();
			if (this.get_s8("lifepoints") <= 0)
			{
				this.server_Die();
			}
		} 
}

void decreaseLife ( CBlob@ this , CBlob@ b )
{
	if(this is null){return;}
	if(b is null){return;}
	string blobname = b.getName();
	s8 life = this.get_s8("lifepoints");

	switch(blobname.getHash())
	{
		case 1370376319: //bees
		{
			this.set_s8("lifepoints", (life - 1));
		}
		break;
		case 829656850: //spores
		{
			this.set_s8("lifepoints", (life - 2));
		}
		break;
		case 1463630946: //spikeballs
		{
			this.set_s8("lifepoints", (life - 2));
		}
		break;
		case 1843332075: //ground rock spikes
		{
			this.set_s8("lifepoints", (life - 3));
		}
		break;
		case -825046729: //mushroom
		{
			this.set_s8("lifepoints", (life - 8));
		}
		break;
		case 131361395: //expunger
		{
			this.set_s8("lifepoints", (life - 2));
		}
		break;
		case -1661937901: //impaler
		{
			this.set_s8("lifepoints", (life - 5));
		}
		break;
		case -32608566: //crusader
		{
			this.set_s8("lifepoints", (life - 7));
		}
		break;
		case -1625426670: //orb
		{
			this.set_s8("lifepoints", (life - 4));
		}
		break;
		case -1214504009: //magic missile
		{
			this.set_s8("lifepoints", (life - 6));
		}
		break;
		default: //anything that one-shots it
		{
			this.set_s8("lifepoints", 0);
		}
	}
}