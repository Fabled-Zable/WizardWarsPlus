// Knight animations

#include "SmallshipCommon.as";
#include "RunnerAnimCommon.as";
#include "RunnerCommon.as";
#include "KnockedCommon.as";
#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "CommonFX.as"
#include "ShieldCommon.as"

const string up_fire = "forward_burn";
const string down_fire = "backward_burn";
const string left_fire = "board_burn";
const string right_fire = "starboard_burn";

Random _fighter_anim_r(14861);

void onInit(CSprite@ this)
{
	LoadSprites(this);
}

void onPlayerInfoChanged(CSprite@ this)
{
	LoadSprites(this);
}

void LoadSprites(CSprite@ this)
{

	// add shiny
	/*
	this.RemoveSpriteLayer(shiny_layer);
	CSpriteLayer@ shiny = this.addSpriteLayer(shiny_layer, "AnimeShiny.png", 16, 16);
	if (shiny !is null)
	{
		Animation@ anim = shiny.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		shiny.SetVisible(false);
		shiny.SetRelativeZ(1.0f);
	}*/

	// add engine burns
	this.RemoveSpriteLayer(up_fire);
	this.RemoveSpriteLayer(down_fire);
	this.RemoveSpriteLayer(left_fire);
	this.RemoveSpriteLayer(right_fire);
	CSpriteLayer@ upFire = this.addSpriteLayer(up_fire, "Flash1.png", 32, 32);
	CSpriteLayer@ downFire = this.addSpriteLayer(down_fire, "Flash1.png", 32, 32);
	CSpriteLayer@ leftFire = this.addSpriteLayer(left_fire, "Flash1.png", 32, 32);
	CSpriteLayer@ rightFire = this.addSpriteLayer(right_fire, "Flash1.png", 32, 32);
	if (upFire !is null)
	{
		Animation@ anim = upFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		upFire.SetVisible(false);
		upFire.SetRelativeZ(-1.1f);
		//upFire.RotateBy(0, Vec2f_zero);
		upFire.SetOffset(Vec2f(8, 0));
	}
	if (downFire !is null)
	{
		Animation@ anim = downFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		downFire.SetVisible(false);
		downFire.SetRelativeZ(-1.2f);
		downFire.ScaleBy(0.5f, 0.5f);
		//downFire.RotateBy(0, Vec2f_zero);
		downFire.SetOffset(Vec2f(-6, 0));
	}
	if (leftFire !is null)
	{
		Animation@ anim = leftFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		leftFire.SetVisible(false);
		leftFire.SetRelativeZ(-1.3f);
		leftFire.ScaleBy(0.3f, 0.3f);
		leftFire.RotateBy(90, Vec2f_zero);
		leftFire.SetOffset(Vec2f(0, 5));
	}
	if (rightFire !is null)
	{
		Animation@ anim = rightFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		rightFire.SetVisible(false);
		rightFire.SetRelativeZ(-1.4f);
		rightFire.ScaleBy(0.3f, 0.3f);
		rightFire.RotateBy(90, Vec2f_zero);
		rightFire.SetOffset(Vec2f(0, -5));
	}
	
}

