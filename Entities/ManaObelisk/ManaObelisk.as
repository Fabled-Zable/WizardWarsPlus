//Mana Obelisk code
#include "MagicCommon.as";

const s16 MAX_MANA = 60;
const s16 MANA_REGEN_RATE = 1;
const s16 MANA_GIVE_RATE = 5;

const u16 REGEN_COOLDOWN_SECS = 10;

void onInit( CBlob@ this )
{
	this.Tag("mana obelisk");
	this.getSprite().SetZ(-100.0f);
	
	this.getShape().SetStatic(true);
	
	this.set_s16("mana", MAX_MANA);
	this.set_s16("regen cooldown", 0);
	
	this.addCommandID("sync mana");
	this.addCommandID("recover mana");
}

void onTick( CBlob@ this )
{
	if (!isServer())
	{ return; }
	int ticksPerSec = getTicksASecond();

	// regen mana of wizards touching
	if (getGameTime() + this.getNetworkID() % ticksPerSec == 0)
	{
		CBitStream params;
		s16 curMana = this.get_s16("mana");

		bool foundTargets = false;
		const uint count = this.getTouchingCount();
		for (uint i = 0; i < count; i++)
		{
			if (curMana <= 0) //mana reduces per loop. Stop if ran out
			{ break; }

			CBlob@ b = this.getTouchingByIndex(i);
			if (b is null)
			{ continue; }

			ManaInfo@ manaInfo;
			if (b.hasTag("dead") || !b.get( "manaInfo", @manaInfo )) 
			{ return; }

			s32 targetMana = manaInfo.mana;
			s32 targetMaxMana = manaInfo.maxMana;
			if (targetMana >= targetMaxMana)
			{ continue; }

			s32 availableMana = curMana > MANA_GIVE_RATE ? MANA_GIVE_RATE : curMana;
			s32 targetManaSpace = targetMaxMana - targetMana;
			
			s32 givenMana = availableMana <= targetManaSpace ? availableMana : targetManaSpace;
			curMana -= givenMana;
			
			params.write_s16(givenMana);
			params.write_u16(b.getNetworkID()); //target ID
			foundTargets = true;
		}

		if (foundTargets)
		{
			this.SendCommand(this.getCommandID("sync mana"), params);
		}
		else
		{
			this.SendCommand(this.getCommandID("recover mana"));
		}
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("sync mana"))
	{
		u16 toBlobID;
		s16 manaAmount;

		s16 curMana = this.get_s16("mana");

		while (params.saferead_u16(toBlobID) && params.saferead_s16(manaAmount)) //immediately stops if something fails
		{
			CBlob@ toBlob = getBlobByNetworkID(toBlobID);
			if (toBlob == null || toBlob.hasTag("dead"))
			{ continue; }

			ManaInfo@ manaInfo;
			if (!toBlob.get( "manaInfo", @manaInfo )) 
			{ continue; }

			manaInfo.mana += manaAmount;
			if (manaInfo.mana > manaInfo.maxMana)
			{
				manaInfo.mana = manaInfo.maxMana;
			}

			curMana -= manaAmount;

			if (isClient())
			{
				toBlob.getSprite().PlaySound("ManaGain.ogg", 1.0f, 1.0f + XORRandom(2)/10.0f);
			}
			
			if (curMana <= 0)
			{
				curMana = 0;
				break;
			}
		}
		this.set_s16("mana", curMana);
		this.Sync("mana", true);
	}
	else if (cmd == this.getCommandID("recover mana"))
	{
		s16 curMana = this.get_s16("mana");
		s16 newMana = curMana + MANA_REGEN_RATE;
		curMana = newMana <= MAX_MANA ? newMana : MAX_MANA;
		this.set_s16("mana", curMana);
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