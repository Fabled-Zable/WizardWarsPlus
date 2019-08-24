
void onInit(CRules@ this)
{
    this.addCommandID('addToChat');
}


bool onServerProcessChat( CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player )
{

    string toDiscord = textIn.replace('\\','\\\\').replace('"','\\"');

    tcpr('discordMessage {"guildID":593227081169502219,"channelID":593227433260613641,"content":"' +toDiscord+ '"}');


    return true;
}



void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
    print("here");

    print(cmd + " " + this.getCommandID("addToChat"));
    if(this.getCommandID("addToChat") == (!isServer() ? cmd + 2 : cmd))
    {
        client_AddToChat(params.read_string(), SColor(255,255,0,255));
    }
}