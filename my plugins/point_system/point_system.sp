#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <left4dhooks>
#include <l4d2util>
#include <cup_function>
#include <l4d2_skill_detect>

enum struct esPlayerCP
{
    int   sI;
    int   cI;
    int   dmgCB;
    float maxFlow;

    int   basicCP;
    float completeBonus;

    void  Reset(){
        this.sI            = 0;
        this.cI            = 0;
        this.dmgCB         = 160;
        this.basicCP       = 0;
        this.maxFlow       = 0.0;
        this.completeBonus = 0.0; }

int GetCompletePoint()
{
    this.basicCP       = RoundToNearest((this.sI + this.cI * 50) * this.maxFlow);
    this.completeBonus = this.dmgCB / 160.0;
    return RoundToNearest(this.basicCP * (1 + this.completeBonus) / 50);
}
}

esPlayerCP g_esPlayerCP[MAXPLAYERS + 1];

enum struct esPlayerSP
{
    int   kill;
    int   gunSkeet;
    int   meleeSkeet;
    int   deadStop;
    int   pinned;
    int   dmgGet;

    float skeetRate[3];
    float deadStopRate;
    float noHurtRate;

    void  Reset(){
        this.kill       = 0;
        this.gunSkeet   = 0;
        this.meleeSkeet = 0;
        this.deadStop   = 0;
        this.pinned     = 0;
        this.dmgGet     = 160;

        for (int i = 0; i < 3; i++){
            this.skeetRate[i] = 0.0; }
this.deadStopRate = 0.0;
this.noHurtRate   = 0.0;
}

int GetSkillPoint()
{
    this.skeetRate[2] = this.meleeSkeet / float(this.kill);
    this.skeetRate[1] = this.gunSkeet / float(this.kill);
    this.skeetRate[0] = this.skeetRate[1] + this.skeetRate[2];
    float allSI       = float(this.deadStop + this.pinned);
    this.deadStopRate = allSI == 0.0 ? 0.0 : this.deadStop / allSI;
    this.noHurtRate   = this.dmgGet / 160.0;

    int skillPoint    = RoundToNearest((50 * this.skeetRate[2] + 50 * this.skeetRate[1] + this.deadStopRate * 100 + this.dmgGet) / 3.6);
    return skillPoint;
}
}

esPlayerSP g_esPlayerSP[MAXPLAYERS + 1];

Handle     g_hTimer;

// int
//     g_iRound;

bool
    g_bLeftSafeArea,
    g_bInEndSafeRoom[MAXPLAYERS + 1],
    g_bLateLoad;

public Plugin myinfo =
{
    name    = "point system",
    author  = "MopeCup",
    version = "1.3.1",


}

public APLRes
    AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("GetPlayerMoney", native_GetPlayerMoney);
    CreateNative("GetTeamPoints", native_GetTeamPoints);
    CreateNative("GetTeamBonus", native_GetTeamBonus);
    RegPluginLibrary("point_system");

    g_bLateLoad = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    // Dealcvar();
    // HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("map_transition", Event_MapTransition);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
    HookEvent("infected_death", Event_InfectedDeath);
    // HookEvent("tank_spawn", Event_TankSpawn);
    //HookEvent("mission_lost", Event_MissionLost);
    HookEvent("bot_player_replace", Event_PlayerReplaceBot, EventHookMode_Pre);
    HookEvent("player_bot_replace", Event_BotReplacePlayer, EventHookMode_PostNoCopy);
    HookEvent("jockey_ride", Event_InterruptCombo, EventHookMode_Post);
    HookEvent("lunge_pounce", Event_InterruptCombo, EventHookMode_Post);
    HookEvent("charger_pummel_start", Event_InterruptCombo, EventHookMode_Post);
    HookEvent("choke_start", Event_InterruptCombo, EventHookMode_Post);

    RegConsoleCmd("sm_point", Cmd_CheckPoint);
    RegConsoleCmd("sm_bonus", Cmd_CheckPoint);

    if (g_bLateLoad && L4D_HasAnySurvivorLeftSafeArea())
        L4D_OnFirstSurvivorLeftSafeArea_Post(0);
}

// void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
// {
// 	Dealcvar();
// }

// void Dealcvar()
// {
//
// }

