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
	version = "1.3.3",
}

//ConVar g_hGodModeEnable;
ConVar g_cvSIDmg;
ConVar g_cvScratcheDmg;
ConVar g_cvTankDmg;

int g_iPlayerNum;

bool g_bGod;
//bool g_bTongueGrab[MAXPLAYERS+1][MAXPLAYERS+1];
//bool g_bJump;
bool g_bOneShot;
bool g_bL4D2Version;

float g_fDamageTheSIGet[MAXPLAYERS+1];
float g_fSIDmg;
float g_fScratchDmg;
float g_fTankDmg;
float g_fTankHealth;

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

    //AutoExecConfig(true, l4d2_TrainMode);

    g_cvSIDmg.AddChangeHook(ConVarChanged_Dmg);
    g_cvScratcheDmg.AddChangeHook(ConVarChanged_Dmg);
    g_cvTankDmg.AddChangeHook(ConVarChanged_Dmg);

    GetCvars();

    RegConsoleCmd("sm_mgod", Cmd_EnableGodMode);
    RegConsoleCmd("sm_mos", Cmd_EnableOneShotMode);
    CreateTimer(180.0, Timer_NoticeOfCmd, _, TIMER_REPEAT);
    g_bGod = false;
    g_bOneShot = false;

    HookEvent("player_incapacitated_start", Event_IncapacitatedStart);
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("tank_spawn", Event_TankSpawn);
    //HookEvent("tongue_grab", Event_Tongue_Grab);
}

void ConVarChanged_Dmg(ConVar convar, const char[] oldValue, const char[] newValue){
    GetCvars();
}

void GetCvars(){
    g_fSIDmg = GetConVarFloat(g_cvSIDmg);
    g_fScratchDmg = GetConVarFloat(g_cvScratcheDmg);
    g_fTankDmg = GetConVarFloat(g_cvTankDmg);
}

// //当用户完全加入游戏后
// //我们使用数组储存玩家是否被舌头控制
// public void OnClientPostAdminCheck(int client){
//     //我们仅仅初始化非bot生还
//     if(IsValidSur(client) && !IsFakeClient(client) && IsPlayerAlive(client)){
//         int i;
//         for(i = 1 && i < MAXPLAYERS+1; i++){
//             g_bTongueGrab[client][i] = false;
//         }
//     }
// }

Action Cmd_EnableGodMode(int client, int args){
    //如果开启了一击必杀，不能使用!mgod
    if(g_bOneShot){
        CPrintToChat(client, "{olive}[提示] {blue}请先关闭一击必杀模式！指令为 {green}!mos");
        return Plugin_Handled;
    }

    //如果没开无敌，开启无敌
    // if(!g_bGod){
    //     g_bGod = true;
    //     CPrintToChat(client, "{olive}[提示] {blue}已开启无敌,输入{green}!mgod{blue}可关闭无敌");
    // }
    // else{
    //     g_bGod = false;
    //     CPrintToChat(client, "{olive}[提示] {blue}已关闭无敌，输入{green}!mgod{blue}可开启无敌");
    // }
    g_bGod = !g_bGod;
    CPrintToChatAll("{olive}[提示] {blue}已%s无敌模式，输入{green}!mgod{blue}可%s无敌模式", g_bGod ? "开启" : "关闭", g_bGod ? "关闭" : "开启");

    return Plugin_Continue;
}

//一击必杀模式必须在关闭无敌才能启用
//若已经开启无敌，不能开启一击必杀
//若开启一击必杀，不能开启无敌
Action Cmd_EnableOneShotMode(int client, int args){
    //如果开启了无敌，不允许开启一击必杀
    if(g_bGod){
        CPrintToChat(client, "{olive}[提示] {blue}请先关闭无敌模式！指令为 {green}!mgod");
        return Plugin_Handled;
    }

    g_bOneShot = !g_bOneShot;
    CPrintToChatAll("{olive}[提示] {blue}已%s一击必杀模式，输入{green}!mos{blue}可%s一击必杀模式", g_bOneShot ? "开启" : "关闭", g_bOneShot ? "关闭" : "开启");

    return Plugin_Continue;
}

public Action Timer_NoticeOfCmd(Handle tiemr){
    CPrintToChatAll("{olive}[提示] {blue}被舌头控住后可按空格强制解控");

    if(!g_bOneShot)
        CPrintToChatAll("{olive}[提示] {blue}输入{green}!mgod{blue}可%s无敌", g_bGod ? "关闭" : "开启");

    if(!g_bGod)
        CPrintToChatAll("{olive}[提示] {blue}输入{green}!mos{blue}可%s一击必杀模式", g_bOneShot ? "关闭" : "开启");

    return Plugin_Continue;
}

