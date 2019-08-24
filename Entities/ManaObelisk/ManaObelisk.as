//Mana Obelisk code
#include "MagicCommon.as";

const s16 MAX_MANA = 60;
const s16 MANA_REGEN_RATE = 1;
const s16 MANA_GIVE_RATE = 10;

const u16 REGEN_COOLDOWN_SECS = 10;

void onInit( CBlob@ this )
{
	this.Tag("mana obelisk");
	this.getSprite().SetZ(-100.0f);
	
	this.getShape().SetStatic(true);
	
	this.set_s16("mana", MAX_MANA);
	this.set_s16("regen cooldown", 0);
	
	this.addCommandID("sync mana");
}

void onTick( CBlob@ this )
{
	int ticksPerSec = getTicksASecond();

	// regen mana of wizards touching
	if (getGameTime() % ticksPerSec == 0)
	{
		if (getNet().isServer())
		{
			SyncMana( this );
		}
		
		s16 currRegenCooldown = this.get_s16("regen cooldown");
		if ( currRegenCooldown > 0 )
			currRegenCooldown -= ticksPerSec;

		s16 storedMana = this.get_s16("mana");
	
		bool hasGivenManaThisFrame = false;		//to prevent multiple wizards from draining mana and causing bugs
		
		const uint count = this.getTouchingCount();
		for (uint step = 0; step < count; ++step)
		{
			if ( hasGivenManaThisFrame == true )
				break;
				
			CBlob@ touchBlob = this.getTouchingByIndex(step);
			if ( touchBlob !is null )
			{
				ManaInfo@ manaInfo;
				if ( touchBlob.get("manaInfo", @manaInfo) && !touchBlob.hasTag("dead") )
				{
					s32 wizMana = manaInfo.mana;
					s32 wizMaxMana = manaInfo.maxMana;
					if ( storedMana >= MANA_GIVE_RATE && wizMana < (wizMaxMana-MANA_GIVE_RATE) )
					{
						storedMana -= MANA_GIVE_RATE;
						manaInfo.mana = wizMana + MANA_GIVE_RATE;
						
						touchBlob.getSprite().PlaySound("ManaGain.ogg", 1.0f, 1.0f + XORRandom(2)/10.0f);
						
						if ( storedMana < MANA_GIVE_RATE )
							touchBlob.getSprite().PlaySound("ManaEmpty.ogg", 0.5f, 1.0f + XORRandom(2)/10.0f);
							
						hasGivenManaThisFrame = true;
						
						currRegenCooldown = REGEN_COOLDOWN_SECS*ticksPerSec;
					}
				}				
			}
		}
		
		if ( storedMana < MAX_MANA && currRegenCooldown <= 0 )
			storedMana += MANA_REGEN_RATE;
		
		if ( getNet().isServer() )		
			this.set_s16("mana", storedMana);	
		
		this.set_s16( "regen cooldown", Maths::Max(currRegenCooldown, 0) );
	}
}

void SyncMana( CBlob@ this )
{
	s16 mana = this.get_s16("mana");
	CBitStream bt;
	bt.write_s16( mana );	
	this.SendCommand( this.getCommandID("sync mana"), bt );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if( cmd == this.getCommandID("sync mana") )
    {
		if ( getNet().isServer() )
		{
			s16 mana;	
			mana = params.read_s16();	
			this.set_s16("mana", mana);
		}
		this.Sync("mana", true);
	}
}

void onTick( CSprite@ this )
{
	f32 storedMana = this.getBlob().get_s16("mana");
	//print("obelisk mana: " + storedMana);
	u16 numFrames = 9;
	
	f32 manaFraction = storedMana/MAX_MANA;
	u16 currentFrame = manaFraction*(numFrames-1);
	this.SetFrame(currentFrame);
}