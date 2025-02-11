#include <l4d2_skill_detect>
#include <cup_function>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_NAME "[L4D2] Skill Analyse"
#define PLUGIN_AUTHOR "MopeCup"
#define PLUGIN_URL "https://github.com/MopeCup/l4d2"
#define PLUGIN_DES "分析玩家的技术"

int g_iSPKill[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DES,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() {
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

    HookEvent("player_hurt", Event_playerHurt, EventHookMode_Pre);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {

}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {

}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (IsValidSur(attacker) && IsValidSI(client)) {
        if (IsZombieClassSI(client)) {
            g_iSPKill[attacker]++;
        }
    }
}