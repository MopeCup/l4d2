#pragma semicolon 1
#pragma newdecls required

#include <left4dhooks>
#include <sdkhooks>
#include <sdktools>
#include "cup/cup_function.sp"

public Plugin myinfo = 
{
	name = "Health Return",
	author = "MopeCup",
	description = "击杀特感回血与过关回血",
	version = "1.0.0",
	url = "https://github.com/MopeCup/l4d2"
}

//===============================================================
//=                         global
//===============================================================
ConVar g_cvReturnType, g_cvSafeRoomNaps, g_cvBaseReturn, g_cvSkillRate, g_cvMeleeRate, g_cvFarDistance, g_cvFarRate, g_cvDangerRate, g_cvHeadShotRate, g_cvMaxHealth;

int g_iSafeRoomNaps, g_iMaxHealth;

float g_fBaseReturn, g_fSkill, g_fMelee, g_fFarDistance, g_fFar, g_fDanger, g_fHeadShot;

bool g_bReturnType;

bool g_bIsSkillKill[MAXPLAYERS + 1];

//===============================================================
//=                        main
//===============================================================
public void OnPluginStart(){
    //Init();

    g_cvReturnType = CreateConVar("hr_return_type", "0", "回复生命值累型<0: 实血, 1: 虚血>", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvSafeRoomNaps = CreateConVar("hr_saferoom_naps", "50", "过关后低于此血量将回复到此<0: 不回复>", FCVAR_NOTIFY);

    g_cvBaseReturn = CreateConVar("hr_base_return", "0.0", "基础回复血量", FCVAR_NOTIFY, true, 0.0);
    g_cvSkillRate = CreateConVar("hr_skill_rate", "1.0", "技巧击杀提供回血倍率(推荐1.5)", FCVAR_NOTIFY);
    g_cvMeleeRate = CreateConVar("hr_melee_rate", "1.0", "近战击杀提供回血倍率(推荐1.2)", FCVAR_NOTIFY);
    g_cvFarDistance = CreateConVar("hr_far_distance", "550.0", "多远会被判定为远距离", FCVAR_NOTIFY);
    g_cvFarRate = CreateConVar("hr_far_rate", "1.0", "远距离击杀提供的回血倍率(推荐1.5)", FCVAR_NOTIFY);
    g_cvDangerRate = CreateConVar("hr_danger_rate", "1.0", "危险击杀提供的回血倍率(推荐2.0)", FCVAR_NOTIFY);
    g_cvHeadShotRate = CreateConVar("hr_headshot_rate", "1.0", "爆头击杀提供的回血倍率(推荐2.0)", FCVAR_NOTIFY);

    g_cvMaxHealth = CreateConVar("hr_max_health", "100", "最大生命值", FCVAR_NOTIFY, true, 1.0);

    g_cvReturnType.AddChangeHook(OnConVarChanged);
    g_cvSafeRoomNaps.AddChangeHook(OnConVarChanged);
    
    g_cvBaseReturn.AddChangeHook(OnConVarChanged);
    g_cvSkillRate.AddChangeHook(OnConVarChanged);
    g_cvMeleeRate.AddChangeHook(OnConVarChanged);
    g_cvFarDistance.AddChangeHook(OnConVarChanged);
    g_cvFarRate.AddChangeHook(OnConVarChanged);
    g_cvDangerRate.AddChangeHook(OnConVarChanged);
    g_cvHeadShotRate.AddChangeHook(OnConVarChanged);      

    g_cvMaxHealth.AddChangeHook(OnConVarChanged);

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("map_transition", Event_MapTransition);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);

    //AutoExecConfig(true, "health_return");
}

public void OnConfigsExecuted(){
    GetCvars();
}

void GetCvars(){
    g_bReturnType = g_cvReturnType.BoolValue;
    g_iSafeRoomNaps = g_cvSafeRoomNaps.IntValue;

    g_fBaseReturn = g_cvBaseReturn.FloatValue;
    g_fSkill = g_cvSkillRate.FloatValue;
    g_fMelee = g_cvMeleeRate.FloatValue;
    g_fFarDistance = g_cvFarDistance.FloatValue;
    g_fFar = g_cvFarRate.FloatValue;
    g_fDanger = g_cvDangerRate.FloatValue;
    g_fHeadShot = g_cvHeadShotRate.FloatValue;

    g_iMaxHealth = g_cvMaxHealth.IntValue;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
    GetCvars();
}
//===============================================================
//=                         event
//===============================================================
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
    SafeRoomNap();
}

