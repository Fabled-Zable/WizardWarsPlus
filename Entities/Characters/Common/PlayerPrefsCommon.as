//Wizard Include
#include "WizardCommon.as";
#include "NecromancerCommon.as";
#include "DruidCommon.as";
#include "SwordCasterCommon.as";
#include "EntropistCommon.as";
#include "FrigateCommon.as";
#include "MagicCommon.as";

const u8 MAX_SPELLS = 20;

const u8 WIZARD_TOTAL_HOTKEYS = 18;
const u8 DRUID_TOTAL_HOTKEYS = 18;
const u8 NECROMANCER_TOTAL_HOTKEYS = 18;
const u8 SWORDCASTER_TOTAL_HOTKEYS = 18;
const u8 ENTROPIST_TOTAL_HOTKEYS = 18;
const u8 FRIGATE_TOTAL_HOTKEYS = 17;

shared class PlayerPrefsInfo
{
	bool infoLoaded;
	
	string classConfig;

	u8 primarySpellID;
	u8 primaryHotkeyID;
	u8 customSpellID;
	u8[] hotbarAssignments_Wizard;
	u8[] hotbarAssignments_Druid;
	u8[] hotbarAssignments_Necromancer;
	u8[] hotbarAssignments_SwordCaster;
	u8[] hotbarAssignments_Entropist;
	u8[] hotbarAssignments_Frigate;
	
	s32[] spell_cooldowns;

	PlayerPrefsInfo()
	{
		infoLoaded = false;
		
		classConfig = "wizard";
	
		primarySpellID = 0;
		primaryHotkeyID = 0;
		
		for (uint i = 0; i < MAX_SPELLS; ++i)
		{
			spell_cooldowns.push_back(0);
		}
	}
};

void SetCustomSpell( CPlayer@ this, const u8 id )
{
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!this.get( "playerPrefsInfo", @playerPrefsInfo ))
	{
		return;
	}
	playerPrefsInfo.customSpellID = id;
}

void assignHotkey( CPlayer@ this, const u8 hotkeyID, const u8 spellID, string playerClass )
{
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!this.get( "playerPrefsInfo", @playerPrefsInfo ))
	{
		return;
	}
	
	print("hotkey " + hotkeyID + " assigned to spell " + spellID);
	if ( playerClass == "wizard" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Wizard.length;
		playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "druid" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Druid.length;
		playerPrefsInfo.hotbarAssignments_Druid[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Druid[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "necromancer" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Necromancer.length;
		playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "swordcaster" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_SwordCaster.length;
		playerPrefsInfo.hotbarAssignments_SwordCaster[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_SwordCaster[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "entropist" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Entropist.length;
		playerPrefsInfo.hotbarAssignments_Entropist[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Entropist[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "frigate" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Frigate.length;
		playerPrefsInfo.hotbarAssignments_Frigate[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Frigate[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	
	saveHotbarAssignments( this );
}

void defaultHotbarAssignments( CPlayer@ this, string playerClass )
{
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!this.get( "playerPrefsInfo", @playerPrefsInfo ))
	{
		return;
	}
	
	if ( playerClass == "wizard" )
	{
		playerPrefsInfo.hotbarAssignments_Wizard.clear();
		
		int spellsLength = WizardParams::spells.length;
		for (uint i = 0; i < WIZARD_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(0);
				continue;
			}
				
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(3);	//assign aux2 to something
		}	
	}
	if ( playerClass == "druid" )
	{
		playerPrefsInfo.hotbarAssignments_Druid.clear();
		
		int spellsLength = DruidParams::spells.length;
		for (uint i = 0; i < DRUID_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Druid.push_back(0);
				continue;
			}
				
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(3);	//assign aux2 to something
		}	
	}
	else if ( playerClass == "necromancer" )
	{
		playerPrefsInfo.hotbarAssignments_Necromancer.clear();
		
		int spellsLength = NecromancerParams::spells.length;
		for (uint i = 0; i < NECROMANCER_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(0);
				continue;
			}
		
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(3);	//assign aux2 to something
		}	
	}
	else if ( playerClass == "swordcaster" )
	{
		playerPrefsInfo.hotbarAssignments_SwordCaster.clear();
		
		int spellsLength = SwordCasterParams::spells.length;
		for (uint i = 0; i < SWORDCASTER_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(0);
				continue;
			}
		
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(3);	//assign aux2 to something
		}	
	}
	else if ( playerClass == "entropist" )
	{
		playerPrefsInfo.hotbarAssignments_Entropist.clear();
		
		int spellsLength = EntropistParams::spells.length;
		for (uint i = 0; i < ENTROPIST_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(0);
				continue;
			}
				
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(3);	//assign aux2 to something
		}	
	}
	else if ( playerClass == "frigate" )
	{
		playerPrefsInfo.hotbarAssignments_Frigate.clear();
		
		int spellsLength = FrigateParams::spells.length;
		for (uint i = 0; i < FRIGATE_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Frigate.push_back(0);
				continue;
			}
				
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Frigate.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Frigate.push_back(1);	//assign aux1 to counter spell
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Frigate.push_back(2);	//assign aux2 to something
		}	
	}
}

void saveHotbarAssignments( CPlayer@ this )
{
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!this.get( "playerPrefsInfo", @playerPrefsInfo ))
	{
		return;
	}
	
	if (isClient())
	{
		ConfigFile cfg;
		
		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Wizard.length; i++)
		{	
			cfg.add_u32("wizard hotkey" + i, playerPrefsInfo.hotbarAssignments_Wizard[i]);
		}
		
		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Druid.length; i++)
		{	
			cfg.add_u32("druid hotkey" + i, playerPrefsInfo.hotbarAssignments_Druid[i]);
		}
		
		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Necromancer.length; i++)
		{		
			cfg.add_u32("necromancer hotkey" + i, playerPrefsInfo.hotbarAssignments_Necromancer[i]);
		}
		
		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_SwordCaster.length; i++)
		{		
			cfg.add_u32("swordcaster hotkey" + i, playerPrefsInfo.hotbarAssignments_SwordCaster[i]);
		}

		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Entropist.length; i++)
		{	
			cfg.add_u32("entropist hotkey" + i, playerPrefsInfo.hotbarAssignments_Entropist[i]);
		}

		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Frigate.length; i++)
		{	
			cfg.add_u32("frigate hotkey" + i, playerPrefsInfo.hotbarAssignments_Frigate[i]);
		}

		cfg.saveFile( "WW_PlayerPrefs.cfg" );
	}	
}

