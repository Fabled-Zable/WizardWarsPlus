

void onInit(CBlob@ this)
{
    this.set_s32("aliveTime",300);
    this.set_s32("nextSpore",getGameTime());
    this.Tag("counterable");
}

void onTick(CBlob@ this)
{

    if(this.getTickSinceCreated() > this.get_s32("aliveTime"))
    {
        this.server_Die();
    }

    if(getGameTime() >= this.get_s32("nextSpore"))
    {
        createSporeshot(this);
        this.set_s32("nextSpore",getGameTime() + 150/2);
    }

}

CBlob@ createSporeshot(CBlob@ this)
{
    if(!isServer()) return null;
    CBlob@ spore = server_CreateBlob("sporeshot",this.getTeamNum(),this.getPosition() + Vec2f(0,-8));
    spore.setVelocity(getRandomVelocity(180,1,180));
    spore.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());

    return spore;
}




void onInit(CShape@ this)
{
    this.SetStatic(true);
    this.getConsts().collidable = false;
}

void onInit(CSprite@ this)
{
    this.ScaleBy(Vec2f(0.75,0.75));
    this.getBlob().set_s32("frame",0);
}

void onTick(CSprite@ this)
{
    if(getGameTime() % 3 == 0)
        this.getBlob().add_s32("frame",1);
    this.SetFrame(this.getBlob().get_s32("frame")%5);
    this.SetOffset(Vec2f(0,-6));
    
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob ){
    return false;
}