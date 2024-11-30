#include <sourcemod>
#include <left4dhooks>
#include <l4d2_nativevote>
#include "cup/cup_function.sp"

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "l4d2 teapot commands",
	author = "MopeCup",
	description = "提供一系列指令",
	version = "1.3.0",
	url = ""
}

public void OnPluginStart(){
    //闲置
    RegConsoleCmd("sm_s", Cmd_Afk, "快速闲置");
    RegConsoleCmd("sm_afk", Cmd_Afk, "快速闲置");
    RegConsoleCmd("sm_AFK", Cmd_Afk, "快速闲置");
    //旁观
    RegConsoleCmd("sm_spec", Cmd_Spec, "旁观");
    RegConsoleCmd("sm_away", Cmd_Spec, "旁观");
    //开位
    RegConsoleCmd("sm_slot", Cmd_Slot, "开位");

    //Lazer
    RegAdminCmd("sm_lazer", Cmd_Lazer, ADMFLAG_GENERIC, "获取镭射");
    RegAdminCmd("sm_ls", Cmd_Lazer, ADMFLAG_GENERIC, "获取镭射");
    //Cvar
    RegAdminCmd("sm_addcvar", Cmd_Cvar, ADMFLAG_GENERIC, "修改Cvar");

    AddCommandListener(Afk_Command, "go_away_from_keyboard");
}

//=============================================================================
//=                             快速闲置
//=============================================================================
Action Cmd_Afk(int client, int args){
    RequestFrame(OnNextFrame_AfkCmd, GetClientUserId(client));

    return Plugin_Handled;
}

void OnNextFrame_AfkCmd(int client){
    client = GetClientOfUserId(client);
    if(!client || !IsClientAndInGame(client) || GetClientTeam(client) != 2){
        //PrintToChatAll("[Test] 不满足闲置条件");
        return;
    }
    
    // int flags = GetCommandFlags("go_away_from_keyboard");
    // SetCommandFlags("go_away_from_keyboard", flags & ~FCVAR_CHEAT);
    L4D_GoAwayFromKeyboard(client);
    //SetCommandFlags("go_away_from_keyboard", flags|FCVAR_CHEAT);
}

Action Afk_Command(int client, const char[] command, int args){
    if(!IsClientAndInGame(client) || GetClientTeam(client) != 2)
        return Plugin_Handled;
    //换用left4dhooks的闲置函数，解决倒地不能闲置的问题
    //L4D_GoAwayFromKeyboard(client);
    RequestFrame(OnNextFrame_AfkCmd, GetClientUserId(client));
    return Plugin_Handled;
}

//=============================================================================
//=                             Cvar
//=============================================================================
Action Cmd_Cvar(int client, int args){
    if(!args){
        ReplyToCommand(client, "!addcvar <ConVar> <Val>");
        return Plugin_Handled;
    }

    char sCvarName[64], sVal[32];
    GetCmdArg(1, sCvarName, sizeof sCvarName);
    GetCmdArg(2, sVal, sizeof sVal);
    ChangeServerCvar(sCvarName, sVal);
    return Plugin_Handled;
}

void ChangeServerCvar(const char[] cvarName, const char[] val){
    ConVar conVar = FindConVar(cvarName);
    if(conVar == null){
        PrintToServer("unable to find convar %s", cvarName);
        return;
    }
    conVar.SetString(val);
}

//=============================================================================
//=                            Spec
//=============================================================================
Action Cmd_Spec(int client, int args){
    if(IsClientInGame(client) && !IsFakeClient(client) && client <= MaxClients && client > 0){
        if(GetClientTeam(client) == 1){
            ReplyToCommand(client, "你已在旁观队伍或取消闲置在输入此指令");
            return Plugin_Handled;
        }
        ChangeClientTeam(client, 1);
    }
    return Plugin_Handled;
}

//=============================================================================
//=                            Slot
//=============================================================================
Action Cmd_Slot(int client, int args){
    char sVal[2];
    GetCmdArg(1, sVal, sizeof sVal);
    if(strlen(sVal) == 0){
        ReplyToCommand(client, "!slot <slotnum>");
        return Plugin_Handled;
    }
    StartSlotVote(client, sVal);
    return Plugin_Handled;
}

void StartSlotVote(int client, const char[] sVal){
    if (!L4D2NativeVote_IsAllowNewVote()) {
        PrintToChat(client, "投票正在进行中，暂不能发起新的投票");
        return;
    }
    L4D2NativeVote slotVote = L4D2NativeVote(SlotVote_Handler);
    slotVote.SetDisplayText("修改slot为%s", sVal);
    slotVote.Initiator = client;
    slotVote.SetInfoString(sVal);

    int iPlayerCount = 0;
    int[] iClients = new int[MaxClients];
    for(int i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i) && !IsFakeClient(i)){
            if(GetClientTeam(i) == 2 || GetClientTeam(i) == 3)
                iClients[iPlayerCount++] = i;
        }
    }
    if(!slotVote.DisplayVote(iClients, iPlayerCount, 20))
        LogError("发起投票失败");
}

void SlotVote_Handler(L4D2NativeVote vote, VoteAction action, int param1, int param2){
    switch(action){
        case VoteAction_Start:{
            PrintToChatAll("\x04[SlotVote] \x05%N\x01发起了一个投票", param1);
        }
        case VoteAction_PlayerVoted:{
            PrintToChatAll("\x04[SlotVote] \x05%N\x01已投票", param1);
        }
        case VoteAction_End:{
            if(vote.YesCount > vote.PlayerCount/2){
                vote.SetPass("加载中...");
                char sVal[2];
                vote.GetInfoString(sVal, sizeof sVal);
                ChangeServerCvar("sv_maxplayers", sVal);

                PrintToChatAll("\x04[SlotVote] \x01已修改slot为\x05%s", sVal);
            }
            else{
                vote.SetFail();
            }
        }
    }
}

//=============================================================================
//=                         Lazer
//=============================================================================
Action Cmd_Lazer(int client, int args){
    if(!IsClientAndInGame(client))
        return Plugin_Handled;
    CheatCommand(client, "upgrade_add", "laser_sight");
    return Plugin_Handled;
}

bool IsClientAndInGame(int client){
    if(IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client))
        return true;
    return false;
}