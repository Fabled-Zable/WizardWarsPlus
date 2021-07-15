#include "AllHashCodes.as";

void decreaseNegatisphereLife( CBlob@ this , CBlob@ b )
{
	if(this is null){return;}
	if(b is null){return;}
	
	s8 life = this.get_s8("lifepoints");
	string blobname = b.getName();

	switch(blobname.getHash())
	{
		case _bee:
		case _sporeshot:
		case _spikeorb:
		case _effect_missile_circle:
		{
			this.set_s8("lifepoints", (life - 1));
		}
		break;

		case _stone_spike:
		case _expunger:
		{
			this.set_s8("lifepoints", (life - 2));
		}
		break;

		case _orb:
		{
			this.set_s8("lifepoints", (life - 4));
		}
		break;

		case _impaler:
		{
			this.set_s8("lifepoints", (life - 5));
		}
		break;

		case _crusader:
		{
			this.set_s8("lifepoints", (life - 7));
		}
		break;
		
		case _mushroom:
		case _magic_missile:
		case _plasma_shot:
		{
			this.set_s8("lifepoints", (life - 6));
		}
		break;

		default: //anything that one-shots it
		{
			this.set_s8("lifepoints", 0);
		}
	}
}

s8 negentropyDecoder( CBlob@ b )
{
	if(b is null){return -1;}

	string blobname = b.getName();
	switch(blobname.getHash())
	{
		case _bee:
		{
			return 4;
		}
		break;
		case _sporeshot:
		{
			return 4;
		}
		break;
		case _spikeorb:
		{
			return 3;
		}
		break;
		case _stone_spike:
		{
			return 2;
		}
		break;
		case _mushroom:
		{
			return 20;
		}
		break;
		case _expunger:
		{
			return 2;
		}
		break;
		case _impaler:
		{
			return 15;
		}
		break;
		case _crusader:
		{
			return 15;
		}
		break;
		case _executioner:
		{
			return 40;
		}
		break;
		case _orb:
		{
			return 10;
		}
		break;
		case _magic_missile:
		{
			return 10;
		}
		break;
		case _plasma_shot:
		{
			return 20;
		}
		break;
		case _magic_barrier:
		{
			return 20;
		}
		break;
		case _rock_wall:
		{
			return 15;
		}
		break;
		case _no_teleport_barrier:
		{
			return 25;
		}
		break;
		case _negatisphere:
		{
			return 20;
		}
		break;
		case _firebomb:
		{
			return 30;
		}
		break;
		case _bunker_buster:
		{
			return 30;
		}
		break;
		case _fire_sprite:
		{
			return 20;
		}
		break;
		case _lightning:
		{
			return 100;
		}
		break;
		case _leech:
		{
			return 80;
		}
		break;
		case _frost_ball:
		{
			return 20;
		}
		break;
		case _ice_prison:
		{
			return 3;
		}
		break;
		case _effect_missile:
		{
			return 15;
		}
		break;
		case _effect_missile_circle:
		{
			return 1;
		}
		break;
		case _plant_aura:
		{
			return 15;
		}
		break;
		case _meteor:
		{
			return 50;
		}
		break;
		case _nova_bolt:
		{
			return 35;
		}
		break;
		case _mana_drain_circle:
		{
			return -2;
		}
		break;
		case _arcane_circle:
		{
			return -2;
		}
		break;
		case _black_hole:
		{
			return -2;
		}
		break;
		case _black_hole_big:
		{
			return -2;
		}
		break;
		case _mana_obelisk:
		{
			return -3;
		}
		break;
		case _force_of_nature:
		{
			return -3;
		}
		break;

		default: //unabsorvable
		{
			return -1;
		}
	}
	
	return -1;
}

bool voltageFieldDamage( CBlob@ b )
{
	if(b is null){return false;}

	string blobname = b.getName();
	switch(blobname.getHash())
	{
		case _executioner:
		case _orb:
		case _no_teleport_barrier:
		case _negatisphere:
		case _bunker_buster:
		case _lightning:
		case _leech:
		case _effect_missile:
		case _effect_missile_circle:
		case _meteor:
		case _mana_drain_circle:
		case _arcane_circle:
		case _black_hole:
		case _black_hole_big:
		case _mana_obelisk:
		case _force_of_nature:
		{
			return false;
		}
		break;

		default: //damage anyways
		{
			return true;
		}
	}
	
	return true;
}

s8 parryTargetIdentifier( CBlob@ b )
{
	if(b is null){return -1;}

	string blobname = b.getName();
	switch(blobname.getHash())
	{
		case _executioner:
		case _negatisphere:
		case _fire_sprite:
		{
			return 1; //need reset
		}
		break;

		case _wizard:
		case _necromancer:
		case _druid:
		case _swordcaster:
		case _entropist:
		case _knight:
		case _archer:
		case _builder:
		{
			return 2; //players slight push
		}
		break;

		case _skeleton:
		case _zombie:
		case _zombieknight:
		case _greg:
		case _wraith:
		{
			return 3; //undead strong push
		}
		break;

		case _arcane_circle:
		case _mana_drain_circle:
		case _force_of_nature:
		case _plant_aura:
		case _mushroom:
		case _rock_wall:
		case _ice_prison:
		case _leech:
		case _impaler:
		case _plasma_shot:
		{
			return -1; //doesn't affect
		}
		break;

		default: //any other blob
		{
			if(b.hasTag("counterable"))
			{
				return 0;
			}
			else
			{
				return -1;
			}
		}
	}
	
	return -1;
}

float undeadCounterspellDamage( CBlob@ b )
{
	if(b is null){return 0;}

	string blobname = b.getName();
	switch(blobname.getHash())
	{
		case _zombie:
		{
			return 3.0f;
		}
		break;

		case _skeleton:
		case _zombieknight:
		{
			return 3.2f;
		}
		break;

		default: //default damage to undead
		{
			return 1.8f;
		}
	}
	
	return 1.8f;
}

bool doesShardDefend ( CBlob@ b )
{
	if(b is null){return false;}

	string blobname = b.getName();
	switch(blobname.getHash())
	{
		case _ice_prison:
		case _magic_barrier:
		case _rock_wall:
		case _plant_aura:
		case _black_hole:
		case _black_hole_big:
		case _arcane_circle:
		case _mana_drain_circle:
		case _effect_missile:
		case _negatisphere:
		case _shard:
		{
			return false;
		}
		break;

		default: //interact and defend
		{
			return true;
		}
	}

	return true;
}

bool doesShardKill ( CBlob@ b )
{
	if(b is null){return false;}

	string blobname = b.getName();
	switch(blobname.getHash())
	{
		case _nova_bolt:
		case _effect_missile_circle:
		case _stone_spike:
		case _sporeshot:
		case _spikeorb:
		{
			return true;
		}

		default: //don't kill it
		{
			return false;
		}
	}
	return false;
}