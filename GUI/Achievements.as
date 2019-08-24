#include "KGUI.as";

string achievementsVersion = "2";

class AchieveList : GenericGUIItem{
	Achievement@[] list;
	int style, timer = 0, page = 1, ApP, totalPages;
	GUIContainer@ tipAnchor = @GUIContainer(Vec2f(0,0),Vec2f(200,46)), pageAnchor = @GUIContainer(Vec2f(0,0),Vec2f(110,30));
	Window@ dropDownW = @Window(Vec2f(getScreenWidth()-400,-150),Vec2f(250,80),3);
	Button@ nextP = @Button(Vec2f(80,0),Vec2f(30,30),"->",SColor(255,255,255,255)), prevP = @Button(Vec2f(0,0),Vec2f(30,30),"<-",SColor(255,255,255,255));
	Label dropDownL;
	Label@ pageNum = @Label(Vec2f(32,4),Vec2f(30,10),"Page\n 1",SColor(255,0,0,0),false);
	Icon dropDownD, dropDownR;
	Icon@ dropDownT = @Icon("GUI/achievement_get.png",Vec2f(45,3),Vec2f(157,25),0,0.5f);
	List@ playerChooser = @List(Vec2f(0,0),Vec2f(300,30));
	Button@ playerChooserArrow = @Button(Vec2f(-322,-430),Vec2f(30,30),"V",SColor(255,255,255,255));
	bool displaying = false, needsUpdate = false, hoverDet = false;
	

	//Styles: 0 = mini|1= small\\
	AchieveList(Vec2f _position,Vec2f _size,int _style){

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
		rules.addCommandID("unlockAchievement");
		rules.addCommandID("requestAchieves");
		rules.addCommandID("sendAchieves");
		playerChooser.setCurrentItem("Your Achievements");
		
	}

	Achievement getAchieveByName(string _name){
		for(int i = 0; i < list.length; i++){
			if(list[i].name == _name && !list[i].gained){
				return list[i];
			}
		}
		return list[0]; //default if name isn't found
	}

	void increaseCondition(string _name,float amount){
		float temp;
		for(int i = 0; i < list.length; i++){
			if(list[i].name == _name && !list[i].checkUnlocked()){
				if (playerChooser.current.label != "Your Achievements") {temp = list[i].conCurrent; list[i].conCurrent = list[i].getProgress();}
				list[i].conditionIncrease(amount);
				if (list[i].conCurrent == list[i].conMax) unlockByName(list[i].name);
				if (playerChooser.current.label != "Your Achievements") list[i].conditionSet(temp);
			}
		}
	}

	void reloadAchievements(){
		for (int i = 0; i < list.length; i++){
			list[i].gained = list[i].checkUnlocked();
			if (list[i].hasCon){
				list[i].conditionSet(list[i].getProgress());
			}
		}
	}

	void unlockByName(string _name){

		CRules@ rules = getRules();
		CPlayer@ player = getLocalPlayer();
		string playerName;  
		bool temp;
		if ( player is null ){ playerName = "Unknown Player";}
		else {playerName = player.getUsername();}
		for(int i = 0; i < list.length; i++){
			if(list[i].name == _name && !list[i].checkUnlocked()){
				if (playerChooser.current.label != "Your Achievements") temp = list[i].gained;
				list[i].Unlock();
				if (playerChooser.current.label != "Your Achievements") list[i].gained = temp;
				startDisplay(list[i]);
				CBitStream params;
				params.write_string(playerName);
				params.write_string(list[i].name);
				rules.SendCommand(rules.getCommandID("unlockAchievement"),params);
			}
		}
	}

	void registerAchievement(string _name,string _desc,int _icon = 0,int _rarity = 0,string _modName = "Default",string _imageName = "GUI/Achievements.png",int _size = 0)
	{
		Achievement@ achieve = @Achievement(_name,_desc,_imageName,_icon,_rarity,_modName,position,_size);
		list.push_back(achieve);
		totalPages = (list.length / ApP)+1;
		if (totalPages > 1)nextP.locked = false;
		pageNum.setText("  Page\n  1/"+totalPages);
	}

	void registerConditionAchievement(string _name,string _desc,int _icon = 0,int _rarity = 0,string _modName = "Default",float _condition = 0,SColor _conColor = SColor(240,0,0,255),string _imageName = "GUI/Achievements.png",int _size = 0)
	{
		Achievement@ achieve = @Achievement(_name,_desc,_imageName,_icon,_rarity,_modName,position,_size);
		achieve.addCondition(_conColor,_condition);
		list.push_back(achieve);
		totalPages = (list.length / ApP)+1;
		if (totalPages > 1)nextP.locked = false;
		pageNum.setText(" Page\n  1/"+totalPages);
	}


	void startDisplay(Achievement@ achieve){
		Icon rarity  = achieve.rarity;//Required for a linux fix (on asu's build) caused by .rarity and others being const
		Icon display = achieve.display;//^
		Label desc   = achieve.desc;// ^
		dropDownR = rarity;
		dropDownR.localPosition =achieve.rarity.localPosition + Vec2f(0,30);
		dropDownD = display;
		dropDownD.localPosition =achieve.display.localPosition + Vec2f(0,30);
		dropDownL = desc;
		dropDownL.localPosition = achieve.desc.localPosition + Vec2f(0,30);
		dropDownL.size =achieve.desc.size + Vec2f(110,0);
		dropDownL.setText(dropDownL.label + "\n"+ dropDownL.textWrap(achieve.description));
		dropDownW.clearChildren();
		dropDownW.addChild(dropDownD);
		dropDownW.addChild(dropDownR);
		dropDownW.addChild(dropDownL);
		dropDownW.addChild(dropDownT);
		displaying = true;
	}

