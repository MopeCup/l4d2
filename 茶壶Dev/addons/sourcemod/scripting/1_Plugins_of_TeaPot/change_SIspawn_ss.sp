#include <sourcemod>
#include <l4d2_nativevote>
#include <multicolors>

#pragma semicolon 1

//======================================================================================
//=                                 Global
//======================================================================================
#define SYMBOL_SELECT "▶"

ConVar g_cvSICH[6];

bool g_bSpecialSpawner;

int g_iPlayerCH = -1, g_iPlayerSet[7], g_iSICH[6];

static const char g_sSpecialName[][] = {
	"", "Smoker", "Boomer", "Hunter", "Spitter", "Jockey", "Charger"
};

public Plugin:myinfo= {
	name = "change SIspawn ss",
	author = "MopeCup",
	description = "用于调控ss的特感种类",
	version = "1.0.0",
	url = ""
}

//======================================================================================
//=                                 Api
//======================================================================================
native int SS_GetSILimit();

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    MarkNativeAsOptional("SS_GetSILimit");

    return APLRes_Success;
}

public void OnAllPluginsLoaded() {
    g_bSpecialSpawner = LibraryExists("specialspawner");
}

public void OnLibraryAdded(const char[] sName) {
    if(StrEqual(sName, "specialspawner"))
        g_bSpecialSpawner = true;
}

public void OnLibraryRemoved(const char[] sName) {
    if(StrEqual(sName, "specialspawner"))
        g_bSpecialSpawner = false;
}

//======================================================================================
//=                                 Main
//======================================================================================
public void OnPluginStart() {
    RegConsoleCmd("sm_sich", Cmd_SICH);
}

Action Cmd_SICH(int client, int args) {
    if (!g_bSpecialSpawner) {
        ReplyToCommand(client, "请装载specialspawner插件");
        return Plugin_Handled;
    }

    ResetPlugin();
    g_iPlayerCH = 1;
    ShowMenuToClient(client);

    return Plugin_Handled;
}

void ShowMenuToClient(int client) {
    Menu SICHMenu = new Menu(MH_SICH);

    //面板名
    SICHMenu.SetTitle("特感面板");

    // //获取服务器名称
    // ConVar cvHostName;
    // cvHostName = FindConVar("hostname");
    char sBuffer[128];
    // if (cvHostName == null) {
    //     strcopy(sBuffer, sizeof sBuffer, "Left 4 Dead 2");
    // }
    // else {
    //     cvHostName.GetString(sBuffer, sizeof sBuffer);
    // }
    // SICHMenu.AddItem("server", sBuffer);

    //获取特感总数量
    Format(sBuffer, sizeof sBuffer, "当前特感数量: %d", SS_GetSILimit());
    SICHMenu.AddItem("sinum", sBuffer);

    //获取特感种类
    //SICHMenu.AddItem("sich", "特感种类分布");
    int iNewSICH;
    FindPluginCvar();
    for (int i = 0; i < 6; i++) {
        int j = i + 1;
        iNewSICH = (g_iSICH[i] + g_iPlayerSet[j]) > 0 ? (g_iSICH[i] + g_iPlayerSet[j]) : 0;
        if (g_iPlayerCH == j)
            Format(sBuffer, sizeof sBuffer, "%s %s: %d -> %d", SYMBOL_SELECT, g_sSpecialName[j], g_iSICH[i], iNewSICH);
        else
            Format(sBuffer, sizeof sBuffer, " %s: %d -> %d", g_sSpecialName[j], g_iSICH[i], iNewSICH);
        char info[32];
        Format(info, sizeof info, "s%d", j);
        SICHMenu.AddItem(info, sBuffer);
    }

    // SICHMenu.AddItem("c1", "下一项");
    // SICHMenu.AddItem("c2", "上一项");
    SICHMenu.AddItem("c3", "+1");
    SICHMenu.AddItem("c4", "-1");
    SICHMenu.AddItem("c5", "发起投票");

    SICHMenu.ExitButton = false;
    SICHMenu.Display(client, MENU_TIME_FOREVER);
}

