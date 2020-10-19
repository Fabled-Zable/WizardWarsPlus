//Necromancer Include

#include "MagicCommon.as";

namespace NecromancerParams
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
	const ::s32 MAX_MANA = 100;
	const ::s32 MANA_REGEN = 4;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};

	const ::Spell[] spells = 
	{
		Spell("orb", "Orb", 6, "Fire a basic orb which ricochets off of most surfaces until impacting an enemy and exploding, dealing minor damage.",
			SpellType::other, 3, 40, 0, 360.0f),
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellType::other, 25, 10, 0, 270.0f, true),
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellType::other, 15, 10, 0, 64.0f, true),
			 
		Spell("slow", "Slow", 19, "Deprive a player of his speed and ability to teleport for a few moments.",
			SpellType::other, 12, 30, 5, 360.0f, true), 
			 
		Spell("zombie", "Summon Zombie", 2, "Summon an undead minion to fight by your side. Summons at the aim location.",
			SpellType::summoning, 15, 10, 0, 64.0f, true),
			 
		Spell("black_hole", "Black Hole", 18, "Open a portal into outer space, pulling your enemies into the airless void. Also drains the mana of enemies in the area and gives it to the caster.",
			SpellType::other, 45, 120, 5, 180.0f, true),
			 
		//Spell("greg", "Greg", 4, "Testing",
			//SpellType::summoning, 20, 50, 15, 64.0f, true),
			 
		Spell("zombieknight", "Summon ZKnight", 5, "Summon a very strong zombie to your side. Very effective for blocking in tight corridors.",
			SpellType::summoning, 50, 15, 0, 64.0f, true),
			
		Spell("skeleton_rain", "Skeleton Rain", 10, "Summon a hailstorm of skeletons to swarm a nearby opponent.",
			SpellType::other, 45, 30, 0, 360.0f, true),
			
		Spell("arrow_rain", "Arrow Rain", 22, "Cause a long volley of randomly assorted arrows to fall upon thy foe. Great for area denial, and possibly overpowered!",
			SpellType::other, 70, 60, 10, 360.0f, true),
			
		Spell("recall_undead", "Recall Undead", 23, "Instantly bring all summoned minions, along with the unfortunate victims they may be carrying, to your location. ",
				SpellType::other, 15, 10, 10, 8.0f, true),
				
		Spell("unholy_resurrection", "Unholy Resurrection", 24, "Inexpensively resurrect fallen allies... though they may not find themselves completely restored to their former glory.",
				SpellType::other, 20, 20, 0, 360.0f, true),
							
		Spell("leech", "Leech", 25, "Fire a short-ranged arc of dark energy which steals the life-force from foes and revitalizes the user.",
				SpellType::other, 20, 40, 0, 180.0f, true),
				
		Spell("force_of_nature", "Force of Nature", 27, "By invoking this spell, you call into being an orb of ghastly green light which destroys anything foolish enough to cross its path, including you!",
				SpellType::other, 60, 10, 3, 360.0f, true),
				
		Spell("arcane_circle","Arcane Circle",32,"Summon an unholy circle that will drain the life force of your foes",
			SpellType::other,50,50,5,360,true),
							
		Spell("bunker_buster", "Bunker Buster", 39, "Anti-Barrier spell.",
				SpellType::other, 15, 30, 0, 360.0f, true),	
				
		Spell("no_teleport_barrier", "Teleport Block", 49, "Prevents enemies from teleporting past this barrier.",
				SpellType::other, 10, 10, 0, 100.0f, true),	
							
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

class NecromancerInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;

	NecromancerInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
	}
}; 

