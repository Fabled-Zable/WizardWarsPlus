//archer HUD

#include "NecromancerCommon.as";
#include "PlayerPrefsCommon.as";
#include "MagicCommon.as";
#include "HUDStartPos.as";

const string iconsFilename = "SpellIcons.png";
const int slotsSize = 6;

void onInit( CSprite@ this )
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	CBlob@ thisBlob = this.getBlob();
	
	thisBlob.set_u8("gui_HUD_slots_width", slotsSize);
}

void ManageCursors( CBlob@ this )
{
	// set cursor
	if (getHUD().hasButtons()) {
		getHUD().SetDefaultCursor();
	}
	else
	{
		// set cursor
		getHUD().SetCursorImage("MagicCursor.png", Vec2f(32,32));
		getHUD().SetCursorOffset( Vec2f(-32, -32) );
		// frame set in logic
	}
}

void DrawManaBar(CBlob@ this, Vec2f origin)
{
	ManaInfo@ manaInfo;
    if (!this.get( "manaInfo", @manaInfo )) 
	{
        return;
    }
    string manaFile = "GUI/ManaBar.png";
	int barLength = 4;
    int segmentWidth = 24;
    GUI::DrawIcon("GUI/jends.png", 0, Vec2f(8,16), origin+Vec2f(-8,0));
    s32 maxMana = manaInfo.maxMana;
    s32 currMana = manaInfo.mana;
	
	f32 manaPerSegment = maxMana/barLength;
	
	f32 fourthManaSeg = manaPerSegment*(1.0f/4.0f);
	f32 halfManaSeg = manaPerSegment*(1.0f/2.0f);
	f32 threeFourthsManaSeg = manaPerSegment*(3.0f/4.0f);
	
	int MANA = 0;
    for (int step = 0; step < barLength; step += 1)
    {
        GUI::DrawIcon("GUI/ManaBack.png", 0, Vec2f(12,16), origin+Vec2f(segmentWidth*MANA,0));
        f32 thisMANA = currMana - step*manaPerSegment;
        if (thisMANA > 0)
        {
            Vec2f manapos = origin+Vec2f(segmentWidth*MANA-1,0);
            if (thisMANA <= fourthManaSeg) { GUI::DrawIcon(manaFile, 4, Vec2f(16,16), manapos); }
            else if (thisMANA <= halfManaSeg) { GUI::DrawIcon(manaFile, 3, Vec2f(16,16), manapos); }
            else if (thisMANA <= threeFourthsManaSeg) { GUI::DrawIcon(manaFile, 2, Vec2f(16,16), manapos); }
            else if (thisMANA > threeFourthsManaSeg) { GUI::DrawIcon(manaFile, 1, Vec2f(16,16), manapos); }
            else { GUI::DrawIcon(manaFile, 0, Vec2f(16,16), manapos); }
        }
        MANA++;
    }
    GUI::DrawIcon("GUI/jends.png", 1, Vec2f(8,16), origin+Vec2f(segmentWidth*MANA,0));
	GUI::DrawText(""+currMana+"/"+maxMana, origin+Vec2f(-42,8), color_white );
}