void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ blob = this.getBlob();
	if (blob == null)
	{ return; }

	Vec2f blobPos = blob.getPosition();
	Vec2f blobVel = blob.getVelocity();
	f32 blobAngle = blob.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;
	Vec2f aimpos;

	/*KnightInfo@ knight;
	if (!blob.get("knightInfo", @knight))
	{
		return;
	}*/

	SmallshipInfo@ ship;
	if (!blob.get( "smallshipInfo", @ship )) 
	{ return; }
	
	/*
	bool knocked = isKnocked(blob);

	bool shieldState = isShieldState(knight.state);
	bool specialShieldState = isSpecialShieldState(knight.state);
	bool swordState = isSwordState(knight.state);

	bool pressed_a1 = blob.isKeyPressed(key_action1);
	bool pressed_a2 = blob.isKeyPressed(key_action2);

	bool walking = (blob.isKeyPressed(key_left) || blob.isKeyPressed(key_right));

	aimpos = blob.getAimPos();
	bool inair = (!blob.isOnGround() && !blob.isOnLadder());

	Vec2f vel = blob.getVelocity();

	if (blob.hasTag("dead"))
	{
		if (this.animation.name != "dead")
		{
			this.RemoveSpriteLayer(shiny_layer);
			this.SetAnimation("dead");
		}
		Vec2f oldvel = blob.getOldVelocity();

		//TODO: trigger frame one the first time we server_Die()()
		if (vel.y < -1.0f)
		{
			this.SetFrameIndex(1);
		}
		else if (vel.y > 1.0f)
		{
			this.SetFrameIndex(3);
		}
		else
		{
			this.SetFrameIndex(2);
		}
		return;
	}

	// get the angle of aiming with mouse
	Vec2f vec;
	int direction = blob.getAimDirection(vec);

	// set facing
	bool facingLeft = this.isFacingLeft();
	// animations
	bool ended = this.isAnimationEnded() || this.isAnimation("shield_raised");
	bool wantsChopLayer = false;
	s32 chopframe = 0;
	f32 chopAngle = 0.0f;

	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);

	bool shinydot = false;

	if (knocked)
	{
		if (inair)
		{
			this.SetAnimation("knocked_air");
		}
		else
		{
			this.SetAnimation("knocked");
		}
	}
	else if (blob.hasTag("seated"))
	{
		this.SetAnimation("crouch");
	}
	else
	{
		switch(knight.state)
		{
			case KnightStates::shieldgliding:
				this.SetAnimation("shield_glide");
			break;

			case KnightStates::shielddropping:
				this.SetAnimation("shield_drop");
			break;

			case KnightStates::resheathing_slash:
				this.SetAnimation("resheath_slash");
			break;

			case KnightStates::resheathing_cut:
				this.SetAnimation("draw_sword");
			break;

			case KnightStates::sword_cut_mid:
				this.SetAnimation("strike_mid");
			break;

			case KnightStates::sword_cut_mid_down:
				this.SetAnimation("strike_mid_down");
			break;

			case KnightStates::sword_cut_up:
				this.SetAnimation("strike_up");
			break;

			case KnightStates::sword_cut_down:
				this.SetAnimation("strike_down");
			break;

			case KnightStates::sword_power:
			case KnightStates::sword_power_super:
			{
				this.SetAnimation("strike_power");

				if (knight.swordTimer <= 1)
					this.animation.SetFrameIndex(0);

				u8 mintime = 6;
				u8 maxtime = 8;
				if (knight.swordTimer >= mintime && knight.swordTimer <= maxtime)
				{
					wantsChopLayer = true;
					chopframe = knight.swordTimer - mintime;
					chopAngle = -vec.Angle();
				}
			}
			break;

			case KnightStates::sword_drawn:
			{
				if (knight.swordTimer < KnightVars::slash_charge)
				{
					this.SetAnimation("draw_sword");
				}
				else if (knight.swordTimer < KnightVars::slash_charge_level2)
				{
					this.SetAnimation("strike_power_ready");
					this.animation.frame = 0;
				}
				else if (knight.swordTimer < KnightVars::slash_charge_limit)
				{
					this.SetAnimation("strike_power_ready");
					this.animation.frame = 1;
					shinydot = true;
				}
				else
				{
					this.SetAnimation("draw_sword");
				}
			}
			break;

			case KnightStates::shielding:
			{
				if (!isShieldEnabled(blob))
					break;

				if (walking)
				{
					if (direction == 0)
					{
						this.SetAnimation("shield_run");
					}
					else if (direction == -1)
					{
						this.SetAnimation("shield_run_up");
					}
					else if (direction == 1)
					{
						this.SetAnimation("shield_run_down");
					}
				}
				else
				{
					this.SetAnimation("shield_raised");

					if (direction == 1)
					{
						this.animation.frame = 2;
					}
					else if (direction == -1)
					{
						if (vec.y > -0.97)
						{
							this.animation.frame = 1;
						}
						else
						{
							this.animation.frame = 3;
						}
					}
					else
					{
						this.animation.frame = 0;
					}
				}
			}
			break;

			default:
			{
				if (inair)
				{
					RunnerMoveVars@ moveVars;
					if (!blob.get("moveVars", @moveVars))
					{
						return;
					}
					f32 vy = vel.y;
					if (vy < -0.0f && moveVars.walljumped)
					{
						this.SetAnimation("run");
					}
					else
					{
						this.SetAnimation("fall");
						this.animation.timer = 0;

						if (vy < -1.5)
						{
							this.animation.frame = 0;
						}
						else if (vy > 1.5)
						{
							this.animation.frame = 2;
						}
						else
						{
							this.animation.frame = 1;
						}
					}
				}
				else if (walking || 
					(blob.isOnLadder() && (blob.isKeyPressed(key_up) || blob.isKeyPressed(key_down))))
				{
					this.SetAnimation("run");
				}
				else
				{
					defaultIdleAnim(this, blob, direction);
				}
			}
		}
	}

	//set the shiny dot on the sword

	CSpriteLayer@ shiny = this.getSpriteLayer(shiny_layer);

	if (shiny !is null)
	{
		shiny.SetVisible(shinydot);
		if (shinydot)
		{
			f32 range = (KnightVars::slash_charge_limit - KnightVars::slash_charge_level2);
			f32 count = (knight.swordTimer - KnightVars::slash_charge_level2);
			f32 ratio = count / range;
			shiny.RotateBy(10, Vec2f());
			shiny.SetOffset(Vec2f(12, -2 + ratio * 8));
		}
	}*/

	//set engine burns to correct places

	CSpriteLayer@ upFire	= this.getSpriteLayer(up_fire);
	CSpriteLayer@ downFire	= this.getSpriteLayer(down_fire);
	CSpriteLayer@ leftFire	= this.getSpriteLayer(left_fire);
	CSpriteLayer@ rightFire	= this.getSpriteLayer(right_fire);

	bool mainEngine = ship.forward_thrust;
	if (upFire !is null)
	{ upFire.SetVisible(mainEngine); }
	if (downFire !is null)
	{ downFire.SetVisible(ship.backward_thrust); }
	if (leftFire !is null)
	{ leftFire.SetVisible(ship.board_thrust); }
	if (rightFire !is null)
	{ rightFire.SetVisible(ship.starboard_thrust); }



	if (mainEngine)
	{
		Vec2f engineOffset = Vec2f(-8.0f, 0);
		engineOffset.RotateByDegrees(blobAngle);
		Vec2f trailPos = blobPos + engineOffset;

		Vec2f trailNorm = Vec2f(-1.0f, 0);
		trailNorm.RotateByDegrees(blobAngle);

		u32 gameTime = getGameTime();

		//f32 trailSwing = Maths::Sin(gameTime * 0.1f) + 1.0f;
		//trailSwing *= 0.5f;
		f32 trailSwing = Maths::Sin(gameTime * 0.1f);

		f32 swingMaxAngle = 30.0f * trailSwing;

		u16 particleNum = 10;

		int teamNum = blob.getTeamNum();
		SColor color = getTeamColorWW(teamNum);

		for(int i = 0; i <= particleNum; i++)
	    {
			u8 alpha = 200.0f + (55.0f * _fighter_anim_r.NextFloat()); //randomize alpha
			color.setAlpha(alpha);

			f32 pRatio = float(i) / float(particleNum);
			f32 pAngle = (pRatio*2.0f) - 1.0f;

			Vec2f pVel = trailNorm;
			pVel.RotateByDegrees(swingMaxAngle*pAngle);
			pVel *= 3.0f - Maths::Abs(pAngle);

			pVel += blobVel;

	        CParticle@ p = ParticlePixelUnlimited(trailPos, pVel, color, true);
	        if(p !is null)
	        {
	   	        p.collides = false;
	   	        p.gravity = Vec2f_zero;
	            p.bounce = 0;
	            p.Z = 7;
	            p.timeout = 30;
				p.setRenderStyle(RenderStyle::light);
	    	}
		}
	}


	//set the head anim
	/*
	if (knocked)
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
	}*/

}

