void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
    OnMapStart();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
    OnMapEnd();
}

void Event_MissionLost(Event event, const char[] name, bool dontBroadcast){
    //ChangeToNextMap();
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast){
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!IsValidPlayer_Sur(client) || g_bReadyUp)
        return;
    g_bPlayerReady[client] = false;
    IsAllSurReady();
}

void Event_MapTransition(Event event, const char[] name, bool dontBroadcast){
    InitPlugins();
}