//==============================
//=     游戏开始阶段的初始化
//==============================
public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
    delete g_hTimer;
    if (!g_bLeftSafeArea)
        g_hTimer = CreateTimer(1.0, Timer_CompletePoint);
    g_bLeftSafeArea = true;
}

public void OnClientDisconnect_Post(int client)
{
    g_esPlayerCP[client].Reset();
    g_esPlayerSP[client].Reset();
}

public void OnMapStart()
{
    //g_iRound = 0;
    ResetData();
}

public void OnMapEnd()
{
    delete g_hTimer;
    g_bLeftSafeArea = false;
    for (int i = 1; i <= MaxClients; i++)
    {
        g_esPlayerCP[i].Reset();
        g_esPlayerSP[i].Reset();
        g_bInEndSafeRoom[i] = false;
    }
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    SummaryScore();
    OnMapEnd();
}

void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
    delete g_hTimer;
    SummaryScore();
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim   = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(victim))
        return;
    int dmg = event.GetInt("dmg_health");
    if (IsValidSur(victim) && !g_bInEndSafeRoom[victim])
    {
        if (!IsFakeClient(victim))
        {
            int lastdmgCB               = g_esPlayerCP[victim].dmgCB > dmg ? g_esPlayerCP[victim].dmgCB - dmg : 0;
            g_esPlayerCP[victim].dmgCB  = lastdmgCB;
            int lastdmgGet              = g_esPlayerSP[victim].dmgGet > dmg ? g_esPlayerSP[victim].dmgGet - dmg : 0;
            g_esPlayerSP[victim].dmgGet = lastdmgGet;
        }
        else
        {
            int player = IsClientIdle(victim);
            if (player > 0)
            {
                int lastdmgCB               = g_esPlayerCP[player].dmgCB > dmg ? g_esPlayerCP[player].dmgCB - dmg : 0;
                int lastdmgGet              = g_esPlayerSP[player].dmgGet > dmg ? g_esPlayerSP[player].dmgGet - dmg : 0;
                g_esPlayerCP[player].dmgCB  = lastdmgCB;
                g_esPlayerSP[player].dmgGet = lastdmgGet;
            }
            else
            {
                int lastdmgCB               = g_esPlayerCP[victim].dmgCB > dmg ? g_esPlayerCP[victim].dmgCB - dmg : 0;
                g_esPlayerCP[victim].dmgCB  = lastdmgCB;
                int lastdmgGet              = g_esPlayerSP[victim].dmgGet > dmg ? g_esPlayerSP[victim].dmgGet - dmg : 0;
                g_esPlayerSP[victim].dmgGet = lastdmgGet;
            }
        }
        return;
    }
    if (!IsValidClient(attacker))
        return;
    if (IsZombieClassSI(victim) && IsValidSur(attacker) && !g_bInEndSafeRoom[attacker])
    {
        g_esPlayerCP[attacker].sI += dmg;
    }
}

// void Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
// {
//     g_iRound++;
//     CPrintToChatAll("{blue}这是你们第{orange}%d{blue}次团灭，请再接再励", g_iRound);
// }

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim   = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(victim))
        return;
    if (IsValidSur(victim) && !g_bInEndSafeRoom[victim])
    {
        if (!IsFakeClient(victim) || (IsFakeClient(victim) && IsClientIdle(victim) <= 0))
        {
            g_esPlayerCP[victim].dmgCB  = 0;
            g_esPlayerSP[victim].dmgGet = 0;
        }
        else
        {
            int player                  = IsClientIdle(victim);
            g_esPlayerCP[player].dmgCB  = 0;
            g_esPlayerSP[player].dmgGet = 0;
        }
        return;
    }
    if (!IsValidClient(attacker))
        return;
    if (IsZombieClassSI(victim) && IsValidSur(attacker) && !g_bInEndSafeRoom[attacker])
    {
        if (!IsFakeClient(attacker))
        {
            g_esPlayerSP[attacker].kill++;
        }
    }
}

void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (!IsValidSur(attacker) || g_bInEndSafeRoom[attacker])
        return;
    g_esPlayerCP[attacker].cI++;
}

