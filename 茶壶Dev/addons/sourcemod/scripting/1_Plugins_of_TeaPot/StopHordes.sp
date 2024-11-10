#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <multicolors>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_FLAG	  FCVAR_SPONLY | FCVAR_NOTIFY
#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))

/*
v1.7.0
    1.现在克局起始路程由激怒坦克时的路程作为起点，而非坦克生成时的路程
    2.修复了由路程计算错误导致的路程播报刷屏的问题，但现在路程播报坏掉了
    3.优化了对坦克总数量的计算方法，相对以前更准确
2024.8.25 - v1.7.1
    重写克局开始与结束判定
*/

int g_iSurCurrent;   //生还当前路程
int g_iTankPath;     //坦克生成后的路程记录

int g_iSurTempPath;
int g_iKeepSpPath;

float g_dRunOffPenalty; //跑图惩罚

bool g_bIsMapStarted;
bool g_bIsSurRunning;
bool g_bIsTheLastTank;
bool g_bIsATimerRunning;

public Plugin myinfo =
{
	name		= "StopHordes",
	author		= "MopeCup",
	description = "当坦克生成时，禁用尸潮生成",
	version		= "1.7.1"

}

public void OnPluginStart(){
    //注册指令
    RegConsoleCmd("sm_tank", GetPathCmd);
	RegConsoleCmd("sm_p", GetPathCmd);
	RegConsoleCmd("sm_t", GetPathCmd);

    //事件钩子
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("tank_spawn", Event_TankSpawn);
    HookEvent("tank_killed", Event_TankKilled);

    PrecacheSound("ui/pickup_secret01.wav", false);
}

public void OnMapStart(){
    g_bIsMapStarted = true;
    ResetPlugin();
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
    g_bIsMapStarted = true;
    ResetPlugin();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
    g_bIsMapStarted = false;
    ResetPlugin();
}

public void OnMapEnd(){
    g_bIsMapStarted = false;
    ResetPlugin();
}

//重置状态栏
void ResetPlugin(){
    g_bIsATimerRunning = false;
    g_bIsSurRunning = false;
    g_bIsTheLastTank = false;
    g_iSurCurrent = 0;
    g_iTankPath = 0;
    g_iSurTempPath = 0;
    g_iKeepSpPath = 0;
    g_dRunOffPenalty = 1.0;
}

void ResetPlugin1(){
    g_bIsATimerRunning = false;
    g_bIsSurRunning = false;
    g_iSurCurrent = 0;
    g_iTankPath = 0;
    g_iSurTempPath = 0;
    g_iKeepSpPath = 0;
    g_dRunOffPenalty = 1.0;
}

//路程查询
//生还可以通过此项指令查询当前路程
Action GetPathCmd(int client, int args){
    if(client == 0)
        return Plugin_Handled;
    RequestFrame(OnNextFrame_CurrentCmd, GetClientUserId(client));
    return Plugin_Handled;
}

/*以下函数来自哈利波特 l4d_current_survivor_progress.sp*/
void OnNextFrame_CurrentCmd(int client){
    client = GetClientOfUserId(client);
	if (!client || !IsClientInGame(client)) return;

	g_iSurCurrent = GetMaxSurvivorCompletion();
	CPrintToChat(client, "{default}[{olive}当前路程{default}] {blue}Current{default}: {green}%d%%", g_iSurCurrent)
}

int GetMaxSurvivorCompletion() {
	float flow = 0.0;
	if(L4D_IsVersusMode())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				flow = MAX(flow, L4D2Direct_GetFlowDistance(i));
			}
		}
		
		flow = (flow / L4D2Direct_GetMapMaxFlowDistance());
	}
	else
	{
		float tmp_flow, origin[3];
		Address pNavArea;
		for (int client = 1; client <= MaxClients; client++) {
			if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
			{
				GetClientAbsOrigin(client, origin);
				pNavArea = L4D2Direct_GetTerrorNavArea(origin);
				if (pNavArea != Address_Null)
				{
					tmp_flow = L4D2Direct_GetTerrorNavAreaFlow(pNavArea);
					flow = MAX(flow, tmp_flow);
				}
			}
		}

		flow = flow / L4D2Direct_GetMapMaxFlowDistance();
	}

	//PrintToChatAll("%.2f - %d -%.2f", flow, g_iSurCurrent, (g_hBossBuffer.FloatValue / L4D2Direct_GetMapMaxFlowDistance()));
	flow = flow * 100;
	if (flow <= 1.0) flow = g_iSurCurrent * 1.0;
	else if(flow > 100.0) flow = 100.0;

	return RoundToNearest(flow);
}
/*以上内容来自哈利波特 l4d_current_survivor_progress.sp*/

