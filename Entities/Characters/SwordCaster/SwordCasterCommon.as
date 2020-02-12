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
	const ::s32 MANA_REGEN = 3;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};
	
	const ::Spell[] spells = 
	{
		Spell("orb", "Orb", 6, "Fire a basic orb which ricochets off of most surfaces until impacting an enemy and exploding, dealing minor damage.",
			SpellType::other, 2, 40, 0, 360.0f),
							// 2 is the cost // 40 is the charge time //360.0f is the range //the 0 is the cooldown //6 is the icon it uses
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellType::other, 20, 6, 0, 270.0f, true), 
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellType::other, 15, 10, 0, 8.0f, true),
			
		Spell("magic_missile", "Missiles of Magic", 17, "Barrage your nearest foes with deadly homing missiles. Does minor damage, is slow moving and easily countered.",
			SpellType::other, 25, 10, 3, 360.0f, true),
			
		Spell("frost_ball", "Ball of Frost", 13, "Send forth a slow travelling ball of pure cold essence to freeze your enemies in place and deal a small amount of damage. Freeze duration increases as the health of your enemy declines.",
			SpellType::other, 18, 25, 0, 360.0f, true),
			
		Spell("heal", "Lesser Heal", 14, "Salves the least of your allies' wounds to restore a moderate portion of their health. Fully charge in order to heal yourself with less efficiency.",
			SpellType::other, 20, 20, 10, 360.0f, true), 
			 
		Spell("firebomb", "Fire Bomb", 11, "Throw a high velocity condensed ball of flames that explodes on contact with enemies, igniting them. Has a minimum engagement distance of about 8 blocks.",
			SpellType::other, 25, 25, 0, 360.0f, true),
			 
		Spell("fire_sprite", "Fire Sprites", 12, "Create long-ranged explosive balls of energy which follow your aim for an extended period of time.",
			SpellType::other, 15, 10, 0, 360.0f, true),	
			 
		Spell("meteor_strike", "Meteor Strike", 9, "Bring flaming meteors crashing down wherever you desire.",
			SpellType::other, 50, 40, 0, 360.0f, true),
			 
		Spell("revive", "Revive", 15, "Fully bring trusty allies back from the dead by aiming a reviving missile at their gravestone.",
			SpellType::other, 50, 40, 0, 360.0f, true),
			 
		Spell("magic_barrier", "Magic Barrier", 21, "Create a wall of pure magical energy in front of you that blocks most small projectiles.",
			SpellType::other, 25, 7, 0, 32.0f, true),
			
		Spell("slow", "Slow", 19, "Deprive a player of his speed and ability to teleport for a few moments.",
			SpellType::other, 20, 10, 0, 360.0f, true), 
			 
		Spell("haste", "Haste", 20, "Give your allies some added speed and maneuverability. Fully charge to hasten yourself.",
			SpellType::other, 10, 15, 0, 360.0f, true),
			
		Spell("lightning", "Lightning", 26, "Call down the blazing wrath of heaven upon the heads of those who oppose you. .",
				SpellType::other, 40, 10, 0, 180.0f, true),

		Spell("mana_drain_circle", "Circle of disenchant", 33, "Those who stand inside this circle lose their mana and are slowed to a crawl",
				SpellType::other,45,40,10,360,true),			
				
		Spell("sword_cast", "Sword Casting", 41, "New sword throwing spell.",
				SpellType::other, 30, 30, 0, 360.0f,true),

		Spell("crusader", "Crusader", 42, "New sword blockading spell.",
				SpellType::other, 20, 30, 0, 360.0f, true),

		Spell("executioner", "Executioner", 43, "New sword Execution spell.",
				SpellType::other, 30, 20, 0, 360.0f, true),

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