
void onInit(CRules@ this)
{
    this.addCommandID('addToChat');
}


bool onServerProcessChat( CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player )
{

    string toDiscord = textIn.replace('\\','\\\\').replace('"','\\"');
    string username = player.getCharacterName();

    tcpr('discordMessage {"guildID":"593227081169502219","channelID":"593227433260613641","content":"' +toDiscord+ '", "username":"'+username+'"}');


    return true;
}



void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
    if(this.getCommandID("addToChat") == (!isServer() ? cmd + 2 : cmd))
    {
        client_AddToChat(params.read_string(), SColor(255,255,0,255));
    }
}