
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
        client_AddToChat(params.read_string(), SColor(255,120,138,235));
    }
}

void onPlayerDie( CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData )
{
    if(!isServer()){return;}
    bool attNull = attacker is null;
    string victimName = victim.getCharacterName();
    int team = victim.getTeamNum();


    tcpr('discordData {"dataType":"playerdie","victim":"'+sanitize(victim.getCharacterName())+'","team":'+team+', "attacker":"'+ (attNull ? ' ' : sanitize(attacker.getCharacterName())) + '","lastVicBlob":"' +  victim.lastBlobName + '","lastAttBlob":"' + (attNull ? ' ' : attacker.lastBlobName) + '", "attackerNull":' + attNull + '}');
}

void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
    if(!isServer()){return;}
    tcpr('discordData {"dataType":"playerjoin","username":"' + sanitize(player.getCharacterName()) + '"}');
}

// void onPlayerLeave( CRules@ this, CPlayer@ player ){
//     tcpr('discordData {"dataType":"playerleave","username":"' + sanitize(player.getCharacterName()) + '"}');
// } //removed until more relyable

string sanitize(string input){
    return input.replace("\\","\\\\").replace('"','\\"').replace('`',' ').replace("@","\\@");
}