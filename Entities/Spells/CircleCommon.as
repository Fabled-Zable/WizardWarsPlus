void onInit(CBlob@ this)
{
    this.getShape().SetGravityScale(0);
    this.set_u8("despelled",0);
    this.set_s32("aliveTime",10);
    this.Tag("circle");
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}

void onTick(CBlob@ this)
{
    if(this.getTickSinceCreated() > this.get_s32("aliveTime") || this.get_u8("despelled") >= 2)
        this.Tag("reverse");
    
}


