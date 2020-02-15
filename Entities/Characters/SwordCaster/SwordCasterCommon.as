//SwordCaster Include

#include "MagicCommon.as";

namespace SwordCasterParams
{
	enum Aim 
		{
			not_aiming = 0,
			charging,
			cast_1,
			cast_2,
			cast_3,
			extra_ready,
		}

	const ::f32 shoot_max_vel = 8.0f;
	const ::f32 MAX_ATTACK_DIST = 360.0f;
	const ::s32 MAX_MANA = 150;
	const ::s32 MANA_REGEN = 5;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};
	
	const ::Spell[] spells = 
	{
		Spell("orb", "Orb", 6, "Fire a basic orb which ricochets off of most surfaces until impacting an enemy and exploding, dealing minor damage.",
			SpellType::other, 2, 40, 0, 360.0f),
							// 2 is the cost // 40 is the charge time //360.0f is the range //the 0 is the cooldown //6 is the icon it uses
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellType::other, 25, 6, 0, 270.0f, true), 
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellType::other, 30, 10, 0, 8.0f, true),
			
		Spell("executioner", "Executioner", 43, "New sword Execution spell.",
				SpellType::other, 40, 30, 0, 360.0f, true),
			
		Spell("crusader", "Crusader", 42, "New sword blockading spell.",
				SpellType::other, 20, 30, 0, 360.0f, true),
			
		Spell("sword_cast", "Expunger", 41, "New sword throwing spell.",
				SpellType::other, 30, 30, 0, 360.0f,true),
			 
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
			 
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
			 
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
			 
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
			 
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
			
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
			 
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
			
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),			
				
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f)						
	};
}

class SwordCasterInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;

	SwordCasterInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
	}
}; 