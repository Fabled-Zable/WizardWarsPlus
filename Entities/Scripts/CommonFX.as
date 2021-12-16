Random _sprk_r2(12432);
void makeManaDrainParticles( Vec2f pPos, int amount )
{
	if ( !isClient() )
	return;
	
	for (int i = 0; i < amount; i++)
    {
        Vec2f pVel(_sprk_r2.NextFloat() * 7.0f, 0);
        pVel.RotateBy(_sprk_r2.NextFloat() * 360.0f);
		
		CParticle@ p = ParticlePixelUnlimited(pPos, pVel, SColor( 255, 120+XORRandom(40), 0, 255), true);
        if(p !is null)
        {
            p.collides = false;
            p.gravity = Vec2f_zero;
            p.bounce = 0;
            p.Z = 200;
            p.timeout = 10 + _sprk_r2.NextRanged(30);
			p.scale = 1.0f + _sprk_r2.NextFloat();
			p.damping = 0.8f;
        }
    }
}

void makeHullHitSparks( Vec2f pPos, int amount )
{
	if ( !isClient() )
	return;
	
	for (int i = 0; i < amount; i++)
    {
        Vec2f pVel(_sprk_r2.NextFloat() * 7.0f, 0);
        pVel.RotateBy(_sprk_r2.NextFloat() * 360.0f);

		u8 alpha = 255;
		u8 red = 200.0f + (50.0f * _sprk_r2.NextFloat());
		u8 green = 200.0f + (50.0f * _sprk_r2.NextFloat());
		u8 blue = 80.0f * _sprk_r2.NextFloat();

		SColor color = SColor(alpha, red, green, blue);
		
		CParticle@ p = ParticlePixelUnlimited(pPos, pVel, color, true);
        if(p !is null)
        {
            p.collides = false;
            p.gravity = Vec2f_zero;
            p.bounce = 0;
            p.Z = 200;
            p.timeout = 3.0f + (3.0f * _sprk_r2.NextFloat());
			p.damping = 0.8f;
        }
    }
}

SColor getTeamColorWW( int teamNum = -1, SColor color = SColor(255, 255, 0, 0) )
{
    switch (teamNum)
		{
			case 0: //blue
			{	
				color = SColor(255, 30, 30, 255);
			}
			break;

			case 1: //red
			{	
				color = SColor(255, 255, 0, 0);
			}
			break;
			case 2: //green
			{	
				color = SColor(255, 0, 200, 0);
			}
			break;
            case 3: //violet
			{	
				color = SColor(255, 255, 0, 255);
			}
			break;

			default:
			{	
				color = SColor(255, 255, 255, 255);
			}
		}
    
    return color;
}