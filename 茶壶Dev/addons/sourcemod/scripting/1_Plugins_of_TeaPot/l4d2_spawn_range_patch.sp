#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sourcescramble>

#define VERSION	"0.3"

ConVar g_cvFinalMapExclude, g_cvEnable;
MemoryPatch g_mPatch;
StringMap g_smExcludeMap;
Handle g_hIsMissionFinalMap;
char g_key[128];

public Plugin myinfo =
{
	name = "L4D2 Spawn range patch",
	author = "fdxx",
	version = VERSION,
	url = "https://github.com/fdxx/l4d2_plugins"
}

public void OnPluginStart()
{
	Init();

	delete g_smExcludeMap;
	g_smExcludeMap = new StringMap();

	CreateConVar("l4d2_spawn_range_patch_version", VERSION, "Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvEnable = CreateConVar("l4d2_spawn_range_patch_enable", "1");
    g_cvFinalMapExclude = CreateConVar("l4d2_spawn_range_patch_finalmap_exclude", "1");
	g_cvEnable.AddChangeHook(OnConVarChanged);

	RegAdminCmd("sm_spawn_range_patch_exclude", Cmd_AddExcludeMap, ADMFLAG_ROOT);
}

void OnConVarChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	delete g_mPatch;
	if (g_cvEnable.BoolValue)
		Init();
}

Action Cmd_AddExcludeMap(int client, int args)
{
	char buffer[256];

	if (args < 1)
	{
		GetCmdArg(0, buffer, sizeof(buffer));
		ReplyToCommand(client, "Usage: %s <map1> [map2] ...", buffer);
		return Plugin_Handled;
	}

	for (int i = 1; i <= args; i++)
	{
		GetCmdArg(i, buffer, sizeof(buffer));
		g_smExcludeMap.SetValue(buffer, 1);
	}

	return Plugin_Handled;
}

public void OnMapInit(const char[] mapName)
{
	strcopy(g_key, sizeof(g_key), "shit");

	if ((SDKCall(g_hIsMissionFinalMap) && g_cvFinalMapExclude.BoolValue) || g_smExcludeMap.ContainsKey(mapName))
		strcopy(g_key, sizeof(g_key), "ZombieSpawnRange");
}

void Init()
{
	GameData hGameData = new GameData("l4d2_spawn_range_patch");
    char buffer[128];

    strcopy(buffer, sizeof(buffer), "OpcodeBytes");
	int offset = hGameData.GetOffset(buffer);
	if (offset == -1)
		SetFailState("Failed to GetOffset: %s", buffer);

	strcopy(buffer, sizeof(buffer), "ZombieManager::GetZombieSpawnRange");
	g_mPatch = MemoryPatch.CreateFromConf(hGameData, buffer);
	if (!g_mPatch.Enable())
		SetFailState("Failed to EnablePatch: %s", buffer);
	StoreToAddress(g_mPatch.Address + view_as<Address>(offset), GetAddressOfString(g_key), NumberType_Int32);

	strcopy(buffer, sizeof(buffer), "CTerrorGameRules::IsMissionFinalMap");
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, buffer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	delete g_hIsMissionFinalMap;
	g_hIsMissionFinalMap = EndPrepSDKCall();
	if (!g_hIsMissionFinalMap)
		SetFailState("Failed to create SDKCall: %s", buffer);

	delete hGameData;
}
