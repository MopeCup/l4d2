#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <left4dhooks>  

//本插件改自fdxx l4d2_alone_mode ， https://github.com/fdxx
public Plugin myinfo =
{
	name = "l4d2_TrainMode",
	author = "fdxx, MopeCup",
	version = "1.4.0",
}

ConVar g_cvSIDmg;
ConVar g_cvScratcheDmg;
ConVar g_cvTankDmg;
ConVar g_cvGod;

Handle g_hTimer;

bool g_bL4D2Version;

float g_fSIDmg;
float g_fScratchDmg;
float g_fTankDmg;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead)
		g_bL4D2Version = false;
	else if (test == Engine_Left4Dead2 )
		g_bL4D2Version = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	//g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart(){
    g_cvSIDmg = CreateConVar("l4d2_train_si_dmg", "10.0", "特感控住人后造成的伤害", FCVAR_NOTIFY, true, 1.0, true, 200.0);
    g_cvScratcheDmg = CreateConVar("l4d2_train_scratch_dmg", "2.0", "特感肘击的伤害", FCVAR_NOTIFY, true, 1.0, true, 200.0);
    g_cvTankDmg = CreateConVar("l4d2_train_tank_dmg", "24.0", "坦克造成的伤害", FCVAR_NOTIFY, true, 1.0, true, 200.0);

    g_cvGod = FindConVar("god");

    //AutoExecConfig(true, l4d2_TrainMode);

    g_cvSIDmg.AddChangeHook(ConVarChanged_Dmg);
    g_cvScratcheDmg.AddChangeHook(ConVarChanged_Dmg);
    g_cvTankDmg.AddChangeHook(ConVarChanged_Dmg);

    GetCvars();

    RegConsoleCmd("sm_mgod", Cmd_EnableGodMode);

    HookEvent("tank_spawn", Event_TankSpawn);
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("charger_charge_end", Event_ChargerChargeEnd, EventHookMode_Post);
}

void ConVarChanged_Dmg(ConVar convar, const char[] oldValue, const char[] newValue){
    GetCvars();
}

void GetCvars(){
    g_fSIDmg = GetConVarFloat(g_cvSIDmg);
    g_fScratchDmg = GetConVarFloat(g_cvScratcheDmg);
    g_fTankDmg = GetConVarFloat(g_cvTankDmg);
}

Action Cmd_EnableGodMode(int client, int args){
    bool bGod = g_cvGod.BoolValue;
    bGod = !bGod;
    g_cvGod.BoolValue = bGod;
    CPrintToChatAll("{olive}[提示] {blue}已%s无敌模式，输入{green}!mgod{blue}可%s无敌模式", bGod ? "开启" : "关闭", bGod ? "关闭" : "开启");

    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    delete g_hTimer;
    g_hTimer = CreateTimer(600.0, Timer_NoticeOfCmd);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    delete g_hTimer;
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast){
    int player = 0;
    int i;
    for(i = 1; i < MaxClients; i++){
        if(!IsValidSur(i) || !IsPlayerAlive(i))
            continue;
        player++;
    }

    int tank = GetClientOfUserId(event.GetInt("userid"));
    if (!tank)
        return;
    int tankHealth;
    tankHealth = 2000 * player;
    SetEntProp(tank, Prop_Data, "m_iHealth", tankHealth);
}

//charger冲锋结束且未携带生还时立即处死
void Event_ChargerChargeEnd(Event event, const char[] name, bool dontBroadcast)
{
    int charger = GetClientOfUserId(event.GetInt("userid"));
    if (!charger)
        return;
    ForcePlayerSuicide(charger);
}

