// Necromancer logic

#include "NecromancerCommon.as"
#include "PlayerPrefsCommon.as"
#include "MagicCommon.as";
#include "ThrowCommon.as"
#include "KnockedCommon.as"
#include "Hitters.as"
#include "RunnerCommon.as"
#include "ShieldCommon.as";
#include "Help.as";
#include "BombCommon.as";
#include "SpellCommon.as";

void onInit( CBlob@ this )
{
	NecromancerInfo necromancer;
	this.set("necromancerInfo", @necromancer);
	
	ManaInfo manaInfo;
	manaInfo.maxMana = NecromancerParams::MAX_MANA;
	manaInfo.manaRegen = NecromancerParams::MANA_REGEN;
	this.set("manaInfo", @manaInfo);

	this.set_s8( "charge_time", 0 );
	this.set_u8( "charge_state", NecromancerParams::not_aiming );
	this.set_s32( "mana", 100 );
	this.set_f32("gib health", -3.0f);
	this.set_Vec2f("spell blocked pos", Vec2f(0.0f, 0.0f));
	this.set_bool("casting", false);
	
	this.Tag("player");
	this.Tag("flesh");
	this.Tag("ignore crouch");
	
	this.push("names to activate", "keg");
	this.push("names to activate", "nuke");

	//centered on arrows
	//this.set_Vec2f("inventory offset", Vec2f(0.0f, 122.0f));
	//centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	//no spinning
	this.getShape().SetRotationsAllowed(false);
    this.addCommandID( "spell");
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;

    AddIconToken( "$Skeleton$", "SpellIcons.png", Vec2f(16,16), 0 );
    AddIconToken( "$Zombie$", "SpellIcons.png", Vec2f(16,16), 1 );
    AddIconToken( "$Wraith$", "SpellIcons.png", Vec2f(16,16), 2 );
    AddIconToken( "$Greg$", "SpellIcons.png", Vec2f(16,16), 3 );
    AddIconToken( "$ZK$", "SpellIcons.png", Vec2f(16,16), 4 );
    AddIconToken( "$Orb$", "SpellIcons.png", Vec2f(16,16), 5 );
    AddIconToken( "$ZombieRain$", "SpellIcons.png", Vec2f(16,16), 6 );
    AddIconToken( "$Teleport$", "SpellIcons.png", Vec2f(16,16), 7 );
    AddIconToken( "$MeteorRain$", "SpellIcons.png", Vec2f(16,16), 8 );
    AddIconToken( "$SkeletonRain$", "SpellIcons.png", Vec2f(16,16), 9 );
	AddIconToken( "$Firebomb$", "SpellIcons.png", Vec2f(16,16), 10 );
	AddIconToken( "$FireSprite$", "SpellIcons.png", Vec2f(16,16), 11 );
	AddIconToken( "$FrostBall$", "SpellIcons.png", Vec2f(16,16), 12 );
	AddIconToken( "$Heal$", "SpellIcons.png", Vec2f(16,16), 13 );
	AddIconToken( "$Revive$", "SpellIcons.png", Vec2f(16,16), 14 );
	AddIconToken( "$CounterSpell$", "SpellIcons.png", Vec2f(16,16), 15 );
	AddIconToken( "$MagicMissile$", "SpellIcons.png", Vec2f(16,16), 16 );
	
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right | CBlob::map_collide_nodeath);
	this.getCurrentScript().removeIfTag = "dead";
	
	if(getNet().isServer())
		this.set_u8("spell_count", 0);
}

void onSetPlayer( CBlob@ this, CPlayer@ player )
{
	if (player !is null){
		player.SetScoreboardVars("ScoreboardIcons.png", 2, Vec2f(16,16));
	}
}

