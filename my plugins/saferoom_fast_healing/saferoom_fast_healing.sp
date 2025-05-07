#include <left4dhooks>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

#define GAMEDATA "saferoom_fast_healing"

ConVar g_cvHealDuration, g_cvMaxHealth;

float  g_fHealDuration;

bool   g_bHealing;

Handle g_hReset;

public Plugin myinfo =
{
	name		= "Saferoom Fast Healing",
	author		= "Eärendil, MopeCup",
	description = "玩家处于安全区域时能秒包",
	version		= "25m3w5a",
};
//原作者地址https://forums.alliedmods.net/showthread.php?t=335683
public void OnPluginStart()
{
	g_cvHealDuration = FindConVar("first_aid_kit_use_duration");
	g_cvMaxHealth	 = FindConVar("first_aid_kit_max_heal");
    
    //HookEvent("heal_success", Event_Heal);

	g_fHealDuration	 = g_cvHealDuration.FloatValue;

	InitGameData();
}

public void OnAllPluginsLoaded()
{
	g_fHealDuration = g_cvHealDuration.FloatValue;
}

void InitGameData()
{
	char sGameData[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sGameData, sizeof(sGameData), "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(sGameData))
		SetFailState("unable to find gamedata in gamedata/%s.txt", sGameData);
	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if (hGameData == null)
		SetFailState("Missing Required File %s", GAMEDATA);
	CreateDetour(hGameData, MedStartAct, "CFirstAidKit::ShouldStartAction", false);
	CreateDetour(hGameData, MedStartAct_Post, "CFirstAidKit::ShouldStartAction", true);
	delete hGameData;
}

void CreateDetour(Handle gameData, DHookCallback CallBack, const char[] sName, const bool post)
{
	Handle hDetour = DHookCreateFromConf(gameData, sName);
	if (!hDetour)
		SetFailState("Failed to find \"%s\" signature.", sName);

	if (!DHookEnableDetour(hDetour, post, CallBack))
		SetFailState("Failed to detour \"%s\".", sName);

	delete hDetour;
}

MRESReturn MedStartAct(Handle hReturn, Handle hParams)
{
	int client = DHookGetParam(hParams, 2);
	int target = DHookGetParam(hParams, 3);
	if (target > MaxClients || GetClientTeam(target) != 2)
		return MRES_Ignored;
	int maxHP  = GetEntProp(client, Prop_Send, "m_iMaxHealth");
	int health = GetClientHealth(target) + 1;
	if (health >= maxHP || health >= g_cvMaxHealth.IntValue)
		return MRES_Ignored;
	float duration = 0.1;
	if (IsClientInSafeArea(client) && IsClientInSafeArea(target))
	{
        //PrintToChatAll("pass");
		//g_fHealDuration = g_cvHealDuration.FloatValue;
		g_cvHealDuration.SetFloat(duration, true, false);
		g_bHealing = true;
	}
	return MRES_Ignored;
}

MRESReturn MedStartAct_Post(Handle hReturn, Handle hParams)
{
	if (g_bHealing)
	{
        //PrintToChatAll("Pass2");
		delete g_hReset;
        g_hReset = CreateTimer(0.1, Timer_ResetDuration);
		//g_cvHealDuration.SetFloat(g_fHealDuration, true, false);
		g_bHealing = false;
	}
	return MRES_Ignored;
}

Action Timer_ResetDuration(Handle timer)
{
	g_hReset = null;
    g_cvHealDuration.SetFloat(g_fHealDuration, true, false);
    return Plugin_Stop;
}

bool IsClientInSafeArea(int client)
{
	if (IsClientInGame(client) && client > 0 && client <= MaxClients)
	{
		float fPos[3];
		GetClientAbsOrigin(client, fPos);
		if (L4D_IsPositionInFirstCheckpoint(fPos) || L4D_IsInLastCheckpoint(client))
			return true;
	}
	return false;
}