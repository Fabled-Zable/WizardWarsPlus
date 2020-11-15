#include "EntropistCommon.as"
#include "PlayerPrefsCommon.as"
#include "MagicCommon.as"
#include "KnockedCommon.as"
#include "Hitters.as"
#include "RunnerCommon.as"
#include "SpellCommon.as"

void onInit( CBlob@ this)
{
	this.set_u16("ticksPassed",0);
}

void onTick( CBlob@ this )
{
	if(!this.get_bool("burnState"))
	{
		return;
	}

	ManaInfo@ manaInfo;
	if (!this.get( "manaInfo", @manaInfo )) 
	{
		return;
	}
	
	manaInfo.mana -= 1;
	
	if(manaInfo.mana < 1)
	{
		s32 OG_manaRegen = this.get_s32("OG_manaRegen");
		if(OG_manaRegen >= 1)
		{
			this.set_s32("OG_manaRegen",OG_manaRegen - 1);
		}

		this.set_bool("burnState", false);
		
		return;
	}
}