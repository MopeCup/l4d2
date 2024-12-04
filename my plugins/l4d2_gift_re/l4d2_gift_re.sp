#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <l4d2_weapons_spawn>
#include "cup/cup_function.sp"

//=====================================================================================================
//                                      注意
//  本插件改自fdxx的[l4d2_gift]https://github.com/fdxx/l4d2_plugins/blob/main/l4d2_gift.sp
//  在此基础上对掉落概率与掉落类型做了重做处理
//
//=====================================================================================================

//=====================================================================================================
//=                                        Global
//=====================================================================================================
#define CFG_PATH  "data/gift/l4d2_gift_re.cfg"
#define CFG_PATH2 "data/gift/l4d2_gift_item.cfg"
#define SOUND_GET "ui/helpful_event_1.wav"

ConVar	  g_cvDropType, g_cvDropChance, g_cvDropTime, g_cvHeadShotBoost;

Handle	  g_hSDK_CreateGift, g_hDropTimer;

ArrayList g_aAward, g_aDrop;

int		  g_iTotalweights, g_iTotalItemWeights[6];

bool	  g_bDropType;

float	  g_fDropChance[6], g_fDropTime, g_fHeadShotBoost;

char 	  g_sCfgPath[PLATFORM_MAX_PATH];

enum struct award_t
{
	char cmd[32];
	char cmdArgs[64];
	int	 weights;
	char msg[255];
}

enum struct item_t{
	char className[511];
	int weights[6];
}

enum struct drop_t
{
	int	  ref;
	float fSpawnTime;
}

public Plugin myinfo =
{
	name		= "[L4D2] gift re",
	author		= "fdxx, MopeCup",
	version		= "1.0.1",
	description = "杀死特感概率掉落道具",
	url			= "https://github.com/MopeCup/l4d2",
};