void DrawSpellBar(CBlob@ this)
{
	if (NecromancerParams::spells.length == 0) {
		return;
	}
	
	CPlayer@ thisPlayer = this.getPlayer();
	if (thisPlayer is null )
	{
		return;
	}
	
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!thisPlayer.get( "playerPrefsInfo", @playerPrefsInfo )) 
	{
		return;
	}
	
    ManaInfo@ manaInfo;
    if (!this.get( "manaInfo", @manaInfo )) 
	{
        return;
    }
	
	if ( playerPrefsInfo.infoLoaded == false )
	{
		return;
	}
	
	CControls@ controls = getControls();
	Vec2f mouseScreenPos = controls.getMouseScreenPos();
	int ticksPerSec = getTicksASecond();
	
	f32 necromancerMana = manaInfo.mana;
	
	u8[] primaryHotkeys = playerPrefsInfo.hotbarAssignments_Necromancer;
	
	//PRIMARY SPELL HUD
    Vec2f primaryPos = Vec2f( 16.0f, getScreenHeight()-128.0f );

	u8 primarySpell;
	if (  playerPrefsInfo.hotbarAssignments_Necromancer.length >= playerPrefsInfo.primaryHotkeyID )
		primarySpell = playerPrefsInfo.hotbarAssignments_Necromancer[playerPrefsInfo.primaryHotkeyID];
	else
		primarySpell = 0;
	
	const u8 primaryHotkey = playerPrefsInfo.primaryHotkeyID;
	
	int spellsLength = NecromancerParams::spells.length;
	int cooldownsLength = playerPrefsInfo.spell_cooldowns.length;
	for (uint i = 0; i < 15; i++)	//only 15 total spells held inside primary hotbar
	{
		u8 primarySpellID = Maths::Min(primaryHotkeys[i], spellsLength-1);
		Spell spell = NecromancerParams::spells[primarySpellID];
		
		f32 spellMana = spell.mana;
		if ( spellMana == 0 )
			spellMana = 1;
		
		s16 currSpellCooldown = playerPrefsInfo.spell_cooldowns[Maths::Min(primarySpellID, cooldownsLength)];
		if ( currSpellCooldown > 0 )
			currSpellCooldown = currSpellCooldown/ticksPerSec + 1;		//this is for rounding issues
		
		if ( i < 5 )		//spells 0 through 4
		{
			GUI::DrawFramedPane(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,96) + Vec2f(32,0)*i);
			GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,64) + Vec2f(32,0)*i);
			GUI::DrawText(""+((i+1)%10), primaryPos + Vec2f(8,-16) + Vec2f(32,0)*i, color_white );
			
			if ( i == primaryHotkey )
				GUI::DrawRectangle(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,96) + Vec2f(32,0)*i, SColor(100, 0, 255, 0));
				
			if ( necromancerMana < spellMana )
				GUI::DrawRectangle(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,64) + Vec2f(0, 32*(1-(necromancerMana/spellMana))) + Vec2f(32,0)*i, SColor(200, 0, 0, 0));	
			
			if ( currSpellCooldown > 0 )
			{
				GUI::DrawRectangle(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,96) + Vec2f(32,0)*i, SColor(100, 255, 0, 0));
				GUI::DrawText(""+currSpellCooldown, primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, color_white );
			}
		}
		else if ( i < 10 )	//spells 5 through 9	
		{
			GUI::DrawFramedPane(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,64) + Vec2f(32,0)*(i-5));
			GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5));
			
			if ( i == primaryHotkey )
				GUI::DrawRectangle(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,64) + Vec2f(32,0)*(i-5), SColor(100, 0, 255, 0));
				
			if ( necromancerMana < spellMana )
				GUI::DrawRectangle(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,32) + Vec2f(0, 32*(1-(necromancerMana/spellMana))) + Vec2f(32,0)*(i-5), SColor(200, 0, 0, 0));
				
			if ( currSpellCooldown > 0 )
			{
				GUI::DrawRectangle(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,64) + Vec2f(32,0)*(i-5), SColor(100, 255, 0, 0));
				GUI::DrawText(""+currSpellCooldown, primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), color_white );
			}
		}
		else				//spells 10 through 14
		{
			GUI::DrawFramedPane(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,32) + Vec2f(32,0)*(i-10));
			GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(32,0)*(i-10));			
			
			if ( i == primaryHotkey )
				GUI::DrawRectangle(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,32) + Vec2f(32,0)*(i-10), SColor(100, 0, 255, 0));
				
			if ( necromancerMana < spellMana )
				GUI::DrawRectangle(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,0) + Vec2f(0, 32*(1-(necromancerMana/spellMana))) + Vec2f(32,0)*(i-10), SColor(200, 0, 0, 0));
				
			if ( currSpellCooldown > 0 )
			{
				GUI::DrawRectangle(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,32) + Vec2f(32,0)*(i-10), SColor(100, 255, 0, 0));
				GUI::DrawText(""+currSpellCooldown, primaryPos + Vec2f(32,0)*(i-10), color_white );
			}
		}
		
		//draw an arrow over the selected column
		bool spellSelected = this.get_bool("spell selected");
		if ( spellSelected == false )
		{
			Vec2f arrowPosOffset = Vec2f(0,0);
		
			if ( (primaryHotkey == 0 ||  primaryHotkey == 5 ||  primaryHotkey == 10) )
				arrowPosOffset = Vec2f(0,0);
			else if ( (primaryHotkey == 1 ||  primaryHotkey == 6 ||  primaryHotkey == 11) )
				arrowPosOffset = Vec2f(32,0);
			else if ( (primaryHotkey == 2 ||  primaryHotkey == 7 ||  primaryHotkey == 12) )
				arrowPosOffset = Vec2f(64,0);
			else if ( (primaryHotkey == 3 ||  primaryHotkey == 8 ||  primaryHotkey == 13) )
				arrowPosOffset = Vec2f(96,0);
			else if ( (primaryHotkey == 4 ||  primaryHotkey == 9 ||  primaryHotkey == 14) )
				arrowPosOffset = Vec2f(128,0);
				
			GUI::DrawArrow2D( primaryPos + Vec2f(14,-32) + arrowPosOffset, primaryPos + Vec2f(14,-16) + arrowPosOffset, color_white);
		}
	}
	
	//primary spell name
	GUI::DrawPane(primaryPos + Vec2f(32,96), primaryPos + Vec2f(64,116) + Vec2f(32,0)*3, color_white);
	GUI::DrawText(NecromancerParams::spells[primarySpell].name, primaryPos + Vec2f(40,98), color_white );
	
	//primary spell mana cost
	GUI::DrawPane(primaryPos + Vec2f(0,96), primaryPos + Vec2f(32,116), color_white);
	GUI::DrawText("-" + NecromancerParams::spells[primarySpell].mana, primaryPos + Vec2f(2,98), SColor(255, 158, 58, 187) );
	
	GUI::DrawText("Primary - "+controls.getActionKeyKeyName( AK_ACTION1 ), primaryPos + Vec2f(0,-48), color_white );
	
	//SECONDARY SPELL HUD
    Vec2f secondaryPos = Vec2f( 192.0f, getScreenHeight()-128.0f );
	
	u8 secondarySpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Necromancer[15], spellsLength-1);
	Spell secondarySpell = NecromancerParams::spells[secondarySpellID];
	
	f32 secondarySpellMana = secondarySpell.mana;
	if ( secondarySpellMana == 0 )
		secondarySpellMana = 1;
	
	s16 currSecSpellCooldown = playerPrefsInfo.spell_cooldowns[Maths::Min(secondarySpellID, cooldownsLength)];
	if ( currSecSpellCooldown > 0 )
		currSecSpellCooldown = currSecSpellCooldown/ticksPerSec + 1;		//this is for rounding issues
			
	GUI::DrawFramedPane(secondaryPos, secondaryPos + Vec2f(32,32));
	GUI::DrawIcon("SpellIcons.png", secondarySpell.iconFrame, Vec2f(16,16), secondaryPos);
		
	if ( necromancerMana < secondarySpellMana )
		GUI::DrawRectangle(secondaryPos, secondaryPos + Vec2f(32, 32*(1-(necromancerMana/secondarySpellMana))), SColor(200, 0, 0, 0));
		
	if ( currSecSpellCooldown > 0 )
	{
		GUI::DrawRectangle(secondaryPos, secondaryPos + Vec2f(32, 32), SColor(100, 255, 0, 0));
		GUI::DrawText(""+currSecSpellCooldown, secondaryPos, color_white );
	}
		
	//secondary spell name
	GUI::DrawPane(secondaryPos + Vec2f(32,32), secondaryPos + Vec2f(64,52) + Vec2f(32,0)*3, color_white);
	GUI::DrawText(secondarySpell.name, secondaryPos + Vec2f(40,34), color_white );
	
	//secondary spell mana cost
	GUI::DrawPane(secondaryPos + Vec2f(0,32), secondaryPos + Vec2f(32,52), color_white);
	GUI::DrawText("-" + secondarySpellMana, secondaryPos + Vec2f(2,34), SColor(255, 158, 58, 187) );
	
	GUI::DrawText("Secondary - "+controls.getActionKeyKeyName( AK_ACTION2 ), secondaryPos + Vec2f(32,8), color_white );	
	
	//AUXILIARY1 SPELL HUD
    Vec2f aux1Pos = Vec2f( 192.0f, getScreenHeight()-64.0f );
	
	u8 aux1SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Necromancer[16], spellsLength-1);
	Spell aux1Spell = NecromancerParams::spells[aux1SpellID];	
	
	f32 aux1SpellMana = aux1Spell.mana;
	if ( aux1SpellMana == 0 )
		aux1SpellMana = 1;	
	
	s16 currAux1SpellCooldown = playerPrefsInfo.spell_cooldowns[Maths::Min(aux1SpellID, cooldownsLength)];
	if ( currAux1SpellCooldown > 0 )
		currAux1SpellCooldown = currAux1SpellCooldown/ticksPerSec + 1;		//this is for rounding issues
	
	GUI::DrawFramedPane(aux1Pos, aux1Pos + Vec2f(32,32));
	GUI::DrawIcon("SpellIcons.png", aux1Spell.iconFrame, Vec2f(16,16), aux1Pos);
		
	if ( necromancerMana < aux1SpellMana )
		GUI::DrawRectangle(aux1Pos, aux1Pos + Vec2f(32, 32*(1-(necromancerMana/aux1SpellMana))), SColor(200, 0, 0, 0));
		
	if ( currAux1SpellCooldown > 0 )
	{
		GUI::DrawRectangle(aux1Pos, aux1Pos + Vec2f(32, 32), SColor(100, 255, 0, 0));
		GUI::DrawText(""+currAux1SpellCooldown, aux1Pos, color_white );
	}
		
	//auxiliary1 spell name
	GUI::DrawPane(aux1Pos + Vec2f(32,32), aux1Pos + Vec2f(64,52) + Vec2f(32,0)*3, color_white);
	GUI::DrawText(aux1Spell.name, aux1Pos + Vec2f(40,34), color_white );
	
	//auxiliary1 spell mana cost
	GUI::DrawPane(aux1Pos + Vec2f(0,32), aux1Pos + Vec2f(32,52), color_white);
	GUI::DrawText("-" + aux1SpellMana, aux1Pos + Vec2f(2,34), SColor(255, 158, 58, 187) );
	
	GUI::DrawText("Auxiliary1 - "+controls.getActionKeyKeyName( AK_ACTION3 ), aux1Pos + Vec2f(32,8), color_white );	
	
	//AUXILIARY2 SPELL HUD
    Vec2f aux2Pos = Vec2f( 364.0f, getScreenHeight()-128.0f );
	
	u8 aux2SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Necromancer[17], spellsLength-1);
	Spell aux2Spell = NecromancerParams::spells[aux2SpellID];	
	
	f32 aux2SpellMana = aux2Spell.mana;
	if ( aux2SpellMana == 0 )
		aux2SpellMana = 1;	
	
	s16 currAux2SpellCooldown = playerPrefsInfo.spell_cooldowns[Maths::Min(aux2SpellID, cooldownsLength)];
	if ( currAux2SpellCooldown > 0 )
		currAux2SpellCooldown = currAux2SpellCooldown/ticksPerSec + 1;		//this is for rounding issues
	
	GUI::DrawFramedPane(aux2Pos, aux2Pos + Vec2f(32,32));
	GUI::DrawIcon("SpellIcons.png", aux2Spell.iconFrame, Vec2f(16,16), aux2Pos);
		
	if ( necromancerMana < aux2SpellMana )
		GUI::DrawRectangle(aux2Pos, aux2Pos + Vec2f(32, 32*(1-(necromancerMana/aux2SpellMana))), SColor(200, 0, 0, 0));
		
	if ( currAux2SpellCooldown > 0 )
	{
		GUI::DrawRectangle(aux2Pos, aux2Pos + Vec2f(32, 32), SColor(100, 255, 0, 0));
		GUI::DrawText(""+currAux2SpellCooldown, aux2Pos, color_white );
	}
		
	//auxiliary1 spell name
	GUI::DrawPane(aux2Pos + Vec2f(32,32), aux2Pos + Vec2f(64,52) + Vec2f(32,0)*3, color_white);
	GUI::DrawText(aux2Spell.name, aux2Pos + Vec2f(40,34), color_white );
	
	//auxiliary1 spell mana cost
	GUI::DrawPane(aux2Pos + Vec2f(0,32), aux2Pos + Vec2f(32,52), color_white);
	GUI::DrawText("-" + aux2SpellMana, aux2Pos + Vec2f(2,34), SColor(255, 158, 58, 187) );
	
	GUI::DrawText("Auxiliary2 - "+controls.getActionKeyKeyName( AK_TAUNTS ), aux2Pos + Vec2f(32,8), color_white );	
}

void onRender( CSprite@ this )
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	CPlayer@ player = blob.getPlayer();

	ManageCursors( blob );

	// draw inventory
	Vec2f tl = getActorHUDStartPosition(blob, slotsSize);
	DrawInventoryOnHUD( blob, tl, Vec2f(0,58));

	// draw coins
	const int coins = player !is null ? player.getCoins() : 0;
	DrawCoinsOnHUD( blob, coins, tl, slotsSize-2 );
	
	GUI::DrawIcon("GUI/jslot.png", 1, Vec2f(32,32), Vec2f(2,48));
	DrawManaBar(blob, Vec2f(52,56));
	DrawSpellBar(blob);
}
