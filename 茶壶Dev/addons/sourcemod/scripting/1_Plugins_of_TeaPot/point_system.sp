#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <left4dhooks>
#include <l4d2util>

public Plugin myinfo =
{
	name	= "point system",
	author	= "MopeCup",
	version = "1.2.0",

}

static const char g_sMainWeapons[][][] = {
	{ "shotgun_chrome", "铁喷", "models/w_models/weapons/w_pumpshotgun_A.mdl", "125", "0", "8" }, 
	{ "pumpshotgun", "木喷", "models/w_models/weapons/w_shotgun.mdl", "125", "0", "3" }, 
	{ "smg", "乌兹", "models/w_models/weapons/w_smg_uzi.mdl", "125", "0", "2" }, 
	{ "smg_silenced", "消音冲锋", "models/w_models/weapons/w_smg_a.mdl", "125", "0", "7" }, 
	{ "autoshotgun", "连喷", "models/w_models/weapons/w_autoshot_m4super.mdl", "200", "200", "4" }, 
	{ "shotgun_spas", "SPAS", "models/w_models/weapons/w_shotgun_spas.mdl", "300", "300", "11" }, 
	{ "rifle", "M16A2", "models/w_models/weapons/w_rifle_m16a2.mdl", "250", "250", "5" }, 
	{ "rifle_desert", "三连发", "models/w_models/weapons/w_desert_rifle.mdl", "220", "220", "9" }, 
	{ "rifle_ak47", "AK47", "models/w_models/weapons/w_rifle_ak47.mdl", "950", "950", "26" }, 
	{ "sniper_military", "连狙", "models/w_models/weapons/w_sniper_military.mdl", "2000", "2000", "10" }, 
	{ "hunting_rifle", "木狙", "models/w_models/weapons/w_sniper_mini14.mdl", "350", "350", "6" }, 
	{ "sniper_awp", "AWP", "models/w_models/weapons/w_sniper_awp.mdl", "1000", "1000", "35" }, 
	{ "sniper_scout", "鸟狙", "models/w_models/weapons/w_sniper_scout.mdl", "125", "0", "36" }, 
	{ "smg_mp5", "MP5", "models/w_models/weapons/w_smg_mp5.mdl", "125", "0", "33" }, 
	{ "rifle_sg552", "SG552", "models/w_models/weapons/w_rifle_sg552.mdl", "225", "225", "34" },
	//{"weapon_grenade_launcher",		"榴弹发射器",	"models/w_models/weapons/w_grenade_launcher.mdl"},
	//{"weapon_rifle_m60",			"M60",			"models/w_models/weapons/w_m60.mdl"},
};

static const char g_sSubWeapons[][][] = {
	// 需要使用近战解锁插件
	{"fireaxe",			 "斧头",			 "models/weapons/melee/w_fireaxe.mdl",		   "215", "215"},
	{ "baseball_bat",	  "棒球棒",		"models/weapons/melee/w_bat.mdl",			  "125", "125"},
	{ "cricket_bat",	 "球拍",			 "models/weapons/melee/w_cricket_bat.mdl",	   "125", "125"},
	{ "crowbar",		 "撬棍",			 "models/weapons/melee/w_crowbar.mdl",		   "180", "180"},
	{ "frying_pan",		"平底锅",		  "models/weapons/melee/w_frying_pan.mdl",	   "100", "100"},
	{ "golfclub",		  "高尔夫球棍", "models/weapons/melee/w_golfclub.mdl",		   "550", "550"},
	{ "electric_guitar", "吉他",			 "models/weapons/melee/w_electric_guitar.mdl", "135", "135"},
	{ "katana",			"武士刀",		  "models/weapons/melee/w_katana.mdl",		   "250", "250"},
	{ "machete",		 "砍刀",			 "models/weapons/melee/w_machete.mdl",		   "240", "240"},
	{ "tonfa",		   "警棍",		   "models/weapons/melee/w_tonfa.mdl",		   "80",	 "80" },
	{ "knife",		   "小刀",		   "models/w_models/weapons/w_knife_t.mdl",		"250", "250"},
	{ "pitchfork",	   "草叉",		   "models/weapons/melee/w_pitchfork.mdl",	   "75",	 "75" },
	{ "shovel",			"铁铲",			"models/weapons/melee/w_shovel.mdl",			 "125", "125"},
	{ "pistol_magnum",   "马格南",		 "",											 "125", "0"	},
 //{"weapon_chainsaw",		"电锯",			"models/weapons/melee/w_chainsaw.mdl"},
};