//坦克生成提醒
public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast){
    CPrintToChatAll("{red}Tank已生成!");

    if (!IsSoundPrecached("ui/pickup_secret01.wav")) {
 		PrecacheSound("ui/pickup_secret01.wav", false);
	}

    EmitSoundToAll("ui/pickup_secret01.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
}

public void Event_TankKilled(Event event, const char[] name, bool dontBroadcast){
    CreateTimer(1.0, Timer_TankDeath, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_TankDeath(Handle timer){
    if(!IsTankFightOn(g_bIsATimerRunning))
        ResetPlugin1();

    return Plugin_Stop;
}

bool IsTankFightOn(bool IsATimerRunning){
    int i;
    int iTankNum = 0;
    for(i = 1; i < MaxClients + 1; i++){
        if(!IsValidTank(i))
            continue;
        if(!IsATimerRunning && !IsActiveTank(i))
            continue;
        iTankNum++;
    }

    if(iTankNum > 0)
        return true;

    return false;
}

//生成实体后触发此函数
public void OnEntityCreated(int entity, const char[] classname){
    //满足生成的是小尸时执行其下方的函数
    if( g_bIsMapStarted && entity > 0 && entity < 2048 && strcmp(classname, "infected") == 0 ){
        //我们希望当无限尸潮发生时、坦克存活时、生还没有推进时和没有boomer相关buff时组织尸潮的生成
        //只要场上的坦克数量仍大于一，插件就不会停止作用
        if(IsInfiniteHordeActive() && IsTankFightOn(g_bIsATimerRunning) && !g_bIsTheLastTank){
            //停止尸潮生成
            //我们需要创建一个计时器来判断生还是否进行推进，此计时器会一直活跃到坦克死亡为止
            //注意:此函数是每次创建小尸都会调用一次
            //为防止出现同时存在多个计数器导致插件bug，我们需要引入一个bool变量来判定是否有计时器正在运行
            if(!g_bIsSurRunning && !IsSurVomited()){
                if(!g_bIsATimerRunning){
                    g_iTankPath = GetMaxSurvivorCompletion();
                    g_iSurTempPath = g_iTankPath;
                    g_iKeepSpPath = g_iTankPath + 5;

                    CreateTimer(1.0, Timer_IsSurRunning, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                    g_bIsATimerRunning = true;
                    //这样就可以解决同时存在多个计时器的问题
                }

                SDKHook(entity, SDKHook_SpawnPost, OnSpawn)
            }

            // if(!g_bIsSurRunning && !IsSurVomited())
            //     SDKHook(entity, SDKHook_SpawnPost, OnSpawn);
        }
    }
}

public Action Timer_IsSurRunning(Handle timer){
    //我们每一秒检测一次生还的路程是否大于g_iKeepSpPath，若大于结束计时器并将g_bIsSurRunning置为真，否则保持其为假
    g_iSurCurrent = GetMaxSurvivorCompletion();

    //满足以下条件，计时器应当立即停止防止刷屏
    if(IsSurVomited() || !IsInfiniteHordeActive() || !IsTankFightOn(g_bIsATimerRunning) || g_bIsTheLastTank){
        g_bIsATimerRunning = false;
        return Plugin_Stop;
    }

    if(g_iSurCurrent > g_iSurTempPath && g_iSurCurrent < g_iKeepSpPath){
        g_iSurTempPath = g_iSurCurrent;
        int g_ilastPath = g_iKeepSpPath - g_iSurCurrent;
        CPrintToChatAll("{blue}继续推进{olive}%d%%{blue}将生成尸潮。", g_ilastPath);
    }
    else if(g_iSurCurrent > g_iKeepSpPath){
        //g_iTankPath = g_iSurCurrent;
        CPrintToChatAll("{red}当前推进路程过多将生成尸潮!");
        g_bIsSurRunning = true;
        CreateTimer(g_dRunOffPenalty, Timer_stopHordesLag, _, TIMER_FLAG_NO_MAPCHANGE);
        //在停止计时器的同时，我们也应该将 g_bIsATimerRunning 置为false
        g_bIsATimerRunning = false;
        return Plugin_Stop;
    }

    //PrintHintTextToAll("[test]尸潮停刷生效中...")

    return Plugin_Continue;
}

//延迟1.0s后继续停止尸潮生成
public Action Timer_stopHordesLag(Handle timer){
    g_dRunOffPenalty += 0.5;
    //g_iTankPath = GetMaxSurvivorCompletion();
    if(g_dRunOffPenalty < 5.0)
        g_bIsSurRunning = false;
    
    return Plugin_Stop;
}

//判断是否有被喷中
bool IsBoomed(int client)
{
	return ((GetEntPropFloat(client, Prop_Send, "m_vomitStart") + 0.01) > GetGameTime());
}

bool IsSurVomited(){
    int i =0;
    for(i = 1; i < MaxClients; i++){
        if(IsBoomed(i))
            return true;
    }
    return false;
}

//无限尸潮判断
bool IsInfiniteHordeActive()
{
	int countdown = GetHordeCountdown();
	return (countdown > -1 && countdown <= 10);
}

int GetHordeCountdown()
{
	return (CTimer_HasStarted(L4D2Direct_GetMobSpawnTimer())) ? RoundFloat(CTimer_GetRemainingTime(L4D2Direct_GetMobSpawnTimer())) : -1;
}

//是否为救援坦克
public Action L4D2_OnSendInRescueVehicle(){
    g_bIsTheLastTank = true;
    return Plugin_Continue;
}

//是否为有效坦克
bool IsValidTank(int client){
    if(IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client,Prop_Send,"m_zombieClass") == 8 && IsPlayerAlive(client))
        return true;
    return false;
}

//是否为激活的坦克
bool IsActiveTank(int client){
    if(GetEntProp(client, Prop_Send, "m_zombieState") == 1 || GetEntProp(client, Prop_Send, "m_hasVisibleThreats") == 1)
        return true;
    return false;
}

void OnSpawn(int entity)
{
	RemoveEntity(entity);
}