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

	// ship general
	const ::f32 main_engine_force = 3.0f;
	const ::f32 secondary_engine_force = 2.0f;
	const ::f32 rcs_force = 1.0f;
	const ::f32 ship_turn_speed = 1.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.1f; // air drag
	//gun general
	const ::u32 firing_rate = 2; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 1; // ticks before first shot
	const ::u32 firing_spread = 1; // degrees
	const ::f32 shot_speed = 3.0f; // pixels per tick, 0 = instant
	const ::f32 max_speed = 200.f; // 0 = infinite speed
}

class SmallshipInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;
	u8 pulse_amount;

	// ship general
	f32 main_engine_force;
	f32 secondary_engine_force;
	f32 rcs_force;
	f32 ship_turn_speed; // degrees per tick, 0 = instant (30 ticks a second)
	f32 ship_drag; // air drag
	//gun general
	u32 firing_rate; // ticks per shot, won't fire if 0
	u32 firing_burst; // bullets per shot, won't fire if 0
	u32 firing_delay; // ticks before first shot
	u32 firing_spread; // degrees
	f32 shot_speed; // pixels per tick, 0 = instant
	f32 max_speed; // 0 = infinite speed

	SmallshipInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
		pulse_amount = 3;

		//ship general
		main_engine_force = 3.0f;
		secondary_engine_force = 2.0f;
		rcs_force = 1.0f;
		ship_turn_speed = 1.0f;
		ship_drag = 0.1f;
		//gun general
		firing_rate = 2;
		firing_burst = 1;
		firing_delay = 1;
		firing_spread = 1;
		shot_speed = 3.0f;
		max_speed = 200.0f;
	}
};