void loadHotbarAssignments( CPlayer@ this, string playerClass )
{
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!this.get( "playerPrefsInfo", @playerPrefsInfo ))
	{
		return;
	}
	
	if ( playerClass == "wizard" )
	{
		playerPrefsInfo.hotbarAssignments_Wizard.clear();
		
		int spellsLength = WizardParams::spells.length;
		for (uint i = 0; i < WIZARD_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(0);
				continue;
			}	
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Wizard.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Wizard.length; i++)
				{		
					if ( cfg.exists( "wizard hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("wizard hotkey" + i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					else
						loadedHotkeys.push_back(0);
				}
				playerPrefsInfo.hotbarAssignments_Wizard = loadedHotkeys;
				print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(0,hotbarLength-1)];
	}
	else if ( playerClass == "druid" )
	{
		playerPrefsInfo.hotbarAssignments_Druid.clear();
		
		int spellsLength = DruidParams::spells.length;
		for (uint i = 0; i < DRUID_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Druid.push_back(0);
				continue;
			}	
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Druid.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Druid.length; i++)
				{		
					if ( cfg.exists( "druid hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("druid hotkey" + i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					else
						loadedHotkeys.push_back(0);
				}
				playerPrefsInfo.hotbarAssignments_Druid = loadedHotkeys;
				print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Druid[Maths::Min(0,hotbarLength-1)];
	}
	else if ( playerClass == "necromancer" )
	{
		playerPrefsInfo.hotbarAssignments_Necromancer.clear();
		
		int spellsLength = NecromancerParams::spells.length;
		for (uint i = 0; i < NECROMANCER_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(0);
				continue;
			}
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Necromancer.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Necromancer.length; i++)
				{		
					if ( cfg.exists( "necromancer hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("necromancer hotkey" + i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					else
						loadedHotkeys.push_back(0);
				}
				playerPrefsInfo.hotbarAssignments_Necromancer = loadedHotkeys;
				print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(0,hotbarLength-1)];
	}
	else if ( playerClass == "swordcaster" )
	{
		playerPrefsInfo.hotbarAssignments_SwordCaster.clear();
		
		int spellsLength = SwordCasterParams::spells.length;
		for (uint i = 0; i < SWORDCASTER_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(0);
				continue;
			}
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_SwordCaster.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_SwordCaster.length; i++)
				{		
					if ( cfg.exists( "swordcaster hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("swordcaster hotkey" + i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					else
						loadedHotkeys.push_back(0);
				}
				playerPrefsInfo.hotbarAssignments_SwordCaster = loadedHotkeys;
				print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_SwordCaster[Maths::Min(0,hotbarLength-1)];
	}
	else if ( playerClass == "entropist" )
	{
		playerPrefsInfo.hotbarAssignments_Entropist.clear();
		
		int spellsLength = EntropistParams::spells.length;
		for (uint i = 0; i < ENTROPIST_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(0);
				continue;
			}	
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Entropist.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Entropist.length; i++)
				{		
					if ( cfg.exists( "entropist hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("entropist hotkey" + i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					else
						loadedHotkeys.push_back(0);
				}
				playerPrefsInfo.hotbarAssignments_Entropist = loadedHotkeys;
				print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Entropist[Maths::Min(0,hotbarLength-1)];
	}
	else if ( playerClass == "frigate" )
	{
		playerPrefsInfo.hotbarAssignments_Frigate.clear();
		
		int spellsLength = FrigateParams::spells.length;
		for (uint i = 0; i < FRIGATE_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Frigate.push_back(1);	//assign aux1 to counter spell
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Frigate.push_back(2);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Frigate.push_back(0);
				continue;
			}	
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Frigate.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Frigate.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Frigate.length; i++)
				{		
					if ( cfg.exists( "frigate hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("frigate hotkey" + i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					else
						loadedHotkeys.push_back(0);
				}
				playerPrefsInfo.hotbarAssignments_Frigate = loadedHotkeys;
				print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Frigate[Maths::Min(0,hotbarLength-1)];
	}
}