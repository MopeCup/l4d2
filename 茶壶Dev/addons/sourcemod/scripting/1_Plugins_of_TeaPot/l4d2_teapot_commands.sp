#include <sourcemod>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "l4d2 teapot commands",
	author = "MopeCup",
	description = "提供一系列指令",
	version = "1.1.0",
	url = ""
}

public void OnPluginStart(){
    //闲置
    RegConsoleCmd("sm_s", Cmd_Afk, "快速闲置");
    RegConsoleCmd("sm_afk", Cmd_Afk, "快速闲置");
    RegConsoleCmd("sm_AFK", Cmd_Afk, "快速闲置");
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
    if(!IsClientAndInGame(client) || GetClientTeam(client) != 2){
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
    L4D_GoAwayFromKeyboard(client);
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

bool IsClientAndInGame(int client){
    if(IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client))
        return true;
    return false;
}