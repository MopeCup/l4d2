#include <l4d2_nativevote>
#include <cup_function>
#include <multicolors>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define MODE_NAME_PATH "configs/hostname/gamemode.txt"

char sPath[128];

public Plugin myinfo = {
	name = "Change Gamemode",
	author = "MopeCup",
	description = "投票更改游戏模式",
	version = "1.0.0",
	url = ""
}

public void OnPluginStart() {
    BuildPath(Path_SM, sPath, sizeof sPath, MODE_NAME_PATH);
    if (!FileExists(sPath)) {
        LogError("can't find file in %s", sPath);
    }

    RegConsoleCmd("sm_votemode", Cmd_VoteMode);
    RegConsoleCmd("sm_vm", Cmd_VoteMode);
}

//sm_restartmap
Action Cmd_VoteMode(int client, int args) {
    if (!args) {
        BuildModeMenu(client);
        return Plugin_Handled;
    }
    char gameMode[64];
    GetCmdArg(1, gameMode, sizeof gameMode);
    StartModeVote(client, gameMode, gameMode);
    return Plugin_Handled;
}

void BuildModeMenu(int client) {
    if (GetClientOfIdlePlayer(client) == -1 && IsValidSpec(client)) {
        CPrintToChat(client, "{orange}[VM] {blue}旁观者不允许发起投票");
        return;
    }
    Menu modeMenu = new Menu(ModeMenu_Handler);
    modeMenu.SetTitle("选择游戏模式\n—————————————");
    KeyValues kv = new KeyValues("ModeName");
    if (!kv.ImportFromFile(sPath))
		ThrowError("Failed to import %s file into KeyValues", sPath);
    kv.Rewind();
    for (bool iter = kv.GotoFirstSubKey(); iter; iter = kv.GotoNextKey()) {
        char modeCode[64], modeName[128];
        kv.GetSectionName(modeCode, sizeof modeCode);
        kv.GetString("name", modeName, sizeof modeName);
        modeMenu.AddItem(modeCode, modeName);
    }
    modeMenu.Display(client, 20);
    delete kv;
}

int ModeMenu_Handler(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char modeCode[64], modeName[128];
            menu.GetItem(param2, modeCode, sizeof modeCode, _, modeName, sizeof modeName);
            StartModeVote(param1, modeCode, modeName);
        }
        case MenuAction_End: {
            delete menu;
        }
    }
    return 0;
}

void StartModeVote(int client, const char[] modeCode, const char[] modeName) {
    if (GetClientOfIdlePlayer(client) == -1 && IsValidSpec(client)) {
        CPrintToChat(client, "{orange}[VM] {blue}旁观者不允许发起投票");
        return;
    }
    if (!L4D2NativeVote_IsAllowNewVote()) {
        CPrintToChat(client, "{orange}[VM] {blue}发起投票失败，有一项投票正在进行中");
        return;
    }
    L4D2NativeVote vote = L4D2NativeVote(Vote_Handler);
    vote.SetDisplayText("更改游戏模式为: %s", modeName);
    vote.Initiator = client;
    vote.SetInfoString(modeCode);
    int count = 0;
    int[] clients = new int[MaxClients];
    for (int i = 1; i <= MaxClients; i++) {
        if (IsPlayerSur(i) || (IsValidSI(i) && !IsFakeClient(i)) || (GetClientOfIdlePlayer(i) != -1 && IsValidSpec(i)))
            clients[count++] = i;
    }
    if (!vote.DisplayVote(clients, count, 20))
        LogError("发起投票失败");
}

void Vote_Handler(L4D2NativeVote vote, VoteAction action, int param1, int param2) {
    switch (action) {
        case VoteAction_Start: {
            CPrintToChatAll("{orange}[VM] {olive}%N{blue}发起了一项投票", param1);
        }
        case VoteAction_PlayerVoted: {
            CPrintToChatAll("{orange}[VM] {olive}%N{blue}已投票", param1);
        }
        case VoteAction_End: {
            if (vote.YesCount > vote.PlayerCount/2) {
                vote.SetPass("加载中...");
                char modeCode[32];
                vote.GetInfoString(modeCode, sizeof modeCode);
                ChangePluginConVar("mp_gamemode", modeCode);
                CPrintToChatAll("{orange}[VM] {blue}游戏模式更改成功, 准备重启游戏");
                SlayAllPlayers();
            }
            else
                vote.SetFail();
        }
    }
}

void SlayAllPlayers() {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsValidSur(i))
            ForcePlayerSuicide(i);
    }
}