static const char g_sItems[][][] = {
	//{"weapon_pain_pills",		"止痛药",		"models/w_models/weapons/w_eq_painpills.mdl",               "0"},
	{"molotov",				 "燃烧瓶",		   "",													   "35",	 "35" },
	{ "pipe_bomb",			   "土制炸弹",	   "",													   "30",	 "30" },
	{ "vomitjar",				  "胆汁瓶",			"",														"40",  "40" },
	{ "upgradepack_incendiary", "燃烧弹升级包", "models/w_models/weapons/w_eq_incendiary_ammopack.mdl", "40",  "40" },
	{ "upgradepack_explosive",  "高爆弹升级包", "models/w_models/weapons/w_eq_explosive_ammopack.mdl",  "30",	"30" },
	{ "laser_sight",			 "红点升级",		 "",													 "250", "250"},
};

ConVar
	g_cvPointShop;

bool
	g_bLateLoad,
	g_bLeftSafeArea,
	g_bPointShop;

int
	g_iTotalPoint;
// g_iBasePoint;

float
	g_fShopCD;

Handle
	g_hWritePath;

enum struct esData
{
	int	  dmgSI;
	int	  dmgCI;
	int	  money;

	float PlayerPath;

	void  CleanInfected(){
		 this.dmgSI		 = 0;
		 this.dmgCI		 = 0;
		 this.PlayerPath = 0.0; }
}

esData
	g_esData[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("GetPlayerMoney", native_GetPlayerMoney);
	CreateNative("GetTeamPoints", native_GetTeamPoints);
	CreateNative("GetTeamBonus", native_GetPlayerBonus);
	RegPluginLibrary("point_system");

	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvPointShop = CreateConVar("ps_pointshop", "0", "是否开启分数商店<0:否, 1:是>", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_cvPointShop.AddChangeHook(ConVarChanged);
	Dealcvar();

	// HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_MapTransition);
	HookEvent("player_hurt", Event_PlayerHurt);
	// HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("infected_death", Event_InfectedDeath);
	// HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("mission_lost", Event_MissionLost);

	RegConsoleCmd("sm_point", Cmd_CheckPoint);
	RegConsoleCmd("sm_bonus", Cmd_CheckPoint);
	//点数商店
	RegConsoleCmd("sm_buy", Cmd_Shop);
	RegConsoleCmd("sm_b", Cmd_Shop);

	RegAdminCmd("sm_givemoney", Cmd_GiveMoney, ADMFLAG_GENERIC);

	g_iTotalPoint = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		g_esData[i].money = 160;
	}

	if (g_bLateLoad && L4D_HasAnySurvivorLeftSafeArea())
		L4D_OnFirstSurvivorLeftSafeArea_Post(0);
}

void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Dealcvar();
}

void Dealcvar()
{
	g_bPointShop = GetConVarBool(g_cvPointShop);
}

//获取当前分数
Action Cmd_CheckPoint(int client, int args)
{
	if (!client || !IsClientInGame(client))
		return Plugin_Handled;

	PrintPoint(client);

	return Plugin_Handled;
}

//==============================
//=     游戏开始阶段的初始化
//==============================
public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	if (!g_bLeftSafeArea)
	{
		g_hWritePath	= CreateTimer(1.0, Timer_WritePath, _, TIMER_REPEAT);
		g_bLeftSafeArea = true;
	}
}

public void OnClientDisconnect(int client)
{
	g_esData[client].CleanInfected();
	g_esData[client].money = 160;
}

// public void OnMapStart(){
//     if(L4D_IsFirstMapInScenario()){

//     }
// }
public void OnMapEnd()
{
	g_bLeftSafeArea = false;
	if (L4D_IsMissionFinalMap(true))
	{
		g_iTotalPoint = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			g_esData[i].money = 160;
		}
	}

	ClearData();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	//PrintPoint(0);

	OnMapEnd();
}

