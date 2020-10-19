// Necromancer animations

#include "NecromancerCommon.as"
#include "PlayerPrefsCommon.as"
#include "MagicCommon.as";
#include "FireParticle.as"
#include "RunnerAnimCommon.as";
#include "RunnerCommon.as";
#include "KnockedCommon.as";
#include "PixelOffsets.as"
#include "RunnerTextures.as"

const f32 config_offset = -4.0f;
const string shiny_layer = "shiny bit";
const string shiny_layer2 = "shiny bit 2";
const string damageboost_layer = "damage boost";
const string damageboost_layer2 = "damage boost 2";

void onInit(CSprite@ this)
{
	RunnerTextures@ runner_tex = addRunnerTextures(this, "necromancer", "Necromancer");

	LoadSprites(this);
}

void onPlayerInfoChanged(CSprite@ this)
{
	LoadSprites(this);
}

void LoadSprites( CSprite@ this )
{
    string texname = "NecromancerMale.png";
    this.ReloadSprite( texname, this.getConsts().frameWidth, this.getConsts().frameHeight,
                       this.getBlob().getTeamNum(), this.getBlob().getSkinNum() );
    
    // add shiny
	this.RemoveSpriteLayer(shiny_layer);
	CSpriteLayer@ shiny = this.addSpriteLayer( shiny_layer, "SpellReady.png", 16, 16 );

	if (shiny !is null)
	{
		Animation@ anim = shiny.addAnimation( "default", 2, true );
		int[] frames = {0,1};
		anim.AddFrames(frames);
		shiny.SetVisible(false);
		shiny.SetRelativeZ(8.0f);
	}
	
	this.RemoveSpriteLayer(shiny_layer2);
	CSpriteLayer@ shiny2 = this.addSpriteLayer( shiny_layer2, "SpellReady.png", 16, 16 );

	if (shiny2 !is null)
	{
		Animation@ anim = shiny2.addAnimation( "default", 2, true );
		int[] frames = {2,3};
		anim.AddFrames(frames);
		shiny2.SetVisible(false);
		shiny2.SetRelativeZ(8.0f);
	}

    this.RemoveSpriteLayer(damageboost_layer);
	CSpriteLayer@ damageboost = this.addSpriteLayer( damageboost_layer, "DamageBoost.png", 32, 32 );

	if (damageboost !is null)
	{
		damageboost.SetVisible(false);
		damageboost.SetRelativeZ(-5.0f);
	}

    this.RemoveSpriteLayer(damageboost_layer2);
	CSpriteLayer@ damageboost2 = this.addSpriteLayer( damageboost_layer2, "DamageBoost.png", 32, 32 );

	if (damageboost2 !is null)
	{
        Animation@ anim = damageboost2.addAnimation( "default", 0, false );
		int[] frames = {1};
		anim.AddFrames(frames);
		damageboost2.SetVisible(false);
        damageboost2.SetRelativeZ(-5.0f);
	}
}

// stuff for shiny - global cause is used by a couple functions in a tick
bool needs_shiny = false;
bool needs_shiny2 = false;
bool needs_damageboost = false;
f32 shiny_angle = 0.0f;

