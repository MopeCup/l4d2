#include <sourcemod>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "l4d2 afk command",
	author = "MopeCup",
	description = "使用!s指令闲置",
	version = "1.0.1",
	url = ""
}

public void OnPluginStart(){
    RegConsoleCmd("sm_s", Cmd_Afk);
    RegConsoleCmd("sm_afk", Cmd_Afk);
    RegConsoleCmd("sm_AFK", Cmd_Afk);

    AddCommandListener(Afk_Command, "go_away_from_keyboard");
}

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

bool IsClientAndInGame(int client){
    if(IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client))
        return true;
    return false;
}