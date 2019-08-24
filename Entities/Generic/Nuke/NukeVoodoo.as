//#include "ThrowCommon.as";

void onInit( CBlob@ this )
{
	this.getShape().SetRotationsAllowed(true);
	this.getShape().getVars().waterDragScale = 8.0f;
	this.getShape().getConsts().collideWhenAttached = true;
	AttachmentPoint@ att = this.getAttachments().getAttachmentPointByName("PICKUP");
	att.SetKeysToTake( key_action1 );
	att.SetMouseTaken( false );
	this.set_f32("explosive_radius",200.0f);
	this.set_f32("explosive_damage",20.0f);
	this.set_string("custom_explosion_sound", "FireBlast8.ogg");
	this.set_f32("map_damage_radius", 200.0f);
	this.set_f32("map_damage_ratio", 1.0f);
	this.set_bool("map_damage_raycast", true);
	this.set_f32("keg_time", 800.0f);
	this.set_bool("explosive_teamkill", true);

	this.getCurrentScript().tickFrequency = 10;
	this.getCurrentScript().tickIfTag = "exploding";
}

void onTick( CBlob@ this )
{
   // if (this.hasTag("exploding"))
    {
        s32 timer = this.get_s32("explosion_timer") - getGameTime();

        if (timer <= 0)
        {
			Boom( this );
        }
        else
        {
            SColor lightColor = SColor( 255, 255, Maths::Min(255, uint(timer * 0.7)), 0);
            this.SetLightColor( lightColor );

            if (XORRandom(2) == 0)
            {
                sparks( this.getPosition(), this.getAngleDegrees(), 1.5f+(XORRandom(10)/5.0f), lightColor );
            }

			if (timer < 90)
			{
				f32 speed = 1.0f + (90.0f - f32(timer))/90.0f;
				this.getSprite().SetEmitSoundSpeed( speed );
				this.getSprite().SetEmitSoundVolume( speed );
			}
        }
    }
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{

    if (cmd == this.getCommandID("activate"))
    {
        this.Tag("activated");
        this.set_s32("explosion_timer", getGameTime() + this.get_f32("keg_time"));
        this.Tag("exploding");
        this.SetLight( true );
        this.SetLightRadius( this.get_f32("explosive_radius")*0.5f );
        this.getSprite().SetEmitSound( "/Sparkle.ogg" );
		this.getSprite().SetEmitSoundPaused( false );
		Sound::Play("NukeSiren.ogg");
    }
}

void Boom( CBlob@ this )
{
	ParticleAnimated( "Nuclear.png",
		this.getPosition()-Vec2f(0,50),
		Vec2f(0.0,0.0f),
		1.0f, 1.0f, 
		3, 
		0.0f, true );
	SetScreenFlash( 200, 255, 255, 100 );
	ShakeScreen( 1000, 100, this.getPosition() );
	Sound::Play("Explosion04.ogg");
		
    this.server_SetHealth(-1.0f);
    this.server_Die();
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	Vec2f dir = velocity;
    dir.Normalize();
    this.AddForce( dir * 30 );
    return damage;
}

void onDie( CBlob@ this )
{
    this.getSprite().SetEmitSoundPaused( true );
}

void sparks(Vec2f at, f32 angle, f32 speed, SColor color )
{
    Vec2f vel = getRandomVelocity(angle+90.0f, speed, 45.0f);
    at.y -= 3.0f;
    ParticlePixel( at, vel, color, true, 119 );
}

// run the tick so we explode in inventory
void onThisAddToInventory( CBlob@ this, CBlob@ inventoryBlob )
{
    if (this.hasTag("exploding")) {
        this.doTickScripts = true;
    }
}
