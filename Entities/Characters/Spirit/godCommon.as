interface IEffectMode
{
	void onTick();
	void init(CBlob@ blob);
	void render(CSprite@ sprite,f32 scale);
	void processCommand(u8 cmd, CBitStream @params);
}

class Force : IEffectMode
{
	CBlob@ blob;

	bool _push = false;
	bool push
	{
		get{return _push;}
		set
		{
			CBitStream params;
			params.write_bool(value);
			blob.SendCommand(blob.getCommandID("Ppush"),params);
		}
	}
	bool _effectPlayers = true;
	bool effectPlayers
	{
		get{return _effectPlayers;}
		set
		{
			CBitStream params;
			params.write_bool(value);
			blob.SendCommand(blob.getCommandID("PeffectPlayers"),params);
		}
	}

	CParticle@[] particles;
	bool particleFlipFlop = true;

	void init(CBlob@ blob)
	{
		@this.blob = blob;
		this.blob.addCommandID("Ppush");
		this.blob.addCommandID("PeffectPlayers");
	}

	void onTick()
	{
		f32 effectRadius = blob.get_f32("effectRadius");

		if(blob.isKeyPressed(key_action1))
		{
			CBlob@[] blobs;
			CMap@ map = getMap();
			map.getBlobsInRadius(blob.getAimPos(),effectRadius,@blobs);
			for(int i = 0; i < blobs.length(); i++)
			{
				CBlob@ cblob = blobs[i];
				if(cblob.getPlayer() !is null && !effectPlayers) {continue;}

				Vec2f pos = cblob.getPosition();
				Vec2f aimPos = blob.getAimPos();
				Vec2f norm = pos - aimPos;
				norm.Normalize();

				cblob.setVelocity(cblob.getVelocity() + norm * (push ? 1 : -1));
			}

			//particles :D
			//made with Vamist's Force of Nature particles as reference so I guess I should credit that
			for(int i = 0; i < 3; i++)
			{
				particleFlipFlop = !particleFlipFlop;
				CParticle@ p = ParticlePixelUnlimited(-getRandomVelocity(0,effectRadius,360) + blob.getAimPos(), Vec2f(0,0), particleFlipFlop ? SColor(255,153,132,212) : SColor(255,97,97,255),true);
				if(p !is null)
				{
					p.fastcollision = true;
					p.gravity = Vec2f(0,0);
					p.bounce = 1;
					p.lighting = false;
					p.timeout = 30;

					particles.push_back(p);
				}
			}
			for(int a = 0; a < particles.length(); a++)
			{
				CParticle@ particle = particles[a];
				//check
				if(particle.timeout < 1)
				{
					particles.erase(a);
					a--;
					continue;
				}

				//Gravity
				Vec2f tempGrav = Vec2f(0,0);
				tempGrav.x = particle.position.x - blob.getAimPos().x;
				tempGrav.y = particle.position.y - blob.getAimPos().y;

				tempGrav *= push ? 1 : -1;


				//Colour
				// SColor col = particle.colour;
				// col.setGreen(col.getGreen() - 1);
				// col.setBlue(col.getBlue() + 1);

				//set stuff
				// particle.colour = col;
				// particle.forcecolor = col;
				particle.gravity = tempGrav / 50;//tweak the 20 till your heart is content

				//particleList[a] = @particle;

			}
		}
		if(blob.getPlayer() !is null && getLocalPlayer() is blob.getPlayer())
		{
			CControls@ controls = getControls();
			if(controls.isKeyJustPressed(KEY_KEY_P))
			{
				push = !push;
			}
			if(controls.isKeyJustPressed(KEY_KEY_O))
			{
				effectPlayers = !effectPlayers;
			}
		}
	}

	void processCommand(u8 cmd, CBitStream @params)
	{
		if(cmd == blob.getCommandID("Ppush"))
		{
			this._push = params.read_bool();
		}
		else if(cmd == blob.getCommandID("PeffectPlayers"))
		{
			this._effectPlayers = params.read_bool();
		}
	}

	void render(CSprite@ sprite, f32 scale)
    {
        
    }
}