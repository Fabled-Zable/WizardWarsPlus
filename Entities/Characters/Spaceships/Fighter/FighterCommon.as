//Fighter Include

#include "MagicCommon.as";

namespace FighterParams
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
	const ::s32 MAX_MANA = 300;
	const ::s32 MANA_REGEN = 5;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};

	const ::Spell[] spells = 
	{
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
			
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
			
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
			 
		Spell("disruption_wave", "Disruption Wave", 51, "Unleash a destructive burst of warping energy, tearing apart anything in its path.",
				SpellType::other, 30, 30, 2, 360.0f, true),
			 
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellType::other, 10, 10, 0, 8.0f, true),
			 
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
			 
		Spell("voltage_field", "Voltage Field", 54, "Releases a bubble of electricity that knocks away projectiles and enemies that collide with it. Cannot cast spells while active.",
				SpellType::other, 15, 60, 6, 1.0f),
			
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

class FighterInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;
	u8 pulse_amount;

	// ship general
	f32 main_engine_force;
	f32 secondary_engine_force;
	f32 rcs_force;
	u32 ship_turn_speed; // degrees per tick, 0 = instant (30 ticks a second)
	u32 firing_rate; // ticks per shot, won't fire if 0
	u32 firing_burst; // bullets per shot, won't fire if 0
	u32 firing_delay; // ticks before first shot
	u32 firing_spread; // degrees
	f32 shot_speed; // pixels per tick, 0 = instant
	f32 max_speed; // 0 = infinite speed

	FrigateInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
		pulse_amount = 3;

		//ship general
		main_engine_force = 3.0f;
		secondary_engine_force = 2.0f;
		rcs_force = 1.0f;
		ship_turn_speed = 1;
		firing_rate = 1;
		firing_burst = 1;
		firing_delay = 1;
		firing_spread = 1;
		shot_speed = 3.0f;
		max_speed = 200.0f;
	}
};