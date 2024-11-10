#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

public Plugin:myinfo= {
	name = "l4d2 no all bot team",
	author = "MopeCup",
	description = "阻止全Bot生还队伍",
	version = "1.0.0",
	url = ""
}

bool bAllowAllBots;
bool bMapStarted;

public void OnPluginStart(){
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

    RegAdminCmd("sm_allbot", Cmd_AllowAllBotTeam, ADMFLAG_GENERIC);

    bAllowAllBots = false;
}

public void OnMapStart(){
    bMapStarted = true;
}

public void OnMapEnd(){
    bMapStarted = false;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
    bMapStarted = true;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
    bMapStarted = false;
}

Action Cmd_AllowAllBotTeam(int client, int args){
    bAllowAllBots = !bAllowAllBots;
    PrintToChatAll("已%s全Bot生还队伍", bAllowAllBots ? "允许" : "禁止");

    return Plugin_Handled;
}

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
    if(IsClientInGame(client) && client > 0 && client < MaxClients+1 && GetClientTeam(client) == 2)
        return true;
    
    return false;
}