void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	PrintPoint(0);
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker, victim;
	if (!(attacker = GetClientOfUserId(event.GetInt("attacker"))) || !IsClientInGame(attacker))
		return;

	if (!(victim = GetClientOfUserId(event.GetInt("userid"))) || victim == attacker || !IsClientInGame(victim))
		return;

	if (GetClientTeam(victim) == 3 && GetClientTeam(attacker) == 2)
	{
		int dmg = event.GetInt("dmg_health");
		switch (GetEntProp(victim, Prop_Send, "m_zombieClass"))
		{
			case 1, 2, 3, 4, 5, 6:
			{
				g_esData[attacker].dmgSI += dmg;
				g_esData[attacker].money += (dmg / 50);
			}
		}
	}
}

void Event_MissionLost(Event event, const char[] name, bool dontBroadcast){
	for(int i = 1; i <= MaxClients; i++){
		if(IsValidSur(i)){
			int point = g_esData[i].money - 100;
			if(point < 60)
				continue;
			else if(point < 160){
				g_esData[i].money = 160;
			}
			else
				g_esData[i].money = point;
		}
	}
	PrintToChatAll("队伍团灭，所有生还扣除100点积分");
}

// void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast){
//     //生还死亡时，记录下他的路程
//     int victim;
//     if(!(victim = GetClientOfUserId(event.GetInt("userid"))) || GetClientTeam(victim) != 2)
//         return;

//     WritePlayerPath(victim, false, true);
//     //PrintToChatAll("%f", g_esData[victim].PlayerPath);
// }

void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2)
		return;

	g_esData[attacker].dmgCI++;
	g_esData[attacker].money++;
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	// for(int i = 1; i <= MaxClients; i++){
	//     if(!IsValidSur(i))
	//         continue;
	//     WritePlayerPath(i, true, false);
	// }
	CPrintToChatAll("{green}[积分系统] {blue}坦克生成，路程已锁定!");
}

//==============================
//=        记录路程
//==============================
Action Timer_WritePath(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidSur(i) || !IsPlayerAlive(i))
			continue;
		WritePlayerPath(i);
	}

	return Plugin_Continue;
}

//==============================
//=        积分播报
//==============================
void PrintPoint(int player)
{
	if (!g_bLeftSafeArea)
		return;

	delete g_hWritePath;

	int count;
	int client;
	int[] clients = new int[MaxClients];
	for (client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && ((GetClientTeam(client) == 1 && IsGetBotOfIdlePlayer(client) != 0) || GetClientTeam(client) == 2))
			clients[count++] = client;
	}

	if (!count)
		return;

	int infoMax	  = count < 4 ? 4 : count;
	int iPointSum = 0;
	int iPlayerPoint[MAXPLAYERS + 1];

	int i;
	for (i = 0; i < infoMax; i++)
	{
		client				 = clients[i];
		int	  dmgSI			 = g_esData[client].dmgSI;
		int	  dmgCI			 = g_esData[client].dmgCI;
		float path			 = g_esData[client].PlayerPath;

		iPlayerPoint[client] = RoundToNearest((dmgSI / 50 + dmgCI) * path);
		iPointSum += iPlayerPoint[client];
	}

	float fHealth = 0.0;
	count = 0;
	for(i = 1; i <= MaxClients; i++){
		if(IsValidSur(i)){
			if(IsPlayerAlive(i))
				fHealth += float(GetClientHealth(i));
			count++;
		}
	}
	float fBonus = fHealth / float(count);


	if (player == 0)
		g_iTotalPoint += RoundToNearest(iPointSum * (1 + fBonus/100.0));

	//排序
	int j;
	for (i = 0; i < (infoMax - 1); i++)
	{
		for (j = i + 1; j < infoMax; j++)
		{
			int client1, client2;
			client1 = clients[i];
			client2 = clients[j];
			if (iPlayerPoint[client1] < iPlayerPoint[client2])
			{
				clients[i] = client2;
				clients[j] = client1;
			}
		}
	}

	//播报
	if (player == 0)
	{
		client = clients[0];
		CPrintToChatAll("{green}分数统计\n{green}[累计总分: {olive}%d {green}| 本关总分: {olive}%d {green}| 奖励分: {olive}%.1f%% {green}] \n{green}[个人最高] {olive}%N - %d", g_iTotalPoint, iPointSum, fBonus, client, iPlayerPoint[client]);
		for (i = 0; i < infoMax; i++)
		{
			client = clients[i];
			CPrintToChat(client, "{green}[你的分数] {olive}%d(%d%%) #%d", iPlayerPoint[client], iPlayerPoint[client] * 100 / iPointSum, i + 1);
		}
	}
	else {
		if ((GetClientTeam(player) == 1 && IsGetBotOfIdlePlayer(player) != 0) || GetClientTeam(player) == 2)
		{
			client = clients[0];
			CPrintToChat(player, "{green}[当前分数{olive}%d {green}| 奖励分: {olive}%.1f%% {green}]\n[个人最高] {olive}%N - %d\n{green}[你的分数] {olive}%d", iPointSum, fBonus, client, iPlayerPoint[client], iPlayerPoint[player]);
		}
		else {
			CPrintToChat(player, "{green}[当前分数{olive}%d {green}| 奖励分: {olive}%.1f%% {green}]\n[个人最高] {olive}%N - %d", iPointSum, fBonus, client, iPlayerPoint[client]);
		}
		g_hWritePath = CreateTimer(1.0, Timer_WritePath, _, TIMER_REPEAT);
	}
}

