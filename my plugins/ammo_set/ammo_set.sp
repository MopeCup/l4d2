#pragma semicolon 1
#pragma newdecls required

#include <left4dhooks>

//插件信息
public Plugin myinfo =
{
    name		= "Ammo Set",
    author		= "MopeCup",
    description	= "设置弹药",
    version		= "1.0.1"
};

//========================================================
//=                     Global
//========================================================
#define PLUGIN_FLAG FCVAR_SPONLY|FCVAR_NOTIFY

ConVar g_cvInfiniteAmmoType, g_cvSafeArea;

int g_iInfinitAmmoType;

bool g_bSafeArea, g_bPlayerLeftSafeArea;

//========================================================
//=                    Main
//========================================================
public void OnPluginStart(){
    g_cvInfiniteAmmoType = CreateConVar("as_infinite_ammo_type", "0", "弹药设置类型<0: 正常, 1: 无限备弹, 2: 无限子弹>", PLUGIN_FLAG, true, 0.0, true, 2.0);
    g_cvSafeArea = CreateConVar("as_safearea_infinite_ammo", "1", "初次离开安全区域前是否无限子弹<0: 否, 1: 是>", PLUGIN_FLAG, true, 0.0, true, 1.0);

    g_cvInfiniteAmmoType.AddChangeHook(OnConVarChange);
    g_cvSafeArea.AddChangeHook(OnConVarChange);
    GetCvars();

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("player_left_safe_area", Event_PlayerLeftSafeArea);
    HookEvent("weapon_fire", Event_WeaponFire);
    HookEvent("weapon_reload", Event_WeaponReload);
}

//========================================================
//=                   Cvar
//========================================================
void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue){
    GetCvars();
}

void GetCvars(){
    g_iInfinitAmmoType = g_cvInfiniteAmmoType.IntValue;
    g_bSafeArea = g_cvSafeArea.BoolValue;
}

//========================================================
//=                     Map
//========================================================
public void OnMapStart(){
    g_bPlayerLeftSafeArea = false;
}

public void OnMapEnd(){
    g_bPlayerLeftSafeArea = false;
}

//========================================================
//=                     Event
//========================================================
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
    OnMapStart();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
    OnMapEnd();
}

void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast){
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!g_bPlayerLeftSafeArea && IsValidSur(client) && IsPlayerAlive(client))
        g_bPlayerLeftSafeArea = !g_bPlayerLeftSafeArea;
}

void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast){
    int client = GetClientOfUserId(event.GetInt("userid"));
    int weaponID = event.GetInt("weaponid");
    if(IsValidSur(client) && (g_iInfinitAmmoType == 2 || (g_bSafeArea && !g_bPlayerLeftSafeArea))){
        SetClips(client, weaponID);
    }
}

void Event_WeaponReload(Event event, const char[] name, bool dontBroadcast){
    int client = GetClientOfUserId(event.GetInt("userid"));
    

    if(IsValidSur(client) && g_iInfinitAmmoType == 1){
        GiveClientAmmo(client);
    }
}

//========================================================
//=                     Function
//========================================================
void GiveClientAmmo(int client){
    int flags = GetCommandFlags("give");
    SetCommandFlags("give", flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "give ammo");
    SetCommandFlags("give", flags|FCVAR_CHEAT);
}

void SetClips(int client, int weaponID){
    int weapon = GetPlayerWeaponSlot(client, 0);
    int subWeapon = GetPlayerWeaponSlot(client, 1);
    char class[56], subClass[56];
    if(weapon != INVALID_ENT_REFERENCE){
        GetEdictClassname(weapon, class, sizeof class);
        if(L4D_GetWeaponID(class) == weaponID)
            SetEntProp(weapon, Prop_Send, "m_iClip1", L4D2_GetIntWeaponAttribute(class, L4D2IWA_ClipSize) + 1);
    }
    if(subWeapon != INVALID_ENT_REFERENCE){
        GetEdictClassname(subWeapon, subClass, sizeof subClass);
        if(L4D_GetWeaponID(subClass) == weaponID && (weaponID == 1 || weaponID == 32))
            SetEntProp(subWeapon, Prop_Send, "m_iClip1", L4D2_GetIntWeaponAttribute(subClass, L4D2IWA_ClipSize) + 1);
    }
}

//========================================================
//=                     子函数
//========================================================
bool IsValidClient(int client){
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool IsValidSur(int client){
    return IsValidClient(client) && GetClientTeam(client) == 2;
}