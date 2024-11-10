//# vim: set filetype=cpp :

/*
Dingshot a SourceMod L4D2 Plugin
Copyright (C) 2016  Victor B. Gonzalez

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the

Free Software Foundation, Inc.
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.1.1"

ConVar g_cvHeadShot;
ConVar g_cvKillShot;
char g_HeadShot[256];
char g_KillShot[256];
char g_sB[512];

public Plugin:myinfo= {
	name = "Dingshot",
	author = "Victor BUCKWANGS Gonzalez",
	description = "DING Headshot!",
	version = PLUGIN_VERSION,
	url = "https://gitlab.com/vbgunz/Dingshot"
}

public OnPluginStart() {
	//因为只需要击杀特感时发出声音，因此注释掉下面两条(Tc)
	//HookEvent("infected_death", HeadShotHook, EventHookMode_Pre);
	HookEvent("player_death", HeadShotHook, EventHookMode_Pre);

	//ui/littlereward.wav
	g_cvHeadShot = CreateConVar("ds_headshot", "level/bell_normal.wav", "Sound bite for head shot");
	HookConVarChange(g_cvHeadShot, UpdateConVarsHook);
	UpdateConVarsHook(g_cvHeadShot, "ui/littlereward.wav", "level/bell_normal.wav");

	//level/bell_normal.wav
	g_cvKillShot = CreateConVar("ds_killshot", "ui/littlereward.wav", "Sound bite for kill shot to the head");
	HookConVarChange(g_cvKillShot, UpdateConVarsHook);
	UpdateConVarsHook(g_cvKillShot, "level/bell_normal.wav", "ui/littlereward.wav");

	AutoExecConfig(true, "dingshot");
}

bool IsClientValid(int client) {
	if (client >= 1 && client < MaxClients) {
		if (IsClientConnected(client)) {
			 if (IsClientInGame(client)) {
				return true;
			 }
		}
	}

	return false;
}

public UpdateConVarsHook(Handle convar, const char[] oldCv, const char[] newCv) {
	GetConVarName(convar, g_sB, sizeof(g_sB));

	if (StrEqual(g_sB, "ds_headshot")) {
		GetConVarString(g_cvHeadShot, g_HeadShot, sizeof(g_HeadShot));
	}

	else if (StrEqual(g_sB, "ds_killshot")) {
		GetConVarString(g_cvKillShot, g_KillShot, sizeof(g_KillShot));
	}
}

// public HeadShotHook(Handle event, const char[] name, bool dontBroadcast) {
// 	int hitgroup;

// 	if (strcmp(name, "infected_death") == 0) {
// 		hitgroup = GetEventInt(event, "headshot");
// 		g_sB = g_KillShot;
// 	}

// 	else {
// 		hitgroup = GetEventInt(event, "hitgroup");
// 		g_sB = g_HeadShot;
// 	}

// 	if (!IsSoundPrecached(g_sB)) {
// 		PrecacheSound(g_sB, false);
// 	}

// 	int attacker = GetEventInt(event, "attacker");
// 	int type = GetEventInt(event, "type");
// 	int client = GetClientOfUserId(attacker);

// 	if (IsClientValid(client) && hitgroup == 1 && type != 8) {  // 8 == death by fire...
// 		EmitSoundToClient(client, g_sB, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
// 	}
// }

public HeadShotHook(Handle event, const char[] name, bool dontBroadcast){
	int hitgroup;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int headshot = GetEventBool(event, "headshot");

	//我么们希望被击杀的是特感时发出声音(Tc)
	//使用此函数获取被击杀的感染者种类
	//int iHLZClass = GetEntProp(client, Prop_Send, "m_zombieClass") - 1;
	if(GetClientTeam(client) == 3){
		//g_sB = g_KillShot;

		//判断是否是爆头击杀，而采用不同的击杀音效
		if(headshot == 1)
			g_sB = g_HeadShot;
		else
			g_sB = g_KillShot;
		
		if (!IsSoundPrecached(g_sB)) {
 				PrecacheSound(g_sB, false);
		 	}
		
		//最后根据情况播放音效
		if(IsClientValid(attacker))
			EmitSoundToClient(attacker, g_sB, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	}
}