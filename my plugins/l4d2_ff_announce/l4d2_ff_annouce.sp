#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

//常量定义
#define VERSION "1.0.0"
//#define CVAR_FLAG FCVAR_SPONLY|FCVAR_NOTIFY
#define VERSUS 2

//作者信息
public Plugin myinfo = {
	name = "L4D2 FF Annouce",
	author = "MopeCup",
	description = "在关卡重启或结束时显示友伤数据",
	version = "VERSION",
};

int g_iGameMode;

//bool g_bLateLoad;
bool g_bFFTimer[MAXPLAYERS + 1];

Handle g_hFFTimer[MAXPLAYERS + 1];

esData
    g_esData[MAXPLAYERS + 1];

enum struct esData{
    int ffDmgGet_Total;
    int ffDmgMake_Total;

    int ffDmgGet[MAXPLAYERS + 1];
    int ffDmgMake[MAXPLAYERS + 1];

    int ffDmgMake_Temp[MAXPLAYERS + 1];

    void ClearFFDmg(){
        this.ffDmgGet_Total = 0;
        this.ffDmgMake_Total = 0;

        int i;
        for(i = 1; i <= MaxClients; i++){
            this.ffDmgGet[i] = 0;
            this.ffDmgMake[i] = 0;
        }
    }
}

public void OnPluginStart(){
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("map_transition", Event_MapTransition);
    HookEvent("player_hurt", Event_PlayerHurt);
}

public void OnClientDisconnect(int client){
    //清除其他玩家对断连玩家的友伤数据
    for(int i = 1; i <= MaxClients; i++){
        g_esData[i].ffDmgGet[client] = 0;
        g_esData[i].ffDmgMake[client] = 0;
        g_esData[i].ffDmgGet_Total -= g_esData[client].ffDmgMake[i];
        g_esData[i].ffDmgMake_Total -= g_esData[client].ffDmgGet[i];
    }
    //清除断链玩家的友伤数据
    g_esData[client].ClearFFDmg();
}

public void OnMapEnd(){
    ClearFFData();
}

//=====================================================================================
//=                                     Event
//=====================================================================================
void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
    PrintFFReport();
    OnMapEnd();
}

void Event_MapTransition(Event event, const char[] name, bool dontBroadcast){
    PrintFFReport();
    OnMapEnd();
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast){
    int attacker, victim;
    if((attacker = GetClientOfUserId(event.GetInt("attacker"))) == 0 || GetClientTeam(attacker) != 2)
        return;
    if((victim = GetClientOfUserId(event.GetInt("userid"))) == 0 || GetClientTeam(victim) != 2)
        return;
    
    int dmg = event.GetInt("dmg_health");
    //g_esData[attacker].ffDmgMake_Temp[victim] = dmg;
    g_esData[attacker].ffDmgMake_Total += dmg;
    g_esData[attacker].ffDmgMake[victim] += dmg;
    g_esData[victim].ffDmgGet_Total += dmg;
    g_esData[victim].ffDmgGet[attacker] += dmg;
    
    //如果是首次造成友伤,记录伤害并启动计时器
    if(!g_bFFTimer[attacker]){
        g_esData[attacker].ffDmgMake_Temp[victim] = dmg;
        Handle pack;
        g_bFFTimer[attacker] = true;
        //KillTimer(g_hFFTimer[attacker]);
        g_hFFTimer[attacker] = CreateDataTimer(1.0, FFAnnounce, pack);
        WritePackCell(pack, attacker);
        for(int i = 1; i < MaxClients; i++){
            if(i == attacker || i == victim)
                continue;
            g_esData[attacker].ffDmgMake_Temp[i] = 0;
        }
    }
    //如果并非首次造成友伤则记录数值
    else{
        Handle pack;
        g_esData[attacker].ffDmgMake_Temp[victim] += dmg;
        KillTimer(g_hFFTimer[attacker]);
        g_hFFTimer[attacker] = CreateDataTimer(0.5, FFAnnounce, pack);
        WritePackCell(pack, attacker);
    }
}

