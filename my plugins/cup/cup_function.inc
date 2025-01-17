#if defined _cup_function_included
    #endinput
#endif
#define _cup_function_included

//团队
enum {
    TEAM_SPEC = 1,
    TEAM_SUR = 2,
    TEAM_SI = 3
}

//特感类型
enum {
    ZC_SMOKER = 1,
    ZC_BOOMER = 2,
    ZC_HUNTER = 3,
    ZC_SPITTER = 4,
    ZC_JOCKEY = 5,
    ZC_CHARGER = 6,
    ZC_WITCH = 7,
    ZC_TANK = 8
}

enum {
    SUR_STATE_NORMAL = 0,
    SUR_STATE_PINNED = 1,
    SUR_STATE_HANGING = 2,
    SUR_STATE_INCAPPED = 3,
    SUR_STATE_DEAD = 4
}

stock const char specialInfectedName[][] = {
    "nope",
    "smoker",
    "boomer",
    "hunter",
    "spitter",
    "jockey",
    "charger",
    "witch",
    "tank"
};

stock const char surviviorState[][] = {
    "正常",
    "被控",
    "挂边",
    "倒地",
    "死亡"
};

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
 * @brief 返回生还是否倒地
 * 
 * @param client    生还对应索引
 * @return          倒地返回true，否则返回false
 */
stock bool IsSurIncapped(int client){
    if(IsValidClient(client) && IsPlayerAlive(client))
        return false;
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
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

/**
 * @brief 返回生还被控时对应的特感索引
 * 
 * @param client    生还索引
 * @param class     被控特感类型
 * @return          对应特感的索引，没有返回-1
 */
stock int GetSIPinClient(int client, int class){
    if(!IsValidSur(client) || !IsPlayerAlive(client))
        return -1;
    int index;
    switch(class){
        case 1:{
            index = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
            return index > 0 ? index : -1;
        }
        case 3:{
            index = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
            return index > 0 ? index : -1;
        }
        case 5:{
            index = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
            return index > 0 ? index : -1;
        }
        case 6:{
            index = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
            if(index > 0)
                return index;
            index = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
            return index > 0 ? index : -1;
        }
    }
    return -1;
}

/**
 * @brief 返回生还是否被挂边
 * 
 * @param client    生还索引
 * @return          是返回true，否返回false
 */
stock bool IsSurHanging(int client){
    if(IsValidSur(client) && IsPlayerAlive(client)){
        return view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1)) || view_as<bool>(GetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1));
    }
    return false;
}

/**
 * 获取生还当前状态
 * 
 * @param client    生还索引
 * @@return         生还状态,非法生还返回-1
 */
stock int GetSurState(int client){
    if(!IsValidSur(client))
        return -1;
    if(!IsPlayerAlive(client))
        return SUR_STATE_DEAD;
    if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") != 0 ||
	GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") != 0 ||
	GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") != 0 ||
	GetEntPropEnt(client, Prop_Send, "m_carryAttacker") != 0 ||
	GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") != 0)
        return SUR_STATE_PINNED;
    if(IsSurHanging(client))
        return SUR_STATE_HANGING;
    if(IsSurIncapped(client))
        return SUR_STATE_INCAPPED;
    return SUR_STATE_NORMAL;
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

/**
 * @brief 返回特感控住的生还索引
 * 
 * @param client    特感索引
 * @return          有则返回生还索引，否则返回-1
 */
stock int GetVictimPinnedByClient(int client){
    if(IsValidSI(client) && IsPlayerAlive(client)){
        int class = GetEntProp(client, Prop_Send, "m_zombieClass");
        int index;
        switch(class){
            case 1:{
                index = GetEntPropEnt(client, Prop_Send, "m_tongueVictim");
                return index > 0 ? index : -1;
            }
            case 3:{
                index = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
                return index > 0 ? index : -1;
            }
            case 5:{
                index = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
                return index > 0 ? index : -1;
            }
            case 6:{
                index = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
                if(index > 0)
                    return index;
                index = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
                return index > 0 ? index : -1;
            }
        }
    }
    return -1;
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

/**
 * @brief 获取特感的类
 * 
 * @param client    特感索引
 * @return          是特感返回特感的类，其他返回0
 */
stock int GetSIClass(int client){
    if(IsValidSI(client)){
        return GetEntProp(client, Prop_Send, "m_zombieClass");
    }
    return 0;
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