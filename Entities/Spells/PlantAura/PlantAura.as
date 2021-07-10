#include "SpellCommon.as";
#include "TeamColour.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	shape.getConsts().mapCollisions = false;
	shape.getConsts().collidable = false;
	
	this.Tag("counterable");

	this.set_u8("frame",0);
	this.set_u8("randomParticleRotation",XORRandom(90));
}

float effectRadius = 8*10;

void onTick( CBlob@ this )
{
	if(this.get_u8("frame") < 38 && getGameTime() % 3 == 0)
	{
		this.getSprite().SetFrame(this.add_u8("frame",1));
	}


	if (this.getTickSinceCreated() < 1)
	{		
		//this.getSprite().PlaySound("rock_hit3.ogg", 1.0f, 1.0f);	
		this.server_SetTimeToDie(this.get_u16("lifetime"));
		
		CShape@ shape = this.getShape();
		shape.SetStatic(true);
		
		CSprite@ sprite = this.getSprite();
		sprite.SetRelativeZ(1000);
	}

	CMap@ map = getMap();
	CBlob@[] blobs;
	map.getBlobsInRadius(this.getPosition(),effectRadius,@blobs);

	if(getGameTime() % 30 == 0)
	{
		for(int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			if(b.getPlayer() !is null && b.getTeamNum() == this.getTeamNum())
			{
				f32 initHealth = b.getInitialHealth();
				f32 health = b.getHealth();

				if(health + 0.1 < initHealth)
				{
					b.server_SetHealth(health + 0.1);
					if(b.getPlayer() !is null && b.getPlayer() is getLocalPlayer())
					{
						SetScreenFlash(50,0,255,0,0.75f);
					}
				}
				else b.server_SetHealth(initHealth);
			}
		}
	}
	

}

void onInit(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	CMap@ map = getMap();

	for(int i = 0; i < 6; i++)
	{
		Vec2f pos = blob.getPosition() - Vec2f(-20 + (i * 8),0);
		if(!map.isTileSolid(pos) && map.isTileSolid(pos + Vec2f(0,8)) )
		{
			CSpriteLayer@ s = this.addSpriteLayer("" + i,"plant_aura2.png",10,18);
			s.SetOffset(Vec2f(-20 + (i * 8),0));
			s.SetRelativeZ(i);
		}
	}

	for(int i = 0; i < 10; i++)
	{	
		CSpriteLayer@ s = this.addSpriteLayer("flower" + i,"Flowers.png",16,16,XORRandom(6),0);
		int xOff = XORRandom(effectRadius) - effectRadius/2;
		s.SetOffset(Vec2f(xOff,7) );
		s.SetFrame(XORRandom(3) +4);
		s.SetRelativeZ(-1 * i);
	}
}

void onTick(CSprite@ this)
{
	if(!isClient())
	{return;}
	
	this.SetVisible(false);

	for(int i = 0; i < 6; i ++)
	{
		CSpriteLayer@ s = this.getSpriteLayer(i + "");
		if(s !is null)
			s.SetFrame(this.getBlob().get_u8("frame"));
	}

	for(int i = 0; i < 10; i++)
	{
		CSpriteLayer@ s = this.getSpriteLayer("flower" + i);
		s.SetOffset(s.getOffset() + Vec2f(0,XORRandom(2) == 0 ? 0.05 : -0.05 ) );
	}

	CBlob@ blob = this.getBlob();
	if(blob is null)
	{return;}
	
	Vec2f blobPos = blob.getPosition();

	uint16 gameTime = getGameTime();
	uint16 timeRotation = (gameTime % 90)*4;
	uint8 randomExtraRotation = blob.get_u8("randomParticleRotation");

	SColor color = SColor(255,XORRandom(191),255,XORRandom(191));

	for(int i = 0; i < 2; i++)
	{
		float pFinalRotation = timeRotation + randomExtraRotation;
		pFinalRotation += 180*i;
		Vec2f pPos = blobPos + Vec2f_lengthdir(effectRadius,pFinalRotation);//game time gets rid of some gaps and can add a rotation effect
		Vec2f pVel = blobPos - pPos;
		pVel.Normalize();

		CParticle@ p = ParticlePixelUnlimited( pPos , pVel*1.8f , color , true );
		if(p !is null)
		{
			p.timeout = 60;
			p.gravity = Vec2f_zero;
			//p.damping = 0.95;
			p.collides = false;
			p.fastcollision = true;
			p.bounce = 0;
			p.lighting = false;
			p.Z = -20;
		}
	}

	if(gameTime % 15 == 0)
	{
		for(int i = 0; i < 180; i++)
		{
			color = SColor(255,XORRandom(191),255,XORRandom(191));
			Vec2f pbPos = blobPos + Vec2f_lengthdir(effectRadius,i*2);//game time gets rid of some gaps and can add a rotation effect
			CParticle@ pb = ParticlePixelUnlimited( pbPos , Vec2f_zero , color , true );
			if(pb !is null)
			{
				pb.timeout = 30;
				pb.gravity = Vec2f_zero;
				pb.damping = 0.9;
				pb.collides = false;
				pb.fastcollision = true;
				pb.bounce = 0;
				pb.lighting = false;
				pb.Z = 500;
			}
		}
	}
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;

	//this.getSprite().PlaySound("/build_wood.ogg");
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return ( !target.hasTag("dead") 
		&& target.getTeamNum() != this.getTeamNum() 
		&& (friend is null
			|| friend.getTeamNum() != this.getTeamNum()
		)
	);
}
