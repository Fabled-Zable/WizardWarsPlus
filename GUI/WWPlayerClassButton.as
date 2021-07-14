#include "KGUI.as";
#include "PlayerPrefsCommon.as";
#include "PlatinumCommon.as";
//#include "UnlocksCommon.as";

string classesVersion = "1";
u32 lastHotbarPressTime = 0;

//----KGUI ELEMENTS----\\
	 	WWPlayerClassButtonList playerClassButtons;

class WWPlayerClassButton 
{
	int classID;
	string name, modName, description, configFilename;
	Icon@ rarity, display;
	Button@ classButton, swapButton;
	ProgressBar@ condition;
	
	Rectangle@ classFrame;
	Button@[] spellButtons;
	Label@ desc, conLbl, spellDescText;
	u32 classCost;

	
	bool gained,hasCon = false;
	
	WWPlayerClassButton(string _name, string _desc, string _configFilename, int _classID, int _cost, string _imageName, int _icon, int _rarity, string _modName, Vec2f _pos, int _size)
	{
		name = _name;
		modName = _modName;
		description = _desc;
		configFilename = _configFilename;
		classID = _classID;
		classCost = _cost;
		@classButton = @Button(_pos,Vec2f(200,46),"",SColor(255,255,255,255));
		@desc = @Label(Vec2f(44,5),Vec2f(114,38),_name,SColor(255,0,0,0),false);
		classButton.addChild(desc);
		switch(_size)
		{
			case 1: {@display = @Icon(_imageName,Vec2f(9,9),Vec2f(32,32),_icon,0.44f);break;}
			case 2: {@display = @Icon(_imageName,Vec2f(9,9),Vec2f(114,114),_icon,0.13f);break;}
			default: {@display = @Icon(_imageName,Vec2f(9,9),Vec2f(16,16),_icon,0.87f);}
		}
		classButton.addChild(display);
		@rarity = @Icon("GUI/Rarity.png",Vec2f(5,5),Vec2f(18,18),_rarity,1.0f);
		
		//gained = checkUnlocked();
		
		classButton.name = _configFilename;
		
		classButton.addClickListener(ClassButtonHandler);
		
		@classFrame = @Rectangle(Vec2f(232,0),Vec2f(760,490), SColor(0,0,0,0));
		playerClassButtons.addChild(classFrame);
		
		@swapButton = @Button(Vec2f(80,-24), Vec2f(200,24), "Respawn as "+_name, SColor(255,255,255,255));
		swapButton.name = _configFilename;
		classFrame.addChild(swapButton);
		swapButton.addClickListener(SwapButtonHandler);
		
		//@unlockButton = @Button(Vec2f(300,-24), Vec2f(200,24), "Unlock for: "+_cost+" platinum", SColor(255,255,255,255));
		//classFrame.addChild(unlockButton);
		//unlockButton.addClickListener(UnlockButtonHandler);
		//if ( gained == true )
			//unlockButton.isEnabled = false;
		
		Label@ classDescText = @Label(Vec2f(0,16), Vec2f(480,34), "", SColor(255,0,0,0), false);
		classDescText.setText(classDescText.textWrap(_desc));
		classFrame.addChild(classDescText);
		
		Spell[] spells;
		if ( _configFilename == "wizard" )
			spells = WizardParams::spells;
		else if ( _configFilename == "druid" )
			spells = DruidParams::spells;
		else if ( _configFilename == "necromancer" )
			spells = NecromancerParams::spells;
		else if ( _configFilename == "swordcaster" )
			spells = SwordCasterParams::spells;
		else if ( _configFilename == "entropist" )
			spells = EntropistParams::spells;
		else if ( _configFilename == "frigate" )
			spells = FrigateParams::spells;
		
		int spellsLength = spells.length;
		for (uint i = 0; i < spellsLength; i++)
		{
			f32 gridSize = 48.0f;
			Vec2f offset;
			if ( i < 10 )
				offset = Vec2f(gridSize*i,0);
			else
				offset = Vec2f(gridSize*(i-10),gridSize);
			
			spellButtons.push_back( @Button(Vec2f(0,100) + offset, Vec2f(gridSize,gridSize), "", SColor(255,255,255,255)) );
			spellButtons[i].name = spells[i].name;
			
			Icon@ spellIcon = @Icon("SpellIcons.png", Vec2f(8,8), Vec2f(16,16) , spells[i].iconFrame, 1.0f);
			spellButtons[i].addChild(spellIcon);
			spellButtons[i].addClickListener(SpellButtonHandler);
			
			classFrame.addChild(spellButtons[i]);
		}
		
		@spellDescText = @Label(Vec2f(0,200), Vec2f(480,34), "Select a spell above to see its description.", SColor(255,0,0,0), false);
		classFrame.addChild(spellDescText);
		
		Label@ hotbarHelpText = @Label(Vec2f(0,408), Vec2f(480,34), "", SColor(255,0,0,0), false);
		hotbarHelpText.setText(hotbarHelpText.textWrap("HOW TO ASSIGN HOTKEYS: Select a spell at the top of the page and click a location in the hotbar directly above")); 
		classFrame.addChild(hotbarHelpText);
		
		classFrame.isEnabled = false;
	}
/*
	bool checkUnlocked()
	{
	
		CPlayer@ localPlayer = getLocalPlayer();
		if ( localPlayer is null )
			return false;
			
		string playerName = localPlayer.getUsername();
		
		bool[] unlocks = client_getPlayerUnlocks( playerName );
		
		if ( classID > (unlocks.length-1) )
			return false;
		
		bool unlocked = unlocks[classID] == true;
		return unlocked;
	}
*/
	/*void Unlock()
	{
	
		CPlayer@ localPlayer = getLocalPlayer();
		if ( localPlayer is null )
			return;

		string playerName = localPlayer.getUsername();
		CRules@ rules = getRules();
		
		CBitStream params1;
		params1.write_string(playerName);
		params1.write_u16(classID);
		rules.SendCommand(rules.getCommandID("unlock class"), params1);
		
		CBitStream params2;
		params2.write_string(playerName);
		params2.write_string(name);
		rules.SendCommand(rules.getCommandID("announce class unlock"), params2);
		
		print("Class Unlocked: "+ name);
		gained = true;
		
	}*/
	
