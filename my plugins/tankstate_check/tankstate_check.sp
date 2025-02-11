#pragma semicolon 1
#pragma newdecls required

#include <cup_function>
#include <left4dhooks>
#include <multicolors>

//===============================================================================
//=                             Global
//===============================================================================
#define TANKSTAGE_FIRSTSPWAN 0
#define TANKSTAGE_ATTACK     1

#define TANKSTATE_THREAT          1
#define TANKSTATE_ANGERY          0
#define TANKSTATE_STUCK           2

#define TANKACTION_WAIT     0
#define TANKACTION_PUNCH    1
#define TANKACTION_ROCK     2
#define TANKACTION_WALK     3
#define TANKACTION_JUMP     4
#define TANKACTION_CLIMB    5

#define PLUGIN_FLAG FCVAR_SPONLY|FCVAR_NOTIFY

#define PLUGIN_NAME "Tank Status Check"
#define AUTHOR "MopeCup"
#define PLUGIN_VERSION "1.0.0"

ConVar g_cvTSC_Print;

Handle g_hStage_SpawnToAttack, g_hStateChange;

bool g_bTSC_Print;

enum struct TankStatus {
    int stage[MAXPLAYERS + 1];
    int state[MAXPLAYERS + 1];
}

public Plugin myinfo = {
    name = PLUGIN_NAME,
    author = AUTHOR,
    description = "显示坦克当前的状态",
    version = PLUGIN_VERSION,
    url = "https://github.com/MopeCup/l4d2"
};

//===============================================================================
//=                           API
//===============================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    RegPluginLibrary("tankstatus_check");
    g_hStage_SpawnToAttack = CreateGlobalForward("TankStage_SpawnToAttack", ET_Ignore, Param_Cell);
    g_hStateChange = CreateGlobalForward("TankStateChange", ET_Ignore, Param_Cell);

    CreateNative("GetTankStage", Native_GetTankStage);
    CreateNative("GetTankState", Native_GetTankState);

    return APLRes_Success;
}

//===============================================================================
//=                         Main
//===============================================================================
public void OnPluginStart() {
    g_cvTSC_Print = CreateConVar("tsc_print", "1", "是否打开Tank阶段提示<0: 否, 1: 是>(此功能用于调试插件)", PLUGIN_FLAG, true, 0.0, true, 1.0);

    g_cvTSC_Print.AddChangeHook(OnConVarChanged);

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

    HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Pre);
    HookEvent("tank_killed", Event_TankKilled, EventHookMode_Pre);
    HookEvent("tank_rock_killed", Event_TankRockKilled);

    HookEvent("ability_use", Event_AbilityUse);
    HookEvent("player_jump", Event_PlayerJump);
}