	void display(){
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

	void renderSmall(){
		
		needsUpdate = false;
		int counterH=0,counterV=0, i = ApP * (page-1);
		for(i; i < list.length; i++){
			if(50*counterV+46 > size.y){counterH++;counterV= 0;}
			if(204*counterH+200 > size.x)break;
			list[i].draw(position+ Vec2f((204*counterH),(50*counterV)));
			if (!list[i].gained) GUI::DrawRectangle(list[i].frame.position, list[i].frame.position+list[i].frame.size,SColor(230,150,150,150));
			if(list[i].frame.isHovered){tipAnchor.position = list[i].frame.position; tipAnchor.setToolTip(list[i].description,0,SColor(255,255,255,255)); hoverDet = true;}
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
				if (player.isMyPlayer()){playerChooser.addItem("Your Achievements");}
				else {playerChooser.addItem(player.getUsername()+"'s Achievements");}
			}
			playerChooser.open = true;
		}
	}
}



class Achievement {
	string name, modName, description;
	float conMax, conCurrent = 0.0f;
	Icon@ rarity, display;
	Window@ frame;
	Label@ desc, conLbl;
	ProgressBar@ condition;
	
	bool gained,hasCon = false;
	
	Achievement(string _name,string _desc,string _imageName,int _icon,int _rarity,string _modName,Vec2f _pos,int _size)
	{
		name = _name;
		modName = _modName;
		description = _desc;
		@frame = @Window(_pos,Vec2f(200,46));
		@desc = @Label(Vec2f(44,5),Vec2f(114,38),_name,SColor(255,0,0,0),false);
		frame.addChild(desc);
		switch(_size){
			case 1: {@display = @Icon(_imageName,Vec2f(9,9),Vec2f(32,32),_icon,0.44f);break;}
			case 2: {@display = @Icon(_imageName,Vec2f(9,9),Vec2f(114,114),_icon,0.13f);break;}
			default: {@display = @Icon(_imageName,Vec2f(9,9),Vec2f(16,16),_icon,0.87f);}
		}
		frame.addChild(display);
		@rarity = @Icon("GUI/Rarity.png",Vec2f(5,5),Vec2f(18,18),_rarity,1.0f);
		frame.addChild(rarity);
		gained = checkUnlocked();
	}

	void addCondition(SColor _color,float _max){
		string text = "";
		conMax = _max;
		@condition = @ProgressBar(Vec2f(42,31),Vec2f(115,10), 0.0f,_color, false);
		conCurrent = getProgress();
		condition.setVal(conCurrent/conMax);
		if (conCurrent >= 1000000) {text += (conCurrent/1000000)+"Mil/";}
		else {text += conCurrent + "/";}
		if (conMax >= 1000000) {text += (conMax/1000000)+"Mil";}
		else{text += conMax;}
		@conLbl = @Label(Vec2f(0,-14),Vec2f(30,0),text,SColor(255,0,0,0),false);
		condition.addChild(conLbl);
		frame.addChild(condition);
		hasCon = true;
	}

	void conditionIncrease(float amount){
		string text = "";
		if (conCurrent == conMax) return;
		if (conCurrent + amount > conMax){conCurrent = conMax;}
		else {conCurrent += amount;}
		
		if (conCurrent >= 1000000) {text += (conCurrent/1000000)+"Mil/";}
		else {text += conCurrent + "/";}
		if (conMax >= 1000000) {text += (conMax/1000000)+"Mil";}
		else{text += conMax;}
		conLbl.setText(text);
		condition.setVal(conCurrent/conMax);
		if (getNet().isClient())
		{
			ConfigFile cfg = ConfigFile( "../Cache/"+modName+"_Achievements"+achievementsVersion+".cfg" );
			cfg.add_f32(name+"_progress", conCurrent);
			cfg.saveFile(modName+"_Achievements"+achievementsVersion+".cfg");
		}
	}

	void conditionSet(float amount){
		string text = "";
		if (amount > conMax){conCurrent = conMax;}
		else {conCurrent = amount;}
		
		if (conCurrent >= 1000000) {text += (conCurrent/1000000)+"Mil/";}
		else {text += conCurrent + "/";}
		if (conMax >= 1000000) {text += (conMax/1000000)+"Mil";}
		else{text += conMax;}
		conLbl.setText(text);
		condition.setVal(conCurrent/conMax);
	}

	float getProgress()
	{
		if (getNet().isClient())
		{
			string configstr = "../Cache/"+modName+"_Achievements"+achievementsVersion+".cfg";
			ConfigFile cfg = ConfigFile( configstr );
			float progress = cfg.read_f32(name +"_progress", 0.0f);
			return progress;
		}
		else {return 0.0f;}
	}

	bool checkUnlocked()
	{
		if (getNet().isClient())
		{
			string configstr = "../Cache/"+modName+"_Achievements"+achievementsVersion+".cfg";
			ConfigFile cfg = ConfigFile( configstr );
			bool unlocked = cfg.read_bool(name, false);
			return unlocked;
		}
		else {return false;}
	}

	void Unlock(){
		if (getNet().isClient())
		{
			gained = true;
			print("Achievement Unlocked: "+ name);
			ConfigFile cfg = ConfigFile( "../Cache/"+modName+"_Achievements"+achievementsVersion+".cfg" );
			cfg.add_bool(name, true);
			cfg.saveFile(modName+"_Achievements"+achievementsVersion+".cfg");
		}
	}

	
	void draw(Vec2f pos){
		frame.position = pos;
		frame.draw();
	}
}

