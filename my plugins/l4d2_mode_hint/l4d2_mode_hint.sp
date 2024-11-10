#pragma newdecls required

#include <sourcemod>

#define PLUGIN_FLAG FCVAR_SPONLY|FCVAR_NOTIFY
#define MODE_NAME_PATH "configs/hostname/mode_name.txt"

/*
2024.8.21 - v1.6.0
    改用其它方式获取当前模式设置
*/

public Plugin myinfo =
{
	name = "l4d2 mode hint",
	author = "MopeCup",
	description = "显示当前模式.",
	version = "1.6.0"
};

static char g_sNamePath[128];

ConVar g_cvCvar;

Handle g_hPrintTimer;

bool g_bSpecialSpawner, g_bNekoSpecials

native int SS_GetSILimit();
native int SS_GetSISpawnTime();

native int NekoSpecials_GetSpecialsNum();
native int NekoSpecials_GetSpecialsTime();

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){
    BuildPath(Path_SM, g_sNamePath, sizeof g_sNamePath, MODE_NAME_PATH);
    if(!FileExists(g_sNamePath)){
        FormatEx(g_sNamePath, sizeof g_sNamePath, "无法找到模式配置文件: %s", MODE_NAME_PATH);
        strcopy(error, err_max, g_sNamePath);
        return APLRes_SilentFailure;
    }

    //SpecialSpawner
    MarkNativeAsOptional("SS_GetSILimit");
    MarkNativeAsOptional("SS_GetSISpawnTime");
    //NekoSpecial
    MarkNativeAsOptional("NekoSpecials_GetSpecialsNum");
    MarkNativeAsOptional("NekoSpecials_GetSpecialsTime");

    return APLRes_Success;
}

public void OnAllPluginsLoaded(){
    g_bSpecialSpawner = LibraryExists("specialspawner");
    g_bNekoSpecials = LibraryExists("nekospecials");
}

public void OnLibraryAdded(const char[] sName){
    if(StrEqual(sName, "specialspawner"))
        g_bSpecialSpawner = true;
    if(StrEqual(sName, "nekospecials"))
        g_bNekoSpecials = true;
}

public void OnLibraryRemoved(const char[] sName){
    if(StrEqual(sName, "specialspawner"))
        g_bSpecialSpawner = false;
    if(StrEqual(sName, "nekospecials"))
        g_bNekoSpecials = false;
}

public void OnPluginStart(){
    RegConsoleCmd("sm_mode", CmdModeCheck, "查看当前模式.");

    //CreateTimer(600.0, Timer_TellAllMode, _, TIMER_REPEAT);
}

//现在我们希望各个玩家每次进入是都能看到播报
public void OnClientPutInServer(int client){
    if(IsFakeClient(client))
        return;
    
    PrintMode(client, false);
}

public void OnMapStart(){
    g_hPrintTimer = CreateTimer(600.0, Timer_PrintMode, _, TIMER_REPEAT);
}

public void OnMapEnd(){
    delete g_hPrintTimer;
}

//每过10min的播报
public Action Timer_PrintMode(Handle timer){
    PrintMode(-1, true);
    return Plugin_Continue;
}

//使用!mode指令时
public Action CmdModeCheck(int client,int args){
    PrintMode(client, false);
    return Plugin_Continue;
}

void PrintMode(int client, bool IsPublic){
    char sGameMode[254];
    sGameMode = GetGameMode();
    //单独播报
    if(!IsPublic){
        PrintToChat(client, "%s", sGameMode);
    }
    //公共播放
    else{
        PrintToChatAll("%s", sGameMode);
    }
}