public int MH_SICH(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_End) {
        // PrintToChatAll("hh");
        // ResetPlugin();
        CloseHandle(menu);
    }

    if (action != MenuAction_Select) {
        return 0;
    }
    
    char info[32];
    menu.GetItem(param2, info, sizeof info);
    if (StrEqual(info, "s1")) {
        g_iPlayerCH = 1;
        //CloseHandle(menu);
        ShowMenuToClient(param1);
        return 0;
    }

    if (StrEqual(info, "s2")) {
        g_iPlayerCH = 2;
        //CloseHandle(menu);
        ShowMenuToClient(param1);
        return 0;
    }

    if (StrEqual(info, "s3")) {
        g_iPlayerCH = 3;
        //CloseHandle(menu);
        ShowMenuToClient(param1);
        return 0;
    }

    if (StrEqual(info, "s4")) {
        g_iPlayerCH = 4;
        //CloseHandle(menu);
        ShowMenuToClient(param1);
        return 0;
    }

    if (StrEqual(info, "s5")) {
        g_iPlayerCH = 5;
        //CloseHandle(menu);
        ShowMenuToClient(param1);
        return 0;
    }

    if (StrEqual(info, "s6")) {
        g_iPlayerCH = 6;
        //CloseHandle(menu);
        ShowMenuToClient(param1);
        return 0;
    }

    if (StrEqual(info, "c3")) {
        g_iPlayerSet[g_iPlayerCH]++;
        //CloseHandle(menu);
        ShowMenuToClient(param1);
        return 0;
    }

    if (StrEqual(info, "c4")) {
        g_iPlayerSet[g_iPlayerCH]--;
        //CloseHandle(menu);
        ShowMenuToClient(param1);
        return 0;
    }

    if (StrEqual(info, "c5")) {
        for (int i = 1; i < 7; i++) {
            if (g_iPlayerSet[i] != 0) {
                StartVote(param1);
                return 0;
            }
        }
    }

    //CloseHandle(menu);
    ShowMenuToClient(param1);
    return 0;
}

void StartVote(int client) {
    if (!L4D2NativeVote_IsAllowNewVote()) {
        PrintToChat(client, "投票正在进行中，暂不能发起新的投票");
        return;
    }

    L4D2NativeVote vote = L4D2NativeVote(Vote_Handler);
    char buffer[128];
    int len;
    FindPluginCvar();
    for (int i = 0; i < 6; i++) {
        int j = i + 1;
        int iNewSICH = (g_iSICH[i] + g_iPlayerSet[j]) > 0 ? (g_iSICH[i] + g_iPlayerSet[j]) : 0;
        if (j == 1)
            Format(buffer, sizeof buffer, "%d;", iNewSICH);
        else if (j < 6) {
            len = strlen(buffer);
            Format(buffer[len], sizeof buffer - len, "%d;", iNewSICH);
        }
        else {
            len = strlen(buffer);
            Format(buffer[len], sizeof buffer - len, "%d", iNewSICH);
        }
    }
    vote.SetDisplayText("修改特感种类: %s ?", buffer);
    vote.Initiator = client;
    vote.SetInfoString(" ");
    
    int iPlayerCount = 0;
	int[] iClients = new int[MaxClients];

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			if (GetClientTeam(i) == 2 || GetClientTeam(i) == 3) {
				iClients[iPlayerCount++] = i;
			}
		}
	}

	if (!vote.DisplayVote(iClients, iPlayerCount, 20))
		LogError("发起投票失败");
}

void Vote_Handler(L4D2NativeVote vote, VoteAction action, int param1, int param2) {
    switch (action) {
		case VoteAction_Start: {
			CPrintToChatAll("{blue}[Vote] {olive}%N {default}发起了一个投票.", param1);
		}
		case VoteAction_PlayerVoted: {
			CPrintToChatAll("{olive}%N {default}已投票", param1);
		}
		case VoteAction_End: {
			if (vote.YesCount > vote.PlayerCount/2) {
				vote.SetPass("加载中...");

				//ConVar cvNewSICH[6];
                int iNewVal[6];
                FindPluginCvar();
                // cvNewSICH[0] = FindConVar("ss_smoker_limit");
                // cvNewSICH[1] = FindConVar("ss_boomer_limit");
                // cvNewSICH[2] = FindConVar("ss_hunter_limit");
                // cvNewSICH[3] = FindConVar("ss_spitter_limit");
                // cvNewSICH[4] = FindConVar("ss_jockey_limit");
                // cvNewSICH[5] = FindConVar("ss_charger_limit");
                for (int i = 0; i < 6; i++) {
                    int tempVal = g_iSICH[i] + g_iPlayerSet[i + 1];
                    iNewVal[i] = tempVal > 0 ? tempVal : 0;
                    SetConVarInt(g_cvSICH[i], iNewVal[i]);
                }
                CPrintToChatAll("更改成功");
                ResetPlugin();
			}
			else
				vote.SetFail();
		}
	}
}

//======================================================================================
//=                                 子函数
//======================================================================================
void ResetPlugin() {
    g_iPlayerCH = -1;
    int i = 1;
    for (i = 1; i < 7; i++) {
        g_iPlayerSet[i] = 0;
    }
}

void FindPluginCvar() {
    g_cvSICH[0] = FindConVar("ss_smoker_limit");
    g_cvSICH[1] = FindConVar("ss_boomer_limit");
    g_cvSICH[2] = FindConVar("ss_hunter_limit");
    g_cvSICH[3] = FindConVar("ss_spitter_limit");
    g_cvSICH[4] = FindConVar("ss_jockey_limit");
    g_cvSICH[5] = FindConVar("ss_charger_limit");

    for (int i = 0; i < 6; i++) {
        if (g_cvSICH[i] == null) {
            LogError("Unable to find ConVar");
            return;
        }
        g_iSICH[i] = g_cvSICH[i].IntValue;
    }
}