void Event_PlayerReplaceBot(Event event, const char[] name, bool dontBroadcast)
{
    int bot    = GetClientOfUserId(event.GetInt("bot"));
    int player = GetClientOfUserId(event.GetInt("player"));
    if (!bot || !player)
        return;
    if (IsValidSpec(player) && GetClientOfIdlePlayer(player) > 0)
        return;
    g_esPlayerSP[player].Reset();
    CopyData(bot, player);
    g_esPlayerCP[bot].Reset();
    g_esPlayerSP[bot].Reset();
}

void Event_BotReplacePlayer(Event event, const char[] name, bool dontBroadcast)
{
    int bot    = GetClientOfUserId(event.GetInt("bot"));
    int player = GetClientOfUserId(event.GetInt("player"));
    if (!bot || !player)
        return;
    if (IsValidSpec(player) && GetClientOfIdlePlayer(player) > 0)
        return;
    g_esPlayerSP[bot].Reset();
    CopyData(player, bot);
    g_esPlayerCP[player].Reset();
    g_esPlayerSP[player].Reset();
}

void Event_InterruptCombo(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));
    if (IsValidSI(attacker) && IsValidSur(victim))
    {
        g_esPlayerSP[victim].pinned++;
    }
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
    PrintToChatAll("Tank生成，路程将被锁定!");
}

Action Timer_CompletePoint(Handle timer)
{
    g_hTimer = null;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidSur(i) || (IsValidSpec(i) && GetClientOfIdlePlayer(i)))
        {
            if (IsPlayerAlive(i))
            {
                float flow = GetSurvivorFlow(i);
                if (g_esPlayerCP[i].maxFlow < flow)
                {
                    if (flow >= 1.0 || !IsTankStayInGame())
                    {
                        g_esPlayerCP[i].maxFlow = flow;
                    }
                }
            }
            if (!g_bInEndSafeRoom[i] && g_esPlayerCP[i].maxFlow >= 1.0 && IsClientInSafeArea(i))
                g_bInEndSafeRoom[i] = true;
        }
    }
    g_hTimer = CreateTimer(1.0, Timer_CompletePoint);
    return Plugin_Continue;
}

public void OnSkeetMelee(int survivor, int victim, bool isHunter, bool headshot)
{
    if (survivor > 0)
    {
        g_esPlayerSP[survivor].meleeSkeet++;
        g_esPlayerSP[survivor].deadStop++;
    }
}

public void OnSkeetSniper(int survivor, int victim, bool isHunter, bool headshot, int shots)
{
    if (survivor > 0)
    {
        g_esPlayerSP[survivor].gunSkeet++;
        g_esPlayerSP[survivor].deadStop++;
    }
}

public void OnSkeetMagnum(int survivor, int victim, bool isHunter, bool headshot, int shots)
{
    if (survivor > 0)
    {
        g_esPlayerSP[survivor].gunSkeet++;
        g_esPlayerSP[survivor].deadStop++;
    }
}

public void OnSkeetShotgun(int survivor, int victim, bool isHunter, bool headshot, int shots)
{
    if (survivor > 0)
    {
        g_esPlayerSP[survivor].gunSkeet++;
        g_esPlayerSP[survivor].deadStop++;
    }
}

public void OnSkeetGL(int survivor, int victim, bool isHunter, bool headshot)
{
    if (survivor > 0)
    {
        g_esPlayerSP[survivor].gunSkeet++;
        g_esPlayerSP[survivor].deadStop++;
    }
}

public void OnHunterDeadstop(int survivor, int hunter)
{
    g_esPlayerSP[survivor].deadStop++;
}

public void OnJockeyDeadstop(int survivor, int jockey)
{
    g_esPlayerSP[survivor].deadStop++;
}

public void OnChargerLevel(int survivor, int charger, bool headshot)
{
    g_esPlayerSP[survivor].deadStop++;
}

public void OnChargerLevelHurt(int survivor, int charger, int damage, bool headshot)
{
    g_esPlayerSP[survivor].deadStop++;
}

public void OnTongueCut(int survivor, int smoker)
{
    g_esPlayerSP[survivor].deadStop++;
}

public void OnSmokerSelfClear(int survivor, int smoker, bool withShove, bool headshot)
{
    g_esPlayerSP[survivor].deadStop++;
}

Action Cmd_CheckPoint(int client, int args)
{
    if (IsValidSur(client))
        PrintPointToClient(client);
    return Plugin_Handled;
}

