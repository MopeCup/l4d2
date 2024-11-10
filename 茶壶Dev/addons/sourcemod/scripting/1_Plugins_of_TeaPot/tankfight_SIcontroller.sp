#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <sdktools>
#include <sdkhooks>

//===================================================================================
//=                                 Global
//===================================================================================
//#define PLUGIN_VERSION 1.0.0
#define PLUGIN_FLAG FCVAR_SPONLY|FCVAR_NOTIFY

bool 
    g_bSpecialSpawner,
    g_bNekoSpecials;

ConVar 
    g_cvTFSINumRule,
    g_cvTFSITimeRule;

int 
    g_iNeko_SpawnTime,
    g_iTFSINumRule;

float 
    g_fSS_SISpawnTime_Min,
    g_fSS_SISpawnTime_Max,
    g_fTFSITimeRule;

public Plugin myinfo =
{
	name = "TankFight SI Controller",
	author = "MopeCup",
	description = "对克局刷特进行修改",
	version = "1.0.1"
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
    g_cvTFSINumRule.AddChangeHook(ConVarChanged);
    g_cvTFSITimeRule.AddChangeHook(ConVarChanged);

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("tank_killed", Event_TankDeath);
}

void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
    GetCvar();
}

void GetCvar(){
    g_iTFSINumRule = g_cvTFSINumRule.IntValue;
    g_fTFSITimeRule = g_cvTFSITimeRule.FloatValue;
}

public void OnMapStart(){
    GetCvar();
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
    int currentTankNum = GetCurrentTankNum();
    if(currentTankNum == 0){
        if(!g_bSpecialSpawner && !g_bNekoSpecials)
            return;
        else if(g_bSpecialSpawner && g_bNekoSpecials){
            LogError("不要同时使用多种多特插件");
            return;
        }
        else if(g_bNekoSpecials)
            ServerCommand("sm_cvar Special_Spawn_Time %d", g_iNeko_SpawnTime);
        else
            TF_SetSpawnTime(g_fSS_SISpawnTime_Max, g_fSS_SISpawnTime_Min);

        PrintToChatAll("{red}坦克已全部死亡，刷特配置恢复正常");
    }
}

//===================================================================================
//=                                SpawnControll
//===================================================================================
public Action L4D_OnSpawnTank(const float vecPos[3], const float vecAng[3]){
    int sILimit;
    int currentSINum = GetCurrentSINum();
    int currentTankNum = GetCurrentTankNum();
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
            ServerCommand("Special_Spawn_Time %d", g_iSpawnTime);
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

    PrintToChatAll("{red}刷特配置已发生更改");
    return Plugin_Continue;
}

//处理特感生成
public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3]){
    int sILimit;
    if(!g_bSpecialSpawner && !g_bNekoSpecials)
        return Plugin_Continue;
    else if(g_bSpecialSpawner && g_bNekoSpecials){
        LogError("Do not use multiple special infected bots plugins at the same time");
        return Plugin_Continue;
    }
    else if(g_bNekoSpecials)
        sILimit = NekoSpecials_GetSpecialsNum();
    else
        sILimit = SS_GetSILimit();
    
    int currentSINum = GetCurrentSINum();
    int currentTankNum = GetCurrentTankNum();
    if(GetCurrentTankNum() == 0)
        return Plugin_Continue;

    if(g_iTFSINumRule == -1){
        if((currentSINum + currentTankNum + 1) > sILimit)
            return Plugin_Handled;
    }
    else{
        if((currentSINum + 1) > (sILimit - g_iTFSINumRule))
            return Plugin_Handled;
    }
    return Plugin_Continue;
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
}