	void draw(Vec2f pos)
	{
		classButton.position = pos;
		classButton.draw();
	}
}

class WWPlayerClassButtonList : GenericGUIItem
{
	WWPlayerClassButton@[] list;
	int style, timer = 0, page = 1, ApP, totalPages;
	GUIContainer@ tipAnchor = @GUIContainer(Vec2f(0,0),Vec2f(200,46)), pageAnchor = @GUIContainer(Vec2f(0,0),Vec2f(110,30));
	Window@ dropDownW = @Window(Vec2f(getScreenWidth()-400,-150),Vec2f(250,200),3);
	Button@ nextP = @Button(Vec2f(-520,0),Vec2f(30,30),"->",SColor(255,255,255,255)), prevP = @Button(Vec2f(-600,0),Vec2f(30,30),"<-",SColor(255,255,255,255));
	Label@ pageNum = @Label(Vec2f(-568,4),Vec2f(30,10),"Page\n 1",SColor(255,0,0,0),false);
	Label dropDownL;
	Icon dropDownD,dropDownR;
	Icon@ dropDownT = @Icon("GUI/achievement_get.png",Vec2f(45,3),Vec2f(157,25),0,0.5f);
	List@ playerChooser = @List(Vec2f(0,0),Vec2f(300,30));
	Button@ playerChooserArrow = @Button(Vec2f(-322,-430),Vec2f(30,30),"V",SColor(255,255,255,255));
	bool displaying = false, needsUpdate = false, hoverDet = false;
	

	//Styles: 0 = mini|1= small\\
	WWPlayerClassButtonList(Vec2f _position,Vec2f _size,int _style){

		super(_position,_size);
		style = _style;
		DebugColor = SColor(155,0,0,0);
		CRules@ rules = getRules();
		pageAnchor.addChild(nextP);
		nextP.locked = true;
		pageAnchor.addChild(pageNum);
		pageAnchor.addChild(prevP);
		prevP.locked = true;
		pageAnchor.addChild(playerChooserArrow);
		playerChooserArrow.locked = true;
		if (_style == 1)ApP = (int(_size.x / 204))*(int(_size.y/50)) - 1;
		//rules.addCommandID("announce class unlock");
		rules.addCommandID("requestClasses");
		rules.addCommandID("sendClasses");
		playerChooser.setCurrentItem("Your Classes");
	}

	void registerWWPlayerClassButton(string _name, string _desc, string _configFilename, int _classID, int _cost, int _icon = 0, int _rarity = 0,string _modName = "Default", 
		string _imageName = "GUI/ClassIcons.png", int _size = 1)
	{
		WWPlayerClassButton@ classButton = @WWPlayerClassButton(_name, _desc, _configFilename, _classID, _cost, _imageName, _icon, _rarity, _modName, position, _size);
		list.push_back(classButton);
		totalPages = (list.length / ApP)+1;
		if (totalPages > 1)nextP.locked = false;
		pageNum.setText("  Page\n  1/"+totalPages);
	}
	
	/*void unlockByName(string _name)
	{
	
		CRules@ rules = getRules();
		CPlayer@ player = getLocalPlayer();
		string playerName;  
		bool temp;
		if ( player is null ){ playerName = "Unknown Player";}
		else {playerName = player.getUsername();}
		for(int i = 0; i < list.length; i++)
		{
			if(list[i].name == _name && !list[i].checkUnlocked())
			{
				if (playerChooser.current.label != "Your Classes") temp = list[i].gained;
				list[i].Unlock();
				if (playerChooser.current.label != "Your Classes") list[i].gained = temp;
				startDisplay(list[i]);
				CBitStream params;
				params.write_string(playerName);
				params.write_string(list[i].name);
				rules.SendCommand(rules.getCommandID("announce class unlock"),params);
			}
		}
		
	}*/
	

	void startDisplay(WWPlayerClassButton@ classButton)
	{
		Icon rarity  = classButton.rarity;//Required for a linux fix (on asu's build) caused by .rarity and others being const
		Icon display = classButton.display;//^
		Label desc   = classButton.desc;// ^
		dropDownR = rarity;
		dropDownR.localPosition = classButton.rarity.localPosition + Vec2f(0,30);
		dropDownD = display;
		dropDownD.localPosition = classButton.display.localPosition + Vec2f(0,30);
		dropDownL = desc;
		dropDownL.localPosition = classButton.desc.localPosition + Vec2f(0,30);
		dropDownL.size = classButton.desc.size + Vec2f(110,0);
		dropDownL.setText(dropDownL.label + "\n"+ dropDownL.textWrap(classButton.description));
		dropDownW.clearChildren();
		dropDownW.addChild(dropDownD);
		dropDownW.addChild(dropDownR);
		dropDownW.addChild(dropDownL);
		dropDownW.addChild(dropDownT);
		displaying = true;
	}

	void display()
	{
		if(dropDownW.position.y < 0 && timer < 10){ dropDownW.position = dropDownW.position + Vec2f(0,10);}
		else{ timer++;}
		if (timer > 80 && dropDownW.position.y > -150){ dropDownW.position = dropDownW.position - Vec2f(0,10);}
		else if (timer > 80){ displaying = false; timer = 0;}
		dropDownW.draw();
	}


	void drawSelf(){
		hoverDet = false;
		if (nextP.isClickedWithLButton)clickerHandle(nextP);
		if (prevP.isClickedWithLButton)clickerHandle(prevP);
		if (style == 1)renderSmall();
		playerChooser.position = Vec2f(position.x,position.y-30);
		playerChooser.draw();
		if (playerChooser.isClickedWithLButton)clickerHandle(playerChooser);
		if (playerChooser.anchor.isClickedWithLButton) {needsUpdate = true;playerChooser.anchor.isClickedWithLButton=false;}
		pageAnchor.position = position + Vec2f(size.x-110,size.y);
		pageAnchor.draw();
		if (hoverDet && !playerChooser.open) tipAnchor.draw();
		GenericGUIItem::drawSelf();
	}

	void renderSmall()
	{
		
		needsUpdate = false;
		int counterH=0,counterV=0, i = ApP * (page-1);
		for(i; i < list.length; i++){
			if(50*counterV+46 > size.y){counterH++;counterV= 0;}
			if(204*counterH+200 > size.x)break;
			list[i].draw(position+ Vec2f((204*counterH),(50*counterV)));
			GUI::DrawRectangle(list[i].classButton.position, list[i].classButton.position+list[i].classButton.size,SColor(0,150,150,150));
			counterV++;
		}
		
	}