void PrintPointToClient(int client)
{
    int count;
    int[] clients = new int[MaxClients];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidSur(i) || (IsValidSpec(i) && GetClientOfIdlePlayer(i) > 0))
        {
            clients[count++] = i;
        }
    }
    int completePoint[MAXPLAYERS + 1],
        basicPoint[MAXPLAYERS + 1],
        // completeBonus[MAXPLAYERS + 1],
        teamPoint = 0;
    float completeBonus[MAXPLAYERS + 1];
    for (int i = 0; i < count; i++)
    {
        int client1            = clients[i];
        completePoint[client1] = g_esPlayerCP[client1].GetCompletePoint();
        basicPoint[client1]    = g_esPlayerCP[client1].basicCP;
        completeBonus[client1] = g_esPlayerCP[client1].completeBonus;
        teamPoint += completePoint[client1];
    }
    for (int i = 0; i < count - 1; i++)
    {
        for (int j = i + 1; j < count; j++)
        {
            int client1 = clients[i];
            int client2 = clients[j];
            if (completePoint[client1] < completePoint[client2])
            {
                clients[i] = client2;
                clients[j] = client1;
            }
        }
    }

    //总结播报
    if (client == 0)
    {
        int highestClient = clients[0];
        CPrintToChatAll("{blue}❀ 本关总分 {orange}%d {blue}❀", teamPoint);
        CPrintToChatAll("{blue}最高得分 {orange}%N %d", highestClient, completePoint[highestClient]);
        for (int i = 0; i < count; i++)
        {
            int currentClient = clients[i];
            CPrintToChat(currentClient, "{blue}你的得分 {orange}%d#%d {blue}完成得分 {orange}%d {blue}奖励分 {orange}%.1f%%", completePoint[currentClient], i + 1, basicPoint[currentClient], completeBonus[currentClient] * 100.0);
        }
    }
    else
    {
        int highestClient = clients[0];
        CPrintToChat(client, "{blue}❀ 当前总分 {orange}%d {blue}❀", teamPoint);
        CPrintToChat(client, "{blue}最高得分 {orange}%N %d", highestClient, completePoint[highestClient]);
        CPrintToChat(client, "{blue}你的得分 {orange}%d {blue}完成得分 {orange}%d {blue}奖励分 {orange}%.1f%%", completePoint[client], basicPoint[client], completeBonus[client] * 100.0);
    }
}

void SummaryScore()
{
    if (!g_bLeftSafeArea)
        return;
    //总结
    PrintPointToClient(0);
    PanelPrint_SkillPoint();
}

void PanelPrint_SkillPoint()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i))
        {
            switch (GetClientTeam(i))
            {
                case 1:
                {
                    if (GetClientOfIdlePlayer(i) > 0)
                        GeneratePanel(i);
                }
                case 2:
                {
                    GeneratePanel(i);
                }
            }
        }
    }
}

void GeneratePanel(int client)
{
    Panel panel = new Panel();
    int kill,
        gunSkeet,
        meleeSkeet,
        pinned;

    float meleeSkeetRate,
        gunSkeetRate,
        skeetRate,
        deadStopRate,
        noHurtRate;

    kill = g_esPlayerSP[client].kill;
    gunSkeet = g_esPlayerSP[client].gunSkeet;
    meleeSkeet = g_esPlayerSP[client].meleeSkeet;
    pinned = g_esPlayerSP[client].pinned;
    int finalSkillPoint = g_esPlayerSP[client].GetSkillPoint();
    skeetRate           = g_esPlayerSP[client].skeetRate[0];
    gunSkeetRate        = g_esPlayerSP[client].skeetRate[1];
    meleeSkeetRate      = g_esPlayerSP[client].skeetRate[2];
    deadStopRate        = g_esPlayerSP[client].deadStopRate;
    noHurtRate          = g_esPlayerSP[client].noHurtRate;

    char line[128];
    FormatEx(line, sizeof line, "▶ 玩家: %N ", client);
    panel.DrawText(line);
    panel.DrawText(" ");

    FormatEx(line, sizeof line, "▶ 回合击杀: %d", kill > 0 ? kill : 0);
    panel.DrawText(line);
    panel.DrawText(" ");

    FormatEx(line, sizeof line, "★ 空爆率: %.1f%% \n 枪械空爆率(GSR): %.1f%%(%d) | 近战空爆率(MSR): %.1f%%(%d) ", skeetRate * 100.0, gunSkeetRate * 100.0, gunSkeet, meleeSkeetRate * 100.0, meleeSkeet);
    panel.DrawText(line);
    FormatEx(line, sizeof line, "☆ 防控率: %.1f%% 被控: %d次 ", deadStopRate * 100.0, pinned);
    panel.DrawText(line);
    FormatEx(line, sizeof line, "★ 保血率: %.1f%% ", noHurtRate * 100.0);
    panel.DrawText(line);
    panel.DrawText(" ");

    FormatEx(line, sizeof line, "▶ 综合评分: %d ", finalSkillPoint);
    panel.DrawText(line);

    panel.Send(client, DummyHandler, 60);
    delete panel;
}

