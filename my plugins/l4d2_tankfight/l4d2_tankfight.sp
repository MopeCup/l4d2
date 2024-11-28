#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <multicolors>
#include <sdktools>
#include <sdkhooks>

//===================================================================================
//=                                 Global
//===================================================================================
//#define PLUGIN_VERSION 1.0.0
#define PLUGIN_FLAG FCVAR_SPONLY|FCVAR_NOTIFY

bool 
    g_bSpecialSpawner,
    g_bNekoSpecials,

    g_bTFHealthDebuff,
    g_bPauseTankFightHordes;

ConVar 
    g_cvTFSINumRule,
    g_cvTFSITimeRule,
    g_cvTFHealthDebuff;

int 
    g_iNeko_SpawnTime,
    g_iTFSINumRule,
    g_iCount[MAXPLAYERS + 1];

float 
    g_fSS_SISpawnTime_Min,
    g_fSS_SISpawnTime_Max,
    g_fTFSITimeRule,

    g_fTankSpawnPath,
    g_fSurMaxPath;

Handle
    g_hTFDebuff[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "l4d2 TankFight",
	author = "MopeCup",
	description = "处理克局的各项事宜",
	version = "1.9.2"
};

//===================================================================================
//=                                    Api
//===================================================================================
//--------------------
//-     Native
//--------------------
//special spawner
native int SS_GetSILimit();
//native int SS_GetSISpawnTime();
//NekoSpecial
native int NekoSpecials_GetSpecialsNum();
native int NekoSpecials_GetSpecialsTime();


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){
    //SpecialSpawner
    MarkNativeAsOptional("SS_GetSILimit");
    //MarkNativeAsOptional("SS_GetSISpawnTime");
    //NekoSpecial
    MarkNativeAsOptional("NekoSpecials_GetSpecialsNum");
    MarkNativeAsOptional("NekoSpecials_GetSpecialsTime");

    //g_bLateLoad = late;

    return APLRes_Success;
}

public void OnAllPluginsLoaded(){
    g_bSpecialSpawner = LibraryExists("specialspawner");
    g_bNekoSpecials = LibraryExists("nekospecials");
}

public void OnLibraryAdded(const char[] sName){
    if(StrEqual(sName, "specialspawner"))
        g_bSpecialSpawner = true;
    if(StrEqual(sName, "nekospecials"))
        g_bNekoSpecials = true;
}

public void OnLibraryRemoved(const char[] sName){
    if(StrEqual(sName, "specialspawner"))
        g_bSpecialSpawner = false;
    if(StrEqual(sName, "nekospecials"))
        g_bNekoSpecials = false;
}

//===================================================================================
//=                               Main
//===================================================================================
public void OnPluginStart(){
    g_cvTFSINumRule = CreateConVar("tfsic_sinum_rule", "-1", "克局刷出特感上限衰减数量<-1: 按坦克刷出数量衰减, >=0: 按给定数量衰减>", PLUGIN_FLAG);
    g_cvTFSITimeRule = CreateConVar("tfsic_sitime_rule", "0.0", "克局刷出特感间隔修改数值<实际值等于此值加上刷特插件设置值>", PLUGIN_FLAG);
    g_cvTFHealthDebuff = CreateConVar("tfsic_health_debuff", "0", "是否开启坦克激怒后丢失目标缓慢扣血<0: 否, 1: 是>", PLUGIN_FLAG, true, 0.0, true, 1.0);

    GetCvar();
    g_cvTFSINumRule.AddChangeHook(ConVarChanged);
    g_cvTFSITimeRule.AddChangeHook(ConVarChanged);
    g_cvTFHealthDebuff.AddChangeHook(ConVarChanged);

    RegConsoleCmd("sm_tank", GetPathCmd);
    RegConsoleCmd("sm_p", GetPathCmd);
    RegConsoleCmd("sm_t", GetPathCmd);

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("tank_killed", Event_TankDeath);

    PrecacheSound("ui/pickup_secret01.wav", false);
}

void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
    GetCvar();
}

void GetCvar(){
    g_iTFSINumRule = g_cvTFSINumRule.IntValue;
    g_fTFSITimeRule = g_cvTFSITimeRule.FloatValue;
    g_bTFHealthDebuff = g_cvTFHealthDebuff.BoolValue;
}

//===================================================================================
//=                               Cmd
//===================================================================================
Action GetPathCmd(int client, int args){
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
    PrintToChat(client, "\x04[Current: \x05%d%%|\x04Tank: \x05%d%%|\x04Witch: \x05%d%%]", iPath, iTankFlow, iWitchFlow);
    return Plugin_Handled;
}

public void OnMapStart(){
    GetCvar();
    g_fSurMaxPath = 0.0;
    ResetPlugin();
}

