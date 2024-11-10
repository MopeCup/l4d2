#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <sdktools>
#include <sdkhooks>
#include <l4d2util>

/*
更新日志
2024.8.4 - v1.1.0
    新增出门音效

*/

public Plugin myinfo =
{
	name		= "l4d2 start item",
	author		= "MopeCup",
	description = "第一位玩家离开安全屋后，给予指定玩家物品",
	version		= "1.1.0"

}

ConVar cvSlot0, cvSlot1, cvSlot2, cvSlot3, cvSlot4;    //给予玩家的物品
ConVar cvBotWeapon;     //给予Bot的初始武器
ConVar cvBotItemGetRule;    //投掷物获取规则
ConVar cvPlayerItemGetRule;
ConVar cvIsAllowPlayMusic;

bool bIsPlayerLeftSafeArea; //记录玩家是否离开安全区域

int iSlot0, iSlot1, iSlot2, iSlot3, iSlot4;
int iBotWeapon;
bool bBotIGR, bPlayerIGR;

//int iT1WeaponNum, iT2WeaponNum, iSniperNum;

public void OnPluginStart(){
    cvSlot0 = CreateConVar("l4d2_start_item_slot0", "0", "初始给予玩家什么样的主武器(0 禁止, 1 任意t1级武器, 2 任意t2级武器, 3 任意狙击枪)", FCVAR_NOTIFY);
    cvSlot1 = CreateConVar("l4d2_start_item_slot1", "0", "初始给予什么样的副武器(0 禁止, 1 任意近战, 2 马格南, 3 近战或马格南)", FCVAR_NOTIFY);
    cvSlot2 = CreateConVar("l4d2_start_item_slot2", "0", "初始给予什么样的投掷物(0 禁止, 1 胆汁, 2 土雷, 3 火瓶, 4 任意)", FCVAR_NOTIFY);
    cvSlot3 = CreateConVar("l4d2_start_item_slot3", "1", "初始给予什么样的医疗物资(0 禁止, 1 医疗包, 2 电击器)", FCVAR_NOTIFY);
    cvSlot4 = CreateConVar("l4d2_start_item_slot4", "0", "初始给予什么样的药物(0 禁止, 1 止痛药, 2 针)", FCVAR_NOTIFY);
    cvBotWeapon = CreateConVar("l4d2_start_item_botweapon", "1", "给予Bot武器的规则(0 禁止, 1 给予t1武器, 2 给予t2武器, 3 给予狙击枪, 4 由玩家的平均装备水平决定)", FCVAR_NOTIFY);

    //cvItemGetTime = CreateConVar("l4d2_start_item_gettime", "0", "什么时候执行给物品功能(0 第一位玩家离开安全区域时, 1 游戏刚开始时)", FCVAR_NOTIFY);
    cvBotItemGetRule = CreateConVar("l4d2_start_item_bgetrule", "0", "给人机物品的原则(0 仅当相应栏位为空时, 1 任意情况下都给)", FCVAR_NOTIFY);
    cvPlayerItemGetRule = CreateConVar("l4d2_start_item_pgetrule", "0", "给玩家物品原则(0 仅当相应栏位为空时, 1 任意情况下)", FCVAR_NOTIFY);

    cvIsAllowPlayMusic = CreateConVar("l4d2_start_item_allowplaymusic", "1", "第一位玩家离开安全区域后是否播放音效(0 禁止, 1 允许)", FCVAR_NOTIFY);

    PrecacheSound("level/countdown.wav", false);
    PrecacheSound("level/scoreregular.wav", false);

    AutoExecConfig(true, "l4d2_start_item");

    HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_left_safe_area", Event_PlayerLeftSafeArea);
}

void ResetPlugin(){
    bIsPlayerLeftSafeArea = false;
    // iT1WeaponNum = 0;
    // iT2WeaponNum = 0;
    // iSniperNum = 0;
}

void GetCvars(){
    iSlot0 = GetConVarInt(cvSlot0);
    iSlot1 = GetConVarInt(cvSlot1);
    iSlot2 = GetConVarInt(cvSlot2);
    iSlot3 = GetConVarInt(cvSlot3);
    iSlot4 = GetConVarInt(cvSlot4);

    iBotWeapon = GetConVarInt(cvBotWeapon);

    bBotIGR = GetConVarBool(cvBotItemGetRule);
    bPlayerIGR = GetConVarBool(cvPlayerItemGetRule);
}

//-----初始化-----
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