	void clickerHandle(IGUIItem@ sender){ //Internal click handler to operate playerchooser, and page buttons
		if(sender is nextP){
			page +=1;
			if (page == totalPages)sender.locked = true;
			if (prevP.locked) prevP.locked = false;
			pageNum.setText(" Page\n  "+page+"/"+totalPages);
		}
		if (sender is prevP){
			page -=1;
			if (page == 1)sender.locked = true;
			if (nextP.locked ) nextP.locked = false;
			pageNum.setText(" Page\n  "+page+"/"+totalPages);
		}
		if (sender is playerChooser){
			playerChooser.resetList();
			int count = getPlayerCount();
			for(int i = 0; i < count; i++){
				CPlayer@ player = getPlayer(i);
				if (player.isMyPlayer()){playerChooser.addItem("Your Classes");}
				else {playerChooser.addItem(player.getUsername()+"'s Classes");}
			}
			playerChooser.open = true;
		}
	}
}

void intitializeClasses()
{
	string configstr = "../Cache/WizardWars_Classes"+classesVersion+".cfg";
	ConfigFile cfg = ConfigFile( configstr );
	if (!cfg.exists("Version")){cfg.add_string("Version","Classes 1.2");
		cfg.saveFile("WizardWars_Classes"+classesVersion+".cfg");}
	playerClassButtons = WWPlayerClassButtonList(Vec2f(50,40),Vec2f(700,400),1);
	playerClassButtons.isEnabled = false;
	
	playerClassButtons.registerWWPlayerClassButton("Wizard", 
													"     A versatile magic-weilding class with a wide variety of spells at their disposal. Control the natural elements to defeat foes and assist allies." +
													"\n\n     Health: 75" +
													"\n     Mana: 150" +
													"\n     Mana Regen: 3 mana/sec", 
													"wizard", 0, 0, 2, 5, "WizardWars");
	
	playerClassButtons.registerWWPlayerClassButton("Necromancer", 
													"     A spell-caster who is able to summon the undead and specializes in dark magic. Takes on the role of AOE damage support, but can hold his own in combat." +
													"\n\n     Health: 75" +
													"\n     Mana: 100" +
													"\n     Mana Regen: 4 mana/sec", 
													"necromancer", 1, 0, 3, 5, "WizardWars");
	
	playerClassButtons.registerWWPlayerClassButton("Knight", 
													"     A shit class really... All he can do is hack and slash. His shield is surprisingly effective. Maybe one day he will prove to be as great as the mighty wizard." +
													"\n\n     Health: 90" +
													"\n     Mana: 0" +
													"\n     Mana Regen: 0 mana/sec",
													"knight", 2, 10, 0, 0, "WizardWars");

	playerClassButtons.registerWWPlayerClassButton("Druid", 
													"     A healing bastard. Druids claim to be in tune with nature, but they fail to mention how annoying bees can be. " +
													"\n\n     Health: 75" +
													"\n     Mana: 150" +
													"\n     Mana Regen: 4 mana/sec",
													"druid", 3, 20, 4, 0, "WizardWars");
													
	playerClassButtons.registerWWPlayerClassButton("SwordCaster", 
													"     \"This is a good day for SwordCasters all around the world.\" " +
													"\n\n     Health: 70" +
													"\n     Mana: 70" +
													"\n     Mana Regen: 3 mana/sec",
													"swordcaster", 4, 0, 5, 0, "WizardWars");
	playerClassButtons.registerWWPlayerClassButton("Entropist", 
													"     There is no better feeling than giving the enemy a taste of their own medicine." +
													"\n\n     Health: 75" +
													"\n     Mana: 200" +
													"\n     Mana is obtained by absorbing enemy spells.",
													"entropist", 5, 0, 6, 0, "WizardWars");
													
/*	playerClassButtons.registerWWPlayerClassButton("Spaceship Combat Initiative", 
													"     Frigate Prototype. In highly fragile state. " +
													"\n\n     Health: 10" +
													"\n     Mana: 300" +
													"\n     Mana Regen: 0 mana/sec",
													"frigate", 6, 0, 6, 0, "WizardWars");

	playerClassButtons.registerWWPlayerClassButton("Archer", 
													"     The most powerful class ever with over 1000 mana fit for taking on the Gods. Too bad they skipped magic class. " +
													"\n\n     Health: 40" +
													"\n     Mana: 1001" +
													"\n     Mana Regen: 100 mana/sec",
													"archer", 6, 0, 6, 0, "WizardWars");*/
}

void SwapButtonHandler(int x , int y , int button, IGUIItem@ sender)	//Button click handler for KGUI
{ 
	CPlayer@ localPlayer = getLocalPlayer();
	if ( localPlayer is null )
		return;
		
	string playerName = localPlayer.getUsername();
	//bool[] unlocks = server_getPlayerUnlocks(playerName);
	
	u16 callerID = localPlayer.getNetworkID();

	CBitStream params;
	params.write_u16(callerID);
	params.write_string(sender.name);
	
	CRules@ rules = getRules();
	rules.SendCommand(rules.getCommandID("swap classes"), params);

	Sound::Play( "MenuSelect2.ogg" );	
}
/*
void UnlockButtonHandler(int x , int y , int button, IGUIItem@ sender)	//Button click handler for KGUI
{ 
	CPlayer@ localPlayer = getLocalPlayer();
	if ( localPlayer is null )
		return;
	
	string playerName = localPlayer.getUsername();
	for(int i = 0; i < playerClassButtons.list.length; i++)
	{
		Button@ iButton = playerClassButtons.list[i].classButton;
		if ( iButton.toggled == true )
		{
			CBitStream params;
			params.write_string(playerName);
			params.write_u16(i);
			
			CRules@ rules = getRules();
			rules.SendCommand(rules.getCommandID("buy unlock"), params);
			
			u32 clientPlatinum = client_getPlayerPlatinum(playerName);
			if ( clientPlatinum >= playerClassButtons.list[i].classCost )
				playerClassButtons.list[i].gained = true;
		}
	}

	Sound::Play( "MenuSelect2.ogg" );	
}
*/