public void OnMapEnd(){
    ResetPlugin();
}

//===================================================================================
//=                                Event
//===================================================================================
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
    OnMapStart();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
    OnMapEnd();
}

void Event_TankDeath(Event event, const char[] name, bool dontBroadcast){
    CreateTimer(0.1, Timer_CheckTank_Death);
}

//===================================================================================
//=                                Timer
//===================================================================================
Action Timer_CheckTank_Death(Handle timer){
    int currentTankNum = GetCurrentTankNum();
    if(currentTankNum == 0){
        g_bPauseTankFightHordes = false;

        if(!g_bSpecialSpawner && !g_bNekoSpecials)
            return Plugin_Stop;
        else if(g_bSpecialSpawner && g_bNekoSpecials){
            LogError("不要同时使用多种多特插件");
            return Plugin_Stop;
        }
        else if(g_bNekoSpecials){
            if(g_fTFSITimeRule != 0)
                ServerCommand("sm_cvar Special_Spawn_Time %d", g_iNeko_SpawnTime);
        }
        else{
            if(g_fTFSITimeRule != 0)
                TF_SetSpawnTime(g_fSS_SISpawnTime_Max, g_fSS_SISpawnTime_Min);
        }

        PrintToChatAll("坦克已全部死亡，刷特配置恢复正常");
    }

    return Plugin_Stop;
}

Action Timer_CheckPath(Handle timer){
    if(GetCurrentTankNum() == 0)
        return Plugin_Stop;
    
    if(!IsInfiniteHordeActive()){
        //PrintToChatAll("nope");
        return Plugin_Continue;
    }

    float fPath = GetCurrentMaxFlow();
    float fDisablePath = g_fTankSpawnPath + 5.0;
    if(fPath > g_fSurMaxPath && fPath <= fDisablePath){
        g_fSurMaxPath = GetCurrentMaxFlow();
        float fLastPath = fDisablePath - fPath;
        PrintToChatAll("继续推进\x05%.1f%%\x01将生成尸潮", fLastPath);
    }
    else if(fPath > fDisablePath){
        g_bPauseTankFightHordes = false;
        g_fSurMaxPath = GetCurrentMaxFlow();
        g_fTankSpawnPath = GetCurrentMaxFlow();
        //PrintToChatAll("fuck");
        CreateTimer(5.0, Timer_TFReSet);
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

Action Timer_TFReSet(Handle timer){
    if(GetCurrentTankNum() != 0){
        g_bPauseTankFightHordes = true;
        CreateTimer(1.0, Timer_CheckPath, _, TIMER_REPEAT);
    }
    return Plugin_Stop;
}

Action Timer_TFCheckActive(Handle timer, int first){
    if(!first){
        for(int i = 1; i <= MaxClients; i++){
            if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 8){
                if(GetEntProp(i, Prop_Send, "m_hasVisibleThreats") != 1){
                    if(g_hTFDebuff[i] == null){
                        g_iCount[i] = 0;
                        int userid = GetClientUserId(i);
                        g_hTFDebuff[i] = CreateTimer(0.1, Timer_TFDebuff, userid);
                    }
                    return Plugin_Stop;
                }
            }
        }
        return Plugin_Continue;
    }

    for(int i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 8){
            if(IsActiveTank(i)){
                if(g_hTFDebuff[i] == null){
                    g_iCount[i] = 0;
                    int userid = GetClientUserId(i);
                    g_hTFDebuff[i] = CreateTimer(0.1, Timer_TFDebuff, userid);
                }
                return Plugin_Stop;
            }
        }
    }
    return Plugin_Continue;
}

