



bool onServerProcessChat( CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player )
{

    string toDiscord = textIn.replace('\\','\\\\').replace('"','\\"');

    tcpr('discordMessage {"guildID":593227081169502219,"channelID":593227433260613641,"content":"' +toDiscord+ '"}');


    return true;
}