public void OnMapStart(){
    ResetPlugin();
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
    ResetPlugin();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
    ResetPlugin();
}

public void OnMapEnd(){
    ResetPlugin();
}

void ResetPlugin(){
    //g_iPlayerNum = 0;

    int i;
    //int j;

    for(i = 1; i < MAXPLAYERS+1; i++){
        g_fDamageTheSIGet[i] = 0.0;
        // for(j = 0; j < MAXPLAYERS+1; j++){
        //     g_bTongueGrab[i][j] = false;
        // }
    }
}

public void OnClientPutInServer(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

    // if(IsValidSur(client)){
    //     int i;
    //     for(i = 1; i < MaxClients; i++){
    //         if(!IsValidSur(i))
    //             continue;
    //         g_iPlayerNum++;
    //     }
    // }
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast){
    int j = 0;
    int i;
    for(i = 1; i < MaxClients; i++){
        if(!IsValidSur(i) || !IsPlayerAlive(i))
            continue;
        j++;
    }
    g_iPlayerNum = j;

    if(g_iPlayerNum < 4)
        g_fTankHealth = g_iPlayerNum * 2000.0;
    else
        g_fTankHealth = 8000.0;
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

static const char g_sSpecialName[][] =
{
	"", "Smoker", "Boomer", "Hunter", "Spitter", "Jockey", "Charger"
};

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype){
    //生还Part
    if(IsPlayerAlive(victim) && IsValidSur(victim)){
        damage = 0.0;
        if(IsPlayerAlive(attacker) && IsValidSI(attacker)){
            int g_iSI_ID;
            g_iSI_ID = GetEntProp(attacker, Prop_Send, "m_zombieClass");
            // if(IsPlayerGetContolled(attacker, g_iSI_ID)){
            //     //damage = 0.0;
            //     if(!g_bGod)
            //         SDKHooks_TakeDamage(victim, attacker, attacker, g_fSIDmg);
            //     if(!IsFakeClient(attacker))
            //         CPrintToChatAll("{blue}[茶壶] {olive}%s (%N) {default}还剩余 {yellow}%i {default}血量.", g_sSpecialName[g_iSI_ID], attacker, GetEntProp(attacker, Prop_Data, "m_iHealth"));
            //     else CPrintToChatAll("{blue}[茶壶] {olive}%N {default}还剩余 {yellow}%i {default}血量.", attacker, GetEntProp(attacker, Prop_Data, "m_iHealth"));

            //     ForcePlayerSuicide(attacker);
            //     //return Plugin_Changed;
            // }

            // if(IsTank(g_iSI_ID) && !g_bGod)
            //     SDKHooks_TakeDamage(victim, attacker, attacker, g_fTankDmg);
            // if(!g_bGod)
            //     damage = 1.0;
            // damage = 0.0;
            //return Plugin_Changed;

            switch(g_iSI_ID){
                //smoker
                case 1:
                {
                    if(IsPlayerGetContolled(attacker, g_iSI_ID)){
                        if(g_bOneShot)
                            ForcePlayerSuicide(victim);
                        else{

                            //被控下造成10点伤害
                            if(!g_bGod && !IsPlayerGetUp(victim))
                                SDKHooks_TakeDamage(victim, attacker, attacker, g_fSIDmg);
                            DamageReport(attacker, g_iSI_ID);
                        
                            ForcePlayerSuicide(attacker);
                        }
                    }
                    else{
                        //肘击造成5点伤害
                        if(!g_bGod && !IsPlayerGetUp(victim))
                            SDKHooks_TakeDamage(victim, attacker, attacker, g_fScratchDmg);
                    }
                }
                //boomer
                case 2:
                {
                    if(!g_bGod && !IsPlayerGetUp(victim))
                        SDKHooks_TakeDamage(victim, attacker, attacker, g_fScratchDmg);
                }
                //hunter
                case 3:
                {
                    if(IsPlayerGetContolled(attacker, g_iSI_ID)){
                        if(g_bOneShot)
                            ForcePlayerSuicide(victim);
                        else{

                            //被控下造成10点伤害
                            if(!g_bGod && !IsPlayerGetUp(victim))
                                SDKHooks_TakeDamage(victim, attacker, attacker, g_fSIDmg);
                            DamageReport(attacker, g_iSI_ID);
                        
                            ForcePlayerSuicide(attacker);
                        }
                    }
                    else{
                        //肘击造成5点伤害
                        if(!g_bGod && !IsPlayerGetUp(victim))
                            SDKHooks_TakeDamage(victim, attacker, attacker, g_fScratchDmg);
                    }
                }
                //spitter
                case 4:
                {
                    //每次1点
                    if(!g_bGod){
                        SDKHooks_TakeDamage(victim, attacker, attacker, 1.0);
                    }
                }
                //jockey
                case 5:
                {
                    if(IsPlayerGetContolled(attacker, g_iSI_ID)){
                        if(g_bOneShot)
                            ForcePlayerSuicide(victim);
                        else{

                            //被控下造成10点伤害
                            if(!g_bGod && !IsPlayerGetUp(victim))
                                SDKHooks_TakeDamage(victim, attacker, attacker, g_fSIDmg);
                            DamageReport(attacker, g_iSI_ID);
                        
                            ForcePlayerSuicide(attacker);
                        }
                    }
                    else{
                        //肘击造成5点伤害
                        if(!g_bGod && !IsPlayerGetUp(victim))
                            SDKHooks_TakeDamage(victim, attacker, attacker, g_fScratchDmg);
                    }
                }
                //charger
                case 6:
                {
                    if(IsPlayerGetContolled(attacker, g_iSI_ID)){
                        if(g_bOneShot)
                            ForcePlayerSuicide(victim);
                        else{

                            //被控下造成10点伤害
                            if(!g_bGod && !IsPlayerGetUp(victim))
                                SDKHooks_TakeDamage(victim, attacker, attacker, g_fSIDmg);
                            DamageReport(attacker, g_iSI_ID);
                        
                            ForcePlayerSuicide(attacker);
                        }
                    }
                    else{
                        //肘击造成5点伤害
                        if(!g_bGod && !IsPlayerGetUp(victim))
                            SDKHooks_TakeDamage(victim, attacker, attacker, g_fScratchDmg);
                    }
                }
                //Tank
                case 8:
                {
                    if(g_bOneShot)
                        ForcePlayerSuicide(victim);
                    else{
                        if(!g_bGod && !IsPlayerGetUp(victim))
                            SDKHooks_TakeDamage(victim, attacker, attacker, g_fTankDmg);
                    }
                }
            }
        }
        //damage = 0.0;
        return Plugin_Changed;
    }

    //Tank Part
    if(IsPlayerAlive(victim) && IsValidSI(victim)){
        int g_iSI_ID;
        g_iSI_ID = GetEntProp(victim, Prop_Send, "m_zombieClass");
        //PrintToChatAll("iClass为%d", g_iSI_ID);
        if(g_iSI_ID == 8){
            //生还造成的伤害
            if(!(g_fDamageTheSIGet[victim] < g_fTankHealth)){
                ForcePlayerSuicide(victim);
                g_fDamageTheSIGet[victim] = 0.0;
            }
            else
                g_fDamageTheSIGet[victim] += damage;
        }
    }

    return Plugin_Continue;
}

