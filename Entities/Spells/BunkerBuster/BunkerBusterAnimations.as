void onInit(CSprite@ this)
{
    CBlob@ b = this.getBlob();
    CParticle@[] particles;
    b.set("particles",@b);
}

void onTick(CSprite@ this)
{
    CBlob@ b = this.getBlob();
    CParticle@ p = ParticlePixelUnlimited(b.getPosition() + getRandomVelocity(0, XORRandom(8) + 4, 360), b.getVelocity(), SColor(255,10,5,5), true);
    if(p !is null)
    {
        p.collides = false;
        p.gravity = Vec2f(0,0);
        p.bounce = 1;
        p.lighting = false;
        p.timeout = 60;

        CParticle@[] particles;
        b.get("particles",particles);

        particles.push_back(p);

        CBlob@[] bariers;
        getBlobsByTag("barrier",@bariers);

        for(int i = 0; i < particles.length(); i++)
        {
            CParticle@ particle = particles[i];
            if(particle.timeout <= 0)
            {
                particles.erase(i);
                i--;
            }
            SColor color = particle.colour;
            color.setRed(XORRandom(50));
            color.setGreen(XORRandom(50));
            color.setBlue(XORRandom(10));
            particle.colour = color;
            particle.forcecolor = color;
        }
    }
}