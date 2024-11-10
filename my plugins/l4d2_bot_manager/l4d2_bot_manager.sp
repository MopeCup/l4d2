#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

/*
2024.8.16 - v1.0.0
    插件创建
2024.8.18 - v1.1.0
    添加离开安全区域后处死所有Bot功能
    添加联动Bot.sp的踢出多余人机功能
2024.8.23 - v1.1.1
    修改了Event_PlayerDeath下的IsValidSur判定，修复插件报错问题
2024.9.5  - v1.2.0
    针对各种bot加智商插件的bot进行削弱，取消bot的爆头伤害奖励
2024.10.21 - v1.2.1
    更改离开安全区域处死人机为，离开安全区域处死多余的人机
*/

public Plugin:myinfo= {
	name = "l4d2 bot manager",
	author = "MopeCup",
	description = "阻止全Bot生还队伍",
	version = "1.2.1",
	url = ""
}

bool bAllowAllBots;
bool bMapStarted;
bool bIsPlayerLeftSafeArea;
bool bAllowKillBots;
bool bIsLateLoad = false;
bool bTeapot;

native int GetBotJoinLimit();

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){
    MarkNativeAsOptional("GetBotJoinLimit");

    bIsLateLoad = late;

    return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	bTeapot = LibraryExists("l4d2_Teapot");
}

public void OnLibraryAdded(const char[] sName)
{
	if(StrEqual(sName, "l4d2_Teapot"))
		bTeapot = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if(StrEqual(sName, "l4d2_Teapot"))
		bTeapot = false;
}

ConVar cvReduceSBHeadshotDmg;

public void OnPluginStart(){
    cvReduceSBHeadshotDmg = CreateConVar("lbm_reduce_headshot_dmg", "1", "是否启用取消bot爆头增伤<0 - 否, 1 - 是>", FCVAR_NOTIFY);

    HookEvent("player_death", Event_PlayerDeath);
    //HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_left_safe_area", Event_PlayerLeftSafeArea);

    RegAdminCmd("sm_allbot", Cmd_AllowAllBotTeam, ADMFLAG_GENERIC);
    RegAdminCmd("sm_killbot", Cmd_KillAllBot, ADMFLAG_GENERIC);
    RegAdminCmd("sm_kickbot", Cmd_KickExtraBot, ADMFLAG_GENERIC);

    bAllowAllBots = false;
    bAllowKillBots = false;
}

public void OnMapStart(){
    bMapStarted = true;
    bIsPlayerLeftSafeArea = false;
}

public void OnMapEnd(){
    bMapStarted = false;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
    bMapStarted = true;
    bIsPlayerLeftSafeArea = false;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
    bMapStarted = false;
}

//-----指令-----
Action Cmd_AllowAllBotTeam(int client, int args){
    bAllowAllBots = !bAllowAllBots;
    PrintToChatAll("已%s全Bot生还队伍", bAllowAllBots ? "允许" : "禁止");

    return Plugin_Handled;
}

Action Cmd_KillAllBot(int client, int args){
    //开启处死Bot后，会立刻处死一次Bot
    if(!bAllowKillBots)
        KillExtraBots();

    //对Bool变量进行一次取反
    bAllowKillBots = !bAllowKillBots;
    PrintHintTextToAll("已%s离开安全区域处死Bot", bAllowKillBots ? "开启" : "关闭");
    
    return Plugin_Handled;
}

Action Cmd_KickExtraBot(int client, int args){
    if(!args){
        char sCmd[128];
        GetCmdArg(0, sCmd, sizeof(sCmd));
        PrintToChat(client, "[提示] %s 0 - 踢出所有人机\n[提示] %s 1 - 踢出多余人机", sCmd, sCmd);

        return Plugin_Handled;
    }
    int iKickType = GetCmdArgInt(1);
    RequestFrame(KickBotDealer, iKickType);
    
    return Plugin_Handled;
}

//-----连接与断开-----
public void OnClientPostAdminCheck(int client){
    if(GetConVarBool(cvReduceSBHeadshotDmg))
    //if(IsValidSI(client) && GetEntProp(client, Prop_Send, "m_zombieClass") != 8)
        SDKHook(client, SDKHook_TraceAttack, TraceAttack);
}

//-----Event-----
//玩家受伤后
// public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
// {
//     if(!GetConVarBool(cvReduceSBHeadshotDmg))
//         return;
    
// 	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
// 	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

// 	if(!IsValidSur(attacker) || !IsValidSI(victim))
// 		return;
	
//     //受击者为坦克或攻击者玩家则返回
//     if(GetEntProp(victim, Prop_Send, "m_zombieClass") == 8)
//         return;
    
// 	int attack_dmg = GetEventInt(event, "dmg_health");
// 	int hitgroup = GetEventInt(event, "hitgroup");
//     int victimhealth = GetClientHealth(victim);

// 	//PrintToChatAll("1.击中部位为%d,击中伤害为%d", hitgroup, attack_dmg);

//     //命中头部时，返还3/4的血量
//     if(hitgroup == 1){
//         attack_dmg = attack_dmg * 3;
//         attack_dmg = attack_dmg / 4;
//         victimhealth = victimhealth + attack_dmg;

//         SetEntityHealth(victim, victimhealth);
//     }
// }

