#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "L4D2 Kill Special Announce",
	author = "MopeCup",
	description = "击杀特感提示",
	version = "1.0.0",
	url = ""
}

//================================================================================
//=                                 Global
//================================================================================
#define PLUGIN_FLAG FCVAR_SPONLY|FCVAR_NOTIFY
#define SOUND_HEADSHOT "level/bell_normal.wav"
#define SOUND_HEADSHOT_B "level/bell_impact.wav"
#define SOUND_KILLSHOT "ui/littlereward.wav"

ConVar g_cvKillSound, g_cvMultiKillHint, g_cvKillPrint;

bool g_bKillSound, g_bMultiKillHint, g_bKillPrint;

int g_iMultiKill[MAXPLAYERS + 1], g_iKillSI[MAXPLAYERS + 1];

Handle g_hMultiKill[MAXPLAYERS + 1];

public void OnPluginStart(){
    g_cvKillSound = CreateConVar("lksa_kill_sound", "1", "是否开启击杀特感音效<0: 否, 1: 是>", PLUGIN_FLAG, true, 0.0, true, 1.0);
    g_cvMultiKillHint = CreateConVar("lksa_multikill_hint", "1", "是否开启连杀提示<0: 否, 1: 是>", PLUGIN_FLAG, true, 0.0, true, 1.0);
    g_cvKillPrint = CreateConVar("lksa_kill_print", "1", "是否开启击杀播报<0: 否, 1: 是>", PLUGIN_FLAG, true, 0.0, true, 1.0);

    GetCvars();
    g_cvKillSound.AddChangeHook(OnConVarChanged);
    g_cvMultiKillHint.AddChangeHook(OnConVarChanged);
    g_cvKillPrint.AddChangeHook(OnConVarChanged);

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
    HookEvent("jockey_ride", Event_InterruptCombo, EventHookMode_Post);
    HookEvent("lunge_pounce", Event_InterruptCombo, EventHookMode_Post);
    HookEvent("charger_carry_start", Event_InterruptCombo, EventHookMode_Post);
	HookEvent("tongue_grab", Event_InterruptCombo, EventHookMode_Post);

    PrecacheSound(SOUND_HEADSHOT, false);
    PrecacheSound(SOUND_HEADSHOT_B, false);
    PrecacheSound(SOUND_KILLSHOT, false);
}

//================================================================================
//=                               Cvars
//================================================================================
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
    GetCvars();
}

void GetCvars(){
    g_bKillSound = g_cvKillSound.BoolValue;
    g_bMultiKillHint = g_cvMultiKillHint.BoolValue;
    g_bKillPrint = g_cvKillPrint.BoolValue;
}

//================================================================================
//=                              初始化
//================================================================================
public void OnMapStart(){
    ResetPlugin();
}

public void OnMapEnd(){
    ResetPlugin();
}

//================================================================================
//=                              Event
//================================================================================
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
    OnMapStart();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
    OnMapEnd();
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast){
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim = GetClientOfUserId(event.GetInt("userid"));
    // if(!IsValidClient(attacker) || !IsValidClient(victim))
    //     return;
    //PrintToChat(attacker, "a!");
    if(!IsValidSur(attacker) || !IsValidSI(victim))
        return;
    bool bHeadShot = event.GetBool("headshot");
    g_iKillSI[attacker] += 1;
    //播报击杀
    if(g_bKillPrint)
        PrintToChat(attacker, "击杀 %N (%d)", victim, g_iKillSI[attacker]);

    if(g_bKillSound || g_bMultiKillHint){
        //首次击杀
        if(g_iMultiKill[attacker] == 0){
            g_iMultiKill[attacker] += 1;
            g_hMultiKill[attacker] = CreateTimer(10.0, Timer_MKLateCheck, GetClientUserId(attacker));
        }
        else if(g_iMultiKill[attacker] <= 9){
            g_iMultiKill[attacker] += 1;
            KillTimer(g_hMultiKill[attacker]);
            g_hMultiKill[attacker] = CreateTimer(10.0, Timer_MKLateCheck, GetClientUserId(attacker));
        }

        //声音播放
        if(g_bKillSound){
            if(g_iMultiKill[attacker] < 5){
                if(bHeadShot)
                    EmitSoundToClient(attacker, SOUND_HEADSHOT, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
                else{
                    //float fVol = RoundFloat(g_iMultiKill[attacker]) > 0.0 ? RoundFloat(g_iMultiKill[attacker]) : 1.0;
                    EmitSoundToClient(attacker, SOUND_KILLSHOT, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
                }
            }
            else{
                EmitSoundToClient(attacker, SOUND_HEADSHOT_B, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
            }
        }

        //Hint
        if(g_bMultiKillHint){
            switch(g_iMultiKill[attacker]){
                case 1:{
                    PrintCenterText(attacker, "首杀");
                }
                case 2:{
                    PrintCenterText(attacker, "双杀");
                }
                case 3:{
                    PrintCenterText(attacker, "三连杀!");
                }
                case 4:{
                    PrintCenterText(attacker, "四连杀!!");
                }
                case 5:{
                    PrintCenterText(attacker, "五连杀!!!");
                }
                case 6, 7:{
                    PrintCenterText(attacker, "超神!!!");
                }
                case 8, 9:{
                    PrintCenterText(attacker, "无双! 万军取首");
                }
            }
        }
    }
}

void Event_InterruptCombo(Event event, const char[] name, bool dontBroadcast){
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));
    if(IsValidSI(attacker) && IsValidSur(victim)){
        if(g_iMultiKill[victim] != 0){
            KillTimer(g_hMultiKill[victim]);
            g_iMultiKill[victim] = 0;
        }
    }
}

//================================================================================
//=                             Timer
//================================================================================
Action Timer_MKLateCheck(Handle timer, int userid){
    int client = GetClientOfUserId(userid);
    if(IsValidSur(client)){
        g_iMultiKill[client] = 0;
    }
    return Plugin_Stop;
}

//================================================================================
//=                             子函数
//================================================================================
bool IsValidClient(int client){
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool IsValidSur(int client){
    return IsValidClient(client) && GetClientTeam(client) == 2;
}

bool IsValidSI(int client){
    return IsValidClient(client) && GetClientTeam(client) == 3 && IsZombieClassSI(client);
}

bool IsZombieClassSI(int client){
    return (GetEntProp(client, Prop_Send, "m_zombieClass") == 6 || GetEntProp(client, Prop_Send, "m_zombieClass") == 5 || 
        GetEntProp(client, Prop_Send, "m_zombieClass") == 4 || GetEntProp(client, Prop_Send, "m_zombieClass") == 3 || 
        GetEntProp(client, Prop_Send, "m_zombieClass") == 2 || GetEntProp(client, Prop_Send, "m_zombieClass") == 1);
}

void ResetPlugin(){
    for(int i = 1; i <= MaxClients; i++){
        g_iKillSI[i] = 0;
        g_iMultiKill[i] = 0;
    }
}