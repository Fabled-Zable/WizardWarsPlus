//Spells Common
#include "MagicCommon.as";
#include "NecromancerCommon.as";
#include "WizardCommon.as";
#include "DruidCommon.as";
#include "Hitters.as";
#include "PlayerPrefsCommon.as";

void CastSpell(CBlob@ this, const s8 charge_state, const Spell spell, Vec2f aimpos )
{	//To get a spell hash to add more spells type this in the console (press home in game)
	//print('cfg_name'.getHash()+'');
	//As an example with the meteor spell, i'd type out
	//print('meteor_strike'.getHash()+'');
	//then add whatever case with the hash
	//print('meteor_strike'.getHash()+'');
    string spellName = spell.typeName;
	switch(spellName.getHash())
	{
		case 1476886618:
		{
			if(isServer())
			{

			Vec2f pos = this.getPosition();
			Vec2f aim = aimpos;
			Vec2f vel = aim - pos;
			Vec2f norm = vel;
			norm.Normalize();
			CBlob@ b = server_CreateBlob('boulder',this.getTeamNum(),this.getPosition() + norm*2);
			b.server_SetHealth(999);
			b.server_SetTimeToDie(3);
			b.setVelocity(vel/32);
			b.getShape().SetGravityScale(0.75);
			b.server_setTeamNum(b.getTeamNum());
			b.SetDamageOwnerPlayer(this.getPlayer());
			}
		}
		break;
		case -825046729: //mushroom
			{
				CBlob@[] mushrooms;
				getBlobsByName("mushroom",@mushrooms);

				for(int i = 0; i < mushrooms.length; i++)
				{
					if(mushrooms[i].get_string("owner") == this.getPlayer().getUsername())
					{
						mushrooms[i].server_Die();
						break;
					}
				}

				int height = getLandHeight(aimpos);
				if(height != 0)
				{
					if(isServer())
					{
						CBlob@ mush = server_CreateBlob("mushroom",this.getTeamNum(),Vec2f(aimpos.x,height) );
						mush.SetDamageOwnerPlayer(this.getPlayer());
						mush.set_string("owner",this.getPlayer().getUsername());
						mush.set_s32("aliveTime",charge_state == 5 ? 1800 : 900); //if full charge last longer
					}
				}
				else
				{
					ManaInfo@ manaInfo;
					if (!this.get( "manaInfo", @manaInfo )) {
						return;
					}
					
					manaInfo.mana += spell.mana;
					
					this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
				}
			}
		break;

		case -1727909596: //arcane_circle
			if(isServer())
			{
				CBlob@ circle = server_CreateBlob('arcane_circle',this.getTeamNum(),aimpos);
				circle.SetDamageOwnerPlayer(this.getPlayer());
				circle.set_s32("aliveTime",charge_state == 5 ? 1350 : 900);
			}
		break;
		case 750462252: //mana_drain_circle
		if(isServer())
		{
			CBlob@ circle = server_CreateBlob("mana_drain_circle",this.getTeamNum(),aimpos);
			circle.set_s32("aliveTime",charge_state == 5 ? 1350 : 900);
		}
		break;

		case -1625426670: //orb
		{
			if (!isServer()){
           		return;
			}

			f32 orbspeed = NecromancerParams::shoot_max_vel;
			f32 orbDamage = 4.0f;
            f32 extraDamage = this.hasTag("extra_damage") ? 0.3f : 0.0f;//Is this condition true? yes is 1.2f and no is 1.0f
            
			if (charge_state == NecromancerParams::cast_1) {
				orbspeed *= (1.0f/2.0f);
				orbDamage *= 0.5f + extraDamage;
			}
			else if (charge_state == NecromancerParams::cast_2) {
				orbspeed *= (4.0f/5.0f);
				orbDamage *= 0.7f + extraDamage;
			}
            else if (charge_state == NecromancerParams::cast_3) {
				orbDamage *= 1.0f + extraDamage;
			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbspeed *= 1.2f;
				orbDamage *= 1.5f + extraDamage;
			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "orb" );
			if (orb !is null)
			{
				orb.set_f32("explosive_damage", orbDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case 1463630946://spikedorb
		{
			if (!isServer()){
           		return;
			}
			f32 orbspeed = NecromancerParams::shoot_max_vel;
			f32 orbDamage = 4.0f;

			if (charge_state == NecromancerParams::cast_1) {
				orbspeed *= (2.0f/3.0f);

			}
			else if (charge_state == NecromancerParams::cast_2) {
				orbspeed *= (4.0f/5.0f);

			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbspeed *= 1.2f;

			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "spikeorb" );
			if (orb !is null)
			{
				
				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case 829656850: //sporeshot
		{
			if (!isServer()){
           		return;
			}
			f32 orbspeed = NecromancerParams::shoot_max_vel;
			f32 orbDamage = 4.0f;

			if (charge_state == NecromancerParams::cast_1) {
				orbspeed *= (2.0f/3.0f);

			}
			else if (charge_state == NecromancerParams::cast_2) {
				orbspeed *= (4.0f/5.0f);

			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbspeed *= 1.2f;

			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "sporeshot" );
			if (orb !is null)
			{
				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case -377943487: //forceorb
		{
			 f32 orbspeed = NecromancerParams::shoot_max_vel;
			f32 orbDamage = 0.0f;

			if (charge_state == NecromancerParams::cast_1) {
				orbspeed *= (1.0f/2.0f);
				orbDamage *= 0.0f;
			}
			else if (charge_state == NecromancerParams::cast_2) {
				orbspeed *= (4.0f/5.0f);
				orbDamage *= 0.0f;
			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbspeed *= 1.2f;
				orbDamage *= 0.0f;
			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "forceorb" );
			if (orb !is null)
			{
				orb.set_f32("explosive_damage", orbDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case 2016613317://firebomb
		{
			if (!isServer()){
           		return;
			}
			f32 orbspeed = NecromancerParams::shoot_max_vel*0.75f;
			f32 orbDamage = 4.0f;
            f32 extraDamage = this.hasTag("extra_damage") ? 0.3f : 0.0f;

			if (charge_state == NecromancerParams::cast_1) {
				orbspeed *= (1.0f/2.0f);
				orbDamage *= 0.5f + extraDamage;
			}
			else if (charge_state == NecromancerParams::cast_2) {
				orbspeed *= (4.0f/5.0f);
				orbDamage *= 0.7f + extraDamage;
			}
            else if (charge_state == NecromancerParams::cast_3) {
				orbDamage *= 1.0f + extraDamage;
			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbspeed *= 1.2f;
				orbDamage *= 1.5f + extraDamage;
			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "firebomb" );
			if (orb !is null)
			{
				orb.set_f32("explosive_damage", orbDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case 1174066691://fire_sprite
		{
			if(!isServer()){
				return;
			}
			f32 orbDamage = 2.0f;
            f32 extraDamage = this.hasTag("extra_damage") ? 0.3f : 0.0f;

			if (charge_state == NecromancerParams::cast_1) {
				orbDamage *= 0.5f + extraDamage;
			}
			else if (charge_state == NecromancerParams::cast_2) {
				orbDamage *= 0.7f + extraDamage;
			}
            else if (charge_state == NecromancerParams::cast_3) {
				orbDamage *= 1.0f + extraDamage;
			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbDamage *= 1.5f + extraDamage;
			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);

			CBlob@ orb = server_CreateBlob( "fire_sprite" );
			if (orb !is null)
			{
				orb.set_f32("explosive_damage", orbDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
			}
		}
		break;

		case 18140583://frost_ball
		{
			if (!isServer()){
           		return;
			}
			f32 orbspeed = 6.0f;
			f32 orbDamage = 4.0f;
            f32 extraDamage = this.hasTag("extra_damage") ? 0.3f : 0.0f;

			if (charge_state == NecromancerParams::cast_1) {
				orbspeed *= (1.0f/2.0f);
				orbDamage *= 0.5f + extraDamage;
			}
			else if (charge_state == NecromancerParams::cast_2) {
				orbspeed *= (4.0f/5.0f);
				orbDamage *= 0.7f + extraDamage;
			}
            else if (charge_state == NecromancerParams::cast_3) {
				orbDamage *= 1.0f + extraDamage;
			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbspeed *= 1.2f;
				orbDamage *= 1.5f + extraDamage;
			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "frost_ball" );
			if (orb !is null)
			{
				orb.set_f32("explosive_damage", orbDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case 979982427://heal
		{
			f32 orbspeed = 4.0f;
			f32 healAmount = 0.8f;

			if (charge_state == NecromancerParams::cast_1) {
				orbspeed *= (1.0f/2.0f);
			}
			else if (charge_state == NecromancerParams::cast_2) {
				orbspeed *= (4.0f/5.0f);
			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbspeed *= 1.2f;
				healAmount *= 0.5f;
			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;
			
			if (charge_state == NecromancerParams::extra_ready)
			{
				Heal(this, healAmount);
			}
			else
			{
				if (isServer())
				{
					CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
					if (orb !is null)
					{
						orb.set_string("effect", "heal");
						orb.set_f32("heal_amount", healAmount);

						orb.IgnoreCollisionWhileOverlapped( this );
						orb.SetDamageOwnerPlayer( this.getPlayer() );
						orb.setVelocity( orbVel );
					}
				}
			}
		}
		break;

		case 1961711901://nature's helpers
		{
			f32 orbspeed = 5.0f;
			f32 healAmount = 0.2f;
			u8 speed = 1;
			if (charge_state == NecromancerParams::cast_1) {
				orbspeed *= (1.0f/2.0f);
			}
			else if (charge_state == NecromancerParams::cast_2) {
				orbspeed *= (4.0f/5.0f);
				speed = 2;
			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbspeed *= 1.2f;
				speed = 3;
			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;
			const int numOrbs = 10;
			
		
			if (isServer())
			{
				
				for (int i = 0; i < numOrbs; i++)
				{
					if (charge_state == NecromancerParams::extra_ready)
					{
						numOrbs + 3;
					}
					// CBlob@ orb = server_CreateBlob( "effect_missile1", this.getTeamNum(), orbPos ); 
					// if (orb !is null)
					// {
					// 	orb.set_string("effect", "heal");
					// 	orb.set_f32("heal_amount", healAmount);

					// 	orb.IgnoreCollisionWhileOverlapped( this );
					// 	orb.SetDamageOwnerPlayer( this.getPlayer() );
					// 	Vec2f newVel = orbVel;
					// 	newVel.RotateBy( -10 + 5*i, Vec2f());
					// 	orb.setVelocity( newVel );
					// }

					CBlob@ orb = server_CreateBlob( "bee", this.getTeamNum(), orbPos ); 
					if (orb !is null)
					{
						orb.set_f32("heal_amount", healAmount);

						orb.IgnoreCollisionWhileOverlapped( this );
						orb.SetDamageOwnerPlayer( this.getPlayer() );
						Vec2f newVel = orbVel;
						newVel.RotateBy( -10 + 3*i, Vec2f());
						orb.setVelocity( newVel );
					}
				}
			}
		}
		break;

		case 1998653938://unholy_resurrection
		{
			f32 orbspeed = 4.0f;

			if (charge_state == NecromancerParams::cast_1) 
			{
				orbspeed *= (1.0f/2.0f);
			}
			else if (charge_state == NecromancerParams::cast_2) 
			{
				orbspeed *= (4.0f/5.0f);
			}
			else if (charge_state == NecromancerParams::extra_ready) 
			{
				orbspeed *= 1.2f;
			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;	
			
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_string("effect", "unholy_res");

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
		}
		break;

		case -456270322://counter_spell
		{
			counterSpell(this);
		}
		break;

		case -1214504009://magic_missle
		{
			f32 orbspeed = 2.0f;

			if (charge_state == NecromancerParams::cast_1) 
			{
				orbspeed *= (1.0f/2.0f);
			}
			else if (charge_state == NecromancerParams::cast_2) 
			{
				orbspeed *= (4.0f/5.0f);
			}
			else if (charge_state == NecromancerParams::extra_ready) 
			{
				orbspeed *= 1.2f;
			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;	
			
			if (isServer())
			{
				const int numOrbs = 4;
				for (int i = 0; i < numOrbs; i++)
				{
					CBlob@ orb = server_CreateBlob( "magic_missile", this.getTeamNum(), orbPos ); 
					if (orb !is null)
					{	
                        if(this.hasTag("extra_damage"))
                            orb.Tag("extra_damage");//Remember to change this in MagicMissile.as
						
                        orb.IgnoreCollisionWhileOverlapped( this );
						orb.SetDamageOwnerPlayer( this.getPlayer() );
						Vec2f newVel = orbVel;
						newVel.RotateBy( -10 + 5*i, Vec2f());
						orb.setVelocity( newVel );
					}
				}
			}
			else
			{
				this.getSprite().PlaySound("MagicMissile.ogg", 0.8f, 1.0f + XORRandom(3)/10.0f);
			}
		}
		break;

		case 882940767://black_hole
		{
			if (!isServer()){
				return;
			}
			f32 orbspeed = 6.0f;

			if (charge_state == NecromancerParams::cast_1) {
				orbspeed *= (1.0f/2.0f);
			}
			else if (charge_state == NecromancerParams::cast_2) {
				orbspeed *= (4.0f/5.0f);
			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbspeed *= 1.2f;
			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "black_hole" );
			if (orb !is null)
			{
				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			} 
		}
		break;

		case 1838498488://slow
		{
			f32 orbspeed = 4.0f;
			u16 slowTime = 600;

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;
			
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_string("effect", "slow");
					orb.set_u16("slow_time", slowTime);

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
		}
		break;

		case 888767856://haste
		{
			f32 orbspeed = 4.0f;
			u16 hasteTime = 600;

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			if (charge_state == NecromancerParams::extra_ready)
			{
				Haste(this, hasteTime);
			}		
			else if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_string("effect", "haste");
					orb.set_u16("haste_time", hasteTime);

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
		}
		break;

		case 545705456://revive
		{
			f32 orbspeed = 4.0f;

			if (charge_state == WizardParams::cast_1) 
			{
				orbspeed *= (1.0f/2.0f);
			}
			else if (charge_state == WizardParams::cast_2) 
			{
				orbspeed *= (4.0f/5.0f);
			}
			else if (charge_state == WizardParams::extra_ready) 
			{
				orbspeed *= 1.2f;
			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;	
			
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_string("effect", "revive");

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
		}
		break;

		case -2014033180://magic_barrier
		{
			u16 lifetime = 20;

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f dirNorm = (targetPos - this.getPosition());
			dirNorm.Normalize();
			Vec2f orbPos = aimpos;	
			if(!isServer()){
				return;
			}
			CBlob@ orb = server_CreateBlob( "magic_barrier" ); 
			if (orb !is null)
			{	
				orb.set_u16("lifetime", lifetime);

				//orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setAngleDegrees(-dirNorm.Angle()+90.0f);
			}
		}
		break;
		
		case 652962395:	//plant_aura
		{			
			u16 lifetime = 10;

			u32 landheight = getLandHeight(aimpos);
			if(landheight != 0)
			{
                if (!isServer()){
				    return;
			    }
				CBlob@ plant = server_CreateBlob( "plant_aura", this.getTeamNum(), Vec2f(aimpos.x , landheight - 8) );
				
				if (plant !is null)
				{
					if( charge_state == 5)//full charge
					{
						lifetime = 15;
					}
					//plant.IgnoreCollisionWhileOverlapped( this );
					plant.set_u16("lifetime", lifetime);
					plant.SetDamageOwnerPlayer( this.getPlayer() );
				}
			}
            else//Can't place this under the map
            {
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
            }
		}
		break;

		case 382419657://rock_wall
		{
			u16 lifetime = 3;

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f dirNorm = (targetPos - this.getPosition());
			dirNorm.Normalize();
			Vec2f orbPos = aimpos;	
			if(!isServer()){
				return;
			}
			CBlob@ orb = server_CreateBlob( "rock_wall" ); 
			if (orb !is null)
			{	
				orb.set_u16("lifetime", lifetime);

				//orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( 255 );
				orb.setPosition( orbPos );
				orb.setAngleDegrees(-dirNorm.Angle()+90.0f);
			}
		}
		break;

		case -1005340482://teleport
		{
			if ( this.get_u16("slowed") > 0 )	//cannot teleport while slowed
			{
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
			}
			else
			{
				ParticleAnimated( "Flash3.png",
								this.getPosition(),
								Vec2f(0,0),
								float(XORRandom(360)),
								1.0f, 
								3, 
								0.0f, true );
				
				Vec2f aimVector = aimpos - this.getPosition();
				Vec2f aimNorm = aimVector;
				aimNorm.Normalize();
				
				for (uint step = 0; step < aimVector.Length(); step += 8)
				{
					teleSparks( this.getPosition() + aimNorm*step, 5, aimNorm*4.0f );
				}
					
				this.setPosition( aimpos );
				this.setVelocity( Vec2f_zero );
				
				ParticleAnimated( "Flash3.png",
								this.getPosition(),
								Vec2f(0,0),
								float(XORRandom(360)),
								1.0f, 
								3, 
								0.0f, true );     
								
				this.getSprite().PlaySound("Teleport.ogg", 0.8f, 1.0f);
			}
		}
		break;

		case -2025350104: //recall_undead
		{
			Vec2f thisPos = this.getPosition();
		
			CPlayer@ thisPlayer = this.getPlayer();
			if ( thisPlayer !is null )
			{		
				CBlob@[] zombies;
				getBlobsByTag("zombie", @zombies);

				for (uint i = 0; i < zombies.length; i++)
				{
					CBlob@ zombie = zombies[i];
					if ( zombie !is null && thisPlayer is zombie.getDamageOwnerPlayer() )
					{
						if ( isClient() )
							ParticleZombieLightning( zombie.getPosition() );
						zombie.setPosition( thisPos );
						zombie.setVelocity( Vec2f(0,0) );
					}
				}
			}
			
			if (!isServer())
			{
				this.getSprite().PlaySound("Summon1.ogg", 1.0f, 1.0f);
				ParticleZombieLightning( thisPos );
			}
		}
		break;

		case 770505718://leech
		{
			Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
		
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "leech", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
                    if(this.hasTag("extra_damage"))
                        orb.Tag("extra_damage");//Remember to change this in Leech.as

					orb.set_Vec2f("aim pos", aimpos);

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
				}
			}
		}
		break;

		case -401411067://lighting
		{
            Vec2f orbPos = this.getPosition() + Vec2f(0.0f,-2.0f);
		
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "lightning", this.getTeamNum(), Vec2f(aimpos.x, 4.0f) ); 
				if (orb !is null)
				{
                    if(this.hasTag("extra_damage"))
                        orb.Tag("extra_damage");//Remember to change this in Lightning.as

					orb.set_Vec2f("aim pos", aimpos);

					orb.SetDamageOwnerPlayer( this.getPlayer() );
				}
			}
		}
		break;

		case -1612772378://force_of_nature
		{
			int castTime = getGameTime();
		
			this.set_Vec2f("spell aim vec", aimpos - this.getPosition());
			
			this.Tag("in spell sequence");
			this.set_u16("FoN cast time", castTime);
			this.Sync("FoN cast time", true);
			
			this.getSprite().PlaySound("forceofnature_start.ogg", 2.0f, 1.0f);
		}
		break;
			
		case 2029285710://zombie_rain
		case 1033042153://skeleton_rain
		case 1761466304://meteor_rain
		case 1137221912://meteor_strike
		case 1057572449://arrow_rain
		{
			if (!isServer())
			{
				return;
			}
			CBitStream params;
			params.write_string(spellName);
			params.write_u8(charge_state);
			params.write_Vec2f(aimpos);

			this.SendCommand(this.getCommandID("rain"), params);
		}
		break;

		case -1911379896://stone_spikes
		{
			if (!isServer())
				return;
			bool isleft = this.isFacingLeft();
			Vec2f tilespace(int(aimpos.x / 8), int(aimpos.y / 8));
			CBlob@ newblob = server_CreateBlob("stone_spike", this.getTeamNum(), (tilespace * 8) + Vec2f(4, 4));
			newblob.set_u8("spikesleft", 8 + charge_state * 1.5 + (charge_state == 5 ? 7 : 0));
			newblob.set_bool("leftdir", isleft);
		}
		break;
			
		default:
		{
			if (spell.type == SpellType::summoning)
			{
				Vec2f pos = aimpos + Vec2f(0.0f,-0.5f*this.getRadius());
				SummonZombie(this, spellName, pos, this.getTeamNum());
			}
			else if ( spellName.getHash() == -2128831035)
			{
				//print("someone just used the blank spell :facepalm:");
			}
			else
			{
				print("spell not found " + spellName +  " with spell hash : " + spellName.getHash()+'' + " in file : spellCommon.as");
			}
		}

	}
}

void SummonZombie(CBlob@ this, string name, Vec2f pos, int team)
{
    ParticleZombieLightning( pos );
    if (isServer())
	{
        CBlob@ summoned = server_CreateBlob( name, team, pos );
		if ( summoned !is null )
		{
			summoned.SetDamageOwnerPlayer( this.getPlayer() );
		}
	}
}

void Heal( CBlob@ blob, f32 healAmount )
{
	f32 health = blob.getHealth();
	f32 initHealth = blob.getInitialHealth();
	
	if ( (health + healAmount) > initHealth )
		blob.server_SetHealth(initHealth);
	else
		blob.server_SetHealth(health + healAmount);
		
    if (blob.isMyPlayer())
    {
        SetScreenFlash( 100, 0, 225, 0 );
    }
		
	blob.getSprite().PlaySound("Heal.ogg", 0.8f, 1.0f + XORRandom(1)/10.0f);
	makeHealParticles(blob);
}

void makeHealParticles(CBlob@ this, const f32 velocity = 1.0f, const int smallparticles = 12, const bool sound = true)
{
	if (isServer()){
		return;	
	}

	//makeSmokeParticle(this, Vec2f(), "Smoke");
	for (int i = 0; i < smallparticles; i++)
	{	
		f32 randomness = (XORRandom(32) + 32)*0.015625f * 0.5f + 0.75f;
		Vec2f vel = getRandomVelocity( -90, velocity * randomness, 360.0f );
		
		const f32 rad = 12.0f;
		Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
		CParticle@ p = ParticleAnimated( "HealParticle.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.0f, false );
		if ( p !is null)
		{
			p.bounce = 0;
    		p.fastcollision = true;
			if ( XORRandom(2) == 0 )
				p.Z = 10.0f;
			else
				p.Z = -10.0f;
		}
	}
}

void Revive( CBlob@ blob )
{			
	int playerId = blob.get_u16( "owner_player" );
	CPlayer@ deadPlayer = getPlayerByNetworkId( playerId );
	
	if( deadPlayer !is null )
	{
		PlayerPrefsInfo@ playerPrefsInfo;
		if ( !deadPlayer.get( "playerPrefsInfo", @playerPrefsInfo ) || playerPrefsInfo is null )
		{
			return;
		}
	
		CBlob @newBlob = server_CreateBlob( playerPrefsInfo.classConfig, deadPlayer.getTeamNum(), blob.getPosition() );		
		if( newBlob !is null )
		{
			f32 health = newBlob.getHealth();
			f32 initHealth = newBlob.getInitialHealth();
	
			newBlob.server_SetPlayer( deadPlayer );
			newBlob.server_SetHealth( initHealth*0.2f );
			
			ManaInfo@ manaInfo;
			if ( newBlob.get( "manaInfo", @manaInfo ) ) 
			{
				manaInfo.mana = 0;
			}			
			
			makeReviveParticles(newBlob);
			
			blob.server_Die();
		}
	}
		
	blob.getSprite().PlaySound("Revive.ogg", 0.8f, 1.0f);
	makeReviveParticles(blob);
}

void UnholyRes( CBlob@ blob )
{			
	int playerId = blob.get_u16( "owner_player" );
	CPlayer@ deadPlayer = getPlayerByNetworkId( playerId );
	
	if( deadPlayer !is null )
	{
		CBlob @newBlob = server_CreateBlob( "wraith", deadPlayer.getTeamNum(), blob.getPosition() );		
		if( newBlob !is null )
		{
			newBlob.server_SetPlayer( deadPlayer );
			
			ManaInfo@ manaInfo;
			if ( newBlob.get( "manaInfo", @manaInfo ) ) 
			{
				manaInfo.mana = 0;
			}			
			
			makeReviveParticles(newBlob);
			
			blob.server_Die();
		}
	}
		
	blob.getSprite().PlaySound("Summon2.ogg", 0.8f, 1.0f);
	ParticleZombieLightning( blob.getPosition() );
}

void makeReviveParticles(CBlob@ this, const f32 velocity = 1.0f, const int smallparticles = 12, const bool sound = true)
{
	if ( !isClient() )
		return;
		
	//makeSmokeParticle(this, Vec2f(), "Smoke");
	for (int i = 0; i < smallparticles; i++)
	{
		f32 randomness = (XORRandom(32) + 32)*0.015625f * 0.5f + 0.75f;
		Vec2f vel = getRandomVelocity( -90, velocity * randomness, 360.0f );
		
		const f32 rad = 12.0f;
		Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
		CParticle@ p = ParticleAnimated( "MissileFire4.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.0f, false );
		if ( p !is null)
		{
			p.bounce = 0;
    		p.fastcollision = true;
			if ( XORRandom(2) == 0 )
				p.Z = 10.0f;
			else
				p.Z = -10.0f;
		}
	}
}

void counterSpell( CBlob@ blob )
{		
	CMap@ map = blob.getMap();
	
	if (map is null)
		return;

	CBlob@[] blobsInRadius;
	if (map.getBlobsInRadius(blob.getPosition(), 64.0f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b !is null)
			{
				bool sameTeam = b.getTeamNum() == blob.getTeamNum();
			
				bool countered = false;
				if ( b.hasTag("counterable") && !sameTeam )
				{
					b.Untag("exploding");
					b.server_Die();
					
					countered = true;
				}
				else if ( b.get_u16("slowed") > 0 && sameTeam )
				{				
					b.set_u16("slowed", 2);
					b.Sync("slowed", true);
					
					countered = true;
				}
				else if ( b.get_u16("hastened") > 0 && !sameTeam )
				{			
					b.set_u16("hastened", 2);
					b.Sync("hastened", true);
					
					countered = true;
				}
				else if ( b.hasTag("zombie") && !sameTeam )
				{					
					if ( b.hasTag("Greg") )
						blob.server_Hit(b, blob.getPosition(), Vec2f(0, 0), 0.25f, Hitters::fire, true);
					else
						blob.server_Hit(b, blob.getPosition(), Vec2f(0, 0), 4.0f, Hitters::fire, true);
					
					countered = true;
				}
				else if(b.hasTag("circle"))
				{
					b.add_u8("despelled",1);
					countered = true;
				}
				
				if ( countered == true )
				{
					if ( isClient() )
					{
						Vec2f bPos = b.getPosition();
						CParticle@ p = ParticleAnimated( "Flash2.png",
										bPos,
										Vec2f(0,0),
										0,
										1.0f, 
										8, 
										0.0f, true ); 	
										
						if ( p !is null)
						{
							p.bounce = 0;
    						p.fastcollision = true;
							p.Z = 600.0f;
						}
					}
				}
			}
		}
	}
	
	if ( isClient() )
	{
		CParticle@ p = ParticleAnimated( "Shockwave2.png",
						blob.getPosition(),
						Vec2f(0,0),
						float(XORRandom(360)),
						1.0f, 
						2, 
						0.0f, true );    
		if ( p !is null)
		{
			p.bounce = 0;
    		p.fastcollision = true;
			p.Z = -10.0f;
		}
		
		blob.getSprite().PlaySound("CounterSpell.ogg", 0.8f, 1.0f);
	}
	
}

void Slow( CBlob@ blob, u16 slowTime )
{	
	if ( blob.get_u16("hastened") > 0 )
	{
		blob.set_u16("hastened", 2);
		blob.Sync("hastened", true);
	}
	else
	{
		blob.set_u16("slowed", slowTime);
		blob.Sync("slowed", true);
		blob.getSprite().PlaySound("SlowOn.ogg", 0.8f, 1.0f + XORRandom(1)/10.0f);
	}
}

void Haste( CBlob@ blob, u16 hasteTime )
{	
	if ( blob.get_u16("slowed") > 0 )
	{
		blob.set_u16("slowed", 2);
		blob.Sync("slowed", true);
	}
	else
	{
		blob.set_u16("hastened", hasteTime);
		blob.Sync("hastened", true);
		blob.getSprite().PlaySound("HasteOn.ogg", 0.8f, 1.0f + XORRandom(1)/10.0f);
	}
}

Random _sprk_r2(12345);
void teleSparks(Vec2f pos, int amount, Vec2f pushVel = Vec2f(0,0))
{
	if ( !isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r2.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r2.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixel( pos, vel + pushVel, SColor( 255, 180+XORRandom(40), 0, 255), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r2.NextRanged(20);
        p.scale = 0.5f + _sprk_r2.NextFloat();
        p.damping = 0.95f;
		p.gravity = Vec2f(0,0);
    }
}

u32 getLandHeight(Vec2f pos)
{
	CMap@ map = getMap();	
	u16 tilesdown = 0;
	
	u32 pos_y = pos.y - pos.y % map.tilesize;//Store the y pos floored to the nearest top of a tile
	while(true)//Loop until stopped inside
	{
		if(map.tilemapheight * map.tilesize < pos_y + tilesdown * map.tilesize)//If we are checking below the map itself
		{
			break;
		}
		if(map.isTileSolid(Vec2f(pos.x, pos_y + map.tilesize * tilesdown)))//if this current point has a solid tile
		{
			return(pos_y + tilesdown * map.tilesize);//The current blobs pos plus one or more tiles down
		}
		tilesdown += 1;
	}
	return 0;
}