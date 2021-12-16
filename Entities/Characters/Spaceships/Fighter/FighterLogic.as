// Frigate logic

#include "SmallshipCommon.as"
#include "SpaceshipVars.as"
#include "PlayerPrefsCommon.as"
#include "MagicCommon.as";
#include "ThrowCommon.as"
#include "KnockedCommon.as"
#include "Hitters.as"
#include "ShieldCommon.as";
#include "Help.as";
#include "BombCommon.as";
#include "CommonFX.as"

const string shot_command_ID = "shot";
const string hit_command_ID = "hit";

void onInit( CBlob@ this )
{
	SmallshipInfo ship;
	ship.main_engine_force = FighterParams::main_engine_force;
	ship.secondary_engine_force = FighterParams::secondary_engine_force;
	ship.rcs_force = FighterParams::rcs_force;
	ship.ship_turn_speed = FighterParams::ship_turn_speed;
	ship.ship_drag = FighterParams::ship_drag;
	ship.max_speed = FighterParams::max_speed;
	
	ship.firing_rate = FighterParams::firing_rate;
	ship.firing_burst = FighterParams::firing_burst;
	ship.firing_delay = FighterParams::firing_delay;
	ship.firing_spread = FighterParams::firing_spread;
	ship.shot_speed = FighterParams::shot_speed;
	this.set("smallshipInfo", @ship);
	
	/*ManaInfo manaInfo;
	manaInfo.maxMana = FrigateParams::MAX_MANA;
	manaInfo.manaRegen = FrigateParams::MANA_REGEN;
	this.set("manaInfo", @manaInfo);*/

	this.set_u32( "m1_heldTime", 0 );
	this.set_u32( "m2_heldTime", 0 );

	this.set_u32( "m1_shotTime", 0 );
	this.set_u32( "m2_shotTime", 0 );

	this.set_bool( "leftCannonTurn", false);

	this.set_s8( "charge_time", 0 );
	this.set_u8( "charge_state", FrigateParams::not_aiming );
	this.set_s32( "mana", 100 );
	this.set_f32("gib health", -3.0f);
	this.set_Vec2f("spell blocked pos", Vec2f(0.0f, 0.0f));
	this.set_bool("casting", false);
	this.set_bool("shifted", false);
	
	this.Tag("player");
	this.Tag("hull");
	this.Tag("ignore crouch");
	
	this.push("names to activate", "keg");
	this.push("names to activate", "nuke");

	//centered on arrows
	//this.set_Vec2f("inventory offset", Vec2f(0.0f, 122.0f));
	//centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	//no spinning
	this.getShape().SetRotationsAllowed(false);
	//this.getShape().SetGravityScale(0);

    this.addCommandID( shot_command_ID );
	this.addCommandID( hit_command_ID );
	this.addCommandID( "pulsed" );
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

	/*if(isClient())
	{
		this.getSprite().SetEmitSound("engine_loop.ogg");
		this.getSprite().SetEmitSoundPaused(true);
	}*/
}

void onSetPlayer( CBlob@ this, CPlayer@ player )
{
	if (player !is null){
		player.SetScoreboardVars("ScoreboardIcons.png", 2, Vec2f(16,16));
	}
}

