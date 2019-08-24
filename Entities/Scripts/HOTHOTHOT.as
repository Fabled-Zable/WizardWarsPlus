//Get stuck running forward/backward based on facing direction
//make sure this goes before the actual mover code in execution order

#include "FireCommon.as";

void onInit(CMovement@ this)
{
	this.getCurrentScript().tickIfTag = burning_tag;
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CMovement@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.getHealth() > 0.0f)
	{
		if (blob.hasTag(burning_tag)) //double check
		{
			MovementVars@ vars = this.getVars();

			if (XORRandom(200) == 0)
			{
				blob.getSprite().PlaySound("/MigrantScream");
			}
		}
	}
}