//=====================================================================================
//=                                 执行播报
//=====================================================================================
//立刻播报
Action FFAnnounce(Handle timer, Handle pack){
    char sVictim[32], sAttacker[32];
    int dmg;
    ResetPack(pack);
    int attacker = ReadPackCell(pack);
    g_bFFTimer[attacker] = false;
    if(IsClientInGame(attacker) && !IsFakeClient(attacker)){
        GetClientName(attacker, sAttacker, sizeof(sAttacker));
    }
    else
        sAttacker = "断连玩家";
    
    for(int i = 1; i <= MaxClients; i++){
        if(attacker != i && IsClientInGame(i) && GetClientTeam(i) == 2){
            dmg = g_esData[attacker].ffDmgMake_Temp[i];
            if(dmg != 0){
                GetClientName(i, sVictim, sizeof(sVictim));
                int j;
                for(j = 1; j <= MaxClients; j++){
                    if(!IsClientInGame(j))
                        continue;
                    if(j == attacker){
                        PrintToChat(j, "\x04[FF] \x01你对\x05%s\x01造成\x05%d\x01点友伤", sVictim, dmg);
                        continue;
                    }
                    if(j == i){
                        PrintToChat(j, "\x04[FF] \x05%s\x01对你造成\x05%d\x01点友伤", sAttacker, dmg);
                        continue;
                    }
                    PrintToChat(j, "\x04[FF] \x05%s\x01对\x05%s\x01造成\x05%d\x01点友伤", sAttacker, sVictim, dmg);
                }
                g_esData[attacker].ffDmgMake_Temp[i] = 0;
            }  
        }
    }

    return Plugin_Stop;
}