//-----出门事件(插件从此处开始)-----
void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast){
    if(bIsPlayerLeftSafeArea)
        return;

    bIsPlayerLeftSafeArea = true;

    if (!IsSoundPrecached("level/countdown.wav") || !IsSoundPrecached("level/scoreregular.wav")) {
 		PrecacheSound("level/countdown.wav", false);
        PrecacheSound("level/scoreregular.wav", false);
	}

    if(GetConVarBool(cvIsAllowPlayMusic)){
        EmitSoundToAll("level/countdown.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
        CreateTimer(3.0, Timer_CountDown, _,TIMER_FLAG_NO_MAPCHANGE);
    }

    GetCvars();

    //玩家Slot0处理
    GivePlayer_Slot0();

    //Slot1处理
    GivePlayer_Slot1();

    //Slot2处理
    GivePlayer_Slot2();

    //Slot3处理
    GivePlayer_Slot3();

    //Slot4处理
    GivePlayer_Slot4();

    //Bot武器处理
    GiveBotWeapon();
}

//-----倒计时-----
Action Timer_CountDown(Handle timer){
    EmitSoundToAll("level/scoreregular.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
    return Plugin_Stop;
}

//-----各种处理-----
//给予物品
void GiveStartItem(int client, const char[] command, const char[] args = ""){
    int flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, args);
    SetCommandFlags(command, flags|FCVAR_CHEAT);
}

//任意t1
char[] RandomT1Weapon(){
    int iWeapon_id = GetRandomInt(1, 4);
    char sWeaponName[128];
    switch(iWeapon_id){
        case 1:
        {
            Format(sWeaponName, sizeof(sWeaponName), "shotgun_chrome");
        }
        case 2:
        {
            Format(sWeaponName, sizeof(sWeaponName), "pumpshotgun");
        }
        case 3:
        {
            Format(sWeaponName, sizeof(sWeaponName), "smg");
        }
        case 4:
        {
            Format(sWeaponName, sizeof(sWeaponName), "smg_silenced");
        }
    }

    return sWeaponName;
}

//任意t2
char[] RandomT2Weapon(){
    int iWeapon_id = GetRandomInt(1, 6);
    char sWeaponName[128];
    switch(iWeapon_id){
        case 1:
        {
            Format(sWeaponName, sizeof(sWeaponName), "autoshotgun");
        }
        case 2:
        {
            Format(sWeaponName, sizeof(sWeaponName), "shotgun_spas");
        }
        case 3:
        {
            Format(sWeaponName, sizeof(sWeaponName), "rifle");
        }
        case 4:
        {
            Format(sWeaponName, sizeof(sWeaponName), "rifle_desert");
        }
        case 5:
        {
            Format(sWeaponName, sizeof(sWeaponName), "rifle_ak47");
        }
        case 6:
        {
            Format(sWeaponName, sizeof(sWeaponName), "rifle_sg552");
        }
    }

    return sWeaponName;
}

//任意狙击枪
char[] RandomSniper(){
    int iWeapon_id = GetRandomInt(1, 4);
    char sWeaponName[128];
    switch(iWeapon_id){
        case 1:
        {
            Format(sWeaponName, sizeof(sWeaponName), "sniper_military");
        }
        case 2:
        {
            Format(sWeaponName, sizeof(sWeaponName), "hunting_rifle");
        }
        case 3:
        {
            Format(sWeaponName, sizeof(sWeaponName), "sniper_awp");
        }
        case 4:
        {
            Format(sWeaponName, sizeof(sWeaponName), "sniper_scout");
        }
    }

    return sWeaponName;
}

//任意近战

//任意投掷
char[] RandomAmmunition(){
    int iWeapon_id = GetRandomInt(1, 3);
    char sWeaponName[128];
    switch(iWeapon_id){
        case 1:
        {
            Format(sWeaponName, sizeof(sWeaponName), "molotov");
        }
        case 2:
        {
            Format(sWeaponName, sizeof(sWeaponName), "pipe_bomb");
        }
        case 3:
        {
            Format(sWeaponName, sizeof(sWeaponName), "vomitjar");
        }
    }

    return sWeaponName;
}

//玩家Slot0
void GivePlayer_Slot0(){
    if(iSlot0 == 0 || !bIsPlayerLeftSafeArea)
        return;

    char sName[128];

    int i;
    for(i = 1; i < MaxClients + 1; i++){
        if(!IsValidSur(i) || IsFakeClient(i))
            continue;
        
        if(!bPlayerIGR && GetPlayerWeaponSlot(i, 0) != -1)
            continue;

        //检查该给予什么武器
        switch(iSlot0){
            case 1:
            {
                Format(sName, sizeof(sName), RandomT1Weapon());
            }
            case 2:
            {
                Format(sName, sizeof(sName), RandomT2Weapon());
            }
            case 3:
            {
                Format(sName, sizeof(sName), RandomSniper());
            }
        }

        GiveStartItem(i, "give", sName);
    }
}

//Slot1
void GivePlayer_Slot1(){
    if(iSlot1 == 0 || !bIsPlayerLeftSafeArea)
        return;

    // char sName[128];

    // int i;
    // for(i = 1; i < MaxClients + 1; i++){
    //     if(!IsValidSur(i) || IsFakeClient(i))
    //         continue;
        
    //     if(!bPlayerIGR && GetPlayerWeaponSlot(i, 0) == -1)
    //         continue;

    //     //检查该给予什么武器
    //     switch(iSlot0){
    //         case 1:
    //         {
    //             Format(sName, sizeof(sName), RandomT1Weapon());
    //         }
    //         case 2:
    //         {
    //             Format(sName, sizeof(sName), RandomT2Weapon());
    //         }
    //         case 3:
    //         {
    //             Format(sName, sizeof(sName), RandomSniper());
    //         }
    //     }

    //     GiveStartItem(i, "give", sName);
    // }

    PrintHintTextToAll("此功能暂未开放...");
}

//Slot2
void GivePlayer_Slot2(){
    if(iSlot2 == 0 || !bIsPlayerLeftSafeArea)
        return;

    char sName[128];

    int i;
    for(i = 1; i < MaxClients + 1; i++){
        if(!IsValidSur(i))
            continue;
        
        if(!bPlayerIGR && GetPlayerWeaponSlot(i, 2) != -1)
            continue;

        //检查该给予什么武器
        switch(iSlot2){
            case 1:
            {
                Format(sName, sizeof(sName), "vomitjar");
            }
            case 2:
            {
                Format(sName, sizeof(sName), "pipe_bomb");
            }
            case 3:
            {
                Format(sName, sizeof(sName), "molotov");
            }
            case 4:
            {
                Format(sName, sizeof(sName), RandomAmmunition());
            }
        }

        GiveStartItem(i, "give", sName);
    }
}

//Slot3
void GivePlayer_Slot3(){
    if(iSlot3 == 0 || !bIsPlayerLeftSafeArea)
        return;

    char sName[128];

    int i;
    for(i = 1; i < MaxClients + 1; i++){
        if(!IsValidSur(i))
            continue;
        
        if(!bPlayerIGR && GetPlayerWeaponSlot(i, 3) != -1)
            continue;

        //检查该给予什么武器
        switch(iSlot3){
            case 1:
            {
                Format(sName, sizeof(sName), "first_aid_kit");
            }
            case 2:
            {
                Format(sName, sizeof(sName), "defibrillator");
            }
        }

        GiveStartItem(i, "give", sName);
    }
}

//Slot4
void GivePlayer_Slot4(){
    if(iSlot4 == 0 || !bIsPlayerLeftSafeArea)
        return;

    char sName[128];

    int i;
    for(i = 1; i < MaxClients + 1; i++){
        if(!IsValidSur(i))
            continue;
        
        if(!bPlayerIGR && GetPlayerWeaponSlot(i, 4) != -1)
            continue;

        //检查该给予什么武器
        switch(iSlot4){
            case 1:
            {
                Format(sName, sizeof(sName), "pain_pills");
            }
            case 2:
            {
                Format(sName, sizeof(sName), "adrenaline");
            }
        }

        GiveStartItem(i, "give", sName);
    }
}

//Bot武器
void GiveBotWeapon(){
    if(iBotWeapon == 0 || !bIsPlayerLeftSafeArea)
        return;

    char sName[128];

    int i;
    for(i = 1; i < MaxClients + 1; i++){
        if(!IsValidSur(i) || !IsFakeClient(i))
            continue;

        if(!bBotIGR && GetPlayerWeaponSlot(i, 0) != -1)
            continue;

        // if(!IsFakeClient(i)){
        //     if(iBotWeapon == 4){
        //         int w_id = GetPlayerWeaponSlot(i, 0);
        //         int w_name = IdentifyWeapon(w_id);
        //         if(IsWeaponT2(w_id))
        //             iT2WeaponNum++;
        //     }

        //     continue;
        // }

        switch(iBotWeapon){
            case 1:
            {
                Format(sName, sizeof(sName), RandomT1Weapon());
            }
            case 2:
            {
                Format(sName, sizeof(sName), RandomT2Weapon());
            }
            case 3:
            {
                Format(sName, sizeof(sName), RandomSniper());
            }
            case 4:
            {
                int j;
                int iTeamT2Weapon = 0;
                for(j = 1; j < MaxClients + 1; j++){
                    if(!IsValidSur(j) || IsFakeClient(j))
                        continue;
                    int w_id = GetPlayerWeaponSlot(j, 0);
                    int w_name = IdentifyWeapon(w_id);
                    if(IsT2Weapon(w_name))
                        iTeamT2Weapon++;
                }

                if(iTeamT2Weapon > 1)
                    Format(sName, sizeof(sName), RandomSniper());
                else
                    Format(sName, sizeof(sName), RandomT1Weapon());
            }
        }
        GiveStartItem(i, "give", sName);
    }
}

//-----一系列判断函数-----
//是否为合法生还
bool IsValidSur(int client){
    return IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2;
}

bool IsT2Weapon(int w_name){
    if(w_name != 2 && w_name != 7 && w_name != 8 && w_name != 3)
        return true;
    
    return  false;
}