void onTick( CBlob@ this )
{
	// vvvvvvvvvvvvvv CLIENT-SIDE ONLY vvvvvvvvvvvvvvvvvvv
	//if (!isClient()) return;
	if (this.isInInventory()) return;
	if (!this.isMyPlayer()) return;

    SmallshipInfo@ ship;
	if (!this.get( "smallshipInfo", @ship )) 
	{ return; }
	
	CPlayer@ thisPlayer = this.getPlayer();
	if ( thisPlayer is null )
	{ return; }

	SpaceshipVars@ moveVars;
    if (!this.get( "moveVars", @moveVars )) {
        return;
    }

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	f32 blobAngle = this.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;

	//gun logic
	bool pressed_m1 = this.isKeyPressed(key_action1);
	bool pressed_m2 = this.isKeyPressed(key_action2);
	
	u32 m1Time = this.get_u32( "m1_heldTime");
	u32 m2Time = this.get_u32( "m2_heldTime");

	u32 m1ShotTicks = this.get_u32( "m1_shotTime" );
	u32 m2ShotTicks = this.get_u32( "m2_shotTime" );

	if (pressed_m1 && m1Time >= ship.firing_delay)
	{
		if (m1ShotTicks >= ship.firing_rate * moveVars.firingRateFactor)
		{
			CBitStream params;
			bool leftCannon = this.get_bool( "leftCannonTurn" );
			this.set_bool( "leftCannonTurn", !leftCannon);

			f32 leftMult = leftCannon ? 1.0f : -1.0f;
			Vec2f firePos = Vec2f(8, 4 * leftMult); //barrel pos
			firePos.RotateByDegrees(blobAngle);
			firePos += thisPos; //fire pos

			Vec2f fireVec = Vec2f(1.0f,0) * ship.shot_speed; 
			fireVec.RotateByDegrees(blobAngle); //shot vector
			fireVec += thisVel; //adds ship speed

			params.write_u16(this.getNetworkID()); //ownerID
			params.write_u8(1); //shot type
			params.write_Vec2f(firePos); //shot position
			params.write_Vec2f(fireVec); //shot velocity
			
			this.SendCommand(this.getCommandID(shot_command_ID), params);

			m1ShotTicks = 0;
		}
	}

	if (pressed_m1)
	{ m1Time++; }
	else { m1Time = 0; }
	
	if (pressed_m2)
	{ m2Time++; }
	else { m2Time = 0; }
	this.set_u32( "m1_heldTime", m1Time );
	this.set_u32( "m2_heldTime", m2Time );

	m1ShotTicks++;
	//m2ShotTicks++;
	this.set_u32( "m1_shotTime", m1ShotTicks );
	this.set_u32( "m2_shotTime", m2ShotTicks );

	//sound logic
	/*Vec2f vel = this.getVelocity();
	float posVelX = Maths::Abs(vel.x);
	float posVelY = Maths::Abs(vel.y);
	if(posVelX > 2.9f)
	{
		this.getSprite().SetEmitSoundVolume(3.0f);
	}
	else
	{
		this.getSprite().SetEmitSoundVolume(1.0f * (posVelX > posVelY ? posVelX : posVelY));
	}*/

	

    //ManageSpell( this, ship, playerPrefsInfo, moveVars );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID(shot_command_ID)) // 1 shot instance
    {
		if (!isServer())
		{ return; }
		
		u16 ownerID;
		if (!params.saferead_u16(ownerID)) return;

		u8 shotType;
		if (!params.saferead_u8(shotType)) return;

		Vec2f blobPos;
		Vec2f blobVel;
		if (!params.saferead_Vec2f(blobPos)) return;
		if (!params.saferead_Vec2f(blobVel)) return;

		CBlob@ ownerBlob = getBlobByNetworkID(ownerID);
		if (ownerBlob == null || ownerBlob.hasTag("dead"))
		{ return; }
		
		if (blobPos == Vec2f_zero || blobVel == Vec2f_zero)
		{ return; }

		string blobName = "orb";
		switch (shotType)
		{
			case 0:
			{
				blobName = "orb";
			}
			break;

			case 1:
			{
				blobName = "gatling_basicshot";
			}
			break;

			case 2:
			{
				blobName = "bee";
			}
			break;
			default: return;
		}

		CBlob@ blob = server_CreateBlob( blobName , ownerBlob.getTeamNum(), blobPos);
		if (blob !is null)
		{
			blob.IgnoreCollisionWhileOverlapped( ownerBlob );
			blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
			blob.setVelocity( blobVel );
		}
	}
	else if (cmd == this.getCommandID(hit_command_ID)) // if a shot hits, this gets sent
    {
		
	}
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    if (( hitterBlob.getName() == "wraith" || hitterBlob.getName() == "orb" ) && hitterBlob.getTeamNum() == this.getTeamNum())
        return 0;

	if (isClient())
	{
		makeHullHitSparks( worldPoint, 15 );
	}

    return damage;
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	//empty
}

void onDie( CBlob@ this )
{
	Vec2f thisPos = this.getPosition();
	blast( thisPos , 12);
}

Random _fighter_logic_r(67532);
void blast( Vec2f pos , int amount)
{
	if(!isClient())
	{return;}

	Sound::Play("GenericExplosion1.ogg", pos, 0.8f, 0.8f + XORRandom(10)/10.0f);

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_fighter_logic_r.NextFloat() * 3.0f, 0);
        vel.RotateBy(_fighter_logic_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated("GenericBlast6.png", 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.5f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) continue; //bail if we stop getting particles
		
    	p.fastcollision = true;
        p.damping = 0.85f;
		p.Z = 200.0f;
		p.lighting = false;
    }
}