//玩家死亡后
void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast){
    if(bAllowAllBots || !bMapStarted)
        return;

    int userid = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userid);
    if(!IsValidSur(client))
        return;

    if(IsFakeClient(client))
        return;

    int iPlayerNum = CheckAlivePlayerNum();
    if(iPlayerNum == 0){
        CreateTimer(1.0, Timer_RebootGame, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}

//第一次离开安全区域判定
void Event_PlayerLeftSafeArea(Handle event, const char[] name, bool dontBroadcast){
    if(bIsPlayerLeftSafeArea)
        return;

    bIsPlayerLeftSafeArea = true;
    if(bAllowKillBots)
        KillExtraBots();
}

//-----处理-----
public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup){
    if(!GetConVarBool(cvReduceSBHeadshotDmg))
        return Plugin_Continue;
    
    if(IsValidSI(victim) && GetEntProp(victim, Prop_Send, "m_zombieClass") != 8 && IsValidSur(attacker) && IsFakeClient(attacker)){
        if(hitgroup == 1)
            damage = damage / 4.0;  //对于bot，若使用喷子则爆头伤害反而会降低
        
        return Plugin_Changed;
    }

    return Plugin_Continue;
}
//延时处理重启游戏
Action Timer_RebootGame(Handle timer){
    //尝试将玩家全杀重启
    int i;
	for (i = 1; i < MaxClients; i++)
	{
		if (IsValidSur(i))
			ForcePlayerSuicide(i);
	}
        
    return Plugin_Stop;
}

void KickBotDealer(int kickType){
    int iMaxNum;
    if(bTeapot)
        iMaxNum = GetBotJoinLimit();
    
    int iNum = 0;
    int i;
    for(i = 1; i < MaxClients; i++){
        if(!IsValidSur(i))
            continue;
        
        if(kickType == 0 && IsFakeClient(i) && IsGetBotOfIdlePlayer(i) == 0){
            KickClient(i);
            continue;
        }

        //第一次循环将所有多余生还移到旁观
        if(kickType == 1 && bTeapot){
            if(iMaxNum == -1)
                break;

            if(!IsFakeClient(i)){
                if(iNum <= iMaxNum)
                    iNum++;
                
                else{
                    ChangeClientTeam(i, 1);
                }
            }
        }
    }

    if(kickType == 0 || iMaxNum == -1 || !bTeapot)
        return;

    iNum = iMaxNum - iNum;
    //第二次循环执行踢出多余Bot的命令
    for(i = 1; i < MaxClients; i++){
        if(!IsValidSur(i))
            continue;
        if(!IsFakeClient(i) || IsGetBotOfIdlePlayer(i) != 0)
            continue;
            
        if(iNum <= 0)
            KickClient(i);
        else
            iNum--;
    }

}

void KillExtraBots(){
    int iTeamSurLimit;
    int i;
    //如果加载了修改后的bot.sp则调用GetBotJoinLimit()
    //注若cvar bots_join_limit为-1则处死所有bot
    if(bTeapot)
        iTeamSurLimit = GetBotJoinLimit();
    else
        iTeamSurLimit = 4;

    int iTeamSurNum = 0;
    for(i = 1; i <= MaxClients; i++){
        if(!IsValidSur(i))
            continue;
        iTeamSurNum++;
    }

    int iSurBotNum = iTeamSurNum - CheckPlayerNum();        //bot数量
    int iEmptySurSlots = iTeamSurLimit - CheckPlayerNum();  //空位数量
    
    if(iSurBotNum == 0)
        return;

    for(i = 1; i < MaxClients; i++){
        if(!IsValidSur(i))
            continue;

        if(IsFakeClient(i) && IsGetBotOfIdlePlayer(i) == 0){
            if(iEmptySurSlots != 0){
                iEmptySurSlots--;
            }
            //PrintToChatAll("执行成功");
            else
                ForcePlayerSuicide(i);
        }
    }
}

//检查玩家人数(此处玩家仅仅包含生还，闲置玩家)
//即以上玩家总数为0时，允许游戏进行重启
int CheckAlivePlayerNum(){
    int iAlivePlayerNum = 0;
    int i;
    for(i = 1; i < MaxClients; i++){
        if(!IsClientInGame(i))
            continue;
        
        if(GetClientTeam(i) == 1){
            int iBot = IsGetBotOfIdlePlayer(i);
            if(iBot != 0)
                iAlivePlayerNum++;

            continue;
        }

        if(IsValidSur(i) && IsPlayerAlive(i) && !IsFakeClient(i))
            iAlivePlayerNum++;
    }

    return iAlivePlayerNum;
}

//检查真人玩家个数
int CheckPlayerNum(){
    int iPlayerNum = 0;
    int i;
    for(i = 1; i < MaxClients; i++){
        if(!IsClientInGame(i))
            continue;
        
        if(GetClientTeam(i) == 1){
            int iBot = IsGetBotOfIdlePlayer(i);
            if(iBot != 0)
                iPlayerNum++;

            continue;
        }

        if(IsValidSur(i) && !IsFakeClient(i))
            iPlayerNum++;
    }

    return iPlayerNum;
}

//返回闲置Bot对应的玩家
int IsGetBotOfIdlePlayer(int client)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && IsClientIdle(i) == client && IsPlayerAlive(i))
			return i;

	return 0;
}

//返回电脑幸存者对应的玩家.
int IsClientIdle(int client)
{
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}

//-----Bool函数-----
bool IsValidSur(int client){
    if(IsValidClient(client) && GetClientTeam(client) == 2)
        return true;
    
    return false;
}

bool IsValidSI(int client){
    if(IsValidClient(client) && GetClientTeam(client) == 3)
        return true;
    
    return false;
}

bool IsValidClient(int client){
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}