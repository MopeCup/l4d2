#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>

public Plugin myinfo = 
{
	name = "anti-friendly_fire",
	author = "HarryPotter",
	description = "shoot teammate = shoot yourself",
	version = "1.7-2023/12/17",
	url = "https://steamcommunity.com/profiles/76561198026784913"
}

bool g_bLate, g_bL4D2Version;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test == Engine_Left4Dead )
	{
		g_bL4D2Version = false;
	}
	else if( test == Engine_Left4Dead2 )
	{
		g_bL4D2Version = true;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	g_bLate = late;
	return APLRes_Success; 
}

#define CLASSNAME_LENGTH 64

ConVar g_hGod,
	g_hEnable, g_hFireDisable, g_hPipeBombDisable, g_hGLDisable, g_hDamageShield, g_hDamageMulti;

//ConVar g_hMaxDamageImmune;

bool g_bGod, g_bEnable, g_bFireDisable, g_bPipeBombDisable, g_bGLDisable;
int g_iDamageShield;
float g_fDamageMulti;

float g_fMaxDamageImmune;

int g_iMainHealth[MAXPLAYERS+1];
float g_fTempHealth[MAXPLAYERS+1];

public void OnPluginStart()
{
	g_hGod = FindConVar("god");

	g_hEnable = CreateConVar(	"anti_friendly_fire_enable", "1",
								"Enable Plugin [0-Disable,1-Enable]",
								FCVAR_NOTIFY, true, 0.0, true, 1.0 );

	g_hFireDisable = CreateConVar(	"anti_friendly_fire_immue_fire", "0",
								"1=Disable Molotov, Gascan and Firework Crate friendly fire damage and don't reflect damage\n0=Enable friendly fire damage",
								FCVAR_NOTIFY, true, 0.0, true, 1.0 );

	g_hPipeBombDisable = CreateConVar( "anti_friendly_fire_immue_explode", "0",
								"1=Disable Pipe Bomb, Propane Tank, and Oxygen Tank Explosive friendly fire and don't reflect damage\n0=Enable friendly fire damage",
								FCVAR_NOTIFY, true, 0.0, true, 1.0 );

	if(g_bL4D2Version)
	{
		g_hGLDisable = CreateConVar( "anti_friendly_fire_immue_GL", "0",
								"(L4D2) 1=Disable Grenade Launcher friendly fire and reflect damage\n0=Enable friendly fire damage",
								FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	}

	g_hDamageShield = CreateConVar( "anti_friendly_fire_damage_sheild", "0",
								"Disable friendly fire damage and don't reflect damage if damage is below this value. (0=Off)",
								FCVAR_NOTIFY, true, 0.0);

	g_hDamageMulti = CreateConVar( "anti_friendly_fire_damage_multi", "1.0",
								"Multiply friendly fire damage value and reflect to attacker. (1.0=original damage value)",
								FCVAR_NOTIFY, true, 1.0 );	

	//g_hMaxDamageImmune = CreateConVar("affd_Max_Damage_Immune", "55", "近距离免伤的最大距离", FCVAR_NOTIFY, true, 0.0, true, 200.0);

	GetCvars();
	g_hGod.AddChangeHook(ConVarChanged_Cvars);
	g_hEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hFireDisable.AddChangeHook(ConVarChanged_Cvars);
	g_hPipeBombDisable.AddChangeHook(ConVarChanged_Cvars);
	if(g_bL4D2Version) g_hGLDisable.AddChangeHook(ConVarChanged_Cvars);
	g_hDamageShield.AddChangeHook(ConVarChanged_Cvars);
	g_hDamageMulti.AddChangeHook(ConVarChanged_Cvars);
	//g_hMaxDamageImmune.AddChangeHook(ConVarChanged_Cvars);

	AutoExecConfig(true, "anti-friendly_fire");

	HookEvent("player_hurt", Event_Hurt);
	HookEvent("player_incapacitated_start", Event_IncapacitatedStart);

	if(g_bLate)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i)) OnClientPutInServer(i);
		}
	}
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bGod = g_hGod.BoolValue;
	g_bEnable = g_hEnable.BoolValue;
	g_bFireDisable = g_hFireDisable.BoolValue;
	g_bPipeBombDisable = g_hPipeBombDisable.BoolValue;
	if(g_bL4D2Version) g_bGLDisable = g_hGLDisable.BoolValue;
	g_iDamageShield = g_hDamageShield.IntValue;
	g_fDamageMulti = g_hDamageMulti.FloatValue;
	//g_fMaxDamageImmune = g_hMaxDamageImmune.FloatValue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

