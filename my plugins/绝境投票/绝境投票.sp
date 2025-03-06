#include <left4dhooks>
#include <l4d2_nativevote>

#define PLUGIN_NAME "mutation4_vote"
#define PLUGIN_VERSION "1.0.0"

enum CmdKey
{
    CmdKey_Num = 1,
    CmdKey_Time,
    CmdKey_Limit,
    CmdKey_Pin,
    CmdKey_Aggressive,
    CmdKey_Assault,
    CmdKey_Flow
};

ArrayList
    g_aSILimit_Vote;

ConVar
    g_cvAlowSpecStartVote,
    g_cvAlowSpecJoinVote,
    g_cvAdminAlwaysPass,
    g_cvGameMode,
    g_cvRelaxMaxFlow;

int
    g_iMaxSpecials,
    g_iSILimit[7],
    g_iDominatorLimit,
    g_iAggressiveSpecials,
    g_iAssaultSpecials;

float
    g_fSpecialRespawnInterval;

char
    g_sCmdKeyTable[][] =
    {
        "num",
        "time",
        "limit",
        "pin",
        "aggressive",
        "assault",
        "flow"
    };

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "MopeCup",
	description = "投票修改绝境刷特",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/MopeCup/l4d2"

}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion gameVersion = GetEngineVersion();
    if (gameVersion == Engine_Left4Dead2)
        return APLRes_Success;
    else
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
    }
}