char[] GetGameMode(){
    char sGameMode[254];
    char sSubMode[32];
    strcopy(sGameMode, sizeof sGameMode, "\x04[Mode]: ");
    //备弹part
    if(FindPluginConVar("ammo_shotgun_max")){
        int iAmmo = g_cvCvar.IntValue;
        iAmmo = iAmmo / 72;
        FormatEx(sSubMode, sizeof sSubMode, "\x05[\x05备弹系数: %dx\x05] ", iAmmo);
        StrCat(sGameMode, sizeof sGameMode, sSubMode);
    }
    //多特part
    if(g_bSpecialSpawner || g_bNekoSpecials){
        int iSINum, iSITime, iSIDistance;
        if(g_bNekoSpecials && g_bSpecialSpawner)
            LogError("do not use two or more SI plugins at the same time!");
        else if(g_bSpecialSpawner){
            iSINum = SS_GetSILimit();
            iSITime = SS_GetSISpawnTime();
            iSIDistance = FindPluginConVar("ss_spawnrange_min") ? g_cvCvar.IntValue : 1100;
            FormatEx(sSubMode, sizeof sSubMode, "\x05[\x05%d特%d秒%d码\x05] ", iSINum, iSITime, iSIDistance);
            StrCat(sGameMode, sizeof sGameMode, sSubMode);
        }
        else{
            iSINum = NekoSpecials_GetSpecialsNum();
            iSITime = NekoSpecials_GetSpecialsTime();
            FormatEx(sSubMode, sizeof sSubMode, "\x05[\x05%d特%d秒\x05] ", iSINum, iSITime);
            StrCat(sGameMode, sizeof sGameMode, sSubMode);
        }
    }
    //自定义part
    //@param Flags - 不同flag对应不同处理方式
    //@param text - 对应相应的处理方式
    //以下为示例,<val>表示ConVar对应的值
    //"Flags" -> "text"
    //"0"     -> "null"                                   - 直接输出<val>
    //"1"     -> "文字1;文字2"                            - <val> == 1 输出文字1, 否则输出文字2
    //"2"     -> "<val1>-文字A;<val2>-文字B;<val3>-文字C"  - 不同的<val>输出不同值
    //"3"     -> "后缀"                              - 为<val>添加后缀
    //"4"     -> "前缀"                              - 为<val>添加前缀
    KeyValues key = new KeyValues("ModeName")
    if(!FileToKeyValues(key, g_sNamePath))
        SetFailState("无法找到模式名文件位于：%s", MODE_NAME_PATH);
    key.Rewind();
    if(key.GotoFirstSubKey()){
        char sSectionName[16], sConVarName[64], sFlags[2];
        do{
            key.GetSectionName(sSectionName, sizeof sSectionName);
            key.GetString("ConVar", sConVarName, sizeof sConVarName);
            key.GetString("Flags", sFlags, sizeof sFlags);
            if(!FindPluginConVar(sConVarName))
                continue;
            switch(StringToInt(sFlags)){
                case 0:{
                    char sVal[16];
                    g_cvCvar.GetString(sVal, sizeof sVal);
                    FormatEx(sSubMode, sizeof sSubMode, "\x05[\x05%s: %s\x05] ", sSectionName, sVal);
                }
                case 1:{
                    bool bVal = g_cvCvar.BoolValue;
                    char sText[32], sTemp[2][16];
                    key.GetString("text", sText, sizeof sText);
                    ExplodeString(sText, ";", sTemp, sizeof sTemp, sizeof sTemp[]);
                    if(bVal)
                        FormatEx(sSubMode, sizeof sSubMode, "\x05[\x05%s: %s\x05] ", sSectionName, sTemp[0]);
                    else
                        FormatEx(sSubMode, sizeof sSubMode, "\x05[\x05%s: %s\x05] ", sSectionName, sTemp[1]);
                }
                case 2:{
                    int iVal = g_cvCvar.IntValue;
                    char sText[254], sTemp[15][16];
                    key.GetString("text", sText, sizeof sText);
                    ExplodeString(sText, ";", sTemp, sizeof sTemp, sizeof sTemp[]);
                    for(int i = 0; i < 15; i++){
                        if(sTemp[i][0] == '\0')
                            continue;
                        char sBuffer[2][16], sTemp1[16]
                        strcopy(sTemp1, sizeof sTemp1, sTemp[0]);
                        ExplodeString(sTemp1, "-", sBuffer, sizeof sBuffer, sizeof sBuffer[]);
                        if(StringToInt(sBuffer[0]) == iVal){
                            FormatEx(sSubMode, sizeof sSubMode, "\x05[\x05%s: %s\x05] ", sSectionName, sBuffer[1]);
                            break;
                        }
                    }
                }
                case 3:{
                    char sVal[16], sText[16];
                    g_cvCvar.GetString(sVal, sizeof sVal);
                    key.GetString("text", sText, sizeof sText);
                    StrCat(sVal, sizeof sVal, sText);
                    FormatEx(sSubMode, sizeof sSubMode, "\x05[\x05%s: %s\x05] ", sSectionName, sVal);
                }
                case 4:{
                    char sVal[16], sText[16];
                    g_cvCvar.GetString(sVal, sizeof sVal);
                    key.GetString("text", sText, sizeof sText);
                    StrCat(sText, sizeof sText, sVal);
                    FormatEx(sSubMode, sizeof sSubMode, "\x05[\x05%s: %s\x05] ", sSectionName, sText);
                }
            }
            StrCat(sGameMode, sizeof sGameMode, sSubMode);
        }while(key.GotoNextKey());
    }
    delete key;
    return sGameMode;
}

bool FindPluginConVar(const char[] conVarName){
    g_cvCvar = FindConVar(conVarName);
    if(g_cvCvar == null){
        PrintToServer("unable to find convar %s", conVarName);
        return false;
    }
    return true;
}