/*
void onGib(CSprite@ this)
{
	if (g_kidssafe)
	{
		return;
	}

	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0f;
	const u8 team = blob.getTeamNum();
	CParticle@ Body     = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm      = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Shield   = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
	CParticle@ Sword    = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80), 3, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
}


// render cursors

void DrawCursorAt(Vec2f position, string& in filename)
{
	position = getMap().getAlignedWorldPos(position);
	if (position == Vec2f_zero) return;
	position = getDriver().getScreenPosFromWorldPos(position - Vec2f(1, 1));
	GUI::DrawIcon(filename, position, getCamera().targetDistance * getDriver().getResolutionScaleFactor());
}

const string cursorTexture = "Entities/Characters/Sprites/TileCursor.png";

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (!blob.isMyPlayer())
	{
		return;
	}
	if (getHUD().hasButtons())
	{
		return;
	}

	// draw tile cursor

	if (blob.isKeyPressed(key_action1))
	{
		CMap@ map = blob.getMap();
		Vec2f position = blob.getPosition();
		Vec2f cursor_position = blob.getAimPos();
		Vec2f surface_position;
		map.rayCastSolid(position, cursor_position, surface_position);
		Vec2f vector = surface_position - position;
		f32 distance = vector.getLength();
		Tile tile = map.getTile(surface_position);

		if ((map.isTileSolid(tile) || map.isTileGrass(tile.type)) && map.getSectorAtPosition(surface_position, "no build") is null && distance < 16.0f)
		{
			DrawCursorAt(surface_position, cursorTexture);
		}
	}
}*/
