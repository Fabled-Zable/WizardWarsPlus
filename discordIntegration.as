
void onInit(CRules@ this)
{
    this.addCommandID('addToChat');
}


bool onServerProcessChat( CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player )
{

    string toDiscord = sanitize(textIn);
    string username = sanitize(player.getCharacterName());

    tcpr('discordData {"dataType":"chat","content":"' +toDiscord+ '", "username":"'+username+'"}');

    return true;
}



void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
    if(this.getCommandID("addToChat") == cmd)
    {
        client_AddToChat(params.read_string(), SColor(255,255,0,255));
    }
}

void onPlayerDie( CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData )
{
    bool attNull = attacker is null;
    string victimName = victim.getCharacterName();


    tcpr('discordData {"dataType":"playerdie","victim":"'+sanitize(victim.getCharacterName())+'","attacker":"'+ (attNull ? ' ' : sanitize(attacker.getCharacterName())) + '","lastVicBlob":"' +  victim.lastBlobName + '","lastAttBlob":"' + (attNull ? ' ' : attacker.lastBlobName) + '", "attackerNull":' + attNull + '}');
}

void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
    tcpr('discordData {"dataType":"playerjoin","username":"' + sanitize(player.getCharacterName()) + '"}');
}

void onPlayerLeave( CRules@ this, CPlayer@ player ){
    tcpr('discordData {"dataType":"playerleave","username":"' + sanitize(player.getCharacterName()) + '"}');
}

string sanitize(string input){
    return input.replace("\\","\\\\").replace('"','\\"').replace('`','\\`');
}