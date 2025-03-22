#include <sourcemod>
#include <left4dhooks>
#include <l4d2_nativevote>
#include <cup_function>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

#define SOUND_CONNECT "doors/door_lock_1.wav"
#define SOUND_JOIN	  "doors/door1_move.wav"
#define SOUND_QUIT	  "doors/default_locked.wav"

int g_iRound;

public Plugin myinfo =
{
	name		= "l4d2 teapot commands",
	author		= "MopeCup",
	description = "提供一系列指令",
	version		= "1.3.3",
	url			= ""

}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("GetRestartTime", native_GetRestartTime);
	RegPluginLibrary("teapot_commands");
	return APLRes_Success;
}

public void
	OnPluginStart()
{
	//闲置
	RegConsoleCmd("sm_s", Cmd_Afk, "快速闲置");
	RegConsoleCmd("sm_afk", Cmd_Afk, "快速闲置");
	RegConsoleCmd("sm_AFK", Cmd_Afk, "快速闲置");
	//旁观
	RegConsoleCmd("sm_spec", Cmd_Spec, "旁观");
	RegConsoleCmd("sm_away", Cmd_Spec, "旁观");
	//开位
	RegConsoleCmd("sm_slot", Cmd_Slot, "开位");

	// Lazer
	RegAdminCmd("sm_lazer", Cmd_Lazer, ADMFLAG_GENERIC, "获取镭射");
	RegAdminCmd("sm_ls", Cmd_Lazer, ADMFLAG_GENERIC, "获取镭射");
	// Cvar
	RegAdminCmd("sm_addcvar", Cmd_Cvar, ADMFLAG_GENERIC, "修改Cvar");

	AddCommandListener(Afk_Command, "go_away_from_keyboard");

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("mission_lost", Event_MissionLost);

	PrecacheSound(SOUND_CONNECT);
	PrecacheSound(SOUND_JOIN);
	PrecacheSound(SOUND_QUIT);
}

public void OnMapStart()
{
	g_iRound = 0;
}

//=============================================================================
//=                             快速闲置
//=============================================================================
Action Cmd_Afk(int client, int args)
{
	RequestFrame(OnNextFrame_AfkCmd, GetClientUserId(client));

	return Plugin_Handled;
}

void OnNextFrame_AfkCmd(int client)
{
	client = GetClientOfUserId(client);
	if (!client || !IsClientAndInGame(client) || GetClientTeam(client) != 2)
	{
		// PrintToChatAll("[Test] 不满足闲置条件");
		return;
	}

	// int flags = GetCommandFlags("go_away_from_keyboard");
	// SetCommandFlags("go_away_from_keyboard", flags & ~FCVAR_CHEAT);
	L4D_GoAwayFromKeyboard(client);
	// SetCommandFlags("go_away_from_keyboard", flags|FCVAR_CHEAT);
}

Action Afk_Command(int client, const char[] command, int args)
{
	if (!IsClientAndInGame(client) || GetClientTeam(client) != 2)
		return Plugin_Handled;
	//换用left4dhooks的闲置函数，解决倒地不能闲置的问题
	// L4D_GoAwayFromKeyboard(client);
	RequestFrame(OnNextFrame_AfkCmd, GetClientUserId(client));
	return Plugin_Handled;
}

//=============================================================================
//=                             Cvar
//=============================================================================
Action Cmd_Cvar(int client, int args)
{
	if (!args)
	{
		ReplyToCommand(client, "!addcvar <ConVar> <Val>");
		return Plugin_Handled;
	}

	char sCvarName[64], sVal[32];
	GetCmdArg(1, sCvarName, sizeof sCvarName);
	GetCmdArg(2, sVal, sizeof sVal);
	ChangeServerCvar(sCvarName, sVal);
	return Plugin_Handled;
}

void ChangeServerCvar(const char[] cvarName, const char[] val)
{
	ConVar conVar = FindConVar(cvarName);
	if (conVar == null)
	{
		PrintToServer("unable to find convar %s", cvarName);
		return;
	}
	conVar.SetString(val);
}

