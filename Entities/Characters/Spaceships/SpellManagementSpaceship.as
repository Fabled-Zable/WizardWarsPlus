
void ManageSpell( CBlob@ this, FrigateInfo@ frigate, PlayerPrefsInfo@ playerPrefsInfo, SpaceshipMoveVars@ moveVars )
{
	CSprite@ sprite = this.getSprite();
	bool ismyplayer = this.isMyPlayer();
	s32 charge_time = frigate.charge_time;
	u8 charge_state = frigate.charge_state;
	
	u8 spellID = playerPrefsInfo.primarySpellID;
	int hotbarLength = playerPrefsInfo.hotbarAssignments_Frigate.length;
	
	ManaInfo@ manaInfo;
	if (!this.get( "manaInfo", @manaInfo )) 
	{
		return;
	}	
    s32 frigateMana = manaInfo.mana;

    bool is_pressed = this.isKeyPressed( key_action2 );
    bool just_pressed = this.isKeyJustPressed( key_action2 );
    bool just_released = this.isKeyJustReleased( key_action2 );

	bool is_aux1 = false;
	bool is_aux2 = false;
	
    if (!is_pressed and !just_released and !just_pressed)//auxiliary1 hand
    {
        spellID = playerPrefsInfo.hotbarAssignments_Frigate[Maths::Min(16,hotbarLength-1)];
		
		CControls@ controls = this.getControls();
        is_pressed = this.isKeyPressed( key_action3 );
        just_pressed = this.isKeyJustPressed( key_action3 );
        just_released = this.isKeyJustReleased( key_action3 ); 

        is_aux1 = true;
    }
    if (!is_pressed and !just_released and !just_pressed)//auxiliary2 hand
    {
        spellID = playerPrefsInfo.hotbarAssignments_Frigate[Maths::Min(17,hotbarLength-1)];
		
		CControls@ controls = this.getControls();
        is_pressed = this.isKeyPressed( key_taunts );
        just_pressed = this.isKeyJustPressed( key_taunts );
        just_released = this.isKeyJustReleased( key_taunts ); 

        is_aux2 = true;
    }
	
	Spell spell = FrigateParams::spells[spellID];

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
	if ( controls.isKeyPressed( KEY_MBUTTON ) || frigate.spells_cancelling == true )
	{
		charge_time = 0;
		charge_state = FrigateParams::not_aiming;
		
		if (frigate.spells_cancelling == false)
		{
			sprite.PlaySound("PopIn.ogg", 1.0f, 1.0f);
		}
		frigate.spells_cancelling = true;	
		
		// only stop cancelling once all spells buttons are released
		if ( !is_pressed )
		{
			frigate.spells_cancelling = false;
		}
	}
	
	bool canCastSpell = frigateMana >= spell.mana && playerPrefsInfo.spell_cooldowns[spellID] <= 0;
    if (is_pressed && canCastSpell) 
    {
        moveVars.flyFactor *= 0.75f;
        charge_time += 1;
        if (charge_time >= spell.full_cast_period)
        {
            charge_state = FrigateParams::extra_ready;
            charge_time = spell.full_cast_period;
        }
        else if (charge_time >= spell.cast_period)
        {
            charge_state = FrigateParams::cast_3;
        }
        else if (charge_time >= spell.cast_period_2)
        {
            charge_state = FrigateParams::cast_2;
        }
        else if (charge_time >= spell.cast_period_1)
        {
            charge_state = FrigateParams::cast_1;
        }
    }
    else if (just_released)
    {
        if (canCastSpell && charge_state > FrigateParams::charging && not (spell.needs_full && charge_state < FrigateParams::cast_3) &&
            (this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot()))
        {
            CBitStream params;
            params.write_u8(charge_state);
			u8 castSpellID;
			if ( is_aux2 )
				castSpellID = playerPrefsInfo.hotbarAssignments_Frigate[Maths::Min(17,hotbarLength-1)];
			else if ( is_aux1 )
				castSpellID = playerPrefsInfo.hotbarAssignments_Frigate[Maths::Min(16,hotbarLength-1)];
			else
				castSpellID = playerPrefsInfo.primarySpellID;
            params.write_u8(castSpellID);
            params.write_Vec2f(spellPos);
			params.write_Vec2f(pos);
            this.SendCommand(this.getCommandID("spell"), params);
			
			playerPrefsInfo.spell_cooldowns[castSpellID] = FrigateParams::spells[castSpellID].cooldownTime*getTicksASecond();
        }
        charge_state = FrigateParams::not_aiming;
        charge_time = 0;
    }

	if(this.get_bool("shifting") && !this.get_bool("shifted"))
	{
		this.set_bool("shifted", true);
		if(frigate.pulse_amount > 0)
		{
			this.SendCommand(this.getCommandID("pulsed"));
		}
	}
	else if(!this.get_bool("shifting") && this.get_bool("shifted"))
	{
		this.set_bool("shifted", false);
	}

    frigate.charge_time = charge_time;
    frigate.charge_state = charge_state;

    if ( ismyplayer )
    {
		if (!getHUD().hasButtons()) 
		{
			int frame = 0;
            if (charge_state == FrigateParams::extra_ready) {
                frame = 15;
				if (charge_state != FrigateParams::not_aiming)
				{
					if (frigate.charge_time == 0)
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
            else if (frigate.charge_time > spell.cast_period)
            {
                frame = 12 + frigate.charge_time % 15 / 5;
            }
			else if (frigate.charge_time > 0) {
				frame = frigate.charge_time * 12 /spell.cast_period; 
			}
			u8 pulses = frigate.pulse_amount;
			u8 frameoffset = 16 * pulses;
			getHUD().SetCursorFrame( frame + frameoffset);
		}

        if (this.isKeyJustPressed(key_action3))
        {
			client_SendThrowOrActivateCommand( this );
        }
    }
	
	if ( !is_pressed )
	{
		if (FrigateParams::spells.length == 0) 
		{
			return;
		}

		FrigateInfo@ frigate;
		if (!this.get( "frigateInfo", @frigate )) 
		{
			return;
		}
		
		bool spellSelected = this.get_bool("spell selected");
		int currHotkey = playerPrefsInfo.primaryHotkeyID;
		int nextHotkey =  playerPrefsInfo.hotbarAssignments_Frigate.length;
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
		
		if ( nextHotkey <  playerPrefsInfo.hotbarAssignments_Frigate.length )
		{
			playerPrefsInfo.primaryHotkeyID = nextHotkey;
			playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Frigate[nextHotkey];
			this.set_bool("spell selected", false);
			
			sprite.PlaySound("PopIn.ogg");
		}
	}
	else
		this.set_bool("spell selected", true);
}