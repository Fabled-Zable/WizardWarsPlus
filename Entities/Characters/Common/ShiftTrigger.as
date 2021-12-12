#include "EntropistCommon.as"
#include "SpellCommon.as"

void onInit( CBlob@ this )
{
    this.addCommandID("shiftpress");
    this.addCommandID("negentropy");
}

void onTick( CBlob@ this )
{
    if (!this.isMyPlayer()) { return; }

    CControls@ controls = getControls();
    CBitStream params;

    //EntropistInfo@ entropist;

    if (controls.isKeyPressed(KEY_LSHIFT))
    {
        if(!this.get_bool("shifting"))
        {
            params.write_bool(true);
            /*
            if (this.get( "entropistInfo", @entropist )) 
	        {
		        if(entropist.pulse_amount > 0)
		        {
                    entropist.pulse_amount -= 1;
                    this.SendCommand(this.getCommandID("negentropy"), params);
                }
	        }
            */
            this.SendCommand(this.getCommandID("shiftpress"), params);
            this.set_bool("shifting", true);
        }
    }
    else
    {
        if(this.get_bool("shifting"))
        {
            params.write_bool(false);
            this.SendCommand(this.getCommandID("shiftpress"), params);
            this.set_bool("shifting", false);
        }
    }
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("shiftpress"))
    {
        if(params.read_bool())
        {
            this.set_bool("shifting", true);
        }
        else
        {
            this.set_bool("shifting", false);
        }
    }
    /*
    if (cmd == this.getCommandID("negentropy"))
    {
        CastNegentropy(this);
    }
    */
}