// 不可偵測到SDKHooks_TakeDamage，此時玩家未扣血
Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// if (victim != attacker && IsSurvivor(victim) && IsSurvivor(attacker))
	// {
	// 	float distance_1[3], distance_2[3];
	// 	GetClientAbsOrigin(attacker, distance_1);
	// 	GetClientAbsOrigin(victim, distance_2);
	// 	float distance = GetVectorDistance(distance_1, distance_2);
	// 	if (distance <= g_fMaxDamageImmune)
	// 	{
	// 		damage = 0.0;
	// 		return Plugin_Changed;
	// 	}
	// }

	if(damage <= 0.0 || g_bEnable == false || g_bGod == true) return Plugin_Continue;

	if(attacker == victim ||
		!IsClientAndInGame(attacker)  || 
		!IsClientAndInGame(victim) || 
		!IsValidEntity(inflictor) ||
		ShouldPluginStop(victim) ||
		GetClientTeam(attacker) == L4D_TEAM_INFECTED ||
		GetClientTeam(victim) != L4D_TEAM_SURVIVOR) return Plugin_Continue;

	if(IsClientInGodFrame(victim)) return Plugin_Continue;

	// 最後實際傷害為"浮點數的傷害數值的整數", 小數點後無條件捨去
	// 但是如果浮點數的傷害大於等於生命值, 依然倒地或死亡
	int iDamage = RoundToFloor(damage);
	if(iDamage <= g_iDamageShield) return Plugin_Handled; 

	//PrintToChatAll("%N attack %N, temp Health: %d, main Health: %d, damage: %d", attacker, victim, L4D_GetPlayerTempHealth(victim), GetClientHealth(victim), iDamage);
	if( GetClientHealth(victim) + L4D_GetPlayerTempHealth(victim) <= iDamage + 1) //倒地或死亡
	{
		static char WeaponName[CLASSNAME_LENGTH];
		GetEntityClassname(inflictor, WeaponName, sizeof(WeaponName));
		//PrintToChatAll("WeaponName: %s", WeaponName);	
		
		bool bIsSpecialWeapon = false;
		if(IsPipeBombExplode_OnTakeDamage(WeaponName)) 
		{
			bIsSpecialWeapon = true;
			if(g_bPipeBombDisable == false) return Plugin_Continue;
		}
		else if(IsFire(WeaponName) || IsFireworkcrate(WeaponName))
		{
			bIsSpecialWeapon = true;
			if(g_bFireDisable== false) return Plugin_Continue;
		}
		else if(g_bL4D2Version && IsGLExplode(WeaponName)) 
		{
			//bIsSpecialWeapon = true;
			if(g_bGLDisable == false) return Plugin_Continue;
		}
		
		if(bIsSpecialWeapon)
		{
			return Plugin_Handled;
		}

		if(!bIsSpecialWeapon && GetClientTeam(attacker) == L4D_TEAM_SURVIVOR)
		{
			HurtEntity(attacker, attacker, damage);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

// 如果傷害造成玩家即將倒地，不會觸發此涵式
// 可偵測到SDKHooks_TakeDamage，此時玩家未扣血
Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// if (victim != attacker && IsSurvivor(victim) && IsSurvivor(attacker))
	// {
	// 	float distance_1[3], distance_2[3];
	// 	GetClientAbsOrigin(attacker, distance_1);
	// 	GetClientAbsOrigin(victim, distance_2);
	// 	float distance = GetVectorDistance(distance_1, distance_2);
	// 	if (distance <= g_fMaxDamageImmune)
	// 	{
	// 		damage = 0.0;
	// 		return Plugin_Changed;
	// 	}
	// }

	if(damage <= 0.0 || g_bEnable == false || g_bGod == true) return Plugin_Continue;

	if(attacker == victim ||
		!IsClientAndInGame(attacker)  || 
		!IsClientAndInGame(victim) || 
		!IsValidEntity(inflictor) ||
		ShouldPluginStop(victim) ||
		GetClientTeam(attacker) == L4D_TEAM_INFECTED ||
		GetClientTeam(victim) != L4D_TEAM_SURVIVOR) return Plugin_Continue;

	g_iMainHealth[victim] = GetClientHealth(victim);
	g_fTempHealth[victim] = L4D_GetTempHealth(victim);
	
	return Plugin_Continue;
}

void Event_Hurt(Event event, const char[] name, bool dontBroadcast) 
{
	if(g_bGod) return;

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int damage = event.GetInt("dmg_health");
	if(g_bEnable == false || 
	attacker == victim || 
	!IsClientAndInGame(attacker) || 
	!IsClientAndInGame(victim) || 
	ShouldPluginStop(victim) ||
	GetClientTeam(victim) != L4D_TEAM_SURVIVOR || 
	GetClientTeam(attacker) == L4D_TEAM_INFECTED ||
	!IsPlayerAlive(victim) || 
	damage <= 0 ||
	damage <= g_iDamageShield) { return; }
	
	
	static char WeaponName[CLASSNAME_LENGTH];
	event.GetString("weapon", WeaponName, sizeof(WeaponName));
	//PrintToChatAll("victim: %N, attacker:%N , WeaponName: %s, damage: %d", victim, attacker, WeaponName, damage);
	
	bool bIsSpecialWeapon = false;
	if(IsPipeBombExplode(WeaponName)) 
	{
		bIsSpecialWeapon = true;
		if(g_bPipeBombDisable == false) return;
	}
	else if(IsFire(WeaponName) || IsFireworkcrate(WeaponName))
	{
		bIsSpecialWeapon = true;
		if(g_bFireDisable== false) return;
	}
	else if(g_bL4D2Version && IsGLExplode(WeaponName)) 
	{
		//bIsSpecialWeapon = true;
		if(g_bGLDisable == false) return;
	}
	
	if(bIsSpecialWeapon)
	{
		if(!IsIncapacitated(victim)) RestoreHp(victim);
	}
	else if(!bIsSpecialWeapon && GetClientTeam(attacker) == L4D_TEAM_SURVIVOR)
	{
		if(!IsIncapacitated(victim)) RestoreHp(victim);
		HurtEntity(attacker, attacker, float(damage));
	}
}

void Event_IncapacitatedStart(Event event, const char[] name, bool dontBroadcast) 
{
	if(g_bGod) return;

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(g_bEnable == false || 
	attacker == victim ||
	!IsClientAndInGame(attacker)  || 
	!IsClientAndInGame(victim) || 
	ShouldPluginStop(victim) ||
	GetClientTeam(attacker) == L4D_TEAM_INFECTED ||
	GetClientTeam(victim) != L4D_TEAM_SURVIVOR) { return; }
	
	int health = GetClientHealth(victim) + L4D_GetPlayerTempHealth(victim);

	static char WeaponName[CLASSNAME_LENGTH];
	event.GetString("weapon", WeaponName, sizeof(WeaponName));
	//PrintToChatAll("Event_IncapacitatedStart victim: %d, attacker:%d , health: %d, WeaponName is %s",victim,attacker, health, WeaponName);	
	
	bool bIsSpecialWeapon = false;
	if(IsPipeBombExplode(WeaponName)) 
	{
		bIsSpecialWeapon = true;
		if(g_bPipeBombDisable == false) return;
	}
	else if(IsFire(WeaponName) || IsFireworkcrate(WeaponName))
	{
		bIsSpecialWeapon = true;
		if(g_bFireDisable== false) return;
	}

	if(!bIsSpecialWeapon && GetClientTeam(attacker) == L4D_TEAM_SURVIVOR)
	{
		HurtEntity(attacker, attacker, float(health));
	}
}

void HurtEntity(int victim, int client, float damage)
{
	SDKHooks_TakeDamage(victim, client, client, damage * g_fDamageMulti, DMG_SLASH);
}

bool IsClientAndInGame(int client)
{
	if (0 < client && client <= MaxClients)
	{	
		return IsClientInGame(client);
	}
	return false;
}

bool IsFire(char[] classname)
{
	return strcmp(classname, "inferno") == 0 || strcmp(classname, "entityflame") == 0;
} 

bool IsPipeBombExplode(char[] classname)
{
	return StrEqual(classname, "pipe_bomb");
} 

bool IsPipeBombExplode_OnTakeDamage(char[] classname)
{
	return StrEqual(classname, "pipe_bomb_projectile");
} 

bool IsGLExplode(char[] classname)
{
	return StrEqual(classname, "grenade_launcher_projectile");
} 

bool IsFireworkcrate(char[] classname)
{
	return StrEqual(classname, "fire_cracker_blast");
} 

bool IsClientInGodFrame( int client )
{
	CountdownTimer timer = L4D2Direct_GetInvulnerabilityTimer(client);
	if(timer == CTimer_Null) return false;

	return (CTimer_GetRemainingTime(timer) > 0.0);
}

bool IsIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

void RestoreHp(int client)
{
	//PrintToChatAll("%d %.2f", g_iMainHealth[client], g_fTempHealth[client]);
	SetEntityHealth(client, g_iMainHealth[client]);
	L4D_SetTempHealth(client, g_fTempHealth[client]);
}

/*以下为新增修复内容*/
//如果受害者是人机，倒地玩家或者被控玩家反伤插件不应该生效
bool ShouldPluginStop(int victim){
	if(IsFakeClient(victim) || IsIncapacitated(victim) || IsClientInControll(victim))
		return true;
	return false;
} 

//判断被攻击玩家是否被控 - 函数来自 l4d2_go_away_from_keyboard.sp
bool IsClientInControll(int client){
	if(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
		return true;
	return false;
}

bool IsSurvivor(int attacker)
{
	return attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == 2;
}