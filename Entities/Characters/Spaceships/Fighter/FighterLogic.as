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

	this.set_s8( "charge_time", 0 );
	this.set_u8( "charge_state", FrigateParams::not_aiming );
	this.set_s32( "mana", 100 );
	this.set_f32("gib health", -3.0f);
	this.set_Vec2f("spell blocked pos", Vec2f(0.0f, 0.0f));
	this.set_bool("casting", false);
	this.set_bool("shifted", false);
	
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
	//this.getShape().SetGravityScale(0);

    this.addCommandID( "spell" );
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

	if(isClient())
	{
		this.getSprite().SetEmitSound("engine_loop.ogg");
		this.getSprite().SetEmitSoundPaused(true);
	}
}

void onSetPlayer( CBlob@ this, CPlayer@ player )
{
	if (player !is null){
		player.SetScoreboardVars("ScoreboardIcons.png", 2, Vec2f(16,16));
	}
}

void onTick( CBlob@ this )
{
    SmallshipInfo@ ship;
	if (!this.get( "smallshipInfo", @ship )) 
	{ return; }
	
	CPlayer@ thisPlayer = this.getPlayer();
	if ( thisPlayer is null )
	{ return; }


	// vvvvvvvvvvvvvv CLIENT-SIDE ONLY vvvvvvvvvvvvvvvvvvv
	if (!isClient()) return;

	SpaceshipVars@ moveVars;
    if (!this.get( "moveVars", @moveVars )) {
        return;
    }

	Vec2f vel = this.getVelocity();
	float posVelX = Maths::Abs(vel.x);
	float posVelY = Maths::Abs(vel.y);
	if(posVelX > 2.9f)
	{
		this.getSprite().SetEmitSoundVolume(3.0f);
	}
	else
	{
		this.getSprite().SetEmitSoundVolume(1.0f * (posVelX > posVelY ? posVelX : posVelY));
	}

	if (this.isInInventory()) return;

    //ManageSpell( this, ship, playerPrefsInfo, moveVars );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("spell"))  //from standardcontrols
    {
		
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