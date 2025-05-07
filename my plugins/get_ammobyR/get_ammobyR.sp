//锁定新语法
#pragma semicolon 1

//包含的库文件
#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <l4d2util>
#include <l4d2_weapons_spawn> // https://github.com/fdxx/l4d2_plugins/blob/main/include/l4d2_weapons_spawn.inc

/*
2024.8.1
    1.1.0 - 新增了距离判定，现在仅仅在100码的距离内可以获取弹药，并修改提示形式为提示文字
2025.4.4
    1.2.0 - 修改了获取弹药的形式
*/

//插件信息
public Plugin myinfo =
{
    name		= "get_ammobyR",
    author		= "MopeCup",
    description	= "玩家可以通过对武器按R获取备弹",
    version		= "1.2.0"
};

//变量
bool SoundPrompt = true;
Handle g_hSDKGiveDefaultAmmo;

//插件开始
public void OnPluginStart(){
    PrecacheSound("player/suit_denydevice.wav");
    InitSDKCall();
}

void InitSDKCall()
{
    Handle configFile = LoadGameConfigFile("get_ammobyR");
    if (configFile == null)
        SetFailState("missing gamedata get_ammobyR.txt");
    StartPrepSDKCall(SDKCall_Entity);
    if (!PrepSDKCall_SetFromConf(configFile, SDKConf_Signature, "CWeaponAmmoSpawn_Use"))
        SetFailState("gamedata missing signature CWeaponAmmoSpawn_Use");
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    g_hSDKGiveDefaultAmmo = EndPrepSDKCall();
    if (g_hSDKGiveDefaultAmmo == null)
        SetFailState("failed to finish SDKCall setup CWeaponAmmoSpawn_Use");
    delete configFile;
}

//给予玩家弹药 -- 来自 r7ws 的 weapon_lock.sp
// void ammo_give(int client)
// {
//     int flags = GetCommandFlags("give");
//     SetCommandFlags("give", flags & ~FCVAR_CHEAT);
//     FakeClientCommand(client, "give ammo");
//     SetCommandFlags("give", flags|FCVAR_CHEAT);
// }

//玩家对武器使用换弹时获取弹药
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]){
    if(buttons & IN_RELOAD == IN_RELOAD){
        if(!IsValidPlayer(client) || !IsPlayerAbleToGetAmmo(client) || !SoundPrompt)
            return Plugin_Continue;

        //ammo_give(client);
        GiveDefaultAmmo(client);
        // //获取武器的索引
        // int weapon_id = GetClientAimTarget(client, false);
        // float fWeaponPos[3], fWeaponAng[3];
        // GetEntPropVector(weapon_id, Prop_Data, "m_vecAbsOrigin", fWeaponPos);
        // GetEntPropVector(weapon_id, Prop_Data, "m_angRotation", fWeaponAng);

        // RemoveEntity(weapon_id);

        // //替换为弹药堆
        // L4D2Wep_Spawn("weapon_ammo_spawn", fPos, fAng, 1, MOVETYPE_NONE);

        // buttons = IN_USE | IN_RELOAD;
        // GiveDefaultAmmo(client);
        // RequestFrame(OnNextFrame_GetBackWeapon, weapon_id);

        //播放音频
        if (!IsSoundPrecached("player/suit_denydevice.wav")) {
 			PrecacheSound("player/suit_denydevice.wav", false);
		}
        EmitSoundToClient(client, "player/suit_denydevice.wav");
        //PrintHintText(client, "弹药已补充");
        SoundPrompt = false;
        CreateTimer(5.0, Timer_Lags, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    return Plugin_Continue;
}

void GiveDefaultAmmo(int client)
{
    SDKCall(g_hSDKGiveDefaultAmmo, 0, client);
}

//音频播放后五秒内不会再播放
public Action Timer_Lags(Handle timer){
    SoundPrompt = true;
    return Plugin_Stop;
}

//检验是否是可以获取弹药的玩家
bool IsValidPlayer(int client){
    if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
        return true;
    return false;
}

//检验玩家是否看着武器
bool IsPlayerAbleToGetAmmo(int client){
    int weapon_id;
    int weapon_name;
    weapon_id = GetClientAimTarget(client, false);
    weapon_name= IdentifyWeapon(weapon_id);

    //我们选择先检查是否可以获取武器，再检查距离是否足够近
    //也许能缓解本地服务器炸var和sv的问题
    if(!IsItGun(weapon_name))
        return false;

    float fPlayerPos[3], fWeaponPos[3];
    GetClientAbsOrigin(client, fPlayerPos);
    GetEntPropVector(weapon_id, Prop_Data, "m_vecAbsOrigin", fWeaponPos);
    float distance = GetVectorDistance(fPlayerPos, fWeaponPos);
    //CPrintToChat(client, "{lightgreen}是%d", weapon_name);
    if((distance > 100.0))
        return false;

    return true;
}

bool IsItGun(int w_name){
    if(
        w_name == 2 || w_name == 7 || w_name == 33 ||
        w_name == 3 || w_name == 8 || w_name == 11 || w_name == 4 ||
        w_name == 6 || w_name == 10 || w_name == 36 || w_name == 35 ||
        w_name == 9 || w_name == 34 || w_name == 5 || w_name == 26
    )
        return true;
    return false;
}