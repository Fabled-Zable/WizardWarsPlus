//There is no cfg file associated with this because it isn't a blob :D
#include "Hitters.as"//we need this so we can use the enums which allows for more readable code
#include "SpellHashDecoder.as"

const uint8 attackRate = 2; //hit rate for voltage field

void onTick(CBlob@ this)
{
	if( this is null )
	{return;}

	if(!this.exists("voltageSetupDone") || !this.get_bool("voltageSetupDone"))//this is done instead of using onInit becuase onInit only runs once even if this script is removed and added again
	{
		this.set_u32("remainingTime",(5*30) + getGameTime());//5 seconds from now
		this.set_f32("effectRadius",9.7f);// increasing radius
		this.getSprite().AddScript("VoltageField.as");//need to do this to get the sprite hooks to run

		this.set_bool("voltageSetupDone",true);
	}

	u16 remainingTime = this.get_u32("remainingTime");

	if(this.hasTag("dead") || remainingTime < getGameTime()) //removes script if user dies or we are past the active time
	{
		cleanUp(this);
		return;
	}

	f32 effectRadius = this.get_f32("effectRadius");
	effectRadius *= 1.01f;
	this.set_f32("effectRadius",effectRadius);

	if ( getGameTime() % attackRate != 0 )
	{return;}

	CMap@ map = getMap(); //standard map check
	if(map is null)
	{return;}

	Vec2f thisPos = this.getPosition();
	CBlob@[] blobs;//blob handle array to store blobs we want to effect
	map.getBlobsInRadius(thisPos,effectRadius, @blobs);//get the blobs

	for(s32 i = 0; i < blobs.length(); i++)//itterate through blobs
	{
		CBlob@ target = blobs[i]; //standard null check for blobs in radius
		if (target is null)
		{continue;}

		if(target.getTeamNum() == this.getTeamNum()){continue;}//skip over same team entities
		if(!tagCheck(target)){continue;}//if target fails tag checks, skip

		float damage = 0.4f;
		Vec2f norm = (target.getPosition() - thisPos);
		norm.Normalize();

		if (target.hasTag("counterable"))
		{
			Vec2f targetVel = target.getVelocity();
			if(targetVel != Vec2f_zero)
			{
				Vec2f targetNorm = targetVel;
				targetNorm.Normalize();
				float direcAngle = norm.getAngleDegrees();
				float targetAngle = targetNorm.getAngleDegrees();
				float difference = targetAngle-direcAngle;
				if (difference > 90 || difference < -90)
				{
					targetVel.RotateByDegrees(difference);
					target.setVelocity(targetVel);
				}
				damage = 0.6;
			}
		}

		if (voltageFieldDamage(target))
		{
			this.server_Hit(target, target.getPosition(), norm*3,damage,Hitters::explosion);// hit em
		}
	}
}

void onTick(CSprite@ this)
{
	CBlob@ b = this.getBlob();
	if(b is null)
	{return;}

	if(!b.exists("voltageSpriteSetupDone") || !b.get_bool("voltageSpriteSetupDone"))
	{
		CSpriteLayer@ layer = this.addSpriteLayer("sphere","active_sphere.png",128,128);
		
		b.set_bool("voltageSpriteSetupDone",true);
		layer.ScaleBy(Vec2f(0.15f,0.15f));
		layer.setRenderStyle(RenderStyle::additive);
	}
	
	CSpriteLayer@ layer = this.getSpriteLayer("sphere");
	layer.ResetTransform();
	{layer.SetFrame(layer.getFrame()+1);}
	layer.ScaleBy(Vec2f(1.01f,1.01f));

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
	if(this is null || this.getSprite() is null)
	{
		return;
	}

	if(this.getSprite().getSpriteLayer("sphere") !is null)
	{
		this.getSprite().RemoveSpriteLayer("sphere");
	}

	this.set_bool("voltageSetupDone",false);
	this.set_bool("voltageSpriteSetupDone",false);
	this.getSprite().RemoveScript("VoltageField.as");
	this.RemoveScript("VoltageField.as");
}

bool tagCheck( CBlob@ target )
{
	return 
	(
		target.hasTag("barrier")
		||
		target.hasTag("flesh") 
		||
		target.hasTag("counterable") 
	);
}