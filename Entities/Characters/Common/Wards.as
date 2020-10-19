#include "Hitters.as"

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    if(this.hasTag("dead") || customData == Hitters::burn || customData == Hitters::fall)
    {
        return damage; //burn and fall damage doesn't trigger anything, proceed as if this script doesn't exist.
    }
/*
    if(customData == Hitters::fall)
    {
        if(this.get_u16("stoneSkin") > 0)
        {return damage*3;} //returns triple damage, skips rest of script
        else
        {return damage;} //normal damage, also skips script
    }
    else
    {
        if(this.get_u16("stoneSkin") > 0)
        {damage /= 2;} //halves damage, doesn't skip rest of code
        if(this.get_u16("airblastShield") < 1)
        {return damage;}
    }
*/

    Vec2f thisPos = this.getPosition();

	this.getSprite().PlaySound("Airblast.ogg", 1.0f, 1.0f + XORRandom(1)/10.0f); //produces airblast sound
    if (isClient()) //placeholder particle
	{
		CParticle@ p = ParticleAnimated( "small_boom.png", thisPos, Vec2f_zero, XORRandom(361), 2.0f, 1, 0.0f, true );
		if(p !is null)
		{
			p.Z = 1.0f;
			p.bounce = 0.0f;
    		p.fastcollision = true;
			p.gravity = Vec2f_zero;
		}
	}

    CMap@ map = getMap();
    CBlob@[] reachedBlobs;
    u16 radius = 5; //radius in blocks
    map.getBlobsInRadius(thisPos, radius*8, reachedBlobs);
    
    for(int i = 0; i < reachedBlobs.length; i++)
	{
        CBlob@ blob = reachedBlobs[i];
        if (blob is null)
	    {continue;}
        if (blob is this)
        {continue;}
        if(blob.get_u16("stoneSkin") > 0) // stone skin knockback nullifier
	    {continue;}
	
        if (blob.getTeamNum() != this.getTeamNum()) //applies force outwards to all enemy blobs
        {
            Vec2f forceDir = blob.getPosition() - thisPos;
            float dist = forceDir.getLength();
            forceDir.Normalize();
            if(dist < 1)
            {dist = 1;}
            forceDir *= 10000/dist;
            blob.AddForce(forceDir);
        }
    }

    return damage;
}