public int DummyHandler(Handle menu, MenuAction action, int param1, int param2)
{
    return 1;
}

//==============================
//=         子函数
//==============================
void ResetData()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        g_esPlayerCP[i].Reset();
        g_esPlayerSP[i].Reset();
    }
}

void CopyData(int passer, int receiver)
{
    g_esPlayerCP[receiver].sI            = g_esPlayerCP[passer].sI;
    g_esPlayerCP[receiver].cI            = g_esPlayerCP[passer].cI;
    g_esPlayerCP[receiver].maxFlow       = g_esPlayerCP[passer].maxFlow;
    g_esPlayerCP[receiver].dmgCB         = g_esPlayerCP[passer].dmgCB;
    g_esPlayerCP[receiver].basicCP       = g_esPlayerCP[passer].basicCP;
    g_esPlayerCP[receiver].completeBonus = g_esPlayerCP[passer].completeBonus;
}

//获取路程
float GetSurvivorFlow(int client)
{
    //非存活生还返回0
    if (!IsValidSur(client))
        return 0.0;

    static float maxDistance;
    maxDistance = L4D2Direct_GetFlowDistance(client);
    return maxDistance / L4D2Direct_GetMapMaxFlowDistance();
}

//生还是否在安全区域
//代码来自"https://steamcommunity.com/id/ChengChiHou/"
stock bool IsClientInSafeArea(int client)
{
    int nav = L4D_GetLastKnownArea(client);
    if (!nav)
        return false;
    int  iAttr         = L4D_GetNavArea_SpawnAttributes(view_as<Address>(nav));
    bool bInStartPoint = !!(iAttr & 0x80);
    bool bInCheckPoint = !!(iAttr & 0x800);
    if (!bInStartPoint && !bInCheckPoint)
        return false;
    return true;
}

bool IsTankStayInGame()
{
    int i;
    for (i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i) || GetClientTeam(i) != 3 || GetEntProp(i, Prop_Send, "m_zombieClass") != 8)
            continue;

        return true;
    }

    return false;
}

//==============================
//=			Native
//==============================
int native_GetPlayerMoney(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return GetPlayerMoney(client);
}

/**
 * 获取玩家当前持有的积分
 *
 * @param client 	玩家索引
 * @return 有效生还返回持有积分，无效生还返回-1
 */
int GetPlayerMoney(int client)
{
    client = 1;
    return -1;
}

int native_GetTeamPoints(Handle plugin, int numParams)
{
    return GetTeamPoints();
}

/**
 * 获取团队总计分数
 * @remark 总计分数为路程与累计获取积分之积, 不会被消耗
 *
 * @return 返回生还团队获取的总分
 */
int GetTeamPoints()
{
    int teamPoints = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsFakeClient(i) && IsClientInGame(i))
        {
            switch (GetClientTeam(i))
            {
                case 1:
                {
                    if (GetClientOfIdlePlayer(i) > 0)
                        teamPoints += g_esPlayerCP[i].GetCompletePoint();
                }
                case 2:
                {
                    teamPoints += g_esPlayerCP[i].GetCompletePoint();
                }
            }
        }
    }
    return teamPoints;
}

int native_GetTeamBonus(Handle plugin, int numParams)
{
    return GetTeamBonus();
}

/**
 * 获取团队的奖励分
 *
 * @return 返回生还的奖励分
 */
int GetTeamBonus()
{
    return -1;
}