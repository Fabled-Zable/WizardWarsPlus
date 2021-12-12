//There is no cfg file associated with this because it isn't a blob :D
#include "Hitters.as"//we need this so we can use the enums which allows for more readable code


void onTick(CBlob@ this)
{
	if(!this.exists("shellSetupDone") || !this.get_bool("shellSetupDone"))//this is done instead of using onInit becuase onInit only runs once even if this script is removed and added again
	{
		this.set_u32("timeActive",(10*30) + getGameTime());//10 seconds from now
		this.set_f32("effectRadius",8*2);// 2 block radius
		this.set_u32("attackRate",15); // half a second
		this.getSprite().AddScript("BladedShell.as");//need to do this to get the sprite hooks to run

		this.set_bool("shellSetupDone",true);
	}

	if(this !is null)
	{
	if(this.hasTag("dead") ) //removes script if user dies
	{cleanUp(this);}
	}

	u16 timeActive = this.get_u32("timeActive");
	f32 effectRadius = this.get_f32("effectRadius");
	if(timeActive < getGameTime())//remove script if we are past the active time
	{
		if(this !is null)
		{
			cleanUp(this);
		}
	}

	

	CMap@ map = getMap(); //going to need map in order to see what blobs are in the radius
	CBlob@[] blobs;//blob handle array to store blobs we want to effect

	map.getBlobsInRadius(this.getPosition(),effectRadius, @blobs);//get the blobs

	for(s32 i = 0; i < blobs.length(); i++)//itterate through blobs
	{
		CBlob@ other = @blobs[i];//setting other blob to a variable for readability
		if(other.getTeamNum() == this.getTeamNum()){continue;}//skip over like team numbers
		if(!isEnemy(this,other)){continue;}//if other isn't an enemy then we don't need to do anything to it
		
		if(!other.exists("BladedShellCooldown" + other.getNetworkID()) || (other.get_u32("BladedShellCooldown" + other.getNetworkID()) < getGameTime()))
		{
			u32 attackRate = this.get_u32("attackRate"); //gets hit delay
			this.server_Hit(other, other.getPosition(), Vec2f(0,0),0.6f,Hitters::hits::sword);// hit em
			other.set_u32("BladedShellCooldown" + other.getNetworkID(), getGameTime() + attackRate);//a second between hits

			Vec2f norm = (this.getPosition() - other.getPosition()) * -1;
			norm.Normalize();
			
			if(other.hasTag("barrier") && other.getName() != "shard") //Knockback System against barriers
			{
				CBlob@ self = this;
				Vec2f selfPos = self.getPosition();
				Vec2f othPos = other.getPosition();
				Vec2f kickDir = selfPos - othPos;
				kickDir.Normalize();
				kickDir *= 11.0f;
				kickDir += Vec2f(0,-1);
				this.server_Hit(self, self.getPosition(), Vec2f(0,0),0.2f,Hitters::hits::sword);
				this.setVelocity(this.getVelocity() + kickDir);
			}
			//ParticleAnimated("Knife.png", this.getPosition(), norm ,norm.getAngle(),1,RenderStyle::Style::normal,0, Vec2f(16,16),0,0, true);//ahh doesn't work, good enough without it
		}
	}
}

void onTick(CSprite@ this)
{
	CBlob@ b = this.getBlob();
	if(!b.exists("shellSpriteSetupDone") || !b.get_bool("shellSpriteSetupDone"))
	{
		for(int i = 0; i < 360; i += 45)//makes 8
		{
			CSpriteLayer@ layer = this.addSpriteLayer("knife" + i,"Knife.png",13,4,b.getTeamNum(),0);
		}
		b.set_bool("shellSpriteSetupDone",true);
	}

	for(int i = 0; i < 360; i += 45)//makes 8
	{
		CSpriteLayer@ layer = this.getSpriteLayer("knife" + i);
		layer.ResetTransform();
		f32 r = getGameTime() * 4 + i;
		Vec2f angle = Vec2f(1,0).RotateByDegrees(r);
		layer.RotateBy(r + 180,Vec2f_zero);
		layer.SetOffset(angle * 12);//block and a half

		layer.SetFacingLeft(true);

		CParticle@ p = ParticlePixelUnlimited(
			layer.getOffset() * 1.5 + b.getInterpolatedPosition(), //position
			b.getVelocity() + Vec2f(XORRandom(2) == 1 ? 0.1 : -0.1,XORRandom(10)/10.0),// velocity
			 SColor(255,255,225,225),//color
			  true);//self lit
		if(p !is null)
		{
			p.fastcollision = true;
			p.gravity = Vec2f(0,-0.1);
			p.bounce = 1;
			p.lighting = false;
			p.timeout = XORRandom(30);
			p.damping = 0.75;
		}
	}

	if(b.hasTag("doubleBlade")) //if activated twice, second layer of knives
	{
		if(!b.exists("spriteSetupDone2") || !b.get_bool("spriteSetupDone2"))
		{
			for(int h = 0; h < 360; h += 45)//makes 8
			{
				CSpriteLayer@ layer = this.addSpriteLayer("2knife" + h,"Knife.png",13,4,b.getTeamNum(),0);
			}
			b.set_bool("spriteSetupDone2",true);
		}

		for(int h = 0; h < 360; h += 45)
		{
			CSpriteLayer@ layer = this.getSpriteLayer("2knife" + h);
			layer.ResetTransform();
			f32 r = getGameTime() + h;
			Vec2f angle = Vec2f(1,0).RotateByDegrees(r);
			layer.RotateBy(-r + 180,Vec2f_zero);
			layer.SetOffset(angle * 24);//three blocks

			layer.SetFacingLeft(false);
		}
	}
}

void cleanUp(CBlob@ this)//because we don't use onInit we need to cleanup so that the script is ready for when it is added again
{
	for(int i = 0; i < 360; i += 45)
	{
		this.getSprite().RemoveSpriteLayer("knife" + i);
	}

	if(this.hasTag("doubleBlade"))
	{
		for(int h = 0; h < 360; h += 45)
		{
		this.getSprite().RemoveSpriteLayer("2knife" + h);
		}
	}

	if(this.hasTag("doubleBlade"))
	{
		this.Untag("doubleBlade");
	}

	this.set_bool("shellSetupDone",false);
	this.set_bool("shellSpriteSetupDone",false);
	this.set_bool("spriteSetupDone2",false);
	this.getSprite().RemoveScript("BladedShell.as");
	this.RemoveScript("BladedShell.as");

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