Action Timer_TFDebuff(Handle timer, int userid){
    int client = GetClientOfUserId(userid);
    g_hTFDebuff[client] = null;
    if(!client)
        return Plugin_Stop;
    if(GetEntProp(client, Prop_Send, "m_hasVisibleThreats") != 1){
        g_iCount[client]++;
        ReCheck(client);
        return Plugin_Stop;
    }
    int first = 0;
    CreateTimer(1.0, Timer_TFCheckActive, first, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
    return Plugin_Stop;
}

//===================================================================================
//=                                SpawnControll
//===================================================================================
public Action L4D_OnSpawnTank(const float vecPos[3], const float vecAng[3]){
    int sILimit;
    int currentSINum = GetCurrentSINum();
    int currentTankNum = GetCurrentTankNum();

    if(currentTankNum == 0){
        SetTFHordesPausePre();
    }
    CPrintToChatAll("{red}Tank已生成");
    if(!IsSoundPrecached("ui/pickup_secret01.wav")){
 		PrecacheSound("ui/pickup_secret01.wav", false);
	}
    EmitSoundToAll("ui/pickup_secret01.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);

    //如果没有装载specialspawner或nekospecials本插件将不在生效
    if(!g_bSpecialSpawner && !g_bNekoSpecials)
        return Plugin_Continue;
    else if(g_bSpecialSpawner && g_bNekoSpecials){
        LogError("Do not use multiple special infected bots plugins at the same time");
        return Plugin_Continue;
    }
    else if(g_bNekoSpecials){
        sILimit = NekoSpecials_GetSpecialsNum();
        if(g_fTFSITimeRule != 0.0 && currentTankNum == 0){
            g_iNeko_SpawnTime = NekoSpecials_GetSpecialsTime();
            int g_iSpawnTime = RoundToNearest(g_iNeko_SpawnTime + g_fTFSITimeRule);
            ServerCommand("sm_cvar Special_Spawn_Time %d", g_iSpawnTime);
        }
    }
    else{
        sILimit = SS_GetSILimit();
        if(g_fTFSITimeRule != 0.0 && currentTankNum == 0){    
            g_fSS_SISpawnTime_Max = GetSpawnTime(true);
            g_fSS_SISpawnTime_Min = GetSpawnTime(false);
            TF_SetSpawnTime((g_fSS_SISpawnTime_Max + g_fTFSITimeRule), (g_fSS_SISpawnTime_Min + g_fTFSITimeRule));
        }
    }

    if(g_iTFSINumRule == -1){
        //场上存在的特感与坦克总和超过设置上限则处死特感为坦克放位
        if((currentSINum + currentTankNum + 1) > sILimit){
            for(int i = 1; i <= MaxClients; i++){
                if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") != 8){
                    ForcePlayerSuicide(i);
                }
                currentSINum = GetCurrentSINum();
                currentTankNum = GetCurrentTankNum();
                if((currentSINum + currentTankNum + 1) == sILimit)
                    break;
            }
        }
    }

    PrintToChatAll("刷特配置已发生更改");
    return Plugin_Continue;
}

//处理特感生成
// public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3]){
//     int sILimit;
//     if(!g_bSpecialSpawner && !g_bNekoSpecials)
//         return Plugin_Continue;
//     else if(g_bSpecialSpawner && g_bNekoSpecials){
//         LogError("Do not use multiple special infected bots plugins at the same time");
//         return Plugin_Continue;
//     }
//     else if(g_bNekoSpecials)
//         sILimit = NekoSpecials_GetSpecialsNum();
//     else
//         sILimit = SS_GetSILimit();
    
//     int currentSINum = GetCurrentSINum();
//     int currentTankNum = GetCurrentTankNum();
//     if(GetCurrentTankNum() == 0)
//         return Plugin_Continue;

//     if(g_iTFSINumRule == -1){
//         if((currentSINum + currentTankNum + 1) > sILimit)
//             return Plugin_Handled;
//     }
//     else{
//         if((currentSINum + 1) > (sILimit - g_iTFSINumRule))
//             return Plugin_Handled;
//     }
//     return Plugin_Continue;
// }

public void L4D_OnSpawnSpecial_Post(int client, int zombieClass, const float vecPos[3], const float vecAng[3]){
    int sILimit;
    if(!g_bSpecialSpawner && !g_bNekoSpecials)
        return;
    else if(g_bSpecialSpawner && g_bNekoSpecials){
        LogError("Do not use multiple special infected bots plugins at the same time");
        return;
    }
    else if(g_bNekoSpecials)
        sILimit = NekoSpecials_GetSpecialsNum();
    else
        sILimit = SS_GetSILimit();
    
    int currentSINum = GetCurrentSINum();
    int currentTankNum = GetCurrentTankNum();
    if(GetCurrentTankNum() == 0)
        return;

    if(g_iTFSINumRule == -1){
        if((currentSINum + currentTankNum) > sILimit)
            ForcePlayerSuicide(client);
    }
    else{
        if((currentSINum) > (sILimit - g_iTFSINumRule))
            ForcePlayerSuicide(client);
    }
}

//获取刷特时间
float GetSpawnTime(bool maxtTime){
    char temp[254];
    char buffer[4][32];
    float num;
    float val;
    if(maxtTime){
        ServerCommandEx(temp, sizeof temp, "ss_time_max");
        ExplodeString(temp, "\"", buffer, sizeof buffer, sizeof buffer[]);
        for(int i = 0; i < 4; i++){
            if (temp[i][0] == '\0') {
                num = -1.0;
                continue;
            }

            if ((val = StringToFloat(temp[i])) < -1) {
                temp[i][0] = '\0';
                num = -1.0;
                continue;
            }

            num = val;
        }
    }
    else{
        ServerCommandEx(temp, sizeof temp, "ss_time_min");
        ExplodeString(temp, "\"", buffer, sizeof buffer, sizeof buffer[]);
        for(int i = 0; i < 4; i++){
            if (temp[i][0] == '\0') {
                num = -1.0;
                continue;
            }

            if ((val = StringToFloat(temp[i])) < -1) {
                temp[i][0] = '\0';
                num = -1.0;
                continue;
            }

            num = val;
        }
    }

    return num;
}

//设置刷特时间
void TF_SetSpawnTime(float maxTime, float minTime){
    ServerCommand("sm_cvar ss_time_min %d", RoundToNearest(minTime));
    ServerCommand("sm_cvar ss_time_max %d", RoundToNearest(maxTime));
}

//===================================================================================
//=                                Stop Hordes
//===================================================================================
// public void OnEntityCreated(int entity, const char[] classname){

// }
void SetTFHordesPausePre(){
    g_fSurMaxPath = GetCurrentMaxFlow();
    g_fTankSpawnPath = GetCurrentMaxFlow();
    CreateTimer(1.0, Timer_CheckPath, _, TIMER_REPEAT);
    g_bPauseTankFightHordes = true;
    if(g_bTFHealthDebuff){
        PrintToChatAll("Tank每丢失生还视野0.1s,将损失部分生命值");
        int first = 1;
        CreateTimer(1.0, Timer_TFCheckActive, first, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action L4D_OnSpawnMob(int &amount){
    if(g_bPauseTankFightHordes && GetCurrentTankNum() > 0 && !IsSurVomited() && IsInfiniteHordeActive()){
        L4D2Direct_SetPendingMobCount(0);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

//===================================================================================
//=                                子函数
//===================================================================================
int GetCurrentSINum(){
    int count = 0;
    for(int i = 1; i<= MaxClients; i++){
        if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && 
        (GetEntProp(i, Prop_Send, "m_zombieClass") == 6 || GetEntProp(i, Prop_Send, "m_zombieClass") == 5 || 
        GetEntProp(i, Prop_Send, "m_zombieClass") == 4 || GetEntProp(i, Prop_Send, "m_zombieClass") == 3 || 
        GetEntProp(i, Prop_Send, "m_zombieClass") == 2 || GetEntProp(i, Prop_Send, "m_zombieClass") == 1))
            count++;
    }
    return count;
}

int GetCurrentTankNum(){
    int count = 0;
    for(int i = 1; i<= MaxClients; i++){
        if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
            count++;
    }
    return count;
}

void ResetPlugin(){
    g_iNeko_SpawnTime = 0;
    g_fSS_SISpawnTime_Min = 0.0;
    g_fSS_SISpawnTime_Max = 0.0;

    g_fTankSpawnPath = 0.0;
    g_bPauseTankFightHordes = false;

    for(int i = 1; i <= MaxClients; i++){
        if(g_hTFDebuff[i] != null)
            delete g_hTFDebuff[i];
    }
}

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

//无限尸潮判断
bool IsInfiniteHordeActive()
{
	int countdown = GetHordeCountdown();
	return (countdown > -1 && countdown <= 10);
}

int GetHordeCountdown()
{
	return (CTimer_HasStarted(L4D2Direct_GetMobSpawnTimer())) ? RoundFloat(CTimer_GetRemainingTime(L4D2Direct_GetMobSpawnTimer())) : -1;
}

//判断是否有被喷中
bool IsBoomed(int client)
{
	return ((GetEntPropFloat(client, Prop_Send, "m_vomitStart") + 0.01) > GetGameTime());
}

bool IsSurVomited(){
    int i;
    for(i = 1; i < MaxClients; i++){
        if(IsBoomed(i))
            return true;
    }
    return false;
}

bool IsValidSur(int client){
    if(client > 0 && client < MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
        return true;
    return false;
}

int GetGameRulesNumber(){
    return GameRules_GetProp("m_bInSecondHalfOfRound");
}

//是否为激活的坦克
bool IsActiveTank(int client){
    if(GetEntProp(client, Prop_Send, "m_zombieState") == 1 || GetEntProp(client, Prop_Send, "m_hasVisibleThreats") == 1)
        return true;
    return false;
}

void ReCheck(int client){
    if(g_iCount[client] <= 10){
        g_hTFDebuff[client] = CreateTimer(0.1, Timer_TFDebuff, GetClientUserId(client));
    }
    else{
        g_iCount[client] = 0;
        int iHealth = GetClientHealth(client);
        float dmg = iHealth > 8000 ? 150.0 : 15.0;
        SDKHooks_TakeDamage(client, client, client, dmg);
        g_hTFDebuff[client] = CreateTimer(0.1, Timer_TFDebuff, GetClientUserId(client));
    }
}