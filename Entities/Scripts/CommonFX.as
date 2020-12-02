Random _sprk_r2(12432);
void makeManaDrainParticles( Vec2f pos, int amount )
{
	if ( !isClient() )
	return;
	
	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r2.NextFloat() * 7.0f, 0);
        vel.RotateBy(_sprk_r2.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixel( pos, vel, SColor( 255, 120+XORRandom(40), 0, 255), true );
        if(p is null) return; //bail if we stop getting particles

        p.timeout = 10 + _sprk_r2.NextRanged(30);
        p.scale = 1.0f + _sprk_r2.NextFloat();
        p.damping = 0.8f;
    	p.fastcollision = true;
		p.gravity = Vec2f(0,0);
		p.Z = 200;
    }
}