//==============================
//=         Shop
//==============================
Action Cmd_GiveMoney(int client, int args)
{
	if (!g_bPointShop)
	{
		ReplyToCommand(client, "点数商店未开启");
		return Plugin_Handled;
	}
	if (IsValidSur(client) && IsPlayerAlive(client) && IsClientInSafeArea(client))
	{
		char sMoney[16];
		GetCmdArg(1, sMoney, sizeof sMoney);
		g_esData[client].money += StringToInt(sMoney);
	}

	return Plugin_Handled;
}

Action Cmd_Shop(int client, int args)
{
	if (!g_bPointShop)
	{
		ReplyToCommand(client, "点数商店未开启");
		return Plugin_Handled;
	}
	if (IsValidSur(client) && IsPlayerAlive(client) && IsClientInSafeArea(client))
	{
		FakeClientCommand(client, "sm_hide");
		CreateShopMenu(client);
	}
	else
		PrintToChat(client, "\x05请在安全区域内购买物品");
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!g_bPointShop)
		return Plugin_Continue;
	if (buttons & (IN_RELOAD | IN_USE) == (IN_RELOAD | IN_USE))
	{
		if (IsValidSur(client) && IsPlayerAlive(client) && IsClientInSafeArea(client))
		{
			if (GetEngineTime() - g_fShopCD >= 2.0)
			{
				FakeClientCommand(client, "sm_hide");
				g_fShopCD = GetEngineTime();
			}
			CreateShopMenu(client);
			if (buttons == (IN_RELOAD | IN_USE))
				buttons &= ~IN_USE;
		}
		else {
			if (GetEngineTime() - g_fShopCD >= 2.0)
			{
				PrintToChat(client, "\x05请在安全区域内购买物品");
				g_fShopCD = GetEngineTime();
			}
		}
	}
	return Plugin_Continue;
}

void CreateShopMenu(int client)
{
	Menu menu = new Menu(Menu_Handler);
	menu.SetTitle("积分商店\n———————————————");

	menu.AddItem("a", "购买主武器");
	menu.AddItem("b", "购买副武器");
	menu.AddItem("c", "购买道具");
	menu.AddItem("d", "退货");

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Menu_Handler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Select:
		{
			char sItem[2];
			if (menu.GetItem(itemNum, sItem, sizeof sItem))
			{
				switch (sItem[0])
				{
					case 'a':
					{
						MW_Menu(client);
					}
					case 'b':
					{
						SW_Menu(client);
					}
					case 'c':
					{
						I_Menu(client);
					}
					case 'd':
					{
						Disorder_Menu(client);
					}
				}
			}
		}
	}
	return 0;
}

//主武器菜单
void MW_Menu(int client)
{
	int	 iMoney = g_esData[client].money;
	char sLine[64];

	Menu mW_Menu = new Menu(mW_Menu_Handler);
	FormatEx(sLine, sizeof sLine, "您当前积分 %d\n选择主武器", iMoney);
	mW_Menu.SetTitle(sLine);

	for (int i = 0; i < 15; i++)
	{
		FormatEx(sLine, sizeof sLine, "%s(价格 %s)", g_sMainWeapons[i][1], g_sMainWeapons[i][3]);
		mW_Menu.AddItem(g_sMainWeapons[i][0], sLine);
	}

	mW_Menu.ExitBackButton = true;
	mW_Menu.Display(client, MENU_TIME_FOREVER);
}

