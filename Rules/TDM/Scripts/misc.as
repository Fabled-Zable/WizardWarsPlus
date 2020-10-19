void onInit(CRules@ this)
{
    this.addCommandID("setPlayerAdminMode");
}

void onTick(CRules@ this)
{
    CPlayer@ p = getLocalPlayer();
    if(p is null){return;}
    CBlob@ b = p.getBlob();
    if(p.isLocal() && p.isMod() && (b is null || (b.getConfig() != "pixie")))
    {
        //CControls@ c = getControls();
        //if(c.isKeyPressed(KEY_LSHIFT) && c.isKeyPressed(KEY_LCONTROL) && c.isKeyJustPressed(KEY_KEY_A))
        //{
        //    CBitStream params;
        //    params.write_u16(p.getNetworkID());
        //   this.SendCommand(this.getCommandID("setPlayerAdminMode"),params,false);//false tells server to not send to client
        //}
    }
}

void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
    if(cmd == this.getCommandID("setPlayerAdminMode"))
    {
        if(isServer())
        {
            CPlayer@ p = getPlayerByNetworkId(params.read_u16());
            if(p is null) {return;}
            CBlob@ b = p.getBlob();
            if(b is null)
            {
                server_CreateBlob("pixie",3,Vec2f(getMap().tilemapwidth*4,0)).server_SetPlayer(p);
            }
            else
            {
                server_CreateBlob("pixie",b.getTeamNum(),b.getPosition()).server_SetPlayer(p);
                b.server_Die();
            }
        }
    }
}