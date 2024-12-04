//==============================================================
//=                     Subfunction
//==============================================================
/**
 * @brief 验证索引是否有效
 * 
 * @param client    索引
 * @return          有效返回true, 否则返回false
 * 
 */
stock bool IsValidClient(int client){
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

//-----Survivior-----
/**
 * @brief 验证是否有效生还
 * 
 * @param client    索引
 * @return          有效返回true, 否则返回false
 */
stock bool IsValidSur(int client){
    return IsValidClient(client) && GetClientTeam(client) == 2;
}

/**
 * @brief 验证是否玩家生还
 * @remark 不包含闲置玩家
 * 
 * @param client    索引
 * @return          是返回true, 否则返回false
 */
stock bool IsPlayerSur(int client){
    return IsValidSur(client) && !IsFakeClient(client);
}

/**
 * @brief 返回闲置玩家对应的bot
 * 
 * @param client    生还bot的索引
 * @return          bot对应的玩家，没有则返回-1
 */
stock int IsClientIdle(int client){
    if(!IsValidSur(client))
        return -1;
    if(!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
        return -1;
    return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}

/**
 * @brief 返回场上存在的生还数量
 * 
 * @param incBot    true包含bot, false排除bot
 * @param incDead   true包含死亡生还, false排除死亡生还
 * @return          生还数量
 */
stock int GetSurNum(bool incBot = true, bool incDead = true){
    int count = 0;
    int client;
    for(client = 1; client <= MaxClients; client++){
        if(!incDead && !IsPlayerAlive(client))
            continue;
        if((IsValidSur(client) && (incBot || IsClientIdle(client) > 0)) || (IsPlayerSur(client)))
            count++;
    }
    return count;
}

//-----Special Infected-----
/**
 * @brief 是否特感
 * 
 * @param client    特感索引
 * @return          是返回true, 否则返回false
 */
stock bool IsValidSI(int client){
    return IsValidClient(client) && GetClientTeam(client) == 3;
}

/**
 * @brief 是否一般特感
 * @remark 不包含Tank(Boss特感)
 * 
 * @param client    特感索引
 * @return          是返回true, 否则false
 */
stock bool IsZombieClassSI(int client){
    if(!IsValidSI(client))
        return false;
    int iClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    return iClass == 1 || iClass == 2 || iClass == 3 ||
    iClass == 4 || iClass == 5 || iClass == 6;
}

/**
 * @brief 是否坦克
 * 
 * @param client    特感索引
 * @return          是返回true, 否则false
 */
stock bool IsClientTank(int client){
    return IsValidSI(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
}

/**
 * @brief 统计场上特感数量
 * 
 * @param incNormSI     true包含一般特感，否则排除
 * @param incTank       true包含Tank，否则排除
 * @return              特感数量
 */
stock int GetSINum(bool incNormSI = true, bool incTank = true){
    int count = 0;
    for(int client = 1; client <= MaxClients; client++){
        if(!IsValidSI(client))
            continue;
        if((IsZombieClassSI(client) && incNormSI) || (IsClientTank(client) && incTank))
            count++;
    }
    return count;
}

//-----旁观-----
/**
 * @brief 是否旁观
 * 
 * @param client    旁观索引
 * @return          是true,否则false
 */
stock bool IsValidSpec(int client){
    return IsValidClient(client) && GetClientTeam(client) == 1 && !IsFakeClient(client);
}

/**
 * @brief 返回闲置玩家对应的bot
 * 
 * @param client    玩家索引
 * @return          玩家对应的bot, 没有则返回-1
 */
stock int GetClientOfIdlePlayer(int client){
    if(!IsValidSpec(client))
        return -1;
    for(int i = 1; i <= MaxClients; i++){
        if(IsValidSur(i) && IsFakeClient(i) && IsClientIdle(i) == client)
            return i;
    }
    return -1;
}

/**
 * @brief 获取旁观数量
 * 
 * @return 返回旁观数量
 */
stock int GetSpecNum(){
    int count = 0;
    for(int client = 1; client <= MaxClients; client++){
        if(IsValidSpec(client) && GetClientOfIdlePlayer(client) == -1)
            count++;
    }
    return count;
}

//-----玩家相关-----
/**
 * @brief 返回玩家数量
 * 
 * @return      玩家数量
 */
stock int GetPlayerNum(){
    int count = 0;
    for(int client = 1; client <= MaxClients; client++){
        if(IsValidClient(client) && !IsFakeClient(client))
            count++;
    }
    return count;
}

//-----指令与ConVar-----
/**
 * @brief 执行作弊指令
 * 
 * @param client    索引
 * @param command   指令名
 * @param val       参数
 * @noreturn
 */
stock void CheatCommand(int client, const char[] command, char[] val = ""){
    if(!IsValidClient(client))
        return;
    int flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    if(strlen(val) > 0)
        FakeClientCommand(client, "%s %s", command, val);
    else
        FakeClientCommand(client, "%s", command);
    SetCommandFlags(command, flags);
}

/**
 * @brief 修改与获取插件ConVar值
 * @remark newVal为空时，仅会获取ConVar值
 * 
 * @param conVar    ConVar名
 * @param newVal    ConVar的新参数
 * @return          ConVar的旧参数
 */
stock char[] ChangePluginConVar(const char[] conVar, char[] newVal = ""){
    ConVar cvConVar = FindConVar(conVar);
    char val[64];
    if(cvConVar == null){
        PrintToServer("unable to find convar %s", conVar);
        strcopy(val , sizeof val, "error");
        return val;
    }
    cvConVar.GetString(val, sizeof val);
    if(strlen(newVal) > 0)
        cvConVar.SetString(newVal);
    return val;
}