void MakeDustParticle(Vec2f pos, string file, float zPos = 0.0 )
{
	if (isServer())
		return;

    CParticle@ temp = ParticleAnimated( CFileMatcher(file).getFirst(), pos - Vec2f(0,8), Vec2f(0,0), 0.0f, 1.0f, 3, 0.0f, false );
	
    if (temp !is null)
    {
        temp.width = 8;
        temp.height = 8;
		    temp.Z = zPos;
        temp.bounce = 0;
    	  temp.fastcollision = true;
    }
}

void MakeParticle(Vec2f pos, string file, float zPos = 0.0, Vec2f direction = Vec2f(1, 0) )
{
	if (isServer())
		return;

    CParticle@ temp = ParticleAnimated( CFileMatcher(file).getFirst(), pos, Vec2f(0,0), 0.0f, 1.0f, 3, 0.0f, false );
	
    if (temp !is null)
    {
        temp.width = 8;
        temp.height = 8;
		temp.Z = zPos;
		temp.rotates = true;
		temp.rotation = direction;
    	temp.fastcollision = true;
    }
}
