#define CLIENT_ONLY
//#include "GameHelp.as";
#include "KGUI.as";
#include "Achievements.as";
int oldBooty; //used for achievement processing

//topedo kill core -rysi

//----KGUI ELEMENTS----\\
	 	AchieveList shipAchievements;

void intitializeAchieves()
{
	string configstr = "../Cache/WizardWars_Achievements"+achievementsVersion+".cfg";
	ConfigFile cfg = ConfigFile( configstr );
	if (!cfg.exists("Version")){cfg.add_string("Version","Achievements 1.2");
		cfg.saveFile("WizardWars_Achievements"+achievementsVersion+".cfg");}
	shipAchievements = AchieveList(Vec2f(50,40),Vec2f(700,400),1);
	shipAchievements.isEnabled = false;
	shipAchievements.registerAchievement("Tester","You're an official, bonafide, Wizard Wars tester!",3,5,"WizardWars");
	shipAchievements.registerAchievement("First Join","First time here? Heh, you've got a lot to learn, buddy.",1,0,"WizardWars");
	shipAchievements.registerConditionAchievement("Ten Joins","Ring the bells, we got a ten timer over here!",2,1,"WizardWars",10.0f,SColor(240,0,0,255));
	shipAchievements.registerConditionAchievement("Keeps Coming Back","You obviously enjoy this mod, but have you truly mastered it yet?",1,2,"WizardWars",100.0f,SColor(240,0,0,255),"GUI/AchievementsM.png",1);

	shipAchievements.registerAchievement("Winner","Congrats on your first win! You've got potential, kid.",8,0,"WizardWars");
	shipAchievements.registerConditionAchievement("Champion","Hey champ, you've earned it. You're on your way to the big leagues now.",9,1,"WizardWars",100.0f,SColor(240,0,0,255));
	shipAchievements.registerConditionAchievement("Unstoppable","Dayum son, I would give you more but all I have is this gold trophy!",10,6,"WizardWars",1000.0f,SColor(240,0,0,255));
	
	shipAchievements.registerAchievement("Flawless","You won without so much as a scratch! You're a diamond in the rough.",11,3,"WizardWars");

	string servName = getNet().joined_servername;
	if (servName == "Wizard Wars Test Center")shipAchievements.unlockByName("Tester");	
}