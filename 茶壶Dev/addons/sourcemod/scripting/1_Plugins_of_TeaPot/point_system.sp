#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "point system",
	author = "MopeCup",
	version = "1.1.1",
}

ConVar
    g_cvPrintPoint;

bool
    g_bLateLoad,
    g_bLeftSafeArea,
    g_bPrintPoint;

int
    g_iTotalDmgSI,
    g_iTotalDmgCI;
    //g_iBasePoint;

enum struct esData{
    int dmgSI;
    int dmgCI;

    float PlayerPath;

    void CleanInfected(){
        this.dmgSI = 0;
        this.dmgCI = 0;
        this.PlayerPath = 0.0;
    }
}

esData
    g_esData[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart(){
    g_cvPrintPoint = CreateConVar("ps_printpoint", "0", "是否开启玩家分数播报<0:否, 1:是>", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    g_cvPrintPoint.AddChangeHook(ConVarChanged);

    //HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("map_transition", Event_MapTransition);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
    HookEvent("infected_death", Event_InfectedDeath);
    //HookEvent("tank_spawn", Event_TankSpawn);

    RegConsoleCmd("sm_point", Cmd_CheckPoint);
    RegConsoleCmd("sm_bonus", Cmd_CheckPoint);

    if (g_bLateLoad && L4D_HasAnySurvivorLeftSafeArea())
		L4D_OnFirstSurvivorLeftSafeArea_Post(0);
}

void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
    Dealcvar();
}

void Dealcvar(){
    g_bPrintPoint = GetConVarBool(g_cvPrintPoint);
}

//获取当前分数
Action Cmd_CheckPoint(int client, int args){
    if(!client || !IsClientInGame(client))
        return Plugin_Handled;

    PrintPoint(client);

    return Plugin_Handled;
}

//==============================
//=     游戏开始阶段的初始化
//==============================
public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client){
    g_bLeftSafeArea = true;
}

public void OnClientDisconnect(int client){
    g_iTotalDmgSI -= g_esData[client].dmgSI;
    g_iTotalDmgCI -= g_esData[client].dmgCI;

    g_esData[client].CleanInfected();
}

public void OnMapEnd(){
    g_bLeftSafeArea = false;

    ClearData();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
    PrintPoint(0);

    OnMapEnd();
}

void Event_MapTransition(Event event, const char[] name, bool dontBroadcast){
    PrintPoint(0);
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast){
    int attacker, victim;
    if(!(attacker = GetClientOfUserId(event.GetInt("attacker"))) || !IsClientInGame(attacker))
        return;

    if(!(victim = GetClientOfUserId(event.GetInt("userid"))) || victim == attacker || !IsClientInGame(victim))
        return;

    if(GetClientTeam(victim) == 3 && GetClientTeam(attacker) == 2){
        int dmg = event.GetInt("dmg_health");
        switch(GetEntProp(victim, Prop_Send, "m_zombieClass")){
            case 1,2,3,4,5,6:{
                g_iTotalDmgSI += dmg;
                g_esData[attacker].dmgSI += dmg;
            }
        }
    }
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast){
    //生还死亡时，记录下他的路程
    int victim;
    if(!(victim = GetClientOfUserId(event.GetInt("userid"))) || GetClientTeam(victim) != 2)
        return;

    WritePlayerPath(victim, false, true);
    //PrintToChatAll("%f", g_esData[victim].PlayerPath);
}

void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast){
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2)
		return;

    g_iTotalDmgCI++;
    g_esData[attacker].dmgCI++;
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3]){
    for(int i = 1; i <= MaxClients; i++){
        if(!IsValidSur(i))
            continue;
        WritePlayerPath(i, true, false);
    }

    CPrintToChatAll("{green}[积分系统] {blue}坦克生成，路程已锁定!");
}