static const char g_sSpecialName[][] =
{
	"", "Smoker", "Boomer", "Hunter", "Spitter", "Jockey", "Charger"
};

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    bool bGod = g_cvGod.BoolValue;

    if (IsValidSur(victim) && IsPlayerAlive(victim))
    {
        damage = 0.0;
        if (IsPlayerAlive(attacker) && IsValidSI(attacker))
        {
            int iClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");
            switch (iClass)
            {
                case 1,3,5,6:
                {
                    if(IsPlayerGetContolled(attacker, iClass))
                    {
                        if (!bGod && !IsPlayerGetUp(victim))
                            SDKHooks_TakeDamage(victim, attacker, attacker, g_fSIDmg);
                        DamageReport(victim, attacker, iClass);
                        ForcePlayerSuicide(attacker);
                    }
                    else
                    {
                        if (!bGod && !IsPlayerGetUp(victim))
                        {
                            SDKHooks_TakeDamage(victim, attacker, attacker, g_fScratchDmg);
                        }
                    }
                }
                case 2,4:
                {
                    if (!bGod && !IsPlayerGetUp(victim))
                    {
                        SDKHooks_TakeDamage(victim, attacker, attacker, g_fScratchDmg);
                    }
                }
                case 8:
                {
                    if (!bGod && !IsPlayerGetUp(victim))
                    {
                        SDKHooks_TakeDamage(victim, attacker, attacker, g_fTankDmg);
                    }
                }
            }
        }
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

Action Timer_NoticeOfCmd(Handle timer)
{
    g_hTimer = null;
    CPrintToChatAll("{blue}[!]使用指令{olive}!mgod{blue}以%s{orange}无敌模式\n", g_cvGod.BoolValue ? "关闭" : "开启");
    CPrintToChatAll("{blue}[!]被舌头拉住时可以按{olive}空格{blue}提前{orange}解控"); 
    g_hTimer = CreateTimer(600.0, Timer_NoticeOfCmd);
    return Plugin_Continue;
}

void DamageReport(int client, int attacker, int iClass){
    if(!IsFakeClient(attacker))
        CPrintToChat(client, "{blue}[伤害报告]{olive}%s(%N){blue}还剩余{orange}%i{blue}血量.", g_sSpecialName[iClass], attacker, GetEntProp(attacker, Prop_Data, "m_iHealth"));
    else CPrintToChat(client, "{blue}[伤害报告]{olive}%N{blue}还剩余{orange}%i{blue}血量.", attacker, GetEntProp(attacker, Prop_Data, "m_iHealth"));

}

bool IsPlayerGetContolled(int iSpecial, int iClass){
    if(iClass == 1 && GetEntPropEnt(iSpecial, Prop_Send, "m_tongueVictim") > 0)
        return true; 
    if(iClass == 3 && GetEntPropEnt(iSpecial, Prop_Send, "m_pounceVictim") > 0)
        return true;
    if(iClass == 5 && GetEntPropEnt(iSpecial, Prop_Send, "m_jockeyVictim") > 0)
        return true;
    if(iClass == 6 && GetEntPropEnt(iSpecial, Prop_Send, "m_pummelVictim") > 0)
        return true;
    return false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]){
    //如果摁了跳跃
    if(buttons & IN_JUMP == IN_JUMP){
        if(IsValidSur(client) && IsPlayerAlive(client)){
            int attacker;
            if((attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner")) > 0){
                if (!g_cvGod.BoolValue && !IsPlayerGetUp(client))
                    SDKHooks_TakeDamage(client, attacker, attacker, g_fSIDmg);
                DamageReport(client, attacker, 1);
                ForcePlayerSuicide(attacker);
            }
        }
    }

    return Plugin_Continue;
}

//判断玩家是否处于起身状态
bool IsPlayerGetUp(int client){
    int Activity;

	if(g_bL4D2Version)
	{
		Activity = PlayerAnimState.FromPlayer(client).GetMainActivity();

		switch (Activity) 
		{
			case L4D2_ACT_TERROR_SHOVED_FORWARD_MELEE, // 633, 634, 635, 636: stumble
				L4D2_ACT_TERROR_SHOVED_BACKWARD_MELEE,
				L4D2_ACT_TERROR_SHOVED_LEFTWARD_MELEE,
				L4D2_ACT_TERROR_SHOVED_RIGHTWARD_MELEE: 
					return true;

			case L4D2_ACT_TERROR_POUNCED_TO_STAND: // 771: get up from hunter
				return true;

			case L4D2_ACT_TERROR_HIT_BY_TANKPUNCH, // 521, 522, 523: HIT BY TANK PUNCH
				L4D2_ACT_TERROR_IDLE_FALL_FROM_TANKPUNCH,
				L4D2_ACT_TERROR_TANKPUNCH_LAND:
				return true;

			case L4D2_ACT_TERROR_CHARGERHIT_LAND_SLOW: // 526: get up from charger
				return true;

			case L4D2_ACT_TERROR_HIT_BY_CHARGER, // 524, 525, 526: flung by a nearby Charger impact
				L4D2_ACT_TERROR_IDLE_FALL_FROM_CHARGERHIT: 
				return true;
		}
	}
	else
	{
		Activity = L4D1_GetMainActivity(client);

		switch (Activity) 
		{
			case L4D1_ACT_TERROR_SHOVED_FORWARD, // 1145, 1146, 1147, 1148: stumble
				L4D1_ACT_TERROR_SHOVED_BACKWARD,
				L4D1_ACT_TERROR_SHOVED_LEFTWARD,
				L4D1_ACT_TERROR_SHOVED_RIGHTWARD: 
					return true;

			case L4D1_ACT_TERROR_POUNCED_TO_STAND: // 1263: get up from hunter
				return true;

			case L4D1_ACT_TERROR_HIT_BY_TANKPUNCH, // 1077, 1078, 1079: HIT BY TANK PUNCH
				L4D1_ACT_TERROR_IDLE_FALL_FROM_TANKPUNCH,
				L4D1_ACT_TERROR_TANKPUNCH_LAND:
				return true;
		}
	}

	return false;
}

bool IsValidSur(int client){
    if (client > 0 && client <= MaxClients)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			return true;
		}
	}
	return false;
}

bool IsValidSI(int client){
    if (client > 0 && client <= MaxClients)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 3)
		{
			return true;
		}
	}
	return false;
}