void ClassButtonHandler(int x , int y , int button, IGUIItem@ sender)	//Button click handler for KGUI
{ 
	// toggle buttons accordingly
	for(int i = 0; i < playerClassButtons.list.length; i++)
	{
		Button@ iButton = playerClassButtons.list[i].classButton;	
		if ( iButton.name == sender.name )
		{
			if ( iButton.toggled == false )
				Sound::Play( "MenuSelect2.ogg" );
				
			iButton.toggled = true;
			
			playerClassButtons.list[i].classFrame.isEnabled = true;
		}
		else
		{
			iButton.toggled = false;
			
			playerClassButtons.list[i].classFrame.isEnabled = false;
		}
	}	
}

void SpellButtonHandler(int x , int y , int button, IGUIItem@ sender)	//Button click handler for KGUI
{ 
	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer is null )
	{
		return;
	}
	
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!localPlayer.get( "playerPrefsInfo", @playerPrefsInfo )) 
	{
		return;
	}

	// toggle buttons accordingly
	bool buttonToggled = false;
	for(int c = 0; c < playerClassButtons.list.length; c++)
	{
		Button@ cButton = playerClassButtons.list[c].classButton;	
		for(int s = 0; s < playerClassButtons.list[c].spellButtons.length; s++)
		{
			Button@ sButton = playerClassButtons.list[c].spellButtons[s];
			if ( sButton.name == sender.name && playerClassButtons.list[c].classFrame.isEnabled )
			{
				SetCustomSpell(localPlayer, s);
			
				if ( sButton.toggled == false && sender.name != "" ) 
					Sound::Play( "MenuSelect2.ogg" );
				
				sButton.toggled = true;
				
				Spell sSpell;
				if ( cButton.name == "wizard" )
					sSpell = WizardParams::spells[Maths::Min( s,(WizardParams::spells.length-1) )];
				else if ( cButton.name == "druid" )
					sSpell = DruidParams::spells[Maths::Min( s,(DruidParams::spells.length-1) )];
				else if ( cButton.name == "necromancer" )
					sSpell = NecromancerParams::spells[Maths::Min( s,(NecromancerParams::spells.length-1) )];
				else if ( cButton.name == "swordcaster" )
					sSpell = SwordCasterParams::spells[Maths::Min( s,(SwordCasterParams::spells.length-1) )];
				else if ( cButton.name == "entropist" )
					sSpell = EntropistParams::spells[Maths::Min( s,(EntropistParams::spells.length-1) )];
				else if ( cButton.name == "frigate" )
					sSpell = FrigateParams::spells[Maths::Min( s,(FrigateParams::spells.length-1) )];
					
				playerClassButtons.list[c].spellDescText.setText(playerClassButtons.list[c].spellDescText.textWrap("-- " + sSpell.name + " --" + 
																													"\n     " + sSpell.spellDesc + 
																													"\n\n  Mana cost: " + sSpell.mana));
			}
			else
			{
				sButton.toggled = false;
			}
		}
	}	
}

