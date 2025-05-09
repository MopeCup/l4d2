#pragma semicolon 1
#pragma newdecls required
#include <sdktools>
#include <sdkhooks>
#include <l4d2util>
#include <left4dhooks>

public Plugin myinfo= {
	name = "Enhance Bolt-ation Sniper",
	author = "MopeCup",
	description = "增强栓狙",
	version = "1.0.2",
	url = "https://github.com/MopeCup/l4d2/tree/main/my%20plugins/enhance_bolt-action_sniper"
};

//=================================================================
//=                       Global
//=================================================================
ConVar g_cvPluginOn;

//=================================================================
//=                         Main
//=================================================================
public void OnPluginStart(){
    g_cvPluginOn = CreateConVar("ebas_plugin_on", "1", "是否开启栓狙增伤<0: 关闭, 1: 开启>");
}

public void OnClientPostAdminCheck(int client){
    SDKHook(client, SDKHook_TraceAttack, TraceAttack);
}

//=================================================================
//=                         SDKHook
//=================================================================
Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup){
    if(!g_cvPluginOn.BoolValue)
        return Plugin_Continue;
    if(!IsValidSI(victim) || !IsZombieClassSI(victim) || !IsValidSur(attacker) || IsFakeClient(attacker) || damage <= 0.0)
        return Plugin_Continue;
    int iWID = GetPlayerWeaponSlot(attacker, 0);
    int iWName = IdentifyWeapon(iWID);
    //PrintToChat(attacker, "%d", iWName);
    if(iWName != 35 && iWName != 36)
        return Plugin_Continue;
    if(hitgroup == 1){
        float fHealth = float(GetClientHealth(victim));
        damage = fHealth;
        //PrintToChat(attacker, "%.1f", damage);
        return Plugin_Changed;
    }
    damage = damage * 2.2;
    int iSIClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
    switch(iSIClass){
        case 3:{
            if(GetEntProp(victim, Prop_Send, "m_isAttemptingToPounce")){
                damage = damage * 1.3;
                //PrintToChat(attacker, "%.1f", damage);
                return Plugin_Changed;
            }
        }
        case 5:{
            if(IsJockeyLeaping(victim)){
                damage = damage * 1.3;
                //PrintToChat(attacker, "%.1f", damage);
                return Plugin_Changed;
            }
        }
        case 6:{
            if(IsCharging(victim)){
                damage = damage * 1.3;
                return Plugin_Changed;
            }
        }
    }
    return Plugin_Changed;
}

//=================================================================
//=                         子函数
//=================================================================
bool IsValidClient(int client){
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool IsValidSur(int client){
    return IsValidClient(client) && GetClientTeam(client) == 2;
}

bool IsValidSI(int client){
    return IsValidClient(client) && GetClientTeam(client) == 3;
}

bool IsZombieClassSI(int client){
    return (GetEntProp(client, Prop_Send, "m_zombieClass") == 6 || GetEntProp(client, Prop_Send, "m_zombieClass") == 5 || 
        GetEntProp(client, Prop_Send, "m_zombieClass") == 4 || GetEntProp(client, Prop_Send, "m_zombieClass") == 3 || 
        GetEntProp(client, Prop_Send, "m_zombieClass") == 2 || GetEntProp(client, Prop_Send, "m_zombieClass") == 1);
}

bool IsJockeyLeaping(int jockey){
    if(GetEntProp(jockey, Prop_Send, "m_zombieClass") != 5 ||
    GetEntPropEnt(jockey, Prop_Send, "m_hGroundEntity") > -1 ||
    GetEntityMoveType(jockey) != MOVETYPE_WALK ||
    GetEntProp(jockey, Prop_Send, "m_nWaterLevel") >= 3 ||
    GetEntPropEnt(jockey, Prop_Send, "m_jockeyVictim") > -1)
        return false;

    int iAbility = GetEntPropEnt( jockey, Prop_Send, "m_customAbility" );
    if(IsValidEntity(iAbility) && GetEntProp(iAbility, Prop_Send, "m_isLeaping") > 0)
        return true;

    float fVel[3];
    GetEntPropVector(jockey, Prop_Data, "m_vecVelocity", fVel);
    fVel[2] = 0.0;
    if(GetVectorLength(fVel) >= 15.0 && GetEntPropEnt(jockey, Prop_Send, "m_hGroundEntity") == -1)
        return true;
    return false;
}

bool IsCharging(int charger){
    int iAbility = GetEntPropEnt(charger, Prop_Send, "m_customAbility");
    if(IsValidEntity(iAbility) && GetEntProp(iAbility, Prop_Send, "m_isCharging") > 0)
        return true;
    return false;
}