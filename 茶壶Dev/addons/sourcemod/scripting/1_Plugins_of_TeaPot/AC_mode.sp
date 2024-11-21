#pragma semicolon 1
#pragma newdecls required

#include <left4dhooks>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <l4d2util>

public Plugin myinfo =
{
	name	= "AC Mode",
	author	= "MopeCup",
	version = "1.0.0",
};

#include "ac_mode/global.sp"
#include "ac_mode/api.sp"

public void OnPluginStart(){
    g_cvServerName = CreateConVar("ac_mode_server_name", "茶壶", "设置显示在panel上的服名，因为我太懒了");
    g_cvServerName.AddChangeHook(OnConVarChanged);

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("mission_lost", Event_MissionLost);
    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("map_transition", Event_MapTransition);

    //准备与取消准备
    RegConsoleCmd("sm_ready", Cmd_Ready);
    RegConsoleCmd("sm_r", Cmd_Ready);
    RegConsoleCmd("sm_unready", Cmd_UnReady);
    RegConsoleCmd("sm_ur", Cmd_UnReady);
    //关闭与显示面板
    RegConsoleCmd("sm_show", Cmd_ShowHud);
    RegConsoleCmd("sm_hide", Cmd_UnShowHud);
    //旁观面板
    RegConsoleCmd("sm_spechud", Cmd_SpecHud);
    //强制开始
    RegAdminCmd("sm_forcestart", Cmd_ForceReady, ADMFLAG_GENERIC);
    RegAdminCmd("sm_fs", Cmd_ForceReady, ADMFLAG_GENERIC);

    //RegConsoleCmd("sm_te", Cmd_te);
}

public void OnConfigsExecuted(){
    g_cvMaxPlayers = FindConVar("sv_maxplayers");
    g_cvGod = FindConVar("god");
    PrecacheSound(SOUND_COUNTDOWN, false);
    PrecacheSound(SOUND_START, false);
    GetCvars();
}

public void OnMapStart(){
    InitPlugins();
}

public void OnMapEnd(){
    //InitPlugins();
    if(g_hSpecHudpanel != null)
        delete g_hSpecHudpanel;
    if(g_hReadyUppanel != null)
        delete g_hReadyUppanel;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
    GetCvars();
}

void GetCvars(){
    g_cvServerName.GetString(g_sServerName, sizeof g_sServerName);
}

#include "ac_mode/cmd.sp"
#include "ac_mode/event.sp"
#include "ac_mode/timer.sp"
#include "ac_mode/readyup.sp"
#include "ac_mode/spechud.sp"
#include "ac_mode/subfunction.sp"