void Event_MapTransition(Event event, const char[] name, bool dontBroadcast){
    SafeRoomNap();
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast){
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsZombieClassSI(client))
        g_bIsSkillKill[client] = false;
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast){
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if(IsZombieClassSI(victim) && IsValidSur(attacker) && IsPlayerAlive(attacker) && !GetEntProp(attacker, Prop_Send, "m_isIncapacitated")){
        int dmg = event.GetInt("dmg_health");
        int remainHealth = GetClientHealth(victim);
        int iClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
        //伤害大于剩余血量
        if(dmg >= remainHealth){
            g_bIsSkillKill[victim] = IsSkillKill(victim, iClass) ? true : false;
        }
    }
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast){
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if(IsZombieClassSI(victim) && IsValidSur(attacker) && IsPlayerAlive(attacker) && !GetEntProp(attacker, Prop_Send, "m_isIncapacitated")){
        //int iClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
        //PrintToChatAll("check");
        int type = event.GetInt("type");
        float fPos1[3], fPos2[3];
        fPos1[0] = event.GetFloat("victim_x");
        fPos1[1] = event.GetFloat("victim_y");
        fPos1[2] = event.GetFloat("victim_z");
        GetClientAbsOrigin(attacker, fPos2);
        float fDistance = GetVectorDistance(fPos1, fPos2);
        float fHealth = float(GetEntProp(attacker, Prop_Data, "m_iHealth")) + GetEntPropFloat(attacker, Prop_Send, "m_healthBuffer");
        //PrintToChatAll("check2");
        
        bool bSkill = g_bIsSkillKill[victim];
        bool bMelee = (type & DMG_SLASH) || (type & DMG_CLUB) ? true : false;
        bool bFar = fDistance > g_fFarDistance ? true : false;
        bool bDanger = (fDistance < 70.0) && (fHealth < 40.0) ? true : false;
        bool bHeadShot = event.GetBool("headshot");
        
        ReturnHealthToPlayer(attacker, bSkill, bMelee, bFar, bDanger, bHeadShot);
    }
}

//===============================================================
//=                        saferoomnap
//===============================================================
void SafeRoomNap(){
    float safeNaps;
    if(g_iSafeRoomNaps == 0)
        return;
    safeNaps = float(g_iSafeRoomNaps);
    for(int client = 1; client <= MaxClients; client++){
        if(IsValidSur(client) && IsPlayerAlive(client) && (L4D_IsInFirstCheckpoint(client) || L4D_IsInLastCheckpoint(client))){
            //int iMaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
            int realHealth = GetEntProp(client, Prop_Data, "m_iHealth");
            float fakeHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
            float allHealth = float(realHealth) + fakeHealth;
            //解除倒地状态与黑白
            CheatCommand(client, "give", "health");
            //总血量低于回复血量
            if(allHealth < safeNaps){
                SetEntProp(client, Prop_Data, "m_iHealth", RoundToCeil(safeNaps));
                SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
            }
            else{
                //总血量高于回复血量但实血低于回复血量
                //要保证实血为回复血量且总血量不变
                if(float(realHealth) < safeNaps){
                    SetEntProp(client, Prop_Data, "m_iHealth", RoundToCeil(safeNaps));
                    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fakeHealth - allHealth + safeNaps);
                }
            }
        }
    }
}

//===============================================================
//=                         return health
//===============================================================
/**
 * @brief 回复玩家血量
 * 
 * @param client        玩家对应索引
 * @param IsSkill       技巧击杀(完成空爆，截停，自救)
 * @param IsMelee       近战击杀(完成近战击杀)
 * @param IsFar         远程击杀(完成远距离击杀)
 * @param IsDanger      危险击杀(完成中低血量超近距离击杀)
 * @param IsHeadShot    爆头击杀
 * @noreturn
 */
void ReturnHealthToPlayer(int client, bool IsSkill, bool IsMelee, bool IsFar, bool IsDanger, bool IsHeadShot){
    float healthReturn = g_fBaseReturn;
    if(IsSkill){
        healthReturn = healthReturn * g_fSkill;
        //PrintToChatAll("技巧击杀");
    }
    if(IsMelee){
        healthReturn = healthReturn * g_fMelee;
        //PrintToChatAll("近战击杀");
    }
    if(IsFar){
        healthReturn = healthReturn * g_fFar;
        //PrintToChatAll("远距离击杀");
    }
    if(IsDanger){
        healthReturn = healthReturn * g_fDanger;
        //PrintToChatAll("危险击杀");
    }
    if(IsHeadShot){
        healthReturn = healthReturn * g_fHeadShot;
        //PrintToChatAll("爆头击杀");
    }

    float realHealth = float(GetEntProp(client, Prop_Data, "m_iHealth"));
    float fakeHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    float allHealth = realHealth + fakeHealth;
    float hpLimit = float(g_iMaxHealth);
    //回血后总血量小于上限
    if(allHealth + healthReturn <= hpLimit){
        if(g_bReturnType){
            //float newFakeHP = fakeHealth + healthReturn;
            SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fakeHealth + healthReturn);
	        SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
        }
        else{
            SetEntProp(client, Prop_Data, "m_iHealth", RoundToCeil(realHealth + healthReturn));
        }
    }
    else if(allHealth <= hpLimit){
        if(g_bReturnType){
            SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fakeHealth + hpLimit - allHealth);
	        SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
        }
        else{
            if(realHealth + healthReturn <= hpLimit){
                SetEntProp(client, Prop_Data, "m_iHealth", RoundToCeil(realHealth + healthReturn));
                SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fakeHealth + allHealth + healthReturn - hpLimit);
            }
            else{
                SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
                SetEntProp(client, Prop_Data, "m_iHealth", RoundToCeil(hpLimit));
            }
        }
    }
}

bool IsSkillKill(int client, int class){
    if(!IsValidSI(client))
        return false;
    switch(class){
        case 1:{
            return GetEntPropEnt(client, Prop_Send, "m_tongueVictim") > 0;
        }
        case 3:{
            return GetEntProp(client, Prop_Send, "m_isAttemptingToPounce") != 0;
        }
        case 5:{
            return IsJockeyLeaping(client);
        }
        case 6:{
            return IsCharging(client);
        }
    }
    return false;
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
