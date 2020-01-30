#include "godCommon.as"//

void onInit(CBlob@ this)
{
    this.set_f32("effectRadius", 8*5); //5 block radius
	Force mode;
    mode.init(this);
	this.set("mode",@mode);


}

void onTick(CBlob@ this)
{
    IEffectMode@ mode;
	this.get("mode",@mode);
	mode.onTick();

    CShape@ shape = this.getShape();
    shape.SetGravityScale(this.get_bool("gravity") ? 1 : 0);
    shape.getConsts().mapCollisions = !this.get_bool("noclip");
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    IEffectMode@ mode;
	this.get("mode",@mode);

    mode.processCommand(cmd, params);
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}