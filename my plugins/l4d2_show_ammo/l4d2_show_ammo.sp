#include <sourcemod>
#include <left4dhooks>
#include <l4d2util>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name	= "l4d2 show ammo",
	author	= "MopeCup",
	version = "1.0.0",

}

/*
2024.8.17 - 1.0.0
    插件创建
*/

ConVar cvMsgType;

public void OnPluginStart(){
    cvMsgType = CreateConVar("l4d2_show_ammo_msgtype", "2", "显示剩余弹药的方法(0 - 禁止, 1 - 聊天栏, 2 - 屏幕下方)", FCVAR_SPONLY);

    HookEvent("weapon_reload", Event_Reload);
}

//-----事件-----
//玩家进行换弹
void Event_Reload(Event event, const char[] name, bool dontBroadcast){
    int userid = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userid);

    //Bot和无效索引，返回
    if(IsFakeClient(client) || !IsValidSur(client))
        return;

    //进行播报
    RequestFrame(ReloadReport, userid);
}

//-----播报处理-----
void ReloadReport(int userid){
    int client = GetClientOfUserId(userid);
    //int weapon_index;
    int cweapon_index;

    // if(IsPlayerIncapacitated(client))
    //     weapon_index = GetPlayerWeaponSlot(client, 1);
    // else
    //     weapon_index = GetPlayerWeaponSlot(client, 0);
    cweapon_index = L4D_GetPlayerCurrentWeapon(client);

    //int weapon_id = IdentifyWeapon(weapon_index);
    int cweapon_id = IdentifyWeapon(cweapon_index);

    //当前持有武器为副武器或玩家倒地时,返回
    if(GetSlotFromWeaponId(cweapon_id) != 0 || IsPlayerIncapacitated(client))
        return;
    
    int iremainAmmo = L4D_GetReserveAmmo(client, cweapon_index);
    //PrintToChat(client, "%d", iremainAmmo);

    if(iremainAmmo > 999)
        RemainingAmmoReport(client, iremainAmmo);
    //L4D_GetReserveAmmo(int client, int weapon)
}

//播报
void RemainingAmmoReport(int client, int remainingAmmo){
    switch(GetConVarInt(cvMsgType)){
        case 0:
        {
            return;
        }
        case 1:
        {
            if((remainingAmmo - 999) > 100)
                PrintToChat(client, "[TS] 当前剩余弹药--> %d", remainingAmmo);
            else
                PrintToChat(client, "[TS] 当前剩余弹药--> %d, 低于999将不再播报", remainingAmmo);
        }
        case 2:
        {
            PrintHintText(client, "剩余弹药--> %d", remainingAmmo);
        }
    }
}

//-----Bool函数-----
//是否为有效索引
bool IsValidClient(int client){
    return client > 0 && client < MaxClients && IsClientInGame(client);
}

//是否为有效生还
bool IsValidSur(int client){
    return IsValidClient(client) && GetClientTeam(client) == 2;
}

//玩家是否处于倒地状态
bool IsPlayerIncapacitated(int client){
    if(!GetEntProp(client, Prop_Send, "m_isIncapacitated"))
        return false;

    return true;
}