//=====================================================================================================
//=                                           Main
//=====================================================================================================
public void OnPluginStart()
{
	g_cvDropType = CreateConVar("l4d2_gr_drop_type", "1", "掉落物的类型<0: 掉落物品, 1: 掉落礼物盒>", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvDropChance = CreateConVar("l4d2_gr_drop_chance", "0.3 0.3 0.3 0.3 0.3 0.3", "每种特感产生掉落物概率", FCVAR_NOTIFY);
	g_cvDropTime   = CreateConVar("l4d2_gr_drop_time", "75.0", "掉落物存在的时间", FCVAR_NOTIFY, true, 1.0);
	g_cvHeadShotBoost = CreateConVar("l4d2_gr_headshot_boost", "0.2", "爆头击杀提供的掉落率提升",FCVAR_NOTIFY);

	g_cvDropType.AddChangeHook(OnConVarChanged);
	g_cvDropChance.AddChangeHook(OnConVarChanged);
	g_cvDropTime.AddChangeHook(OnConVarChanged);
	g_cvHeadShotBoost.AddChangeHook(OnConVarChanged);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("christmas_gift_grab", Event_GiftGrab);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
	if(g_bDropType)
		strcopy(g_sCfgPath, sizeof g_sCfgPath, CFG_PATH);
	else
		strcopy(g_sCfgPath, sizeof g_sCfgPath, CFG_PATH2);
	CreateTimer(2.0, Timer_Init);
	delete g_hDropTimer;
	if (g_fDropTime > 0.0)
		g_hDropTimer = CreateTimer(1.0, Timer_DropRemove_Check, _, TIMER_REPEAT);
}

void GetCvars()
{
	g_bDropType = g_cvDropType.BoolValue;

	char sTemp[64];
	g_cvDropChance.GetString(sTemp, sizeof sTemp);
	char sBuffer[6][10];
	ExplodeString(sTemp, " ", sBuffer, sizeof sBuffer, sizeof sBuffer[]);
	for (int i = 0; i < 6; i++)
	{
		if (sBuffer[i][0] == '\0')
		{
			g_fDropChance[i] = 0.0;
			continue;
		}
		if (StringToFloat(sBuffer[i]) < 0.0)
		{
			g_fDropChance[i] = 0.0;
			sBuffer[i][0]	 = '\0';
			continue;
		}
		if (StringToFloat(sBuffer[i]) > 1.0)
		{
			g_fDropChance[i] = 1.0;
			sBuffer[i][0]	 = '\0';
			continue;
		}
		g_fDropChance[i] = StringToFloat(sBuffer[i]);
		sBuffer[i][0]	 = '\0';
	}

	g_fDropTime = g_cvDropTime.FloatValue;
	g_fHeadShotBoost = g_cvHeadShotBoost.FloatValue;
}

public void OnConfigsExecuted()
{
	GetCvars();
	if(g_bDropType)
		strcopy(g_sCfgPath, sizeof g_sCfgPath, CFG_PATH);
	else
		strcopy(g_sCfgPath, sizeof g_sCfgPath, CFG_PATH2);
	CreateTimer(2.0, Timer_Init);
	// InitPlugins();
}

void InitPlugins()
{
	delete g_aAward;
	delete g_aDrop;
	g_aAward		   = new ArrayList(sizeof(award_t));
	g_aDrop			   = new ArrayList(sizeof(drop_t));

	GameData hGameData = new GameData("l4d2_gift_re");
	char	 buffer[511];

	strcopy(buffer, sizeof buffer, "CHolidayGift::Create");
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, buffer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	delete g_hSDK_CreateGift;
	g_hSDK_CreateGift = EndPrepSDKCall();
	if (g_hSDK_CreateGift == null)
		SetFailState("Failed to create SDKCall: %s", buffer);

	delete hGameData;

	BuildPath(Path_SM, buffer, sizeof buffer, "%s", g_sCfgPath);
	KeyValues kv = new KeyValues(" ");
	if (!kv.ImportFromFile(buffer))
		SetFailState("Failed to load %s", buffer);
	//掉落礼物盒
	if (g_bDropType)
	{
		for (bool iter = kv.GotoFirstSubKey(); iter; iter = kv.GotoNextKey())
		{
			award_t award;

			// char sCmd[128];
			kv.GetString("cmd", buffer, sizeof buffer);
			int num = SplitString(buffer, " ", award.cmd, sizeof(award.cmd));
			if (num != -1)
				strcopy(award.cmdArgs, sizeof(award.cmdArgs), buffer[num]);
			else
				strcopy(award.cmd, sizeof(award.cmd), buffer);

			kv.GetNum("weights", award.weights);

			kv.GetString("msg", award.msg, sizeof(award.msg));
			g_aAward.PushArray(award);
		}
		delete kv;

		g_iTotalweights = GetTotalWeights();
	}
	//直接掉落物品
	else
	{
		for (bool iter = kv.GotoFirstSubKey(); iter; iter = kv.GotoNextKey())
		{
			item_t item;
			kv.GetString("classname", item.className, sizeof(item.className));
			kv.GetString("weights", buffer, sizeof buffer);
			char sTemp[6][16];
			int val;
			ExplodeString(buffer, " ", sTemp, sizeof sTemp, sizeof sTemp[]);
			for (int i = 0; i < 6; i++)
			{
				if (sTemp[i][0] == '\0')
				{	
					item.weights[i] = 0;
					continue;
				}
				if ((val = StringToInt(sTemp[i])) < 0)
				{
					item.weights[i] = 0;
					sTemp[i][0] = '\0';
					continue;
				}
				item.weights[i] = val;
				sTemp[i][0] = '\0';
			}
			g_aAward.PushArray(item);
		}
		delete kv;
		for (int i = 0; i < 6; i++)
		{
			g_iTotalItemWeights[i] = GetTotalItemWeights(i);
		}
	}
}

//=====================================================================================================
//=                                        Timer
//=====================================================================================================
Action Timer_Init(Handle timer)
{
	InitPlugins();
	return Plugin_Continue;
}

Action Timer_DropRemove_Check(Handle timer)
{
	if (!g_aDrop)
		return Plugin_Continue;
	int len = g_aDrop.Length;
	if (!len)
		return Plugin_Continue;
	drop_t drop;
	float  fCurTime = GetEngineTime();
	int	   entity;

	for (int i = 0; i < len; i++)
	{
		g_aDrop.GetArray(i, drop);
		entity = EntRefToEntIndex(drop.ref);
		if (!IsValidEntity(entity))
		{
			g_aDrop.Erase(i);
			i--;
			len--;
			continue;
		}
		if (fCurTime - drop.fSpawnTime > g_fDropTime)
			RemoveEntity(entity);
	}
	return Plugin_Continue;
}

//=====================================================================================================
//=                                         Event
//=====================================================================================================
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_aDrop)
		g_aDrop.Clear();
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	bool headshot = event.GetBool("headshot");
	if (IsZombieClassSI(client))
	{
		int iClass = GetEntProp(client, Prop_Send, "m_zombieClass") - 1;
		float fChance = headshot ? g_fHeadShotBoost + g_fDropChance[iClass] : g_fDropChance[iClass];
		if (GetURandomFloat() < fChance)
		{
			float fAbsOrigin[3], fAbsAngles[3], fEyeAngles[3], fAbsVelocity[3];
			GetClientAbsOrigin(client, fAbsOrigin);
			GetClientAbsAngles(client, fAbsAngles);
			GetClientEyeAngles(client, fEyeAngles);
			int entity;
			if (g_bDropType)
				entity = SDKCall(g_hSDK_CreateGift, fAbsOrigin, fAbsAngles, fEyeAngles, fAbsVelocity, client);
			else
			{
				item_t item;
				ItemWeightRandomSelect(item, iClass);
				// entity = CreateEntityByName(item.className);
				// if (entity == -1)
				// {
				// 	PrintToServer("failed to create by classname %s", item.className);
				// 	return;
				// }
				// DispatchSpawn(entity);
				// DispatchKeyValueInt(entity, "count", 1);
				// TeleportEntity(entity, fAbsOrigin, fAbsAngles, fAbsVelocity);
				entity = L4D2Wep_Spawn(item.className, fAbsOrigin, fAbsAngles, 1);
				if (entity == -1)
				{
					PrintToServer("failed to create by classname %s", item.className);
					return;
				}
			}
			drop_t drop;
			drop.ref		= EntIndexToEntRef(entity);
			drop.fSpawnTime = GetEngineTime();
			g_aDrop.PushArray(drop);
		}
	}
}

