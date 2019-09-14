
void onInit(CBlob@ this)
{
    CShape@ shape = this.getShape();
    shape.SetGravityScale(0);
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}