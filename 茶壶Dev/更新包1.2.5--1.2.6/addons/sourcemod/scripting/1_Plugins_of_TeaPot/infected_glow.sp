#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cup_function>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_NAME "Infected Glow"
#define PLUGIN_PREFIX "infected_glow"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "MopeCup",
	description = "给特感加发光轮廓",
	version = PLUGIN_VERSION,
	url = ""
};

ConVar
    g_cvIGEnable,
    g_cvIGColor[3],
    g_cvIGRange[2],
    g_cvIGFlash;

int
    g_iIGColor[3],
    g_iIGRange[2];

bool
    g_bIGEnable,
    g_bSIInSight[MAXPLAYERS + 1],
    g_bIGFlash;

Handle
    g_hIGTimer;

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);

    g_cvIGEnable = CreateConVar(PLUGIN_PREFIX ... "_enable", "0", "是否启用插件<0 = 关闭, 1 = 开启>", _, true, 0.0, true, 1.0);
    g_cvIGColor[0] = CreateConVar(PLUGIN_PREFIX ... "_color_r", "255", "特感轮廓颜色(红色)", _, true, 0.0, true, 255.0);
    g_cvIGColor[1] = CreateConVar(PLUGIN_PREFIX ... "_color_g", "185", "特感轮廓颜色(绿色)", _, true, 0.0, true, 255.0);
    g_cvIGColor[2] = CreateConVar(PLUGIN_PREFIX ... "_color_b", "230", "特感轮廓颜色(蓝色)", _, true, 0.0, true, 255.0);
    g_cvIGRange[0] = CreateConVar(PLUGIN_PREFIX ... "_range_min", "0", "发光最小范围<0即无限范围>", _, true, 0.0);
    g_cvIGRange[1] = CreateConVar(PLUGIN_PREFIX ... "_range_max", "0", "发光最大范围<0即无限范围>", _, true, 0.0);
    g_cvIGFlash = CreateConVar(PLUGIN_PREFIX ... "_flash", "0", "是否闪烁<0 = 不闪烁, 1 = 闪烁>", _, true, 0.0, true, 1.0);

    g_cvIGEnable.AddChangeHook(ConVarChange_PluginEnable);
    g_cvIGColor[0].AddChangeHook(OnConVarChange);
    g_cvIGColor[1].AddChangeHook(OnConVarChange);
    g_cvIGColor[2].AddChangeHook(OnConVarChange);
    g_cvIGRange[0].AddChangeHook(OnConVarChange);
    g_cvIGRange[1].AddChangeHook(OnConVarChange);
    g_cvIGFlash.AddChangeHook(OnConVarChange);

    //AutoExecConfig(true, PLUGIN_PREFIX);
    GetCvar();
}

void GetCvar()
{
    g_bIGEnable = g_cvIGEnable.BoolValue;
    for (int i = 0; i < 2; i++)
    {
        g_iIGColor[i] = g_cvIGColor[i].IntValue;
        g_iIGRange[i] = g_cvIGRange[i].IntValue;
    }
    g_iIGColor[2] = g_cvIGColor[2].IntValue;
    g_bIGFlash = g_cvIGFlash.BoolValue;
}

void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvar();
}

void ConVarChange_PluginEnable(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_bIGEnable = g_cvIGEnable.BoolValue;
    if (g_bIGEnable)
    {
        ResetAllGlow();
        g_hIGTimer = CreateTimer(3.0, Timer_InfectedGlow, _, TIMER_REPEAT);
    }
    else
    {
        delete g_hIGTimer;
        ResetAllGlow();
    }
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    ResetAllGlow();
    if (g_bIGEnable)
        g_hIGTimer = CreateTimer(1.0, Timer_InfectedGlow, _, TIMER_REPEAT);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bIGEnable)
        delete g_hIGTimer;
    ResetAllGlow();
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsZombieClassSI(client))
        g_bSIInSight[client] = false;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsZombieClassSI(client))
        ResetGlow(client);
}

public void OnClientDisconnect_Post(int client)
{
    g_bSIInSight[client] = false;
}

Action Timer_InfectedGlow(Handle timer)
{
    if (!g_bIGEnable)
        return Plugin_Continue;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != 3 || !IsPlayerAlive(i))
            continue;
        if (!IsZombieClassSI(i))
            continue;
        //bool bInSight = GetEntProp(i, Prop_Send, "m_hasVisibleThreats") == 1 ? true : false;
        bool bInSight = IsSIVisableToSur(i);
        if (bInSight == g_bSIInSight[i])
            continue;
        else
            g_bSIInSight[i] = bInSight;
        if (g_bSIInSight[i])
        {
            SetGlow(i, 1, g_iIGColor, g_iIGRange, g_bIGFlash);
            //PrintHintTextToAll("%Ncolors_on", i);
        }
        else
            ResetGlow(i);
    }
    return Plugin_Continue;
}

void SetGlow(int entity, int type = 0, const int color[3] = {0, 0, 0}, const int range[2] = {0, 0}, bool flash = false)
{
    SetEntProp(entity, Prop_Send, "m_iGlowType", type);
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", color[0] + color[1] * 256 + color[2] * 65536);
    SetEntProp(entity, Prop_Send, "m_nGlowRange", range[1]);
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", range[0]);
    SetEntProp(entity, Prop_Send, "m_bFlashing", flash ? 1 : 0);
}

void ResetGlow(int client)
{
    SetGlow(client);
}

void ResetAllGlow()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        g_bSIInSight[i] = false;
        if (IsClientInGame(i) && GetClientTeam(i) == 3)
            ResetGlow(i);
    }
}

bool IsSIVisableToSur(int client)
{
    float fPos[3], fPos_1[3], fPos_2[3];
    GetClientAbsOrigin(client, fPos);
    GetClientAbsOrigin(client, fPos_1);
    GetClientAbsOrigin(client, fPos_2);
    fPos_1[2] += 36.0;
    fPos_2[2] += 72.0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
            continue;
        if (IsSurIncapped(i))
            continue;
        if (L4D2_IsVisibleToPlayer(i, 2, 3, 0, fPos) || L4D2_IsVisibleToPlayer(i, 2, 3, 0, fPos_1) || L4D2_IsVisibleToPlayer(i, 2, 3, 0, fPos_2))
            return true;
    }
    return false;
}

public void OnPluginEnd()
{
    if (g_bIGEnable)
        delete g_hIGTimer;
    ResetAllGlow();
}