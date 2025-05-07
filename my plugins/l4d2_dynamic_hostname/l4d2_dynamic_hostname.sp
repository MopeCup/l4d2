#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#pragma newdecls required

#define PLUGIN_FLAG		 FCVAR_SPONLY | FCVAR_NOTIFY
#define SERVER_NAME_PATH "configs/hostname/hostname.txt"
#define MODE_NAME_PATH	 "configs/hostname/gamemode.txt"

/*
2024.8.19 - v1.6.0
	彻底重写

2024.8.19 - v1.6.1
	修复第二次读取时，服名为默认的bug(重置读取位置)

2024.09.09 - v1.6.2
	修复路程的%不正常显示的问题

2025.02.23 - v1.7.1
	新增灭团统计
*/
public Plugin myinfo =
{
	name		= "l4d2 dynamic hostname",
	author		= "MopeCup",
	description = "动态修改服名.",
	version		= "1.7.1"
};

//-----变量-----
static char		 serverNamePath[128], modeNamePath[128];
static KeyValues key, kv;

bool			 bLateLoad, bSpecialSpawner, bTeapotCommands;

ConVar			 cvServerName, cvGameMode;

ConVar			 cvExtraGameMode;

Handle			 hRefreshTime = null;

//-----Native-----
// SpecialSpawner
native int		 SS_GetSILimit();
native int		 SS_GetSISpawnTime();
// //bots
// native int GetBotJoinLimit();
// l4d2 teapot commands
native int GetRestartTime();

//-----插件库-----
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// SpecialSpawner
	MarkNativeAsOptional("SS_GetSILimit");
	MarkNativeAsOptional("SS_GetSISpawnTime");
	// //bots
	// MarkNativeAsOptional("GetBotJoinLimit");
	// l4d2 teapot commands
	MarkNativeAsOptional("GetRestartTime");

	BuildPath(Path_SM, serverNamePath, sizeof(serverNamePath), SERVER_NAME_PATH);
	BuildPath(Path_SM, modeNamePath, sizeof modeNamePath, MODE_NAME_PATH);
	if (!FileExists(serverNamePath))
	{
		FormatEx(serverNamePath, sizeof(serverNamePath), "无法找到服名文件位于：%s", SERVER_NAME_PATH);
		strcopy(error, err_max, serverNamePath);
		return APLRes_SilentFailure;
	}

	if (!FileExists(modeNamePath))
	{
		FormatEx(modeNamePath, sizeof(modeNamePath), "无法找到服名文件位于：%s", MODE_NAME_PATH);
		strcopy(error, err_max, modeNamePath);
		return APLRes_SilentFailure;
	}
	bLateLoad = late;
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	// bTeapot = LibraryExists("l4d2_Teapot");
	bSpecialSpawner = LibraryExists("specialspawner");
	bTeapotCommands = LibraryExists("teapot_commands");
}

public void OnLibraryAdded(const char[] sName)
{
	// if(StrEqual(sName, "l4d2_Teapot"))
	// 	bTeapot = true;

	if (StrEqual(sName, "specialspawner"))
		bSpecialSpawner = true;

	if (StrEqual(sName, "teapot_commands"))
		bTeapotCommands = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	// if(StrEqual(sName, "l4d2_Teapot"))
	// 	bTeapot = false;

	if (StrEqual(sName, "specialspawner"))
		bSpecialSpawner = false;
	if (StrEqual(sName, "teapot_commands"))
		bTeapotCommands = false;
}

//-----插件开始-----
public void OnPluginStart()
{
	key = CreateKeyValues("ServerName");
	kv	= CreateKeyValues("ModeName");
	if (!FileToKeyValues(key, serverNamePath)) { SetFailState("无法找到服名文件位于：%s", SERVER_NAME_PATH); }
	if (!FileToKeyValues(kv, modeNamePath)) { SetFailState("无法找到模式文件位于：%s", MODE_NAME_PATH); }

	cvExtraGameMode = CreateConVar("ldh_extra_gamemode", "", "设置额外的游戏模式", PLUGIN_FLAG);

	cvServerName	= FindConVar("hostname");
	// cvMaxSlots = FindConVar("sv_maxplayers");
	cvGameMode		= FindConVar("mp_gamemode");

	hRefreshTime	= CreateTimer(2.0, Timer_RefreshHostName, _, TIMER_REPEAT);
}

public void OnPluginEnd()
{
	delete key;
	delete hRefreshTime;
}

//初始设置服名
public void OnConfigsExecuted()
{
	setServerName();
}

//玩家登入或登出设置服名
public void OnClientConnected()
{
	setServerName();
}

public void OnClientDisconnect()
{
	setServerName();
}

//每两秒设置一次服名
public Action Timer_RefreshHostName(Handle timer)
{
	setServerName();
	return Plugin_Continue;
}