//=============================================================================
//=                            Spec
//=============================================================================
Action Cmd_Spec(int client, int args)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && client <= MaxClients && client > 0)
	{
		if (GetClientTeam(client) == 1)
		{
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
Action Cmd_Slot(int client, int args)
{
	char sVal[2];
	GetCmdArg(1, sVal, sizeof sVal);
	if (strlen(sVal) == 0)
	{
		ReplyToCommand(client, "!slot <slotnum>");
		return Plugin_Handled;
	}
	StartSlotVote(client, sVal);
	return Plugin_Handled;
}

void StartSlotVote(int client, const char[] sVal)
{
	if (!L4D2NativeVote_IsAllowNewVote())
	{
		PrintToChat(client, "投票正在进行中，暂不能发起新的投票");
		return;
	}
	L4D2NativeVote slotVote = L4D2NativeVote(SlotVote_Handler);
	slotVote.SetDisplayText("修改slot为%s", sVal);
	slotVote.Initiator = client;
	slotVote.SetInfoString(sVal);

	int iPlayerCount = 0;
	int[] iClients	 = new int[MaxClients];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == 2 || GetClientTeam(i) == 3)
				iClients[iPlayerCount++] = i;
		}
	}
	if (!slotVote.DisplayVote(iClients, iPlayerCount, 20))
		LogError("发起投票失败");
}

void SlotVote_Handler(L4D2NativeVote vote, VoteAction action, int param1, int param2)
{
	switch (action)
	{
		case VoteAction_Start:
		{
			PrintToChatAll("\x04[SlotVote] \x03%N\x01发起了一个投票", param1);
		}
		case VoteAction_PlayerVoted:
		{
			PrintToChatAll("\x04[SlotVote] \x03%N\x01已投票", param1);
		}
		case VoteAction_End:
		{
			if (vote.YesCount > vote.PlayerCount / 2)
			{
				vote.SetPass("加载中...");
				char sVal[2];
				vote.GetInfoString(sVal, sizeof sVal);
				ChangeServerCvar("sv_maxplayers", sVal);
				ChangeServerCvar("sv_visiblemaxplayers", sVal);

				PrintToChatAll("\x04[SlotVote] \x01已修改slot为\x03%s", sVal);
			}
			else {
				vote.SetFail();
			}
		}
	}
}

//=============================================================================
//=                         Lazer
//=============================================================================
Action Cmd_Lazer(int client, int args)
{
	if (!IsClientAndInGame(client))
		return Plugin_Handled;
	CheatCommand(client, "upgrade_add", "laser_sight");
	return Plugin_Handled;
}

//=============================================================================
//                          连接与退出
//=============================================================================
public void OnClientConnected(int client)
{
	if (IsFakeClient(client))
		return;
	PrintToChatAll("\x03%N\x05正在连接服务器...", client);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
			EmitSoundToClient(i, SOUND_CONNECT);
	}
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		return;
	PrintToChatAll("\x03%N\x05加入游戏, 当前游戏人数(\x03%d/%s\x05)", client, GetPlayerNum(), ChangePluginConVar("sv_maxplayers"));
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
			EmitSoundToClient(i, SOUND_JOIN);
	}
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0 || IsFakeClient(client))
		return;
	char reason[128];
	event.GetString("reason", reason, sizeof reason);
	if (IsClientInGame(client))
		PrintToChatAll("\x03%N\x05退出了游戏, 当前游戏人数(\x03%d/%s\x05)\n退出原因: \x03%s", client, GetPlayerNum() - 1, ChangePluginConVar("sv_maxplayers"), reason);
	else
		PrintToChatAll("\x03%N\x05退出了游戏, 当前游戏人数(\x03%d/%s\x05)\n退出原因: \x03%s", client, GetPlayerNum(), ChangePluginConVar("sv_maxplayers"), reason);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
			EmitSoundToClient(i, SOUND_QUIT);
	}
}

//灭团提示
void Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
    g_iRound++;
    CPrintToChatAll("{blue}这是你们第{orange}%d{blue}次团灭，请再接再励", g_iRound);
}

int native_GetRestartTime(Handle plugin, int numParams)
{
	return GetRestartTime();
}

/**
 * 返回生还重启次数
 * 
 * @return 生还重启次数
 */
int GetRestartTime()
{
	return g_iRound;
}

bool IsClientAndInGame(int client)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client))
		return true;
	return false;
}