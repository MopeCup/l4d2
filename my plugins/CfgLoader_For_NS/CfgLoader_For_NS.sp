#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "CfgLoader For NS",
	author = "MopeCup",
	description = "用于neko多特的克局配置文件加载",
	version = "1.0.0"
};

#define PATH_NAME "data/NS_TankFight.cfg"

char g_sConfig[PLATFORM_MAX_PATH];

public void OnPluginStart(){
    HookEvent("tank_spawn", Event_TankSpawn);
    HookEvent("tank_killed", Event_TankKilled);

    SetPath();
}

void SetPath(){
    BuildPath(Path_SM, g_sConfig, sizeof g_sConfig, PATH_NAME);
    if(!FileExists(g_sConfig))
        SetFailState("%s file does not exist!", g_sConfig);
}

public void OnClientDisconnect(int client){
    if(!IsClientTank(client) || !IsPlayerAlive(client))
        return;
    CreateTimer(0.1, Timer_CheckTank_Death);
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast){
    CreateTimer(0.1, Timer_CheckTank_Spawn);
}

void Event_TankKilled(Event event, const char[] name, bool dontBroadcast){
    CreateTimer(0.1, Timer_CheckTank_Death);
}

Action Timer_CheckTank_Spawn(Handle timer){
    int count = 0;
    int i;
    for(i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i) && IsClientTank(i) && IsPlayerAlive(i))
            count++;
    }

    if(count == 1){
        PrintToChatAll("坦克出现，克局刷特已调整");
        KeyValues kv = new KeyValues("");
        if(!kv.ImportFromFile(g_sConfig))
            ThrowError("Failed to import %s file into KeyValues", g_sConfig);
        // if(!FileToKeyValues(kv, g_sConfig))
        //     SetFailState("无法找到配置文件位于: %s", g_sConfig);
        if(kv.GotoFirstSubKey()){
            char sCmd[64];
            char sVal[32];
            do{
                kv.GetSectionName(sCmd, sizeof sCmd);
                kv.GetString("Tank", sVal, sizeof sVal);
                ConVar newCVar = FindConVar(sCmd);
                if(newCVar == null){
                    PrintToChatAll("Unable to find convar!");
                    continue;
                }
                else{
                    SetConVarString(newCVar, sVal);
                }
            }while(kv.GotoNextKey());
        }

        delete kv;
    }

    return Plugin_Handled;
}

Action Timer_CheckTank_Death(Handle timer){
    int count = 0;
    int i;
    for(i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i) && IsClientTank(i) && IsPlayerAlive(i))
            count++;
    }

    if(count == 0){
        PrintToChatAll("坦克死亡，非克局刷特已恢复");
        KeyValues kv = new KeyValues("");
        if(!kv.ImportFromFile(g_sConfig))
            ThrowError("Failed to import %s file into KeyValues", g_sConfig);
        // if(!FileToKeyValues(kv, g_sConfig))
        //     SetFailState("无法找到配置文件位于: %s", g_sConfig);
        if(kv.GotoFirstSubKey()){
            char sCmd[64];
            char sVal[32];
            do{
                kv.GetSectionName(sCmd, sizeof sCmd);
                kv.GetString("Norm", sVal, sizeof sVal);
                ConVar newCVar = FindConVar(sCmd);
                if(newCVar == null){
                    PrintToChatAll("Unable to find convar!");
                    continue;
                }
                else{
                    SetConVarString(newCVar, sVal);
                }
            }while(kv.GotoNextKey());
        }

        delete kv;
    }

    return Plugin_Handled;
}

bool IsClientTank(int client){
    if(client > 1 && client <= MaxClients && GetClientTeam(client) == 3 && GetEntProp(client,Prop_Send,"m_zombieClass") == 8)
        return true;
    return false;
}