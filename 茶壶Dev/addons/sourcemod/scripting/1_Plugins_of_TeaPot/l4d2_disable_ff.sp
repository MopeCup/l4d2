#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>

public Plugin myinfo = 
{
	name = "l4d2 disable friendly fire",
	author = "MopeCup",
	description = "取消掉某些情况下的友伤",
	version = "1.0.0",
	url = ""
}

/*
更新日志:
2024.09.08 - v1.0.0
    插件创建
*/

bool bLateLoad;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){
    bLateLoad = late;

    return APLRes_Success;
}
//-------变量-------
ConVar cvDisableFFDis, cvDisableFFInSafeArea, cvDisableFFInPinned, cvDisableFFInBot;

float fCVDistance;

bool bCVInSafeArea, bCVInPinned, bCVInBot;

bool bIsPlayerLeftSafeArea;

//-------插件开始-------
public void OnPluginStart(){
    //cvar
    cvDisableFFDis = CreateConVar("lff_distance", "35.0", "生还者之间间隔多少将取消友伤\n<[0.0 , 200.0]>", FCVAR_NOTIFY, true, 0.0, true, 200.0);
    cvDisableFFInSafeArea = CreateConVar("lff_in_safe_area", "1", "生还者处于初始安全区时, 是否取消友伤\n<0 否, 1 仅限初次离开前取消>", FCVAR_NOTIFY);
    cvDisableFFInPinned = CreateConVar("lff_in_pinned", "1", "攻击受到特感控制的生还, 是否取消友伤\n<0 否, 1 是>", FCVAR_NOTIFY);
    cvDisableFFInBot = CreateConVar("lff_in_bot", "0", "攻击生还bot时, 是否取消友伤\n<0 否, 1 是>", FCVAR_NOTIFY);

    GetCvars();
    cvDisableFFDis.AddChangeHook(OnConVarChanged);
    cvDisableFFInSafeArea.AddChangeHook(OnConVarChanged);
    cvDisableFFInPinned.AddChangeHook(OnConVarChanged);
    cvDisableFFInBot.AddChangeHook(OnConVarChanged);

    //cfg
    //AutoExecConfig(true, "l4d2_disable_ff");

    //Event
    HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_left_safe_area", Event_PlayerLeftSafeArea);

    //延迟加载
    if(bLateLoad){
        int i;
        for(i = 1; i <= MaxClients; i++){
            if(IsClientInGame(i))
                OnClientPutInServer(i);
        }
    }
}

//-------Cvar处理-------
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
    GetCvars();
}

void GetCvars(){
    fCVDistance = cvDisableFFDis.FloatValue;
    bCVInSafeArea = cvDisableFFInSafeArea.BoolValue;
    bCVInPinned = cvDisableFFInPinned.BoolValue;
    bCVInBot = cvDisableFFInBot.BoolValue;
}

//-------钩住client-------
//client进入房间
public void OnClientPutInServer(int client){
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

//client退出房间
public void OnClientDisconnect(int client){
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

//-------地图开始与结束-------
public void OnMapStart(){
    bIsPlayerLeftSafeArea = false;
}

public void OnMapEnd(){
    bIsPlayerLeftSafeArea = false;
}

//-------Event-------
//round start
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
    bIsPlayerLeftSafeArea = false;
}

//round end
void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
    bIsPlayerLeftSafeArea = false;
}

//玩家离开安全区域
void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast){
    if(bIsPlayerLeftSafeArea)
        return;
    
    bIsPlayerLeftSafeArea = true;
}

//-------钩子处理-------
Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype){
    if(IsValidSur(victim) && IsValidSur(attacker) && IsPlayerAlive(victim)){
        if(ShouldDisableFF(attacker, victim)){
            damage = 0.0;

            return Plugin_Changed;
        }
    }

    return Plugin_Continue;
}

Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype){
    if(IsValidSur(victim) && IsValidSur(attacker) && IsPlayerAlive(victim)){
        if(ShouldDisableFF(attacker, victim)){
            damage = 0.0;

            return Plugin_Changed;
        }
    }

    return Plugin_Continue;
}

//-------Bool函数-------
//是否为合法client
bool IsValidClient(int client){
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

//是否是合法生还
bool IsValidSur(int client){
    return IsValidClient(client) && GetClientTeam(client) == 2;
}

//是否应造成友伤
bool ShouldDisableFF(int attacker, int victim){
    //距离判断
    if(fCVDistance > 0.0){
        float fPos_1[3], fPos_2[3];
        GetClientAbsOrigin(attacker, fPos_1);
        GetClientAbsOrigin(victim, fPos_2);

        float fDistance = GetVectorDistance(fPos_1, fPos_2);

        if(fDistance <= fCVDistance)
            return true;
    }

    //安全区域判断
    if(bCVInSafeArea){
        if(!bIsPlayerLeftSafeArea)
            return true;
    }

    //被控判断
    if(bCVInPinned){
        if(IsClientInControll(victim))
            return true;
    }

    //生还Bot判断
    if(bCVInBot){
        if(IsValidSur(victim) && IsFakeClient(victim))
            return true;
    }

    return false;
}

//判断被攻击玩家是否被控 - 函数来自 l4d2_go_away_from_keyboard.sp
bool IsClientInControll(int client){
	if(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
		return true;
	return false;
}