//-----服名处理-----
void setServerName()
{
	char port[16], sFinalServerName[128];

	//获取端口号
	FindConVar("hostport").GetString(port, sizeof(port));

	key.Rewind();
	kv.Rewind();
	//获取配置文件中的基本服名
	if (key.JumpToKey(port, false))
		key.GetString("baseName", sFinalServerName, sizeof(sFinalServerName), "Left 4 Dead 2");
	else
		FormatEx(sFinalServerName, sizeof(sFinalServerName), "Left 4 Dead 2");

	//配置模式与特感刷新状态
	//配置额外模式
	char sExtraMode[32];
	cvExtraGameMode.GetString(sExtraMode, sizeof(sExtraMode));

	if (strlen(sExtraMode) < 1)
		FormatEx(sExtraMode, sizeof(sExtraMode), "默认");

	char sExtra[32];
	FormatEx(sExtra, sizeof(sExtra), "[%s]", sExtraMode);
	StrCat(sFinalServerName, sizeof(sFinalServerName), sExtra);

	//配置模式
	char sGameMode[32], sGameModeName[32];

	cvGameMode.GetString(sGameMode, sizeof(sGameMode));
	if (kv.JumpToKey(sGameMode, false))
	{
		kv.GetString("name", sGameModeName, sizeof sGameModeName);
		FormatEx(sGameMode, sizeof sGameMode, "[%s", sGameModeName);
	}
	else
		FormatEx(sGameMode, sizeof sGameMode, "[其他");
	//此部分可以自行添加模式代码
	// if(strcmp(sGameMode, "coop", false) == 0)
	//     FormatEx(sGameMode, sizeof(sGameMode), "[战役 - ");
	// else if(strcmp(sGameMode, "realism", false) == 0)
	//     FormatEx(sGameMode, sizeof(sGameMode), "[写实 - ");
	// else if(strcmp(sGameMode, "mutation4", false) == 0)
	//     FormatEx(sGameMode, sizeof(sGameMode), "[绝境 - ");
	// else if(strcmp(sGameMode, "community1", false) == 0)
	//     FormatEx(sGameMode, sizeof(sGameMode), "[特感速递 - ");
	// else if(strcmp(sGameMode, "community5", false) == 0)
	//     FormatEx(sGameMode, sizeof(sGameMode), "[死门 - ");
	// else
	//     FormatEx(sGameMode, sizeof(sGameMode), "[其他 - ");

	StrCat(sFinalServerName, sizeof(sFinalServerName), sGameMode);

	//特感刷新
	char  sInfectedInfo[32];
	int	  iMaxSpecials;
	//float fRespawnInterval;
	//未加载specialspawner刷特插件时我们选择不显示
	if (!bSpecialSpawner)
	{
		// iMaxSpecials	 = L4D2_GetScriptValueInt("MaxSpecials", -1);
		// fRespawnInterval = L4D2_GetScriptValueFloat("SpecialRespawnInterval", -1.0);

		// FormatEx(sInfectedInfo, sizeof(sInfectedInfo), "%d特%d秒]", iMaxSpecials, RoundToNearest(fRespawnInterval));
		strcopy(sInfectedInfo, sizeof sInfectedInfo, "]");
	}
	else {
		iMaxSpecials = SS_GetSILimit();
		// fRespawnInterval = GetSISpawnTime();

		FormatEx(sInfectedInfo, sizeof(sInfectedInfo), "%d特%d秒]", iMaxSpecials, SS_GetSISpawnTime());
	}

	StrCat(sFinalServerName, sizeof(sFinalServerName), sInfectedInfo);

	//灭团次数
	if (bTeapotCommands)
	{
		char sRestart[32];
		FormatEx(sRestart, sizeof sRestart, "[重启%d]", GetRestartTime());
		StrCat(sFinalServerName, sizeof sFinalServerName, sRestart);
	}

	//配置路程状态
	char sCurrentInfo[32] = { '\0' };

	FormatEx(sCurrentInfo, sizeof(sCurrentInfo), "[当前%d%s]", RoundToNearest(GetSurvivorFlow() * 100.0), "%");
	StrCat(sFinalServerName, sizeof(sFinalServerName), sCurrentInfo);

	//配置人员状态
	if (IsServerEmpty())
		StrCat(sFinalServerName, sizeof(sFinalServerName), "[无人]");
	else if (IsNeedPeople())
		StrCat(sFinalServerName, sizeof(sFinalServerName), "[缺人]");
	else
		StrCat(sFinalServerName, sizeof(sFinalServerName), "[满人]");

	cvServerName.SetString(sFinalServerName, false, false);
}

bool IsServerEmpty()
{
	int i;
	for (i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
			return false;
	}

	return true;
}

bool IsNeedPeople()
{
	int i;
	for (i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && IsGetBotOfIdlePlayer(i) == 0)
			return true;
	}

	return false;
}

//返回闲置Bot对应的玩家
int IsGetBotOfIdlePlayer(int client)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && IsClientIdle(i) == client && IsPlayerAlive(i))
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

//获取生还路程
//来自server_namer by 夜羽真白 https://steamcommunity.com/id/saku_ra/
float GetSurvivorFlow()
{
	static float maxDistance;
	static int	 targetSurvivor;
	targetSurvivor = L4D_GetHighestFlowSurvivor();
	if (!IsValidSur(targetSurvivor)) { L4D2_GetFurthestSurvivorFlow(); }
	else {
		maxDistance = L4D2Direct_GetFlowDistance(targetSurvivor);
	}
	return maxDistance / L4D2Direct_GetMapMaxFlowDistance();
}

//-----Bool函数-----
bool IsValidSur(int client)
{
	if (client > 0 && client < MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		return true;
	return false;
}