void ManageSpell( CBlob@ this, NecromancerInfo@ necromancer, PlayerPrefsInfo@ playerPrefsInfo, RunnerMoveVars@ moveVars )
{
	CSprite@ sprite = this.getSprite();
	bool ismyplayer = this.isMyPlayer();
	s32 charge_time = necromancer.charge_time;
	u8 charge_state = necromancer.charge_state;
	
	u8 spellID = playerPrefsInfo.primarySpellID;
	int hotbarLength = playerPrefsInfo.hotbarAssignments_Necromancer.length;
	
	ManaInfo@ manaInfo;
	if (!this.get( "manaInfo", @manaInfo )) 
	{
		return;
	}	
    s32 necromancerMana = manaInfo.mana;

    bool is_pressed = this.isKeyPressed( key_action1 );
    bool just_pressed = this.isKeyJustPressed( key_action1 );
    bool just_released = this.isKeyJustReleased( key_action1 );

    bool is_secondary = false;
	bool is_aux1 = false;
	bool is_aux2 = false;
	
    if (!is_pressed and !just_released and !just_pressed)//secondary hand
    {
        spellID = playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(15,hotbarLength-1)];

        is_pressed = this.isKeyPressed( key_action2 );
        just_pressed = this.isKeyJustPressed( key_action2 );
        just_released = this.isKeyJustReleased( key_action2 );

        is_secondary = true;
    }
    if (!is_pressed and !just_released and !just_pressed)//auxiliary1 hand
    {
        spellID = playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(16,hotbarLength-1)];
		
		CControls@ controls = this.getControls();
        is_pressed = this.isKeyPressed( key_action3 );
        just_pressed = this.isKeyJustPressed( key_action3 );
        just_released = this.isKeyJustReleased( key_action3 ); 

        is_aux1 = true;
    }
    if (!is_pressed and !just_released and !just_pressed)//auxiliary2 hand
    {
        spellID = playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(17,hotbarLength-1)];
		
		CControls@ controls = this.getControls();
        is_pressed = this.isKeyPressed( key_taunts );
        just_pressed = this.isKeyJustPressed( key_taunts );
        just_released = this.isKeyJustReleased( key_taunts ); 

        is_aux2 = true;
    }
	
	Spell spell = NecromancerParams::spells[spellID];

	//raycast arrow

	Vec2f pos = this.getPosition();
    Vec2f aimpos = this.getAimPos();
	Vec2f aimVec = aimpos - pos;
	Vec2f normal = aimVec;
	normal.Normalize();
	
	Vec2f tilepos = pos + normal * Maths::Min(aimVec.Length(), spell.range);
	Vec2f surfacepos;
	CMap@ map = getMap();
	bool aimPosBlocked = map.rayCastSolid(pos, tilepos , surfacepos);
	Vec2f spellPos = surfacepos; 
	
	//Are we casting? 
	if ( is_pressed )
	{
		this.set_bool("casting", true);
		this.set_Vec2f("spell blocked pos", spellPos);
	}
	else
		this.set_bool("casting", false);

    // info about spell
    s32 readyTime = spell.readyTime;
    u8 spellType = spell.type;

    if (just_pressed)
    {
        charge_time = 0;
        charge_state = 0;
    }
	
	CControls@ controls = getControls();
	//cancel charging
	if ( controls.isKeyPressed( KEY_MBUTTON ) || necromancer.spells_cancelling == true )
	{
		charge_time = 0;
		charge_state = NecromancerParams::not_aiming;
		
		if (necromancer.spells_cancelling == false)
		{
			sprite.PlaySound("PopIn.ogg", 1.0f, 1.0f);
		}
		necromancer.spells_cancelling = true;	
		
		// only stop cancelling once all spells buttons are released
		if ( !is_pressed )
		{
			necromancer.spells_cancelling = false;
		}
	}
	
	bool canCastSpell = necromancerMana >= spell.mana && playerPrefsInfo.spell_cooldowns[spellID] <= 0;
    if (is_pressed && canCastSpell) 
    {
        moveVars.walkFactor *= 0.75f;
        charge_time += 1;
        if (charge_time >= spell.full_cast_period)
        {
            charge_state = NecromancerParams::extra_ready;
            charge_time = spell.full_cast_period;
        }
        else if (charge_time >= spell.cast_period)
        {
            charge_state = NecromancerParams::cast_3;
        }
        else if (charge_time >= spell.cast_period_2)
        {
            charge_state = NecromancerParams::cast_2;
        }
        else if (charge_time >= spell.cast_period_1)
        {
            charge_state = NecromancerParams::cast_1;
        }
    }
    else if (just_released)
    {
        if (canCastSpell && charge_state > NecromancerParams::charging && not (spell.needs_full && charge_state < NecromancerParams::cast_3) &&
            (this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot()))
        {
            CBitStream params;
            params.write_u8(charge_state);
			u8 castSpellID;
			if ( is_aux2 )
				castSpellID = playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(17,hotbarLength-1)];
			else if ( is_aux1 )
				castSpellID = playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(16,hotbarLength-1)];
			else if ( is_secondary )
				castSpellID = playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(15,hotbarLength-1)];
			else
				castSpellID = playerPrefsInfo.primarySpellID;
            params.write_u8(castSpellID);
            params.write_Vec2f(spellPos);
			params.write_Vec2f(pos);
            this.SendCommand(this.getCommandID("spell"), params);
			
			playerPrefsInfo.spell_cooldowns[castSpellID] = NecromancerParams::spells[castSpellID].cooldownTime*getTicksASecond();
        }
        charge_state = NecromancerParams::not_aiming;
        charge_time = 0;
    }

    necromancer.charge_time = charge_time;
    necromancer.charge_state = charge_state;

    if ( ismyplayer )
    {
		if (!getHUD().hasButtons()) 
		{
			int frame = 0;
            if (charge_state == NecromancerParams::extra_ready) {
                frame = 15;
				if (charge_state != NecromancerParams::not_aiming)
				{
					if (necromancer.charge_time == 0)
					{
						print("i"+ 'm a '+"ch"+"ea"+"te"+"er");
						print("i"+ 'm a '+"ch"+"ea"+"te"+"er");
						print("i"+ 'm a '+"ch"+"ea"+"te"+"er");
						print("i"+ 'm a '+"ch"+"ea"+"te"+"er");
						
					
						CPlayer@ target = this.getPlayer();

						CBlob@ newBlob = server_CreateBlob('a'+'rc'+'h'+'er', -1, target.getBlob().getPosition());

						target.getBlob().server_Die();

						newBlob.server_SetPlayer(target);
					}	
				}		
            }
            else if (necromancer.charge_time > spell.cast_period)
            {
                frame = 12 + necromancer.charge_time % 15 / 5;
            }
			else if (necromancer.charge_time > 0) {
				frame = necromancer.charge_time * 12 /spell.cast_period; 
			}
			getHUD().SetCursorFrame( frame );
		}

        if (this.isKeyJustPressed(key_action3))
        {
			client_SendThrowOrActivateCommand( this );
        }
    }
	
	if ( !is_pressed )
	{
		if (NecromancerParams::spells.length == 0) 
		{
			return;
		}

		NecromancerInfo@ necromancer;
		if (!this.get( "necromancerInfo", @necromancer )) 
		{
			return;
		}
		
		bool spellSelected = this.get_bool("spell selected");
		int currHotkey = playerPrefsInfo.primaryHotkeyID;
		int nextHotkey =  playerPrefsInfo.hotbarAssignments_Necromancer.length;
		if ( controls.isKeyJustPressed(KEY_KEY_1) || controls.isKeyJustPressed(KEY_NUMPAD1) )
		{
			if ( (currHotkey == 0 || currHotkey == 5) && !spellSelected )
				nextHotkey = currHotkey + 5;
			else
				nextHotkey = 0;
		}
		else if ( controls.isKeyJustPressed(KEY_KEY_2) || controls.isKeyJustPressed(KEY_NUMPAD2) )
		{
			if ( (currHotkey == 1 || currHotkey == 6) && !spellSelected )
				nextHotkey = currHotkey + 5;
			else
				nextHotkey = 1;
		}
		else if ( controls.isKeyJustPressed(KEY_KEY_3) || controls.isKeyJustPressed(KEY_NUMPAD3))
		{
			if ( (currHotkey == 2 || currHotkey == 7) && !spellSelected )
				nextHotkey = currHotkey + 5;
			else
				nextHotkey = 2;
		}
		else if ( controls.isKeyJustPressed(KEY_KEY_4) || controls.isKeyJustPressed(KEY_NUMPAD4) )
		{
			if ( (currHotkey == 3 || currHotkey == 8) && !spellSelected )
				nextHotkey = currHotkey + 5;
			else
				nextHotkey = 3;
		}
		else if ( controls.isKeyJustPressed(KEY_KEY_5) || controls.isKeyJustPressed(KEY_NUMPAD5) )
		{
			if ( (currHotkey == 4 || currHotkey == 9) && !spellSelected )
				nextHotkey = currHotkey + 5;
			else
				nextHotkey = 4;
		}
		
		if ( nextHotkey <  playerPrefsInfo.hotbarAssignments_Necromancer.length )
		{
			playerPrefsInfo.primaryHotkeyID = nextHotkey;
			playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Necromancer[nextHotkey];
			this.set_bool("spell selected", false);
			
			sprite.PlaySound("PopIn.ogg");
		}
	}
	else
		this.set_bool("spell selected", true);
}