int mW_Menu_Handler(Menu menu, MenuAction action, int client, int param2)
{
	int iMoney = g_esData[client].money;
	switch (action)
	{
		case MenuAction_Select:
		{
			if (IsClientInSafeArea(client))
			{
				char line[32];
				FormatEx(line, sizeof line, "give %s", g_sMainWeapons[param2][0]);
				if (StringToInt(g_sMainWeapons[param2][3]) <= iMoney)
				{
					g_esData[client].money -= StringToInt(g_sMainWeapons[param2][3]);
					CheatCommand(client, line);
					PrintToChatAll("\x05%N\x01购买了\x05%s", client, g_sMainWeapons[param2][1]);
				}
				else
					PrintToChat(client, "\x05积分不足, 购买失败");
			}
			else {
				PrintToChat(client, "\x05请在安全区域内购买物品");
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				CreateShopMenu(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
			FakeClientCommand(client, "sm_show");
		}
	}
	return 0;
}

//副武器
void SW_Menu(int client)
{
	int	 iMoney = g_esData[client].money;
	char sLine[64];

	Menu sW_Menu = new Menu(SW_Menu_Handler);
	FormatEx(sLine, sizeof sLine, "您当前积分 %d\n选择副武器", iMoney);
	sW_Menu.SetTitle(sLine);

	for (int i = 0; i < 14; i++)
	{
		FormatEx(sLine, sizeof sLine, "%s(价格 %s)", g_sSubWeapons[i][1], g_sSubWeapons[i][3]);
		sW_Menu.AddItem(g_sSubWeapons[i][0], sLine);
	}

	sW_Menu.ExitBackButton = true;
	sW_Menu.Display(client, MENU_TIME_FOREVER);
}

int SW_Menu_Handler(Menu menu, MenuAction action, int client, int param2)
{
	int iMoney = g_esData[client].money;
	switch (action)
	{
		case MenuAction_Select:
		{
			if (IsClientInSafeArea(client))
			{
				char line[32];
				FormatEx(line, sizeof line, "give %s", g_sSubWeapons[param2][0]);
				if (StringToInt(g_sSubWeapons[param2][3]) <= iMoney)
				{
					g_esData[client].money -= StringToInt(g_sSubWeapons[param2][3]);
					CheatCommand(client, line);
					PrintToChatAll("\x05%N\x01购买了\x05%s", client, g_sSubWeapons[param2][1]);
				}
				else
					PrintToChat(client, "\x05积分不足, 购买失败");
			}
			else {
				PrintToChat(client, "\x05请在安全区域内购买物品");
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				CreateShopMenu(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
			FakeClientCommand(client, "sm_show");
		}
	}
	return 0;
}

//物品
void I_Menu(int client)
{
	int	 iMoney = g_esData[client].money;
	char sLine[64];

	Menu i_Menu = new Menu(I_Menu_Handler);
	FormatEx(sLine, sizeof sLine, "您当前积分 %d\n选择物品", iMoney);
	i_Menu.SetTitle(sLine);

	for (int i = 0; i < 6; i++)
	{
		FormatEx(sLine, sizeof sLine, "%s(价格 %s)", g_sItems[i][1], g_sItems[i][3]);
		i_Menu.AddItem(g_sItems[i][0], sLine);
	}

	i_Menu.ExitBackButton = true;
	i_Menu.Display(client, MENU_TIME_FOREVER);
}

int I_Menu_Handler(Menu menu, MenuAction action, int client, int param2)
{
	int iMoney = g_esData[client].money;
	switch (action)
	{
		case MenuAction_Select:
		{
			if (IsClientInSafeArea(client))
			{
				char line[32];
				if (param2 != 5)
					FormatEx(line, sizeof line, "give %s", g_sItems[param2][0]);
				else
					FormatEx(line, sizeof line, "upgrade_add %s", g_sItems[param2][0]);
				if (StringToInt(g_sItems[param2][3]) <= iMoney)
				{
					g_esData[client].money -= StringToInt(g_sItems[param2][3]);
					CheatCommand(client, line);
					PrintToChatAll("\x05%N\x01购买了\x05%s", client, g_sItems[param2][1]);
				}
				else
					PrintToChat(client, "\x05积分不足, 购买失败");
			}
			else {
				PrintToChat(client, "\x05请在安全区域内购买物品");
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				CreateShopMenu(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
			FakeClientCommand(client, "sm_show");
		}
	}
	return 0;
}

//退货菜单
void Disorder_Menu(int client)
{
	int	 iMoney = g_esData[client].money;
	char sLine[64];

	Menu disorder_Menu = new Menu(Disorder_Menu_Handler);
	FormatEx(sLine, sizeof sLine, "您当前积分 %d\n选择退货物品", iMoney);
	disorder_Menu.SetTitle(sLine);

	disorder_Menu.AddItem("a", "1号栏");
	disorder_Menu.AddItem("b", "2号栏");
	disorder_Menu.AddItem("c", "3号栏");
	disorder_Menu.AddItem("d", "4号栏");

	disorder_Menu.ExitBackButton = true;
	disorder_Menu.Display(client, MENU_TIME_FOREVER);
}

int Disorder_Menu_Handler(Menu menu, MenuAction action, int client, int itemNum)
{
	// int iMoney = g_esData[client].money;
	switch (action)
	{
		case MenuAction_Select:
		{
			char sItem[2];
			if (menu.GetItem(itemNum, sItem, sizeof sItem))
			{
				int w_id;
				switch (sItem[0])
				{
					case 'a':
					{
						w_id = GetPlayerWeaponSlot(client, 0);
						if (IsValidEntity(w_id))
						{
							int wepid = IdentifyWeapon(w_id);
							for (int i = 0; i < 15; i++)
							{
								if (wepid == StringToInt(g_sMainWeapons[i][5]))
								{
									g_esData[client].money += StringToInt(g_sMainWeapons[i][4]);
									RemovePlayerItem(client, w_id);
									RemoveEntity(w_id);
									PrintToChatAll("\x05%N\x01退货了\x05%s, \x01回收了\x05%s\x01分", client, g_sMainWeapons[i][1], g_sMainWeapons[i][4]);
									break;
								}
							}
						}
						else
							return 0;
					}
					case 'b':
					{
						w_id = GetPlayerWeaponSlot(client, 1);
						if (IsValidEntity(w_id))
						{
							char classname[32];
							GetEntPropString(w_id, Prop_Data, "m_ModelName", classname, sizeof(classname));
							for (int i = 0; i < 14; i++)
							{
								if (StrContains(classname, g_sSubWeapons[i][0], true) != -1)
								{
									g_esData[client].money += StringToInt(g_sSubWeapons[i][4]);
									RemovePlayerItem(client, w_id);
									RemoveEntity(w_id);
									PrintToChatAll("\x05%N\x01退货了\x05%s, \x01回收了\x05%s\x01分", client, g_sSubWeapons[i][1], g_sSubWeapons[i][4]);
									break;
								}
							}
						}
						else
							return 0;
					}
					case 'c':
					{
						w_id = GetPlayerWeaponSlot(client, 2);
						if (IsValidEntity(w_id))
						{
							char classname[32];
							GetEntPropString(w_id, Prop_Data, "m_ModelName", classname, sizeof(classname));
							for (int i = 0; i < 3; i++)
							{
								if (StrContains(classname, g_sItems[i][0], true) != -1)
								{
									g_esData[client].money += StringToInt(g_sItems[i][4]);
									RemovePlayerItem(client, w_id);
									RemoveEntity(w_id);
									PrintToChatAll("\x05%N\x01退货了\x05%s, \x01回收了\x05%s\x01分", client, g_sItems[i][1], g_sItems[i][4]);
									break;
								}
							}
						}
						else
							return 0;
					}
					case 'd':
					{
						w_id = GetPlayerWeaponSlot(client, 3);
						if (IsValidEntity(w_id))
						{
							char classname[32];
							GetEntPropString(w_id, Prop_Data, "m_ModelName", classname, sizeof(classname));
							for (int i = 3; i < 5; i++)
							{
								if (StrContains(classname, g_sItems[i][0], true) != -1)
								{
									g_esData[client].money += StringToInt(g_sItems[i][4]);
									RemovePlayerItem(client, w_id);
									RemoveEntity(w_id);
									PrintToChatAll("\x05%N\x01退货了\x05%s, \x01回收了\x05%s\x01分", client, g_sItems[i][1], g_sItems[i][4]);
									break;
								}
							}
						}
						else
							return 0;
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				CreateShopMenu(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
			FakeClientCommand(client, "sm_show");
		}
	}
	return 0;
}

//==============================
//=         子函数
//==============================
//写入路程
void WritePlayerPath(int client)
{
	if (!IsValidSur(client))
		return;

	//只有当前路程超过记录路程才会记录
	float path = GetSurvivorFlow(client);
	if (path < 0.99 && IsTankStayInGame())
		return;

	if (g_esData[client].PlayerPath >= path)
		return;
	g_esData[client].PlayerPath = path;
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

//是否为有效索引
bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}

//是否为存活的生还
bool IsValidSur(int client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 2)
		return true;
	return false;
}

//场上是否存在坦克
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

void ClearData()
{
	for (int i = 1; i <= MaxClients; i++)
		g_esData[i].CleanInfected();
}

//返回闲置玩家对应的bot
int IsGetBotOfIdlePlayer(int client)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && IsClientIdle(i) == client && IsPlayerAlive(i))
			return i;

	return 0;
}

//返回电脑幸存者对应的玩家.
int IsClientIdle(int client)
{
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}

//生还是否在安全区域
//代码来自"https://steamcommunity.com/id/ChengChiHou/"
stock bool IsClientInSafeArea(int client)
{
	int nav = L4D_GetLastKnownArea(client);
	if (!nav)
		return false;
	int	 iAttr		   = L4D_GetNavArea_SpawnAttributes(view_as<Address>(nav));
	bool bInStartPoint = !!(iAttr & 0x80);
	bool bInCheckPoint = !!(iAttr & 0x800);
	if (!bInStartPoint && !bInCheckPoint)
		return false;
	return true;
}

void CheatCommand(int client, const char[] sCommand)
{
	if (!client || !IsClientInGame(client))
		return;

	char sCmd[32];
	if (SplitString(sCommand, " ", sCmd, sizeof sCmd) == -1)
		strcopy(sCmd, sizeof sCmd, sCommand);

	int iFlagBits, iCmdFlags;
	iFlagBits = GetUserFlagBits(client);
	iCmdFlags = GetCommandFlags(sCmd);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(sCmd, iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, sCommand);
	SetUserFlagBits(client, iFlagBits);
	SetCommandFlags(sCmd, iCmdFlags);
}

//==============================
//=			Native
//==============================
int native_GetPlayerMoney(Handle plugin, int numParams){
	int client = GetNativeCell(1);
	return GetPlayerMoney(client);
}

/**
 * 获取玩家当前持有的积分
 * 
 * @param client 	玩家索引
 * @return 有效生还返回持有积分，无效生还返回-1
 */
int GetPlayerMoney(int client){
	int iMoney;
	if(IsValidSur(client))
		iMoney = g_esData[client].money;
	else
		iMoney = -1;
	return iMoney;
}

int native_GetTeamPoints(Handle plugin, int numParams){
	return GetTeamPoints();
}

/**
 * 获取团队总计分数
 * @remark 总计分数为路程与累计获取积分之积, 不会被消耗
 * 
 * @return 返回生还团队获取的总分
 */
int GetTeamPoints(){
	int iPointSum = 0;
	for(int i = 1; i <= MaxClients; i++){
		if(IsValidSur(i)){
			int dmgSI = g_esData[i].dmgSI;
			int dmgCI = g_esData[i].dmgCI;
			float fPath = g_esData[i].PlayerPath;
			int iPlayerPoint = RoundToNearest((dmgSI / 50 + dmgCI) * fPath);
			iPointSum += iPlayerPoint;
		}
	}
	return (g_iTotalPoint + iPointSum);
}

int native_GetPlayerBonus(Handle plugin, int numParams){
	return GetPlayerBonus();
}

/**
 * 获取团队的奖励分
 * 
 * @return 返回生还的奖励分
 */
int GetPlayerBonus(){
	float fHealth = 0.0;
	int count = 0;
	for(int i = 1; i <= MaxClients; i++){
		if(IsValidSur(i)){
			if(IsPlayerAlive(i))
				fHealth += float(GetClientHealth(i));
			count++;
		}
	}
	float fBonus = fHealth / float(count);
	return RoundToNearest(fBonus);
}