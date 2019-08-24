//Generic Magic Class Include
//
namespace SpellType
{
	enum type
	{
		summoning,
		other
	};
}

shared class Spell
{
	string typeName;
	string name;
	string icon;
	u16 iconFrame;
	string spellDesc;
	u8 type;
	s32 mana;

	s32 fullChargeTime;
	s32 readyTime;
	s32 cooldownTime;

	f32 range;

	s32 ready_time;

	s32 cast_period;
	s32 cast_period_1;
	s32 cast_period_2;
	s32 full_cast_period;

	bool needs_full;

	Spell(string i_typeName, string i_name, u16 i_iconFrame, string i_spellDesc, u8 i_type, s32 i_mana, s32 i_cast_period, s32 i_cooldownTime, f32 i_range, bool fully_loaded = false)
	{
		typeName = i_typeName;
		name = i_name;
		iconFrame = i_iconFrame;
		spellDesc = i_spellDesc;
		type = i_type;
		mana = i_mana;
		cooldownTime = i_cooldownTime;
		range = i_range;

		cast_period = i_cast_period;
		cast_period_1 = cast_period/3;
		cast_period_2 = 2*cast_period/3;
		full_cast_period = cast_period*3;

		needs_full = fully_loaded;
	}
};

shared class ManaInfo
{
	s32 mana;
	s32 maxMana;
	s32 manaRegen;
	s32 maxtestmana;

	ManaInfo()
	{
		mana = 0;
		maxMana = 100;
		manaRegen = 3;
		maxtestmana = 205;
	}
}; 

