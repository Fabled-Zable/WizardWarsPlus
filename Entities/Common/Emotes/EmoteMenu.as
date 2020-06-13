#include "EmotesCommon.as"
#include "WheelMenuCommon.as"

#include "MagicCommon.as"
#include "PlayerPrefsCommon.as"

#include "WizardCommon.as"
#include "NecromancerCommon.as"
#include "DruidCommon.as"
#include "SwordCasterCommon.as"
#include "EntropistCommon.as"
#include "FrigateCommon.as"

#define CLIENT_ONLY


enum spellClass
{
    Wizard = 1,
    Necromancer,
    Druid,
	SwordCaster,
    Entropist,
}

void onInit(CRules@ rules)
{
    rules.set_bool("usespellwheel", true);
	string filename = "EmoteEntries.cfg";
	string cachefilename = "../Cache/" + filename;
	ConfigFile cfg;

	//attempt to load from cache first
	bool loaded = false;
	if(CFileMatcher(cachefilename).getFirst() == cachefilename && cfg.loadFile(cachefilename))
	{
		loaded = true;
	}
	else if (cfg.loadFile(filename))
	{
		loaded = true;
	}

	if(!loaded)
	{
		return;
	}

	WheelMenu@ menu = get_wheel_menu("emotes");
	menu.option_notice = getTranslatedString("Select emote");

	string[] names;
	cfg.readIntoArray_string(names, "emotes");

	if (names.length % 2 != 0)
	{
		error("EmoteEntries.cfg is not in the form of visible_name; token;");
		return;
	}

	for (uint i = 0; i < names.length; i += 2)
	{
		IconWheelMenuEntry entry(names[i+1]);
		entry.visible_name = getTranslatedString(names[i]);
		entry.texture_name = "Emoticons.png";
		entry.frame = Emotes::names.find(names[i+1]);
		entry.frame_size = Vec2f(32.0f, 32.0f);
		entry.scale = 1.0f;
		entry.offset = Vec2f(0.0f, -3.0f);
		menu.entries.push_back(@entry);
	}
}

void onSetPlayer( CRules@ this, CBlob@ blob, CPlayer@ player )//Selects the spell selector wheelmenu for the class on spawn
{
    //if(this.get_bool("usespellwheel") == false){//Use the spell wheel?
    //    return;
    //}
    if(player == null || getLocalPlayer() == null){//Vital to this
        return;
    }
    if(player.getNetworkID() != getLocalPlayer().getNetworkID()){//Make sure this is the player who wanted it
        return;
    }
    string blob_name = blob.getName();
    uint spells_length;
    uint i;

    uint8 _class;
    if(blob_name == "wizard")
    {
        _class = Wizard;
        spells_length = WizardParams::spells.length;
    }
    else if(blob_name == "necromancer")
    {
        _class = Necromancer;
        spells_length = NecromancerParams::spells.length;
    }
    else if(blob_name == "druid")
    {
        _class = Druid;
        spells_length = DruidParams::spells.length;
    }
    else if(blob_name == "swordcaster")
    {
        _class = SwordCaster;
        spells_length = SwordCasterParams::spells.length;
    }
    else if(blob_name == "entropist")
    {
        _class = Entropist;
        spells_length = EntropistParams::spells.length;
    }
    else
    {
        return;
    }

    
    WheelMenu@ menu = get_wheel_menu("spells");
    menu.option_notice = getTranslatedString("Select a spell");
    menu.for_spells = true;
    menu.entries.resize(0);

    string[] names;
    //cfg.readIntoArray_string(names, "emotes");
    for (i = 0; i < spells_length; i++)
    {
        Spell spell; 
        switch(_class)
        {
            case Wizard:
                spell = WizardParams::spells[i];
            break;
            case Necromancer:
                spell = NecromancerParams::spells[i];
            break;
            case Druid:
                spell = DruidParams::spells[i];
            break;
            case SwordCaster:
                spell = SwordCasterParams::spells[i];
            break;
            case Entropist:
                spell = EntropistParams::spells[i];
            break;
            
            default:
                print("EmoteMenu Unknown error");
        }
        if(spell.typeName == "")//No empty spells in the spell wheel
        {
            continue;
        }   
        IconWheelMenuEntry entry(spell.typeName);
        entry.object_id = i;
        
        entry.visible_name = spell.name + "\n\n" + "Mana: " + spell.mana + "\n\n" + "Cooldown: " + spell.cooldownTime + "\n\n" + "Cast Length: " + spell.cast_period;//Add description and ( mana | cooldownTime | cast_period | needs_full | range)
        entry.texture_name = "SpellIcons.png";
        entry.frame = spell.iconFrame;
        entry.frame_size = Vec2f(16.0f, 16.0f);
        entry.scale = 2.0f;
        entry.offset = Vec2f(0.0f, -3.0f);
        menu.entries.push_back(@entry);
    }
}


void onTick(CRules@ rules)
{
	CBlob@ blob = getLocalPlayerBlob();

	if (blob is null)
	{
		set_active_wheel_menu(null);
		return;
	}

    bool usespellwheel = rules.get_bool("usespellwheel");

    WheelMenu@ menu;

    if(usespellwheel == true)
    {
        @menu = get_wheel_menu("spells");
        if(menu.entries == null || menu.entries.length() == 0)
        {
            print("In EmoteMenu.as spell length is equal to zero");
            return;
        }

    }
    else
    {
        @menu = get_wheel_menu("emotes");
    }

	if (blob.isKeyJustPressed(key_bubbles))
	{
		set_active_wheel_menu(@menu);
	}
	else if (blob.isKeyJustReleased(key_bubbles) && get_active_wheel_menu() is menu)
	{
		WheelMenuEntry@ selected = menu.get_selected();
        if(usespellwheel == true)
        {
            PlayerPrefsInfo@ playerPrefsInfo;
            if (!getLocalPlayer().get( "playerPrefsInfo", @playerPrefsInfo )) 
            {
                set_active_wheel_menu(null);
                return;
            }

            if ( playerPrefsInfo.infoLoaded == false )
            {
                set_active_wheel_menu(null);
                return;
            }
            if(selected != null){
                //playerPrefsInfo.primaryHotkeyID = ???;//currently selected spell in spell selector bottom left
                playerPrefsInfo.primarySpellID = selected.object_id;//currently selected spell
            }
        }
        else
        {
            set_emote(blob, (selected !is null ? Emotes::names.find(selected.name) : Emotes::off));
        }
        
        set_active_wheel_menu(null);
    }
}