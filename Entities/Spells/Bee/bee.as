#include "SpellCommon.as";

const f32 radius = 8*10;

void onInit(CBlob@ this){
    this.Tag('counterable');
    this.getShape().SetGravityScale(0);
    this.set_u8("speed",3);
    this.set_f32("targetAngle",0);
    this.set_f32("heal_ammount",0.1);
    //this.set_netid("caster",0);
    if(!isServer()){return;}
    this.server_SetTimeToDie(5);
}

void onTick(CBlob@ this){

    CBlob@[] blobs;
    getMap().getBlobsInRadius(this.getPosition(),radius,@blobs);

    CPlayer@ damageOwnerPlayer = this.getDamageOwnerPlayer();


    int index = closestBlobIndex(this,blobs,this.getDamageOwnerPlayer());
    if(index == -1) return;

    CBlob@ target = blobs[index];

    if(this.getTickSinceCreated() >= 15)//wait a bit before homing
    {
        Vec2f thisPos = this.getPosition();
        Vec2f targetPos = target.getPosition();
        Vec2f norm = targetPos - thisPos;
        norm.Normalize();

        Vec2f newVelocity = this.getVelocity() + norm;
        newVelocity.Normalize(); 
        this.setVelocity(newVelocity * this.get_u8("speed"));
    }

    if(this.getDistanceTo(target) <= 8)
    {
        if(target.getTeamNum() == this.getTeamNum())
        {
            Heal(target,this.get_f32("heal_amount"));
            this.server_Die();
        }
        else{
            target.server_Hit(target,this.getPosition(), Vec2f_zero,0.3,41);
            this.server_Die();
        }
    }
}

void onTick(CSprite@ this){
    this.ResetTransform();
    this.RotateBy(this.getBlob().getVelocity().getAngle() * -1,Vec2f_zero);
}

int closestBlobIndex(CBlob@ this, CBlob@[] blobs, CPlayer@ caster)
{
    f32 bestDistance = 99999999;
    int bestIndex = -1;

    for(int i = 0; i < blobs.length; i++){
        if((this.getTeamNum() == blobs[i].getTeamNum() && blobs[i].getHealth() == blobs[i].getInitialHealth()) || (caster !is null && blobs[i] is caster.getBlob()) || blobs[i].getPlayer() is null){
            continue;
        }
        f32 dist = this.getDistanceTo(blobs[i]);
        if(bestDistance > dist)
        {
            bestDistance = dist;
            bestIndex = i;
        }
    }
    return bestIndex;
}

// Vec2f lerp(Vec2f start,Vec2f end, f32 percent){
//     Vec2f x = end - start;
//     x *= percent;
//     x += start;
//     return x;
// }