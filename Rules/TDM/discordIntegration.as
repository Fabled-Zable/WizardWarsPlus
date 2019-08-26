
void onInit(CRules@ this)
{
    this.addCommandID('addToChat');
}


bool onServerProcessChat( CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player )
{

    string toDiscord = textIn;
    string username = player.getCharacterName();

    tcpr('discordMessage {"dataType":"chat","content":"' +toDiscord+ '", "username":"'+username+'"}');

    return true;
}



void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
    if(this.getCommandID("addToChat") == (!isServer() ? cmd + 2 : cmd))
    {
        client_AddToChat(params.read_string(), SColor(255,255,0,255));
    }
}