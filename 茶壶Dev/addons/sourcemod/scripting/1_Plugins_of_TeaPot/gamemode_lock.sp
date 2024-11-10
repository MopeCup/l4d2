#include<sourcemod>
#pragma semicolon 1
#pragma newdecls required

ConVar g_cgamemode;
ConVar g_hsetGamemode;
char g_sgamemode[32];
char g_ssetGamemode[32];

public Plugin myinfo =
{
	name = "gamemode_lock",
	author = "MopeCup",
	description = "锁定当前游戏模式为特定游戏模式，若不是则转化为该模式",
	version = "1.1.0"
}

/*
	coop - 战役
	realism - 写实
	community5 - 
	community1 - 














*/

public void OnPluginStart()
{
	g_hsetGamemode = CreateConVar("gamemode_lock_on", "none", "锁定游戏模式为(在括号内修改模式代码), FCVAR_SPONLY");
	//AutoExecConfig(true, "gamemode_lock");

	g_cgamemode = FindConVar("mp_gamemode");
	g_hsetGamemode.AddChangeHook(GameModeChange);
	g_cgamemode.AddChangeHook(GameModeChange);
	ChangeGameMode();
}

void GetCvars()
{
	GetConVarString(g_cgamemode, g_sgamemode, sizeof(g_sgamemode));
	GetConVarString(g_hsetGamemode, g_ssetGamemode, sizeof(g_ssetGamemode));
	//ChangeGameMode();
}

public void GameModeChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	//GetCvars();
	ChangeGameMode();
}

bool IsGameModeRight()
{
	if(strcmp(g_ssetGamemode, "none", false) == 0)
		return true;
	// if(strcmp(g_sgamemode, "community1", false) == 0)
	// 	return true;
	// if(strcmp(g_sgamemode, "realism", false) == 0)
	// 	return true;
	// if(strcmp(g_sgamemode, "community5", false) == 0)
	// 	return true;
	if(strcmp(g_sgamemode, g_ssetGamemode, false) == 0)
		return true;

	return false;
}

void ChangeGameMode()
{
	GetCvars();
	//if(strcmp(g_sgamemode, "community1", false) == 1 && strcmp(g_sgamemode, "realism", false) == 1 && strcmp(g_sgamemode, "community5", false) == 1)
	if(!IsGameModeRight())
	{
		SetConVarString(g_cgamemode, g_ssetGamemode);
		PrintToChatAll("\x05当前游戏模式不符合规定模式，已切换游戏模式为\x03%s", g_ssetGamemode);
		//ServerCommand("sm_restartmap");
	}
}