//==============================
//=        积分播报
//==============================
void PrintPoint(int player){
    int count;
	int client;
	int[] clients = new int[MaxClients];
	for(client = 1; client <= MaxClients; client++){
	    if(IsClientInGame(client) && ((GetClientTeam(client) == 1 && IsGetBotOfIdlePlayer(client) != 0) || GetClientTeam(client) == 2))
	        clients[count++] = client;
	}

    if (!count)
		return;

    int infoMax = count < 4 ? 4 : count;
    int iPointSum = 0;
    int iPlayerPoint[MAXPLAYERS + 1];

    int i;
    for(i = 0; i < infoMax; i++){
        client = clients[i];
        WritePlayerPath(client, false, false);
        int dmgSI = g_esData[client].dmgSI;
        int dmgCI = g_esData[client].dmgCI;
        float path = g_esData[client].PlayerPath;

        iPlayerPoint[client] = RoundToNearest((dmgSI/50 + dmgCI) * path);
        iPointSum += iPlayerPoint[client];
    }

    //排序
    int j;
    for(i = 0; i < (infoMax - 1); i++){
        for(j = i + 1; j < infoMax; j++){
            int client1, client2;
            client1 = clients[i];
            client2 = clients[j];
            if(iPlayerPoint[client1] < iPlayerPoint[client2]){
                clients[i] = client2;
                clients[j] = client1;
            }
        }
    }

    //播报
    if(player == 0){
        client = clients[0];
        CPrintToChatAll("{green}分数统计\n{green}[团队总分] {olive}%d\n{green}[个人最高] {olive}%N - %d", iPointSum, client, iPlayerPoint[client]);
        for(i = 0; i < infoMax; i++){
            client = clients[i];
            CPrintToChat(client, "{green}[你的分数] {olive}%d(%d%%) #%d", iPlayerPoint[client], iPlayerPoint[client] * 100 / iPointSum, i+1);
        }
    }
    else{
        if((GetClientTeam(player) == 1 && IsGetBotOfIdlePlayer(player) != 0) || GetClientTeam(player) == 2){
            client = clients[0];
            CPrintToChat(player, "{green}[当前分数] {olive}%d\n{green}[个人最高] {olive}%N - %d\n{green}[你的分数] {olive}%d", iPointSum, client, iPlayerPoint[client], iPlayerPoint[player]);
        }
        else{
            CPrintToChat(player, "{green}[当前分数] {olive}%d\n{green}[个人最高] {olive}%N - %d", iPointSum, client, iPlayerPoint[client]);
        }
    }
}

//==============================
//=         子函数
//==============================
//写入路程
void WritePlayerPath(int client, bool IsTankSpawn, bool IsPlayerDeath){
    if(!IsValidSur(client))
        return;
    
    //只有当前路程超过记录路程才会记录
    float path = GetSurvivorFlow(client, IsTankSpawn, IsPlayerDeath);
    if(g_esData[client].PlayerPath >= path)
        return;
    g_esData[client].PlayerPath = path;
}

//获取路程
float GetSurvivorFlow(int client, bool IsTankSpawn, bool IsPlayerDeath){
    //非存活生还返回0
    if(!IsValidSur(client))
        return 0.0;

    if(!IsPlayerAlive(client) && !IsPlayerDeath)
        return 0.0;
    
    static float maxDistance;
    maxDistance = L4D2Direct_GetFlowDistance(client);

    //场上存在坦克返回0
    if(IsTankStayInGame() && !IsTankSpawn && maxDistance != L4D2Direct_GetMapMaxFlowDistance())
        return 0.0;

    return maxDistance / L4D2Direct_GetMapMaxFlowDistance();
}

//是否为有效索引
bool IsValidClient(int client){
    if(client > 0 && client <= MaxClients && IsClientInGame(client))
        return true;
    return false;
}

//是否为存活的生还
bool IsValidSur(int client){
    if(IsValidClient(client) && GetClientTeam(client) == 2)
        return true;
    return false;
}

//场上是否存在坦克
bool IsTankStayInGame(){
    int i;
    for(i = 1; i <= MaxClients; i++){
        if(!IsValidClient(i) || GetClientTeam(i) != 3 || GetEntProp(i, Prop_Send, "m_zombieClass") != 8)
            continue;
        
        return true;
    }

    return false;
}

void ClearData(){
    g_iTotalDmgSI = 0;
    g_iTotalDmgCI = 0;

    for (int i = 1; i <= MaxClients; i++)
		g_esData[i].CleanInfected();
}

//返回闲置玩家对应的bot
int IsGetBotOfIdlePlayer(int client)
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && IsClientIdle(i) == client && IsPlayerAlive(i))
			return i;

	return 0;
}

//返回电脑幸存者对应的玩家.
int IsClientIdle(int client)
{
	if(!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}