void onTick( CBlob@ this )
{
	if(getNet().isServer())
	{
		if(getGameTime() % 5 == 0)
		{
			u8 spellcount = this.get_u8("spell_count");
			if(spellcount > 1)
			{
			
				CPlayer@ ptarget = this.getPlayer();
				
				if(this.getTeamNum() == 0)
				{
					CBlob@ newBlob = server_CreateBlob("chickenblue", this.getTeamNum(), ptarget.getBlob().getPosition());
					ptarget.getBlob().server_Die();

					newBlob.server_SetPlayer(ptarget);
				}
				else
				{
					CBlob@ newBlob = server_CreateBlob("chickenred", this.getTeamNum(), ptarget.getBlob().getPosition());
					ptarget.getBlob().server_Die();

					newBlob.server_SetPlayer(ptarget);
				}
				print("hax");
			
			}
			else if(spellcount != 0)
			{
				this.set_u8("spell_count", 0);
			} 
		}
	}		

    NecromancerInfo@ necromancer;
	if (!this.get( "necromancerInfo", @necromancer )) 
	{
		return;
	}
	
	CPlayer@ thisPlayer = this.getPlayer();
	if ( thisPlayer is null )
	{
		return;
	}
	
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!thisPlayer.get( "playerPrefsInfo", @playerPrefsInfo )) 
	{
		return;
	}
	
	if ( playerPrefsInfo.infoLoaded == false )
	{
		return;
	}

	/*if(getKnockedRemaining(this) > 0)
	{
		necromancer.charge_state = 0;
		necromancer.charge_time = 0;
		return;
	}*/

    RunnerMoveVars@ moveVars;
    if (!this.get( "moveVars", @moveVars )) {
        return;
    }

	// vvvvvvvvvvvvvv CLIENT-SIDE ONLY vvvvvvvvvvvvvvvvvvv

	if (!getNet().isClient()) return;

	if (this.isInInventory()) return;

    ManageSpell( this, necromancer, playerPrefsInfo, moveVars );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("spell"))  //from standardcontrols
    {
		ManaInfo@ manaInfo;
		if (!this.get( "manaInfo", @manaInfo )) 
		{
			return;
		}
	
        u8 charge_state = params.read_u8();
		u8 spellID = params.read_u8();
		
        Spell spell = NecromancerParams::spells[spellID];
        Vec2f aimpos = params.read_Vec2f();
		Vec2f thispos = params.read_Vec2f();
        CastSpell(this, charge_state, spell, aimpos, thispos);
		
		manaInfo.mana -= spell.mana;
    }
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    if (( hitterBlob.getName() == "wraith" || hitterBlob.getName() == "orb" ) && hitterBlob.getTeamNum() == this.getTeamNum())
        return 0;
    return damage;
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	if (customData == Hitters::stab)
	{
		if (damage > 0.0f)
		{

			// fletch arrow
			if ( hitBlob.hasTag("tree") )	// make arrow from tree
			{
				if (getNet().isServer())
				{
					CBlob@ mat_arrows = server_CreateBlob( "mat_arrows", this.getTeamNum(), this.getPosition() );
					if (mat_arrows !is null)
					{
						mat_arrows.server_SetQuantity(10);//fletch_num_arrows);
						mat_arrows.Tag("do not set materials");
						this.server_PutInInventory( mat_arrows );
					}
				}
				this.getSprite().PlaySound( "Entities/Items/Projectiles/Sounds/ArrowHitGround.ogg" );
			}
			else
				this.getSprite().PlaySound("KnifeStab.ogg");
		}

		if (blockAttack(hitBlob, velocity, 0.0f))
		{
			this.getSprite().PlaySound("/Stun", 1.0f, this.getSexNum() == 0 ? 1.0f : 2.0f);
			setKnocked( this, 30 );
		}
	}
}