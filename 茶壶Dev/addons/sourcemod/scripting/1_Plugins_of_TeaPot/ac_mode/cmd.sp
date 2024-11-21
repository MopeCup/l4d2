Action Cmd_Ready(int client, int args){
    if(IsValidPlayer_Sur(client) && !g_bReadyUp && !g_bPlayerReady[client]){
        g_bPlayerReady[client] = true;
        PrintToChatAll("%N已准备", client);
        IsAllSurReady();
    }
    return Plugin_Handled;
}

Action Cmd_UnReady(int client, int args){
    if(IsValidPlayer_Sur(client) && !g_bReadyUp && g_bPlayerReady[client]){
        g_bPlayerReady[client] = false;
        PrintToChatAll("%N取消准备", client);
        IsAllSurReady();
    }
    return Plugin_Handled;
}

Action Cmd_ShowHud(int client, int args){
    if(IsValidPlayer_Sur(client)){
        if(!g_bReadypanel[client] && !g_bReadyUp)
            g_bReadypanel[client] = true;
    }
    return Plugin_Handled;
}

Action Cmd_UnShowHud(int client, int args){
    if(IsValidPlayer_Sur(client)){
        if(g_bReadypanel[client] && !g_bReadyUp)
            g_bReadypanel[client] = false;
    }
    return Plugin_Handled;
}

Action Cmd_SpecHud(int client, int args){
    if(IsValidSpec(client)){
        g_bSpecHud[client] = !g_bSpecHud[client];
    }
    return Plugin_Handled;
}

Action Cmd_ForceReady(int client, int args){
    if(!g_bReadyUp){
        ReadyUp();
        PrintToChatAll("管理员已强制开始游戏!");
    }
    return Plugin_Handled;
}