public void OnPluginStart()
{
    g_cvAlowSpecStartVote = CreateConVar(PLUGIN_NAME ... "allow_spec_start_vote", "0", "是否允许旁观发起投票<0: 否，1: 是>", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvAlowSpecJoinVote = CreateConVar(PLUGIN_NAME ... "allow_spec_join_vote", "0", "是否允许旁观参与投票<0: 否，1: 是>", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvAdminAlwaysPass = CreateConVar(PLUGIN_NAME ... "admin_always_pass", "0", "是否打开管理员一票通过<0: 否，1: 是>", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    RegConsoleCmd("sm_mutation4vote", Cmd_Mutation4Vote);
    RegConsoleCmd("sm_mvt", Cmd_Mutation4Vote);

    g_cvGameMode = FindConVar("mp_gamemode");
    g_cvRelaxMaxFlow = FindConVar("director_relax_max_flow_travel");
    g_cvGameMode.AddChangeHook(OnConVarChanged);
    GetScriptValue();
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetScriptValue();
}

Action Cmd_Mutation4Vote(int client, int args)
{
    char cmd[32];
    GetCmdArg(1, cmd, sizeof cmd);
    if (strlen(cmd) <= 0)
    {
        ReplyToCommand(client, "请输入关键词\n输入格式: !mvt <关键词> <数值>\n");
        ReplyToCommand(client, "<关键词>: \nnum - 特感数量\nlimit - 特感种类数量\npin - 控制型特感同时存在的种类数量限制\n");
        ReplyToCommand(client, "time - 刷特间隔\naggressive - 主动进攻\nassault - 强攻\nflow - 码数");
        return Plugin_Handled;
    }
    int keyNum = 0;
    for (int i = 0; i < 7; i++)
    {
        if (StrEqual(cmd, g_sCmdKeyTable[i]))
        {
            keyNum = i + 1;
            break;
        }
    }
    switch (keyNum)
    {
        case 0:
        {
            ReplyToCommand(client, "请输入关键词\n输入格式: !mvt <关键词> <数值>\n");
            ReplyToCommand(client, "<关键词>: \nnum - 特感数量\nlimit - 特感种类数量\npin - 控制型特感同时存在的种类数量限制\n");
            ReplyToCommand(client, "time - 刷特间隔\naggressive - 主动进攻\nassault - 强攻\nflow - 码数");
        }
        case 1:
        {
            int val = GetCmdArgInt(2);
            StartVote(client, CmdKey_Num, val);
        }
        case 2:
        {
            float val = GetCmdArgFloat(2);
            StartVote(client, CmdKey_Time, _, val);
        }
        case 3:
        {
            int val[7];
            for (int i = 0; i < 7; i++)
            {
                val[i] = GetCmdArgInt(i + 2);
            }
            StartVote(client, CmdKey_Limit, _, _, val);
        }
        case 4:
        {
            int val = GetCmdArgInt(2);
            StartVote(client, CmdKey_Pin, val);
        }
        case 5:
        {
            int val = GetCmdArgInt(2);
            StartVote(client, CmdKey_Aggressive, val);
        }
        case 6:
        {
            int val = GetCmdArgInt(2);
            StartVote(client, CmdKey_Assault, val);
        }
        case 7:
        {
            int val = GetCmdArgInt(2);
            StartVote(client, CmdKey_Flow, val);
        }
    }
    return Plugin_Handled;
}

void GetScriptValue()
{
    char gameMode[16];
    GetConVarString(g_cvGameMode, gameMode, sizeof gameMode);
    if (StrEqual(gameMode, "mutation4"))
    {
        g_iMaxSpecials = L4D2_GetScriptValueInt("cm_MaxSpecials", 8);
        g_iSILimit[0] = L4D2_GetScriptValueInt("cm_BaseSpecialLimit", 2);
        g_iSILimit[1] = L4D2_GetScriptValueInt("SmokerLimit", 2);
        g_iSILimit[2] = L4D2_GetScriptValueInt("BoomerLimit", 2);
        g_iSILimit[3] = L4D2_GetScriptValueInt("HunterLimit", 2);
        g_iSILimit[4] = L4D2_GetScriptValueInt("SpitterLimit", 2);
        g_iSILimit[5] = L4D2_GetScriptValueInt("JockeyLimit", 2);
        g_iSILimit[6] = L4D2_GetScriptValueInt("ChargerLimit", 2);
        g_iDominatorLimit = L4D2_GetScriptValueInt("DominatorLimit", 4);
        g_iAggressiveSpecials = L4D2_GetScriptValueInt("cm_AggressiveSpecials", 1);
        g_iAssaultSpecials = L4D2_GetScriptValueInt("SpecialInfectedAssault", 0);
        
        g_fSpecialRespawnInterval = L4D2_GetScriptValueFloat("cm_SpecialRespawnInterval", 15.0);
    }
}

/**
 * cm_SpecialRespawnInterval - 刷特时间间隔
 * cm_MaxSpecials - 最大特感数量
 * cm_BaseSpecialLimit - 这个参数必须取下面四个参数的最大值
 * HunterLimit
 * BoomerLimit
 * SmokerLimit
 * JockeyLimit
 * ChargerLimit
 * SpitterLimit
 * DominatorLimit - 控制型特感种类
 * cm_AggressiveSpecials - 特感主动进攻
 * SpecialInfectedAssault - 特感强攻
 * 
 * cvar director_relax_max_flow_travel
 */
public Action L4D2_OnGetScriptValueInt(const char[] key, int &retVal, int hScope)
{
    if (StrEqual(key, "cm_MaxSpecials"))
    {
        retVal = g_iMaxSpecials;
        return Plugin_Handled;
    }
    if (StrEqual(key, "cm_BaseSpecialLimit"))
    {
        retVal = g_iSILimit[0];
        return Plugin_Handled;
    }
    if (StrEqual(key, "SmokerLimit"))
    {
        retVal = g_iSILimit[1];
        return Plugin_Handled;
    }
    if (StrEqual(key, "BoomerLimit"))
    {
        retVal = g_iSILimit[2];
        return Plugin_Handled;
    }
    if (StrEqual(key, "HunterLimit"))
    {
        retVal = g_iSILimit[3];
        return Plugin_Handled;
    }
    if (StrEqual(key, "SpitterLimit"))
    {
        retVal = g_iSILimit[4];
        return Plugin_Handled;
    }
    if (StrEqual(key, "JockeyLimit"))
    {
        retVal = g_iSILimit[5];
        return Plugin_Handled;
    }
    if (StrEqual(key, "ChargerLimit"))
    {
        retVal = g_iSILimit[6];
        return Plugin_Handled;
    }
    if (StrEqual(key, "DominatorLimit"))
    {
        retVal = g_iDominatorLimit;
        return Plugin_Handled;
    }
    if (StrEqual(key, "cm_AggressiveSpecials"))
    {
        retVal = g_iAggressiveSpecials;
        return Plugin_Handled;
    }
    if (StrEqual(key, "SpecialInfectedAssault"))
    {
        retVal = g_iAssaultSpecials;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action L4D2_OnGetScriptValueFloat(const char[] key, float &retVal, int hScope)
{
    if (StrEqual(key, "cm_SpecialRespawnInterval"))
    {
        retVal = g_fSpecialRespawnInterval;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

void StartVote(int client, CmdKey keyVal, int param1 = 0, float param2 = 0.0, int[] param3 = {0, 0, 0, 0, 0, 0, 0})
{
    int team = GetClientTeam(client);
    if (team == 3)
    {
        PrintToChat(client, "\x03感染者不允许发起投票");
        return;
    }
    if (!g_cvAlowSpecStartVote.BoolValue && team == 1)
    {
        PrintToChat(client, "\x03旁观者不允许发起投票");
        return;
    }
    if (!L4D2NativeVote_IsAllowNewVote())
    {
        PrintToChat(client, "\x03发起投票失败,有一项投票正在进行中");
        return;
    }
    
    L4D2NativeVote vote = L4D2NativeVote(Vote_Handler);
    switch (keyVal)
    {
        case CmdKey_Num:
        {
            if (g_cvAdminAlwaysPass.BoolValue && IsClientAdmin(client))
            {
                PrintToChatAll("\x04%N\x03修改刷特数量为%d", client, param1);
                g_iMaxSpecials = param1;
                return;
            }
            //L4D2NativeVote vote = L4D2NativeVote(Vote_Handler);
            vote.Initiator = client;
            vote.SetDisplayText("%N发起投票: 修改刷特数量为%d?", client, param1);
            vote.Value = param1;
            vote.SetInfoString("1"); 
        }
        case CmdKey_Time:
        {
            if (g_cvAdminAlwaysPass.BoolValue && IsClientAdmin(client))
            {
                PrintToChatAll("\x04%N\x03修改刷特间隔为%.1fs", client, param2);
                g_fSpecialRespawnInterval = param2;
                return;
            }
            //L4D2NativeVote vote = L4D2NativeVote(Vote_Handler);
            vote.Initiator = client;
            vote.SetDisplayText("%N发起投票: 修改刷特间隔为%.1fs?", client, param2);
            vote.Value = param2;
            vote.SetInfoString("2"); 
        }
        case CmdKey_Limit:
        {
            if (g_cvAdminAlwaysPass.BoolValue && IsClientAdmin(client))
            {
                PrintToChatAll("\x04%N\x03修改特感种类为\n基础:%d Smoker%d Boomer%d Hunter%d Spitter%d Jockey%d Charger%d", client, param3[0], param3[1], param3[2], param3[3], param3[4], param3[5], param3[6]);
                for (int i = 0; i < 7; i++)
                {
                    g_iSILimit[i] = param3[i];
                }
                return;
            }
            //L4D2NativeVote vote = L4D2NativeVote(Vote_Handler);
            vote.Initiator = client;
            vote.SetDisplayText("%N发起投票: 修改特感种类为%d-%d %d %d %d %d %d?", client, param3[0], param3[1], param3[2], param3[3], param3[4], param3[5], param3[6]);
            //vote.Value = param3;
            delete g_aSILimit_Vote;
            g_aSILimit_Vote = new ArrayList(1);
            g_aSILimit_Vote.PushArray(param3);
            vote.SetInfoString("3");
        }
        case CmdKey_Pin:
        {
            if (g_cvAdminAlwaysPass.BoolValue && IsClientAdmin(client))
            {
                PrintToChatAll("\x04%N\x03修改控制特感种类为%d种", client, param1);
                g_iDominatorLimit = param1;
                return;
            }
            //L4D2NativeVote vote = L4D2NativeVote(Vote_Handler);
            vote.Initiator = client;
            vote.SetDisplayText("%N发起投票: 修改控制特感种类为%d种?", client, param1);
            vote.Value = param1;
            vote.SetInfoString("4"); 
        }
        case CmdKey_Aggressive:
        {
            if (g_cvAdminAlwaysPass.BoolValue && IsClientAdmin(client))
            {
                PrintToChatAll("\x04%N\x03修改特感主动进攻为%s", client, param1 > 0 ? "开启" : "关闭");
                g_iAggressiveSpecials = param1;
                return;
            }
            //L4D2NativeVote vote = L4D2NativeVote(Vote_Handler);
            vote.Initiator = client;
            vote.SetDisplayText("%N发起投票: 修改特感主动进攻为%s?", client, param1 > 0 ? "开启" : "关闭");
            vote.Value = param1;
            vote.SetInfoString("5"); 
        }
        case CmdKey_Assault:
        {
            if (g_cvAdminAlwaysPass.BoolValue && IsClientAdmin(client))
            {
                PrintToChatAll("\x04%N\x03修改特感强攻为%s", client, param1 > 0 ? "开启" : "关闭");
                g_iAssaultSpecials = param1;
                return;
            }
            //L4D2NativeVote vote = L4D2NativeVote(Vote_Handler);
            vote.Initiator = client;
            vote.SetDisplayText("%N发起投票: 修改特感强攻为%s?", client, param1 > 0 ? "开启" : "关闭");
            vote.Value = param1;
            vote.SetInfoString("6");
        }
        case CmdKey_Flow:
        {
            if (g_cvAdminAlwaysPass.BoolValue && IsClientAdmin(client))
            {
                PrintToChatAll("\x04%N\x03修改Relax最大允许推进距离为%d", client, param1);
                g_cvRelaxMaxFlow.IntValue = param1;
                return;
            }
            vote.Initiator = client;
            vote.SetDisplayText("%N发起投票: 修改Relax最大允许推进距离为%d?", client, param1);
            vote.Value = param1;
            vote.SetInfoString("7"); 
        }
    }

    int count = 0;
    int[] clients = new int[MaxClients];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            if (GetClientTeam(i) == 2 || GetClientOfIdlePlayer(i) > 0)
                clients[count++] = i;
            if (g_cvAlowSpecJoinVote.BoolValue && GetClientTeam(i) == 1 && GetClientOfIdlePlayer(i) <= 0)
                clients[count++] = i;
        }
    }
    if (!vote.DisplayVote(clients, count, 20))
        LogError("发起投票失败");
}

void Vote_Handler(L4D2NativeVote vote, VoteAction action, int param1, int param2)
{
    char cmdKey[2];
    vote.GetInfoString(cmdKey, sizeof cmdKey);
    int cmdKeyNum = StringToInt(cmdKey);
    switch (action)
    {
        case VoteAction_PlayerVoted:
        {
            PrintToChatAll("\x4%N\x01已投票", param1);
        }
        case VoteAction_End:
        {
            if (vote.YesCount > vote.PlayerCount / 2)
            {
                vote.SetPass("加载中...");
                switch (cmdKeyNum)
                {
                    case 1:
                    {
                        g_iMaxSpecials = vote.Value;
                    }
                    case 2:
                    {
                        g_fSpecialRespawnInterval = vote.Value;
                    }
                    case 3:
                    {
                        g_aSILimit_Vote.GetArray(0, g_iSILimit);
                    }
                    case 4:
                    {
                        g_iDominatorLimit = vote.Value;
                    }
                    case 5:
                    {
                        g_iAggressiveSpecials = vote.Value;
                    }
                    case 6:
                    {
                        g_iAssaultSpecials = vote.Value;
                    }
                    case 7:
                    {
                        g_cvRelaxMaxFlow.IntValue = vote.Value;
                    }
                }
                PrintToChatAll("\x03加载成功");
            }
            else
            {
                vote.SetFail();
            }
        }
    }
}

bool IsClientAdmin(int client)
{
    if (!IsClientInGame(client))
        return false;
    char steamId[32];
    GetClientAuthId(client, AuthId_Steam2, steamId, sizeof steamId);
    AdminId admin = FindAdminByIdentity(AUTHMETHOD_STEAM, steamId);
    return admin != INVALID_ADMIN_ID;
}

stock int GetClientOfIdlePlayer(int client)
{
    if (GetClientTeam(client) != 1)
        return -1;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientIdle(i) == client)
            return i;
    }
    return -1;
}

stock int IsClientIdle(int client)
{
    if(!IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != 2)
        return -1;
    if(!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
        return -1;
    return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}