void DamageReport(int attacker, int iClass){
    if(!IsFakeClient(attacker))
        CPrintToChatAll("{blue}[伤害报告] {olive}%s (%N) {default}还剩余 {yellow}%i {default}血量.", g_sSpecialName[iClass], attacker, GetEntProp(attacker, Prop_Data, "m_iHealth"));
    else CPrintToChatAll("{blue}[伤害报告] {olive}%N {default}还剩余 {yellow}%i {default}血量.", attacker, GetEntProp(attacker, Prop_Data, "m_iHealth"));

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

// //舌头防卡死部分
// void Event_Tongue_Grab(Event event, const char[] name, bool dontBroadcast){
//     int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
//     int victim = GetClientOfUserId(GetEventInt(event, "victim"));

//     //玩家被拉后对应数组存为true
//     //CreateTimer(3.0, Timer_CheckTongueState, _, TIMER_REPEAT);
//     g_bTongueGrab[victim][attacker] = true;
// }

// public Action PlayerJump(int client, const char[] command, int args){
//     if(IsValidSur(client) && IsPlayerAlive(client))
//         g_bJump = true;
//     //CreateTimer(2.0, Timer_CheckJump);
//     return Plugin_Stop;
// }

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]){
    //如果摁了跳跃
    if(buttons & IN_JUMP == IN_JUMP){
        if(IsValidSur(client) && IsPlayerAlive(client)){
            int attacker;
            if((attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner")) > 0){
                if(g_bOneShot)
                    ForcePlayerSuicide(client);
                else{
                    if(!g_bGod && !IsPlayerGetUp(client))
                        SDKHooks_TakeDamage(client, attacker, attacker, g_fSIDmg);
                    DamageReport(attacker, 1);

                    ForcePlayerSuicide(attacker);
                }
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

//玩家倒地后处死
void Event_IncapacitatedStart(Event event, const char[] name, bool dontBroadcast){
    int victim = GetClientOfUserId(event.GetInt("userid"));
    ForcePlayerSuicide(victim);
}