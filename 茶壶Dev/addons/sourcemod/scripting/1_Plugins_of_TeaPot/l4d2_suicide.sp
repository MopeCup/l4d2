#include <sourcemod>
#include <multicolors>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_FLAG FCVAR_SPONLY | FCVAR_NOTIFY

public Plugin myinfo =
{
	name	= "l4d2 Suicide",
	author	= "MopeCup",
	version = "1.1.0",

}

ConVar g_hSuicideType;
ConVar g_hSuicideAcess;

int	   g_iSuicideType;

bool   g_bIsPlayerLeftSafeArea;

public void OnPluginStart()
{
	g_hSuicideType = CreateConVar("l4d2Suicide_type", "1", "允许怎样状态的玩家自杀(1-所有玩家, 2-倒地玩家，其他-不允许)", PLUGIN_FLAG);
	g_hSuicideAcess = CreateConVar("l4d2Suicide_Acess", "0", "允许玩家在那个阶段自杀(0-离开安全区域后任何阶段, 1-有玩家进入终点安全区后)", PLUGIN_FLAG);

	//g_hSuicideType.AddChangeHook(GetCvars);

	RegConsoleCmd("sm_kill", Cmd_Suicide);
	RegConsoleCmd("sm_zs", Cmd_Suicide);
	RegAdminCmd("sm_killall", Cmd_KillAll, ADMFLAG_GENERIC);

	HookEvent("round_start", Event_ReSetValue);
	HookEvent("round_end", Event_ReSetValue);
	//HookEvent("mission_lost", Event_ReSetValue);
	HookEvent("player_left_safe_area", Event_PlayerLeftSafeArea);
}

// void GetCvars(ConVar convar, const char[] oldValue, const char[] newValue)
// {
// 	g_iSuicideType = GetConVarInt(g_hSuicideType);
// }

public void OnMapStart()
{
	g_bIsPlayerLeftSafeArea = false;
}

public void OnMapEnd()
{
	g_bIsPlayerLeftSafeArea = false;
}

void Event_ReSetValue(Event event, const char[] name, bool dontBroadcast)
{
	g_bIsPlayerLeftSafeArea = false;
}

void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
	g_bIsPlayerLeftSafeArea = true;
}

/*本段来自豆瓣酱l4d2_player_suicide*/
//正常返回true,倒地返回false
bool IsPlayerState(int client)
{
	if(!GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
        return true;
    return false;
}

//返回闲置玩家对应的电脑.
int IsGetBotOfIdlePlayer(int client)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && IsClientIdle(i) == client)
			return i;

	return 0;
}
//返回电脑幸存者对应的玩家.
int IsClientIdle(int client)
{
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}
/*本段来自豆瓣酱l4d2_player_suicide*/

public Action Cmd_Suicide(int client, int args)
{
	RequestFrame(IsFrameSuicide, GetClientUserId(client));
    //IsFrameSuicide(client);
	return Plugin_Handled;
}

void IsFrameSuicide(int client)
{
	client = GetClientOfUserId(client);
	g_iSuicideType = GetConVarInt(g_hSuicideType);

	if (IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client))
	{	
		//SuicideDealer(client, GetClientTeam(client));

		switch (GetClientTeam(client))
		{
			case 1:
			{
				//在旁观下的玩家应该先检查一边其是否为闲置状态
				int iBot = IsGetBotOfIdlePlayer(client);
				if (iBot != 0)
				{
					//不允许玩家在游戏刚开始自杀
					//防止误触事件
					if (!g_bIsPlayerLeftSafeArea)
						PrintHintText(client, "游戏未开始时无法自杀");
					else {
						if(g_iSuicideType != 1 && g_iSuicideType != 2){
                            CPrintToChat(client, "{olive}[提示] {blue}自杀功能未开启");
							return;
						}

						if(GetConVarBool(g_hSuicideAcess) && !HasAnyPlayerInEndSafePoint()){
							PrintHintText(client, "任一生还者抵达安全区域前禁止自杀");
							return;
							//KillPlayer(client);
						}

						if (g_iSuicideType == 1)
							KillPlayer(client);
						// char sName[32];
						// sName = GetPlayerName(client,)
						// CPrintToChatAll("{olive}[提示]:{blue}杂鱼❤{green}%s{blue}坚持不下去了呢", sName);
						else if (g_iSuicideType == 2) {
							if (!IsPlayerState(client))
								KillPlayer(client);
							else
								CPrintToChat(client, "{olive}[提示] {blue}自杀仅允许倒地或挂边玩家使用");
						}
					}
				}
				else
					CPrintToChat(client, "{olive}[提示] {blue}旁观者不允许自杀");
			}
			case 2:
			{
				//不允许玩家在游戏刚开始自杀
				//防止误触事件
				if (!g_bIsPlayerLeftSafeArea)
					PrintHintText(client, "游戏未开始时无法自杀");
				else {
					if(g_iSuicideType != 1 && g_iSuicideType != 2){
                        CPrintToChat(client, "{olive}[提示] {blue}自杀功能未开启");
						return;
					}

					if(GetConVarBool(g_hSuicideAcess) && !HasAnyPlayerInEndSafePoint()){
						PrintHintText(client, "任一生还者抵达安全区域前禁止自杀");
						return;
						//KillPlayer(client);
					}
					
					if (g_iSuicideType == 1)
						KillPlayer(client);
					else if (g_iSuicideType == 2) {
						if (!IsPlayerState(client))
							KillPlayer(client);
						else
							CPrintToChat(client, "{olive}[提示] {blue}自杀仅允许倒地或挂边玩家使用");
					}


					// else
					// 	CPrintToChat(client, "{olive}[提示] {blue}自杀功能未开启");
				}
            }
			case 3:
			{
				CPrintToChat(client, "{olive}[提示] {blue}感染者不允许自杀");
			}
		}
	}
}

void KillPlayer(int client)
{
	char sName[32];
	sName = GetPlayerName(client);
	ForcePlayerSuicide(client);
	CPrintToChatAll("{olive}[提示] {blue}杂鱼♥ {green}%s {blue}坚持不下去自杀了呢", sName);
}

public Action Cmd_KillAll(int client, int args)
{
	int i;
	for (i = 0; i < MaxClients; i++)
	{
		if (IsValidClient(i))
			ForcePlayerSuicide(i);
	}

    return Plugin_Continue;
}

bool IsValidClient(int client)
{
	if (client > 0 && client < MaxClients && IsClientInGame(client))
	    return true;
	return false;
}

char[] GetPlayerName(int client)
{
	char sName[32];
	GetClientName(client, sName, sizeof(sName));
	return sName;
}

bool HasAnyPlayerInEndSafePoint(){
	int i;
	for(i = 1; i < MaxClients; i++){
		if(!IsValidClient(i))
			continue;
		if(!IsPlayerAlive(i) || GetClientTeam(i) != 2)
			continue;
		
		if(L4D_IsInLastCheckpoint(i)){
			PrintToChatAll("fuck you");
			return true;
		}
	}
	PrintToChatAll("stop fuck");

	return false;
}