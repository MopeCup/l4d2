#include <l4d2_nativevote>
#include <multicolors>
#include <sdkhooks>
#include <sdktools>
/**
 * 2024.12.28 - v1.3.1
 * 修复一个报错问题
 * 
 *  2024.12.5 - v1.3.0
 *  重做并作为bots的扩展插件使用
 */

//=================================================================================
//=                             cmd
//=================================================================================
Action cmdBotVote(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "!setbot <num>");
		return Plugin_Handled;
	}
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && !IsFakeClient(client))
	{
		int botNum = GetCmdArgInt(1);
		if (botNum < 1 || botNum > 32)
		{
			ReplyToCommand(client, "参数应在1~32之间");
			return Plugin_Handled;
		}
		StartBotVote(client, botNum);
	}
	return Plugin_Handled;
}

Action cmdKickBots(int client, int args)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == TEAM_SURVIVOR || (GetClientTeam(i) == TEAM_SPECTATOR && GetBotOfIdlePlayer(i)))
				count++;
		}
	}
	g_cBotLimit.IntValue = count;
	delete g_hBotsTimer;
	g_hBotsTimer = CreateTimer(1.0, tmrBotsUpdate);
	return Plugin_Handled;
}

//=================================================================================
//=                             botvote
//=================================================================================
void StartBotVote(int client, int botNum)
{
	if (!L4D2NativeVote_IsAllowNewVote())
	{
		CPrintToChat(client, "{green}[BotVote] {blue}发起投票失败, 有一项投票正在进行中");
		return;
	}
	L4D2NativeVote botvote = L4D2NativeVote(BotVoteHandler);
	botvote.SetDisplayText("更改bot数量为%d", botNum);
	botvote.Initiator = client;
	botvote.SetInfoString("%d", botNum);
	int iPlayerCount = 0;
	int[] clients	 = new int[MaxClients];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == 2 || (GetClientTeam(i) && GetBotOfIdlePlayer(i)))
				clients[iPlayerCount++] = i;
		}
	}
	if (!botvote.DisplayVote(clients, iPlayerCount, 20))
		LogError("Failed to start BotVote");
}

void BotVoteHandler(L4D2NativeVote vote, VoteAction action, int param1, int param2)
{
	switch (action)
	{
		case VoteAction_Start:
		{
			CPrintToChatAll("{olive}%N{blue}发起了一项投票", param1);
		}
		case VoteAction_PlayerVoted:
		{
			CPrintToChatAll("{olive}%N{blue}已投票", param1);
		}
		case VoteAction_End:
		{
			if (vote.YesCount > vote.PlayerCount / 2)
			{
				vote.SetPass("投票通过, 正在加载配置");
				char info[16];
				vote.GetInfoString(info, sizeof info);
				int botNum			 = StringToInt(info);
				g_cBotLimit.IntValue = botNum;
				ConVar cMaxPlayer	 = FindConVar("sv_maxplayers");
				if (cMaxPlayer != null)
				{
					if (cMaxPlayer.IntValue < botNum)
						cMaxPlayer.IntValue = botNum;
				}
				delete g_hBotsTimer;
				g_hBotsTimer = CreateTimer(1.0, tmrBotsUpdate);
				CPrintToChatAll("{green}[BotVote] {blue}更改开局bot成功");
			}
			else
				vote.SetFail();
		}
	}
}

//=================================================================================
//=                             HeadShotDmg
//=================================================================================
public void OnClientPostAdminCheck(int client)
{
	if (g_cSBHeadShotDmg.BoolValue)
		SDKHook(client, SDKHook_TraceAttack, TraceAttack);
}

public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!g_cSBHeadShotDmg.BoolValue)
		return Plugin_Continue;

	if (victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients)
	{
		if (IsClientInGame(victim) && GetClientTeam(victim) == 3 && GetEntProp(victim, Prop_Send, "m_zombieClass") != 8 && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && IsFakeClient(attacker))
		{
			if (hitgroup == 1)
			{
				damage = damage / 4.0;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

//=================================================================================
//=                             Reboot Game
//=================================================================================
Action Timer_RebootGame(Handle timer)
{
	int i;
	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
			ForcePlayerSuicide(i);
	}
	return Plugin_Stop;
}

int CheckAlivePlayerNum()
{
	int iAlivePlayerNum = 0;
	int i;
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		if (GetClientTeam(i) == TEAM_SPECTATOR)
		{
			int iBot = GetBotOfIdlePlayer(i);
			if (iBot != 0)
				iAlivePlayerNum++;
			continue;
		}
		if (GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && !IsFakeClient(i))
			iAlivePlayerNum++;
	}
	return iAlivePlayerNum;
}