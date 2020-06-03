//Entropist Include

#include "MagicCommon.as";

namespace EntropistParams
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
	const ::s32 MAX_MANA = 200;
	const ::s32 MANA_REGEN = 0;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};

	const ::Spell[] spells = 
	{
		Spell("orb", "Orb", 6, "Fire a basic orb which ricochets off of most surfaces until impacting an enemy and exploding, dealing minor damage.",
			SpellType::other, 3, 20, 0, 360.0f),
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellType::other, 15, 6, 0, 270.0f, true),
			
		Spell("haste", "Haste", 20, "Give your allies some added speed and maneuverability. Fully charge to hasten yourself.",
			SpellType::other, 5, 15, 0, 360.0f, true),
			 
		Spell("disruption_wave", "Disruption Wave", 51, "Empty spell.",
				SpellType::other, 30, 30, 2, 360.0f),
			 
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
				SpellType::other, 1, 1, 0, 0.0f),	
							
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),		

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f)				
	};
}

class EntropistInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;
	u8 pulse_amount;

	EntropistInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
		pulse_amount = 3;
	}
}; 