void onTick( CSprite@ this )
{
	if ( this is null )
		return;
	
    // store some vars for ease and speed
    CBlob@ blob = this.getBlob();
	
	if ( blob is null )
		return;
	
	if (blob.hasTag("dead"))
    {
		if (this.animation.name != "dead")
		{
			this.SetAnimation("dead");
			this.RemoveSpriteLayer(shiny_layer);
            this.RemoveSpriteLayer(damageboost_layer);
            this.RemoveSpriteLayer(damageboost_layer2);
		}
        
        Vec2f vel = blob.getVelocity();

        if (vel.y < -1.0f) {
            this.SetFrameIndex( 0 );
        }
		else if (vel.y > 2.0f) {
			this.SetFrameIndex( 1 );
		}
		else {
			this.SetFrameIndex( 2 );
		}

        return;
    }
    
    NecromancerInfo@ necromancer;
	if (!blob.get( "necromancerInfo", @necromancer )) 
	{
		return;
	}
	
	CPlayer@ localPlayer = getLocalPlayer();
	if ( localPlayer is null )
	{
		return;
	}
	
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!localPlayer.get( "playerPrefsInfo", @playerPrefsInfo )) 
	{
		return;
	}

	// animations
	int spellsLength = NecromancerParams::spells.length;
	const bool firing = blob.isKeyPressed(key_action1) || blob.isKeyPressed(key_action2);
	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);
	const bool inair = (!blob.isOnGround() && !blob.isOnLadder());
	bool spell_ready = false;
	if (blob.isKeyPressed(key_action1))
		spell_ready = NecromancerParams::spells[playerPrefsInfo.primarySpellID].needs_full ? necromancer.charge_state >= NecromancerParams::cast_3 : necromancer.charge_state >= NecromancerParams::cast_1;
	else if (blob.isKeyPressed(key_action2))
		spell_ready = NecromancerParams::spells[Maths::Min(playerPrefsInfo.hotbarAssignments_Necromancer[15], spellsLength-1)].needs_full ? necromancer.charge_state >= NecromancerParams::cast_3 : necromancer.charge_state >= NecromancerParams::cast_1;
	bool full_charge = necromancer.charge_state == NecromancerParams::extra_ready;
	needs_shiny = spell_ready;
	needs_shiny2 = necromancer.charge_state >= NecromancerParams::charging;
	needs_damageboost = blob.hasTag("extra_damage");
    bool crouch = false;

	const u8 knocked = getKnockedRemaining(blob);
	const bool frozen = blob.get_bool("frozen");
	Vec2f pos = blob.getPosition();
	Vec2f aimpos = blob.getAimPos();
	// get the angle of aiming with mouse
	Vec2f vec = aimpos - pos;
	f32 angle = vec.Angle();
	Vec2f shiny_offset = Vec2f( 12.0f, 0.0f );
	shiny_offset.RotateBy( this.isFacingLeft() ?  -angle : (angle+180));

	if (knocked > 0 || frozen)
	{
		if (inair) {
			this.SetAnimation("knocked_air");
		}
		else {
			this.SetAnimation("knocked");
		}
	}
	else if (blob.hasTag( "seated" ))
	{
		this.SetAnimation("default");
	}
	else if (firing)
	{
		if (inair)
		{
			this.SetAnimation("shoot_jump");
		}
		else if ((left || right) ||
             (blob.isOnLadder() && (up || down) ) ) {
			this.SetAnimation("shoot_run");
		}
		else
		{
			this.SetAnimation("shoot");
			if (spell_ready)
				this.SetFrameIndex(1);
		}
    }
    else if (inair)
    {
		RunnerMoveVars@ moveVars;
		if (!blob.get( "moveVars", @moveVars )) {
			return;
		}
		Vec2f vel = blob.getVelocity();
		f32 vy = vel.y;
		if (vy < -0.0f && moveVars.walljumped)
		{
			this.SetAnimation("run");
		}
		else
		{	
			this.SetAnimation("fall");
			this.animation.timer = 0;

			if (vy < -1.5 ) {
				this.animation.frame = 0;
			}
			else if (vy > 1.5 ) {
				this.animation.frame = 2;
			}
			else {
				this.animation.frame = 1;
			}
		}
    }
    else if ((left || right) ||
             (blob.isOnLadder() && (up || down) ) ) {
        this.SetAnimation("run");
    }
    else
    {
		if(down && this.isAnimationEnded())
			crouch = true;

		int direction;

		if ((angle > 330 && angle < 361) || (angle > -1 && angle < 30) ||
			(angle > 150 && angle < 210)) {
				direction = 0;
		}
		else if (aimpos.y < pos.y) {
			direction = -1;
		}
		else {
			direction = 1;
		}

        defaultIdleAnim(this, blob, direction);
    }
    
    //set the shiny dot on the arrow
    
    CSpriteLayer@ shiny = this.getSpriteLayer( shiny_layer );
    if(shiny !is null)
    {
		shiny.SetVisible(needs_shiny);
		if(needs_shiny)
		{
			shiny.RotateBy(10, Vec2f());
				
			shiny.SetOffset(shiny_offset);
		}
	}
	
    CSpriteLayer@ shiny2 = this.getSpriteLayer( shiny_layer2 );
    if(shiny2 !is null)
    {
		shiny2.SetVisible(needs_shiny2);
		if(needs_shiny2)
		{
			shiny2.RotateBy(10, Vec2f());
				
			shiny2.SetOffset(shiny_offset);
		}
	}

    //Damage boost sprite
    CSpriteLayer@ damageboost = this.getSpriteLayer( damageboost_layer );
    if(damageboost !is null)
    {
		damageboost.SetVisible(needs_damageboost);
		if(needs_damageboost)
		{
			damageboost.RotateBy(-5, Vec2f());
			damageboost.SetOffset(Vec2f(0.0f,-1.0f));
		}
	}
    CSpriteLayer@ damageboost2 = this.getSpriteLayer( damageboost_layer2 );
    if(damageboost2 !is null)
    {
		damageboost2.SetVisible(needs_damageboost);
		if(needs_damageboost)
		{
			damageboost2.RotateBy(4, Vec2f());
			damageboost2.SetOffset(Vec2f(0.0f,-1.0f));
		}
	}

	//set the head anim
    if (knocked > 0 || frozen || crouch)
    {
		blob.Tag("dead head");
	}
    else if (blob.isKeyPressed(key_action1))
    {
        blob.Tag("attack head");
        blob.Untag("dead head");
    }
    else
    {
        blob.Untag("attack head");
        blob.Untag("dead head");
    }
}

void onGib(CSprite@ this)
{
	if (g_kidssafe) {
		return;
	}
	
	if ( !getNet().isClient() )
		return;

	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()),2.0f) + 1.0f;
	const u8 team = blob.getTeamNum();
	makeGibParticle( "Entities/Characters/Archer/ArcherGibs.png", pos, vel + getRandomVelocity( 90, hp , 80 ), 0, 0, Vec2f (16,16), 2.0f, 20, "/BodyGibFall", team );
	makeGibParticle( "Entities/Characters/Archer/ArcherGibs.png", pos, vel + getRandomVelocity( 90, hp - 0.2 , 80 ), 1, 0, Vec2f (16,16), 2.0f, 20, "/BodyGibFall", team );
	makeGibParticle( "Entities/Characters/Archer/ArcherGibs.png", pos, vel + getRandomVelocity( 90, hp , 80 ), 2, 0, Vec2f (16,16), 2.0f, 0, "Sounds/material_drop.ogg", team );
	makeGibParticle( "Entities/Characters/Archer/ArcherGibs.png", pos, vel + getRandomVelocity( 90, hp + 1 , 80 ), 3, 0, Vec2f (16,16), 2.0f, 0, "Sounds/material_drop.ogg", team );
}