void RenderClassMenus()		//very light use of KGUI
{
	if ( playerClassButtons.isEnabled == false )
		return;

	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer is null )
	{
		return;
	}
	
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!localPlayer.get( "playerPrefsInfo", @playerPrefsInfo )) 
	{
		return;
	}
	
	if ( playerPrefsInfo.infoLoaded == false )
	{
		return;
	}

	for(int i = 0; i < playerClassButtons.list.length; i++)
	{
		Button@ iButton = playerClassButtons.list[i].classButton;
		if ( iButton.toggled == true )
		{
			if ( iButton.name == "wizard" )
			{
				CControls@ controls = localPlayer.getControls();
				Vec2f mouseScreenPos = controls.getMouseScreenPos();
			
				u8[] primaryHotkeys = playerPrefsInfo.hotbarAssignments_Wizard;
			
				//PRIMARY SPELL HUD
				Vec2f offset = Vec2f(264.0f, 350.0f);
				Vec2f primaryPos = helpWindow.position + Vec2f( 16.0f, 0.0f ) + offset;
				
				bool canCustomizeHotbar = controls.mousePressed1 && controls.lastKeyPressTime != lastHotbarPressTime;
				bool hotbarClicked = false;
				int spellsLength = WizardParams::spells.length;
				for (uint i = 0; i < 15; i++)	//only 15 total spells held inside primary hotbar
				{
					u8 primarySpellID = Maths::Min(primaryHotkeys[i], spellsLength-1);
					Spell spell = WizardParams::spells[primarySpellID];
					
					if ( i < 5 )		//spells 0 through 4
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,96) + Vec2f(32,0)*i);
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,64) + Vec2f(32,0)*i);
						GUI::DrawText(""+((i+1)%10), primaryPos + Vec2f(8,-16) + Vec2f(32,0)*i, color_white );
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,80) + Vec2f(32,0)*i) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "wizard");
							hotbarClicked = true;
						}			
					}
					else if ( i < 10 )	//spells 5 through 9	
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,64) + Vec2f(32,0)*(i-5));
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5));
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,48) + Vec2f(32,0)*(i-5)) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "wizard");
							hotbarClicked = true;
						}
					}
					else				//spells 10 through 14
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,32) + Vec2f(32,0)*(i-10));
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(32,0)*(i-10));			
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,16) + Vec2f(32,0)*(i-10)) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "wizard");
							hotbarClicked = true;
						}
					}
				}
				
				GUI::DrawText("Primary - "+controls.getActionKeyKeyName( AK_ACTION1 ), primaryPos + Vec2f(0,-32), color_white );
				
				//SECONDARY SPELL HUD
				Vec2f secondaryPos = helpWindow.position + Vec2f( 192.0f, 0.0f ) + offset;
				
				u8 secondarySpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Wizard[15], spellsLength-1);
				Spell secondarySpell = WizardParams::spells[secondarySpellID];
				
				GUI::DrawFramedPane(secondaryPos, secondaryPos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", secondarySpell.iconFrame, Vec2f(16,16), secondaryPos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (secondaryPos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 15, playerPrefsInfo.customSpellID, "wizard");	//hotkey 15 is the secondary fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Secondary - "+controls.getActionKeyKeyName( AK_ACTION2 ), secondaryPos + Vec2f(32,8), color_white );	
				
				//AUXILIARY1 SPELL HUD
				Vec2f aux1Pos = helpWindow.position + Vec2f( 192.0f, 64.0f ) + offset;
				
				u8 aux1SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Wizard[16], spellsLength-1);
				Spell aux1Spell = WizardParams::spells[aux1SpellID];
				
				GUI::DrawFramedPane(aux1Pos, aux1Pos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", aux1Spell.iconFrame, Vec2f(16,16), aux1Pos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (aux1Pos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 16, playerPrefsInfo.customSpellID, "wizard");	//hotkey 16 is the auxiliary1 fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Auxiliary1 - "+controls.getActionKeyKeyName( AK_ACTION3 ), aux1Pos + Vec2f(32,8), color_white );

				//AUXILIARY2 SPELL HUD
				Vec2f aux2Pos = helpWindow.position + Vec2f( 364.0f, 0.0f ) + offset;
				
				u8 aux2SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Wizard[17], spellsLength-1);
				Spell aux2Spell = WizardParams::spells[aux2SpellID];
				
				GUI::DrawFramedPane(aux2Pos, aux2Pos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", aux2Spell.iconFrame, Vec2f(16,16), aux2Pos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (aux2Pos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 17, playerPrefsInfo.customSpellID, "wizard");	//hotkey 17 is the auxiliary2 fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Auxiliary2 - "+controls.getActionKeyKeyName( AK_TAUNTS ), aux2Pos + Vec2f(32,8), color_white );					
				
				if ( canCustomizeHotbar == true )	//play sound, keep menu open by refreshing, and update selected spell 
				{
					if ( hotbarClicked )
					{
						lastHotbarPressTime = controls.lastKeyPressTime;
						Sound::Play( "MenuSelect1.ogg" );	
					}
				}
			}
			if ( iButton.name == "druid" )
			{
				CControls@ controls = localPlayer.getControls();
				Vec2f mouseScreenPos = controls.getMouseScreenPos();
			
				u8[] primaryHotkeys = playerPrefsInfo.hotbarAssignments_Druid;
			
				//PRIMARY SPELL HUD
				Vec2f offset = Vec2f(264.0f, 350.0f);
				Vec2f primaryPos = helpWindow.position + Vec2f( 16.0f, 0.0f ) + offset;
				
				bool canCustomizeHotbar = controls.mousePressed1 && controls.lastKeyPressTime != lastHotbarPressTime;
				bool hotbarClicked = false;
				int spellsLength = DruidParams::spells.length;
				for (uint i = 0; i < 15; i++)	//only 15 total spells held inside primary hotbar
				{
					u8 primarySpellID = Maths::Min(primaryHotkeys[i], spellsLength-1);
					Spell spell = DruidParams::spells[primarySpellID];
					
					if ( i < 5 )		//spells 0 through 4
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,96) + Vec2f(32,0)*i);
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,64) + Vec2f(32,0)*i);
						GUI::DrawText(""+((i+1)%10), primaryPos + Vec2f(8,-16) + Vec2f(32,0)*i, color_white );
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,80) + Vec2f(32,0)*i) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "druid");
							hotbarClicked = true;
						}			
					}
					else if ( i < 10 )	//spells 5 through 9	
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,64) + Vec2f(32,0)*(i-5));
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5));
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,48) + Vec2f(32,0)*(i-5)) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "druid");
							hotbarClicked = true;
						}
					}
					else				//spells 10 through 14
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,32) + Vec2f(32,0)*(i-10));
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(32,0)*(i-10));			
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,16) + Vec2f(32,0)*(i-10)) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "druid");
							hotbarClicked = true;
						}
					}
				}
				
				GUI::DrawText("Primary - "+controls.getActionKeyKeyName( AK_ACTION1 ), primaryPos + Vec2f(0,-32), color_white );
				
				//SECONDARY SPELL HUD
				Vec2f secondaryPos = helpWindow.position + Vec2f( 192.0f, 0.0f ) + offset;
				
				u8 secondarySpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Druid[15], spellsLength-1);
				Spell secondarySpell = DruidParams::spells[secondarySpellID];
				
				GUI::DrawFramedPane(secondaryPos, secondaryPos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", secondarySpell.iconFrame, Vec2f(16,16), secondaryPos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (secondaryPos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 15, playerPrefsInfo.customSpellID, "druid");	//hotkey 15 is the secondary fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Secondary - "+controls.getActionKeyKeyName( AK_ACTION2 ), secondaryPos + Vec2f(32,8), color_white );	
				
				//AUXILIARY1 SPELL HUD
				Vec2f aux1Pos = helpWindow.position + Vec2f( 192.0f, 64.0f ) + offset;
				
				u8 aux1SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Druid[16], spellsLength-1);
				Spell aux1Spell = DruidParams::spells[aux1SpellID];
				
				GUI::DrawFramedPane(aux1Pos, aux1Pos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", aux1Spell.iconFrame, Vec2f(16,16), aux1Pos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (aux1Pos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 16, playerPrefsInfo.customSpellID, "druid");	//hotkey 16 is the auxiliary1 fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Auxiliary1 - "+controls.getActionKeyKeyName( AK_ACTION3 ), aux1Pos + Vec2f(32,8), color_white );

				//AUXILIARY2 SPELL HUD
				Vec2f aux2Pos = helpWindow.position + Vec2f( 364.0f, 0.0f ) + offset;
				
				u8 aux2SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Druid[17], spellsLength-1);
				Spell aux2Spell = DruidParams::spells[aux2SpellID];
				
				GUI::DrawFramedPane(aux2Pos, aux2Pos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", aux2Spell.iconFrame, Vec2f(16,16), aux2Pos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (aux2Pos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 17, playerPrefsInfo.customSpellID, "druid");	//hotkey 17 is the auxiliary2 fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Auxiliary2 - "+controls.getActionKeyKeyName( AK_TAUNTS ), aux2Pos + Vec2f(32,8), color_white );					
				
				if ( canCustomizeHotbar == true )	//play sound, keep menu open by refreshing, and update selected spell 
				{
					if ( hotbarClicked )
					{
						lastHotbarPressTime = controls.lastKeyPressTime;
						Sound::Play( "MenuSelect1.ogg" );	
					}
				}
			}
			if ( iButton.name == "necromancer" )
			{
				CControls@ controls = localPlayer.getControls();
				Vec2f mouseScreenPos = controls.getMouseScreenPos();
			
				u8[] primaryHotkeys = playerPrefsInfo.hotbarAssignments_Necromancer;
			
				//PRIMARY SPELL HUD
				Vec2f offset = Vec2f(264.0f, 350.0f);
				Vec2f primaryPos = helpWindow.position + Vec2f( 16.0f, 0.0f ) + offset;
				
				bool canCustomizeHotbar = controls.mousePressed1 && controls.lastKeyPressTime != lastHotbarPressTime;
				bool hotbarClicked = false;
				int spellsLength = NecromancerParams::spells.length;
				for (uint i = 0; i < 15; i++)	//only 15 total spells held inside primary hotbar
				{
					u8 primarySpellID = Maths::Min(primaryHotkeys[i], spellsLength-1);
					Spell spell = NecromancerParams::spells[primarySpellID];
					
					if ( i < 5 )		//spells 0 through 4
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,96) + Vec2f(32,0)*i);
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,64) + Vec2f(32,0)*i);
						GUI::DrawText(""+((i+1)%10), primaryPos + Vec2f(8,-16) + Vec2f(32,0)*i, color_white );
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,80) + Vec2f(32,0)*i) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "necromancer");
							hotbarClicked = true;
						}			
					}
					else if ( i < 10 )	//spells 5 through 9	
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,64) + Vec2f(32,0)*(i-5));
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5));
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,48) + Vec2f(32,0)*(i-5)) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "necromancer");
							hotbarClicked = true;
						}
					}
					else				//spells 10 through 14
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,32) + Vec2f(32,0)*(i-10));
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(32,0)*(i-10));			
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,16) + Vec2f(32,0)*(i-10)) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "necromancer");
							hotbarClicked = true;
						}
					}
				}
				
				GUI::DrawText("Primary - "+controls.getActionKeyKeyName( AK_ACTION1 ), primaryPos + Vec2f(0,-32), color_white );
				
				//SECONDARY SPELL HUD
				Vec2f secondaryPos = helpWindow.position + Vec2f( 192.0f, 0.0f ) + offset;
							
				u8 secondarySpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Necromancer[15], spellsLength-1);
				Spell secondarySpell = NecromancerParams::spells[secondarySpellID];
				
				GUI::DrawFramedPane(secondaryPos, secondaryPos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", secondarySpell.iconFrame, Vec2f(16,16), secondaryPos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (secondaryPos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 15, playerPrefsInfo.customSpellID, "necromancer");	//hotkey 15 is the secondary fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Secondary - "+controls.getActionKeyKeyName( AK_ACTION2 ), secondaryPos + Vec2f(32,8), color_white );	
				
				//AUXILIARY1 SPELL HUD
				Vec2f aux1Pos = helpWindow.position + Vec2f( 192.0f, 64.0f ) + offset;
				
				u8 aux1SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Necromancer[16], spellsLength-1);
				Spell aux1Spell = NecromancerParams::spells[aux1SpellID];	
				
				GUI::DrawFramedPane(aux1Pos, aux1Pos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", aux1Spell.iconFrame, Vec2f(16,16), aux1Pos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (aux1Pos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 16, playerPrefsInfo.customSpellID, "necromancer");	//hotkey 16 is the auxiliary1 fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Auxiliary1 - "+controls.getActionKeyKeyName( AK_ACTION3 ), aux1Pos + Vec2f(32,8), color_white );

				//AUXILIARY2 SPELL HUD
				Vec2f aux2Pos = helpWindow.position + Vec2f( 364.0f, 0.0f ) + offset;
				
				u8 aux2SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Necromancer[17], spellsLength-1);
				Spell aux2Spell = NecromancerParams::spells[aux2SpellID];
				
				GUI::DrawFramedPane(aux2Pos, aux2Pos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", aux2Spell.iconFrame, Vec2f(16,16), aux2Pos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (aux2Pos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 17, playerPrefsInfo.customSpellID, "necromancer");	//hotkey 17 is the auxiliary2 fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Auxiliary2 - "+controls.getActionKeyKeyName( AK_TAUNTS ), aux2Pos + Vec2f(32,8), color_white );						
				
				if ( canCustomizeHotbar == true )	//play sound, keep menu open by refreshing, and update selected spell 
				{
					if ( hotbarClicked )
					{
						lastHotbarPressTime = controls.lastKeyPressTime;
						Sound::Play( "MenuSelect1.ogg" );	
					}
				}
			}
			if ( iButton.name == "swordcaster" )
			{
				CControls@ controls = localPlayer.getControls();
				Vec2f mouseScreenPos = controls.getMouseScreenPos();
			
				u8[] primaryHotkeys = playerPrefsInfo.hotbarAssignments_SwordCaster;
			
				//PRIMARY SPELL HUD
				Vec2f offset = Vec2f(264.0f, 350.0f);
				Vec2f primaryPos = helpWindow.position + Vec2f( 16.0f, 0.0f ) + offset;
				
				bool canCustomizeHotbar = controls.mousePressed1 && controls.lastKeyPressTime != lastHotbarPressTime;
				bool hotbarClicked = false;
				int spellsLength = SwordCasterParams::spells.length;
				for (uint i = 0; i < 15; i++)	//only 15 total spells held inside primary hotbar
				{
					u8 primarySpellID = Maths::Min(primaryHotkeys[i], spellsLength-1);
					Spell spell = SwordCasterParams::spells[primarySpellID];
					
					if ( i < 5 )		//spells 0 through 4
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,96) + Vec2f(32,0)*i);
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,64) + Vec2f(32,0)*i);
						GUI::DrawText(""+((i+1)%10), primaryPos + Vec2f(8,-16) + Vec2f(32,0)*i, color_white );
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,80) + Vec2f(32,0)*i) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "swordcaster");
							hotbarClicked = true;
						}			
					}
					else if ( i < 10 )	//spells 5 through 9	
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,64) + Vec2f(32,0)*(i-5));
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5));
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,48) + Vec2f(32,0)*(i-5)) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "swordcaster");
							hotbarClicked = true;
						}
					}
					else				//spells 10 through 14
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,32) + Vec2f(32,0)*(i-10));
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(32,0)*(i-10));			
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,16) + Vec2f(32,0)*(i-10)) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "swordcaster");
							hotbarClicked = true;
						}
					}
				}
				
				GUI::DrawText("Primary - "+controls.getActionKeyKeyName( AK_ACTION1 ), primaryPos + Vec2f(0,-32), color_white );
				
				//SECONDARY SPELL HUD
				Vec2f secondaryPos = helpWindow.position + Vec2f( 192.0f, 0.0f ) + offset;
				
				u8 secondarySpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_SwordCaster[15], spellsLength-1);
				Spell secondarySpell = SwordCasterParams::spells[secondarySpellID];
				
				GUI::DrawFramedPane(secondaryPos, secondaryPos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", secondarySpell.iconFrame, Vec2f(16,16), secondaryPos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (secondaryPos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 15, playerPrefsInfo.customSpellID, "swordcaster");	//hotkey 15 is the secondary fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Secondary - "+controls.getActionKeyKeyName( AK_ACTION2 ), secondaryPos + Vec2f(32,8), color_white );	
				
				//AUXILIARY1 SPELL HUD
				Vec2f aux1Pos = helpWindow.position + Vec2f( 192.0f, 64.0f ) + offset;
				
				u8 aux1SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_SwordCaster[16], spellsLength-1);
				Spell aux1Spell = SwordCasterParams::spells[aux1SpellID];
				
				GUI::DrawFramedPane(aux1Pos, aux1Pos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", aux1Spell.iconFrame, Vec2f(16,16), aux1Pos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (aux1Pos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 16, playerPrefsInfo.customSpellID, "swordcaster");	//hotkey 16 is the auxiliary1 fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Auxiliary1 - "+controls.getActionKeyKeyName( AK_ACTION3 ), aux1Pos + Vec2f(32,8), color_white );

				//AUXILIARY2 SPELL HUD
				Vec2f aux2Pos = helpWindow.position + Vec2f( 364.0f, 0.0f ) + offset;
				
				u8 aux2SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_SwordCaster[17], spellsLength-1);
				Spell aux2Spell = SwordCasterParams::spells[aux2SpellID];
				
				GUI::DrawFramedPane(aux2Pos, aux2Pos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", aux2Spell.iconFrame, Vec2f(16,16), aux2Pos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (aux2Pos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 17, playerPrefsInfo.customSpellID, "swordcaster");	//hotkey 17 is the auxiliary2 fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Auxiliary2 - "+controls.getActionKeyKeyName( AK_TAUNTS ), aux2Pos + Vec2f(32,8), color_white );					
				
				if ( canCustomizeHotbar == true )	//play sound, keep menu open by refreshing, and update selected spell 
				{
					if ( hotbarClicked )
					{
						lastHotbarPressTime = controls.lastKeyPressTime;
						Sound::Play( "MenuSelect1.ogg" );	
					}
				}
			}
			if ( iButton.name == "entropist" )
			{
				CControls@ controls = localPlayer.getControls();
				Vec2f mouseScreenPos = controls.getMouseScreenPos();
			
				u8[] primaryHotkeys = playerPrefsInfo.hotbarAssignments_Entropist;
			
				//PRIMARY SPELL HUD
				Vec2f offset = Vec2f(264.0f, 350.0f);
				Vec2f primaryPos = helpWindow.position + Vec2f( 16.0f, 0.0f ) + offset;
				
				bool canCustomizeHotbar = controls.mousePressed1 && controls.lastKeyPressTime != lastHotbarPressTime;
				bool hotbarClicked = false;
				int spellsLength = EntropistParams::spells.length;
				for (uint i = 0; i < 15; i++)	//only 15 total spells held inside primary hotbar
				{
					u8 primarySpellID = Maths::Min(primaryHotkeys[i], spellsLength-1);
					Spell spell = EntropistParams::spells[primarySpellID];
					
					if ( i < 5 )		//spells 0 through 4
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,96) + Vec2f(32,0)*i);
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,64) + Vec2f(32,0)*i);
						GUI::DrawText(""+((i+1)%10), primaryPos + Vec2f(8,-16) + Vec2f(32,0)*i, color_white );
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,80) + Vec2f(32,0)*i) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "entropist");
							hotbarClicked = true;
						}			
					}
					else if ( i < 10 )	//spells 5 through 9	
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,64) + Vec2f(32,0)*(i-5));
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5));
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,48) + Vec2f(32,0)*(i-5)) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "entropist");
							hotbarClicked = true;
						}
					}
					else				//spells 10 through 14
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,32) + Vec2f(32,0)*(i-10));
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(32,0)*(i-10));			
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,16) + Vec2f(32,0)*(i-10)) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "entropist");
							hotbarClicked = true;
						}
					}
				}
				
				GUI::DrawText("Primary - "+controls.getActionKeyKeyName( AK_ACTION1 ), primaryPos + Vec2f(0,-32), color_white );
				
				//SECONDARY SPELL HUD
				Vec2f secondaryPos = helpWindow.position + Vec2f( 192.0f, 0.0f ) + offset;
				
				u8 secondarySpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Entropist[15], spellsLength-1);
				Spell secondarySpell = EntropistParams::spells[secondarySpellID];
				
				GUI::DrawFramedPane(secondaryPos, secondaryPos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", secondarySpell.iconFrame, Vec2f(16,16), secondaryPos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (secondaryPos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 15, playerPrefsInfo.customSpellID, "entropist");	//hotkey 15 is the secondary fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Secondary - "+controls.getActionKeyKeyName( AK_ACTION2 ), secondaryPos + Vec2f(32,8), color_white );	
				
				//AUXILIARY1 SPELL HUD
				Vec2f aux1Pos = helpWindow.position + Vec2f( 192.0f, 64.0f ) + offset;
				
				u8 aux1SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Entropist[16], spellsLength-1);
				Spell aux1Spell = EntropistParams::spells[aux1SpellID];
				
				GUI::DrawFramedPane(aux1Pos, aux1Pos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", aux1Spell.iconFrame, Vec2f(16,16), aux1Pos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (aux1Pos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 16, playerPrefsInfo.customSpellID, "entropist");	//hotkey 16 is the auxiliary1 fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Auxiliary1 - "+controls.getActionKeyKeyName( AK_ACTION3 ), aux1Pos + Vec2f(32,8), color_white );

				//AUXILIARY2 SPELL HUD
				Vec2f aux2Pos = helpWindow.position + Vec2f( 364.0f, 0.0f ) + offset;
				
				u8 aux2SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Entropist[17], spellsLength-1);
				Spell aux2Spell = EntropistParams::spells[aux2SpellID];
				
				GUI::DrawFramedPane(aux2Pos, aux2Pos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", aux2Spell.iconFrame, Vec2f(16,16), aux2Pos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (aux2Pos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 17, playerPrefsInfo.customSpellID, "entropist");	//hotkey 17 is the auxiliary2 fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Auxiliary2 - "+controls.getActionKeyKeyName( AK_TAUNTS ), aux2Pos + Vec2f(32,8), color_white );					
				
				if ( canCustomizeHotbar == true )	//play sound, keep menu open by refreshing, and update selected spell 
				{
					if ( hotbarClicked )
					{
						lastHotbarPressTime = controls.lastKeyPressTime;
						Sound::Play( "MenuSelect1.ogg" );	
					}
				}
			}
			if ( iButton.name == "frigate" )
			{
				CControls@ controls = localPlayer.getControls();
				Vec2f mouseScreenPos = controls.getMouseScreenPos();
			
				u8[] primaryHotkeys = playerPrefsInfo.hotbarAssignments_Frigate;
			
				//PRIMARY SPELL HUD
				Vec2f offset = Vec2f(264.0f, 350.0f);
				Vec2f primaryPos = helpWindow.position + Vec2f( 16.0f, 0.0f ) + offset;
				
				bool canCustomizeHotbar = controls.mousePressed1 && controls.lastKeyPressTime != lastHotbarPressTime;
				bool hotbarClicked = false;
				int spellsLength = FrigateParams::spells.length;
				for (uint i = 0; i < 15; i++)	//only 15 total spells held inside primary hotbar
				{
					u8 primarySpellID = Maths::Min(primaryHotkeys[i], spellsLength-1);
					Spell spell = FrigateParams::spells[primarySpellID];
					
					if ( i < 5 )		//spells 0 through 4
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,96) + Vec2f(32,0)*i);
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,64) + Vec2f(32,0)*i);
						GUI::DrawText(""+((i+1)%10), primaryPos + Vec2f(8,-16) + Vec2f(32,0)*i, color_white );
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,80) + Vec2f(32,0)*i) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "frigate");
							hotbarClicked = true;
						}			
					}
					else if ( i < 10 )	//spells 5 through 9	
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,64) + Vec2f(32,0)*(i-5));
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5));
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,48) + Vec2f(32,0)*(i-5)) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "frigate");
							hotbarClicked = true;
						}
					}
					else				//spells 10 through 14
					{
						GUI::DrawFramedPane(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,32) + Vec2f(32,0)*(i-10));
						GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(32,0)*(i-10));			
							
						if ( canCustomizeHotbar && ( mouseScreenPos - (primaryPos + Vec2f(16,16) + Vec2f(32,0)*(i-10)) ).Length() < 16.0f )
						{
							assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, "frigate");
							hotbarClicked = true;
						}
					}
				}
				
				GUI::DrawText("Primary - "+controls.getActionKeyKeyName( AK_ACTION1 ), primaryPos + Vec2f(0,-32), color_white );
				
				//SECONDARY SPELL HUD
				/*Vec2f secondaryPos = helpWindow.position + Vec2f( 192.0f, 0.0f ) + offset;
				
				u8 secondarySpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Frigate[15], spellsLength-1);
				Spell secondarySpell = FrigateParams::spells[secondarySpellID];
				
				GUI::DrawFramedPane(secondaryPos, secondaryPos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", secondarySpell.iconFrame, Vec2f(16,16), secondaryPos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (secondaryPos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 15, playerPrefsInfo.customSpellID, "frigate");	//hotkey 15 is the secondary fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Secondary - "+controls.getActionKeyKeyName( AK_ACTION2 ), secondaryPos + Vec2f(32,8), color_white );	
				*/

				//AUXILIARY1 SPELL HUD
				Vec2f aux1Pos = helpWindow.position + Vec2f( 192.0f, 64.0f ) + offset;
				
				u8 aux1SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Frigate[15], spellsLength-1);
				Spell aux1Spell = FrigateParams::spells[aux1SpellID];
				
				GUI::DrawFramedPane(aux1Pos, aux1Pos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", aux1Spell.iconFrame, Vec2f(16,16), aux1Pos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (aux1Pos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 15, playerPrefsInfo.customSpellID, "frigate");	//hotkey 15 is the auxiliary1 fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Auxiliary1 - "+controls.getActionKeyKeyName( AK_ACTION3 ), aux1Pos + Vec2f(32,8), color_white );

				//AUXILIARY2 SPELL HUD
				Vec2f aux2Pos = helpWindow.position + Vec2f( 192.0f, 0.0f ) + offset;
				
				u8 aux2SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Frigate[16], spellsLength-1);
				Spell aux2Spell = FrigateParams::spells[aux2SpellID];
				
				GUI::DrawFramedPane(aux2Pos, aux2Pos + Vec2f(32,32));
				GUI::DrawIcon("SpellIcons.png", aux2Spell.iconFrame, Vec2f(16,16), aux2Pos);
					
				if ( canCustomizeHotbar && (mouseScreenPos - (aux2Pos + Vec2f(16,16))).Length() < 16.0f )
				{
					assignHotkey(localPlayer, 16, playerPrefsInfo.customSpellID, "frigate");	//hotkey 16 is the auxiliary2 fire hotkey
					hotbarClicked = true;
				}
				
				GUI::DrawText("Auxiliary2 - "+controls.getActionKeyKeyName( AK_TAUNTS ), aux2Pos + Vec2f(32,8), color_white );					
				
				if ( canCustomizeHotbar == true )	//play sound, keep menu open by refreshing, and update selected spell 
				{
					if ( hotbarClicked )
					{
						lastHotbarPressTime = controls.lastKeyPressTime;
						Sound::Play( "MenuSelect1.ogg" );	
					}
				}
			}
			else if ( iButton.name == "Knight" )
			{
			
			}
			/*else if ( iButton.name == "Archer" )
			{
			
			}*/
			
			break;
		}
	}	
}