void Event_GiftGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidSur(client) && IsPlayerAlive(client) && !GetEntProp(client, Prop_Send, "m_isIncapacitated"))
	{
		award_t award;
		WeightedRandomSelect(award);
		//PrintToChatAll("%s %s", award.cmd, award.cmdArgs);
		int len = strlen(award.cmdArgs);
		if (len > 0)
			CheatCommand(client, award.cmd, award.cmdArgs);
		else
			CheatCommand(client, award.cmd);

		CPrintToChatAll("{olive}[Gift] {olive}%N{blue}%s", client, award.msg);
		float origin[3];
		GetClientAbsOrigin(client, origin);
		EmitAmbientSound(SOUND_GET, origin);
	}
}

int WeightedRandomSelect(award_t award)
{
	int randomNum;
	if (g_iTotalweights < 1)
	{
		randomNum = GetURandomInt() % g_aAward.Length;
		g_aAward.GetArray(randomNum, award);
		return randomNum;
	}
	randomNum = GetURandomInt() % g_iTotalweights;
	for (int i = 0, len = g_aAward.Length; i < len; i++)
	{
		g_aAward.GetArray(randomNum, award);
		if (randomNum < award.weights)
			return i;
		randomNum -= award.weights;
	}
	return -1;
}

int ItemWeightRandomSelect(item_t item, int class)
{
	int randomNum;
	if (g_iTotalItemWeights[class] < 1)
	{
		randomNum = GetURandomInt() % g_aAward.Length;
		g_aAward.GetArray(randomNum, item);
		return randomNum;
	}
	randomNum = GetURandomInt() % g_iTotalItemWeights[class];
	for (int i = 0, len = g_aAward.Length; i < len; i++)
	{
		g_aAward.GetArray(randomNum, item);
		if (randomNum < item.weights[class])
			return i;
		randomNum -= item.weights[class];
	}
	return -1;
}

int GetTotalWeights()
{
	int		count;
	award_t award;

	for (int i = 0, len = g_aAward.Length; i < len; i++)
	{
		g_aAward.GetArray(i, award);
		count += award.weights;
	}

	return count;
}

int GetTotalItemWeights(int class)
{
	int count;
	item_t item;

	for (int i = 0, len = g_aAward.Length; i < len; i++)
	{
		g_aAward.GetArray(i, item);
		count += item.weights[class];
	}
	return count;
}