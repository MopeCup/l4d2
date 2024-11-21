//是否有效索引
bool IsValidClient(int client){
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

//是否生还
bool IsValidSur(int client){
    return IsValidClient(client) && GetClientTeam(client) == 2;
}

//是否有效生还玩家
bool IsValidPlayer_Sur(int client){
    return IsValidSur(client) && (!IsFakeClient(client));
}

bool IsValidSpec(int client){
    return IsValidClient(client) && (!IsFakeClient(client)) && GetClientTeam(client) == 1;
}

//初始化插件
void InitPlugins(){
    g_bReadyUp = false;

    g_iCmd = 0;

    for(int i; i <= MaxClients; i++){
        g_bPlayerReady[i] = false;
        g_bReadypanel[i] = true;
        g_bSpecHud[i] = false;
    }
    if(g_hSpecHudpanel == null)
        g_hSpecHudpanel = CreateTimer(1.0, Timer_Specpanel, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    if(g_hReadyUppanel == null)
        g_hReadyUppanel = CreateTimer(1.0, Timer_ReadyUppanel, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

//获取生还数量
int GetSurNum(bool bIncBot){
    int count = 0;
    for(int i = 1; i <= MaxClients; i++){
        if(IsValidPlayer_Sur(i) || (IsValidSur(i) && bIncBot))
            count++;
    }
    return count;
}

//获取玩家数量
int GetPlayerNum(){
    int count = 0;
    for(int i = 1; i <= MaxClients; i++){
        if(IsValidClient(i) && !IsFakeClient(i))
            count++;
    }
    return count;
}

//获取当前最远生还路程
float GetCurrentMaxFlow(){
    static float maxDistance;
    static int targetSurvivor;
    targetSurvivor = L4D_GetHighestFlowSurvivor();
    if(!IsValidSur(targetSurvivor))
        maxDistance = L4D2_GetFurthestSurvivorFlow();
    else
        maxDistance = L4D2Direct_GetFlowDistance(targetSurvivor);
    
    return (maxDistance / L4D2Direct_GetMapMaxFlowDistance()) * 100.0;
}

int GetGameRulesNumber(){
    return GameRules_GetProp("m_bInSecondHalfOfRound");
}

//获取全部路程数据
int GetAllFlow(int iType){
    int iPath = RoundToNearest(GetCurrentMaxFlow());
    int iRound = GetGameRulesNumber();
    int iTankFlow, iWitchFlow, iFlow;
    ConVar cvVS_BossBuffer = FindConVar("versus_boss_buffer");
    if(L4D2Direct_GetVSTankToSpawnThisRound(iRound)){
        iFlow = RoundToCeil(L4D2Direct_GetVSTankFlowPercent(iRound) * 100.0);
        if(iFlow > 0)
            iFlow -= RoundToFloor(cvVS_BossBuffer.FloatValue / L4D2Direct_GetMapMaxFlowDistance() * 100.0);
        iTankFlow = iFlow < 0 ? 0 : iFlow;
    }
    if(L4D2Direct_GetVSWitchToSpawnThisRound(iRound)){
        iFlow = RoundToCeil(L4D2Direct_GetVSWitchFlowPercent(iRound) * 100.0);
        if(iFlow > 0)
            iFlow -= RoundToFloor(cvVS_BossBuffer.FloatValue / L4D2Direct_GetMapMaxFlowDistance() * 100.0);
        iWitchFlow = iFlow < 0 ? 0 : iFlow;
    }
    if(iType == 0){
        return iTankFlow;
    }
    else if(iType == 1){
        return iWitchFlow;
    }
    return iPath;
}

//将玩家传送回安全区域
void ReturnPlayerToSafeRoom(int client, bool flagSet = true){
    int warp_flags;
    if(!flagSet){
        warp_flags = GetCommandFlags("warp_to_start_area");
        SetCommandFlags("warp_to_start_area", warp_flags & ~FCVAR_CHEAT);
    }
    if(GetEntProp(client, Prop_Send, "m_isHangingFromLedge")){
        L4D_ReviveSurvivor(client);
    }
    FakeClientCommand(client, "warp_to_start_area");
    if(!flagSet){
        SetCommandFlags("warp_to_start_area", warp_flags);
    }
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
    SetEntPropFloat(client, Prop_Send, "m_flFallVelocity", 0.0);
}

//冻结玩家
void SetClientFrozen(int client, bool freeze){
    SetEntityMoveType(client, freeze ? MOVETYPE_NONE : MOVETYPE_WALK);
}