//结束播报
void PrintFFReport(){
    g_iGameMode = L4D_GetGameModeType();
    int count;
	int client;
	int[] clients = new int[MaxClients];
    for(client = 1; client <= MaxClients; client++){
        if(IsClientConnected(client) && 
        ((g_iGameMode == VERSUS && GetClientTeam(client) == 2) || (GetClientTeam(client) == 2 || (GetClientTeam(client) == 1 && IsGetBotOfIdlePlayer(client) != 0))))
            clients[count++] = client;
    }

    if(!count)
        return;
    
    int infoMax = count < 4 ? 4 : count;

    int i, j, k;

    int dmgGet_T;
    int dmgMake_T;
    int dmgFFGet;
    int dmgFFMake;

    for(i = 0; i < infoMax; i++){
        //按照友伤受到进行排行
        client = clients[i];
        //每位玩家按受到队友友伤大小对队友序号进行排序
        for(j = 0; j < (infoMax - 1); j++){
            for(k = j + 1; k < infoMax; k++){
                int client1 = clients[j];
                int client2 = clients[k];
                if(g_esData[client].ffDmgGet[client1] < g_esData[client].ffDmgGet[client2]){
                    clients[j] = client2;
                    clients[k] = client1;
                }
            }
        }
        dmgGet_T = g_esData[client].ffDmgGet_Total;
        dmgMake_T = g_esData[client].ffDmgMake_Total;
        
        char str[12];
        int dataSort[MAXPLAYERS + 1];
        
        //找到最长友伤接受字符长度
        count = 0;
        for(j = 0; j < infoMax; j++){
            int client1 = clients[j];
            dataSort[count++] = g_esData[client].ffDmgGet[client1];
        }
        SortIntegers(dataSort, count, Sort_Descending);
        int dmgFFGetLen = !count ? 1 : IntToString(dataSort[0], str, sizeof str);

        count = 0;
        for(j = 0; j < infoMax; j++){
            int client1 = clients[j];
            dataSort[count++] = g_esData[client].ffDmgMake[client1];
        }
        SortIntegers(dataSort, count, Sort_Descending);
        int dmgFFMakeLen = !count ? 1 : IntToString(dataSort[0], str, sizeof str);

        int len, numSpace;
        char buffer[254];

        PrintToChat(client, "\x04友伤统计: \x01你本局共计受到友伤\x05%d\x01, 造成友伤\x05%d\x01", dmgGet_T, dmgMake_T);
        PrintToChat(client, "\x04你与队友之间的友伤分布");
        for(j = 0; j < infoMax; j++){
            int client1 = clients[j];
            if(client1 == client)
                continue;
            
            dmgFFGet = g_esData[client].ffDmgGet[client1];
            dmgFFMake = g_esData[client].ffDmgMake[client1];
            strcopy(buffer, sizeof buffer, "\x04[FF] \x01造成友伤: ");
            numSpace = dmgFFGetLen - IntToString(dmgFFGet, str, sizeof str);
            AppendSpaceChar(buffer, sizeof buffer, numSpace);
            len = strlen(buffer);
            Format(buffer[len], sizeof buffer - len, "\x05%s", str);
            AppendSpaceChar(buffer, sizeof buffer, numSpace);

            len = strlen(buffer);
            strcopy(buffer[len], sizeof buffer - len, "\x01受到友伤: ");
            numSpace = dmgFFMakeLen - IntToString(dmgFFMake, str, sizeof str);
            AppendSpaceChar(buffer, sizeof buffer, numSpace);
            len = strlen(buffer);
            Format(buffer[len], sizeof buffer - len, "\x05%s", str);
            AppendSpaceChar(buffer, sizeof buffer, numSpace);

            len = strlen(buffer);
            Format(buffer[len], sizeof buffer - len, "\x01玩家: \x05%N", client1);

            PrintToChat(client, "%s", buffer);
        }
    }

    //按玩家造成友伤大小排序
    for(j = 0; j < (infoMax - 1); j++){
        for(k = j + 1; k < infoMax; k++){
            int client1 = clients[j];
            int client2 = clients[k];
            if(g_esData[client1].ffDmgMake_Total < g_esData[client2].ffDmgMake_Total){
                clients[j] = client2;
                clients[k] = client1;
            }
        }
    }

    for(i = 1; i <= MaxClients; i++){
        if(!IsClientInGame(i))
            continue;
        if((g_iGameMode == VERSUS && GetClientTeam(i) == 2) || (GetClientTeam(i) == 2 || (GetClientTeam(i) == 1 && IsGetBotOfIdlePlayer(i) != 0)))
            continue;
        
        char str[12];
        int dataSort[MAXPLAYERS + 1];

        count = 0;
        for(j = 0; j < infoMax; j++){
            client = clients[j];
            dataSort[count++] = g_esData[client].ffDmgGet_Total;
        }
        SortIntegers(dataSort, count, Sort_Descending);
        int dmgFFGetTLen = !count ? 1 : IntToString(dataSort[0], str, sizeof str);

        count = 0;
        for(j = 0; j < infoMax; j++){
            client = clients[j];
            dataSort[count++] = g_esData[client].ffDmgMake_Total;
        }
        SortIntegers(dataSort, count, Sort_Descending);
        int dmgFFMakeTLen = !count ? 1 : IntToString(dataSort[0], str, sizeof str);

        int len, numSpace;
        char buffer[254];
        
        PrintToChat(i, "\x04生还友伤分布");
        for(j = 0; j < infoMax; j++){
            client = clients[j];
            dmgGet_T = g_esData[client].ffDmgGet_Total;
            dmgMake_T = g_esData[client].ffDmgMake_Total;

            strcopy(buffer, sizeof buffer, "\x04[FF] \x01黑枪: ");
            numSpace = dmgFFMakeTLen - IntToString(dmgMake_T, str, sizeof str);
            AppendSpaceChar(buffer, sizeof buffer, numSpace);
            len = strlen(buffer);
            Format(buffer[len], sizeof buffer - len, "\x05%s", str);
            AppendSpaceChar(buffer, sizeof buffer, numSpace);

            len = strlen(buffer);
            strcopy(buffer[len], sizeof buffer - len, "\x01被黑: ");
            numSpace = dmgFFGetTLen - IntToString(dmgGet_T, str, sizeof str);
            AppendSpaceChar(buffer, sizeof buffer, numSpace);
            len = strlen(buffer);
            Format(buffer[len], sizeof buffer - len, "\x05%s", str);
            AppendSpaceChar(buffer, sizeof buffer, numSpace);

            len = strlen(buffer);
            Format(buffer[len], sizeof buffer - len, "\x01玩家: \x05%N", client);

            PrintToChat(i, "%s", buffer);
        }
    }
    
}

//=====================================================================================
//=                                     子函数
//=====================================================================================
//返回闲置玩家对应的bot
int IsGetBotOfIdlePlayer(int client)
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && IsClientIdle(i) == client && IsPlayerAlive(i))
			return i;

	return 0;
}

//返回电脑幸存者对应的玩家.
int IsClientIdle(int client)
{
	if(!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}

//清除友伤数据
void ClearFFData(){
    int i;
    for(i = 1; i <= MaxClients; i++){
        g_esData[i].ClearFFDmg();
        g_bFFTimer[i] = false;
    }
}

void AppendSpaceChar(char[] buffer, int maxlength, int numSpace){
	int len;
	for(int i; i < numSpace; i++){
		len = strlen(buffer);
		strcopy(buffer[len], maxlength - len, " ");
	}
}