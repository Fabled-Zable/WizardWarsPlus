//There is no cfg file associated with this because it isn't a blob :D
#include "Hitters.as"//we need this so we can use the enums which allows for more readable code
#include "SpellHashDecoder.as"


void onTick(CBlob@ this)
{
	if(!this.exists("setupDone") || !this.get_bool("setupDone"))//this is done instead of using onInit becuase onInit only runs once even if this script is removed and added again
	{
		this.set_u32("remainingTime",(5*30) + getGameTime());//5 seconds from now
		this.set_u32("timeActive", 0); //counter system
		this.set_f32("effectRadius",9.6f);// increasing radius
		this.set_u32("attackRate",2);
		this.getSprite().AddScript("VoltageField.as");//need to do this to get the sprite hooks to run

		this.set_bool("setupDone",true);
	}

	u32 timeActive = this.get_u32("timeActive");

	if(this !is null)
	{
		if(this.hasTag("dead") ) //removes script if user dies
		{cleanUp(this);}
	}

	u16 remainingTime = this.get_u32("remainingTime");
	if(remainingTime < getGameTime())//remove script if we are past the active time
	{
		if(this !is null)
		{
			cleanUp(this);
		}
	}


	f32 effectRadius = this.get_f32("effectRadius");
	effectRadius *= 1.01f;
	this.set_f32("effectRadius",effectRadius);

	u32 attackRate = this.get_u32("attackRate"); //gets hit delay
	if ( getGameTime() % attackRate != 0 )
	{return;}
	CMap@ map = getMap(); //going to need map in order to see what blobs are in the radius
	CBlob@[] blobs;//blob handle array to store blobs we want to effect

	map.getBlobsInRadius(this.getPosition(),effectRadius, @blobs);//get the blobs

	for(s32 i = 0; i < blobs.length(); i++)//itterate through blobs
	{
		CBlob@ target = @blobs[i];//setting target blob to a variable for readability
		if(target is null){continue;}
		if(target.getTeamNum() == this.getTeamNum()){continue;}//skip over like team numbers
		if(!isEnemy(this,target)){continue;}//if target isn't an enemy then we don't need to do anything to it

		float damage = 0.4f;
		Vec2f norm = (target.getPosition() - this.getPosition());
		norm.Normalize();

		if (target.hasTag("counterable"))
		{
			Vec2f targetVel = target.getVelocity();
			Vec2f targetNorm = targetVel;
			targetNorm.Normalize();
			float direcAngle = norm.getAngle();
			float targetAngle = targetNorm.getAngle();
			float difference = targetAngle-direcAngle;
			if (difference > 90 || difference < -90)
			{
				targetVel.RotateByDegrees(difference);
				target.setVelocity(targetVel);
			}
			damage = 0.6;
		}

		if (voltageFieldDamage(target))
		{
			this.server_Hit(target, target.getPosition(), norm*3,damage,Hitters::water);// hit em
		}
		
	}

	timeActive++;
	this.set_u32("timeActive", timeActive); //counts up by 1
}

void onTick(CSprite@ this)
{
	CBlob@ b = this.getBlob();
	if(!b.exists("sphereSetupDone") || !b.get_bool("sphereSetupDone"))
	{
		CSpriteLayer@ layer = this.addSpriteLayer("sphere","active_sphere.png",128,128);
		
		b.set_bool("sphereSetupDone",true);
		layer.ScaleBy(Vec2f(0.15f,0.15f));
	}

	
	CSpriteLayer@ layer = this.getSpriteLayer("sphere");
	layer.ResetTransform();
	layer.setRenderStyle(RenderStyle::additive);
	{layer.SetFrame(layer.getFrame()+1);}
	layer.ScaleBy(Vec2f(1.01f,1.01f));
	layer.SetFacingLeft(true);

	CParticle@ p = ParticlePixelUnlimited(
		b.getInterpolatedPosition(), //position
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

void cleanUp(CBlob@ this)//because we don't use onInit we need to cleanup so that the script is ready for when it is added again
{
	this.getSprite().RemoveSpriteLayer("sphere");

	this.set_bool("setupDone",false);
	this.set_bool("sphereSetupDone",false);
	this.getSprite().RemoveScript("VoltageField.as");
	this.RemoveScript("VoltageField.as");
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		(
			target.hasTag("barrier")
			||
			target.hasTag("flesh") 
			||
			target.hasTag("counterable") 
		)
		&& target.getTeamNum() != this.getTeamNum() 
	);
}