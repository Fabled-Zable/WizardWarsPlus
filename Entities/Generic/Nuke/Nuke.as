// Nuke logic
#include "Hitters.as";

void onInit( CBlob@ this )
{
    this.set_f32("explosive_radius", 1000.0f);
    this.set_f32("explosive_damage",20.0f);
    this.set_u8("custom_hitter", Hitters::keg);
    this.set_string("custom_explosion_sound", "FireBlast8.ogg");
    this.set_f32("map_damage_radius", 200.0f);
    this.set_f32("map_damage_ratio", 1.0f);
    this.set_bool("map_damage_raycast", false);
	this.set_bool("explosive_teamkill", true);
	this.set_f32("keg_time", 500.0f);  // 180.0f
    this.Tag("medium weight");
	this.Tag("nuke");
    
    CSpriteLayer@ fuse = this.getSprite().addSpriteLayer( "fuse", "Nuke.png" , 16, 16, 0, 0 );

	if (fuse !is null)
	{
		fuse.addAnimation("default",0,false);
		int[] frames = {8,9,10,11,12,13};
		fuse.animation.AddFrames(frames);
		fuse.SetOffset(Vec2f(3,-4));
	}

	//this.getCurrentScript().runFlags |= Script::remove_after_this;
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return true; 
}

void onTick( CBlob@ this )
{
    CSprite@ thisSprite = this.getSprite();
    
    thisSprite.animation.frame = (thisSprite.animation.getFramesCount()) * (1.0f - (this.getHealth() / this.getInitialHealth()));
    
    s32 timer = this.get_s32("explosion_timer") - getGameTime();
	
	if (timer < 0) {
        return;
    }	
    
    CSpriteLayer@ fuse = thisSprite.getSpriteLayer( "fuse" );
    
    if (fuse !is null)
    {
		fuse.animation.frame = 1 + (fuse.animation.getFramesCount() - 1) * (1.0f - ((timer + 5) / f32(this.get_f32("keg_time"))));
	}
    
}