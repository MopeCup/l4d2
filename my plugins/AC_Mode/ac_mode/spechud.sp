static const char g_sWeaponName[][][] = {
    {"Uzi", "2"},
    {"Mac", "7"},
    {"Chorme", "8"},
    {"Pump", "3"},
    {"Scout", "36"},
    {"M16", "5"},
    {"Desert", "9"},
    {"AK47", "26"},
    {"Auto", "4"},
    {"Spas", "11"},
    {"Hunt", "6"},
    {"Mili", "10"},
    {"AWP", "35"},
    {"MP5", "33"},
    {"Sg552", "34"},
    {"Ma", "32"},
    {"P", "1"},
    {"M", "19"},
};

static const char g_sSIName[9][] = {
    "Nope",
    "Smoker",
    "Boomer",
    "Hunter",
    "Spitter",
    "Jockey",
    "Charger",
    "Witch",
    "Tank",
};

void Refresh_SHpanel(){
    Panel SHpanel = new Panel();
    char line[128], sBuffer[64];

    Format(line, sizeof(line), "%s旁观面板", SYSMBOL_ARROW);
    SHpanel.DrawText(line);
    //玩家状态
    Format(line, sizeof(line), "%s玩家: ", SYSMBOL_ARROW);
    int playerNum = GetPlayerNum();
    int playerSurNum = GetSurNum(false);
    int surNum = GetSurNum(true);
    int slotNum = g_cvMaxPlayers.IntValue;
    Format(sBuffer, sizeof(sBuffer), "%d(%d)/%d", playerSurNum, playerNum, slotNum);
    StrCat(line, sizeof(line), sBuffer);
    Format(sBuffer, sizeof(sBuffer), "[%s]", playerSurNum < surNum ? "缺人" : "满人");
    StrCat(line, sizeof(line), sBuffer);
    SHpanel.DrawText(line);

    //路程
    Format(line, sizeof(line), "%s[Current ", SYSMBOL_ARROW);
    Format(sBuffer, sizeof(sBuffer), "%d% ", GetAllFlow(2));
    StrCat(line, sizeof line, sBuffer);
    char sPath[16];
    IntToString(GetAllFlow(0), sPath, sizeof sPath);
    StrCat(sPath, sizeof(sPath), "%");
    Format(sBuffer, sizeof(sBuffer), "|Tank %s ", GetAllFlow(0) != 0 ? sPath : "None");
    StrCat(line, sizeof(line), sBuffer);
    IntToString(GetAllFlow(1), sPath, sizeof sPath);
    StrCat(sPath, sizeof(sPath), "%");
    Format(sBuffer, sizeof(sBuffer), "|Witch %s]", GetAllFlow(1) != 0 ? sPath : "None");
    StrCat(line, sizeof(line), sBuffer);
    SHpanel.DrawText(line);
    SHpanel.DrawText(" ");

    //生还数据
    if(g_bPointSystem)
        Format(line, sizeof line, "1.生还者(%d)", GetTeamPoints());
    else
        strcopy(line, sizeof line, "1.生还者");
    SHpanel.DrawText(line);
    for(int i = 1; i <= MaxClients; i++){
        if(IsValidPlayer_Sur(i)){
            char sPlayerName[32];
            GetClientName(i, sPlayerName ,sizeof sPlayerName);
            if(g_bPointSystem){
                int iMoney = GetPlayerMoney(i);
                Format(line, sizeof line, "%dP|%s: ", iMoney, sPlayerName);
            }
            else
                Format(line, sizeof line, "%s: ", sPlayerName);
            //血量
            int iHealth = GetClientHealth(i) + L4D_GetPlayerTempHealth(i);
            if(!IsPlayerAlive(i)){
                strcopy(sBuffer, sizeof(sBuffer), "死亡");
                StrCat(line, sizeof(line), sBuffer);
                SHpanel.DrawText(line);
                continue;
            }
            Format(sBuffer, sizeof(sBuffer), "%dHP ", iHealth);
            StrCat(line, sizeof(line), sBuffer);
            //武器
            int mainWeapon = GetPlayerWeaponSlot(i, 0);
            if(IsValidEntity(mainWeapon)){
                int mWepID = IdentifyWeapon(mainWeapon);
                for(int j = 0; j < 15; j++){
                    if(StringToInt(g_sWeaponName[j][1]) == mWepID){
                        Format(sBuffer, sizeof(sBuffer), "[%s ", g_sWeaponName[j][0]);
                        StrCat(line, sizeof(line), sBuffer);
                        break;
                    }
                }
                int iClips = GetEntProp(mainWeapon, Prop_Send, "m_iClip1");
                int iAmmo = L4D_GetReserveAmmo(i, mainWeapon);
                Format(sBuffer, sizeof(sBuffer), "%d / %d", iClips, iAmmo);
                StrCat(line, sizeof(line), sBuffer);
            }
            int subWeapon = GetPlayerWeaponSlot(i, 1);
            if(IsValidEntity(subWeapon)){
                int sWepID = IdentifyWeapon(subWeapon);
                for(int j = 15; j < 18; j++){
                    if(StringToInt(g_sWeaponName[j][1]) == sWepID){
                        Format(sBuffer, sizeof(sBuffer), "|%s]", g_sWeaponName[j][0]);
                        StrCat(line, sizeof(line), sBuffer);
                        break;
                    }
                }
            }
            SHpanel.DrawText(line);
        }
    }
    SHpanel.DrawText(" ");

    //感染者
    SHpanel.DrawText("2.感染者");
    bool count = false;
    for(int i = 1; i <= MaxClients; i++){
        if(IsValidClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i)){
            int iClass = GetEntProp(i, Prop_Send, "m_zombieClass");
            int iHealth = GetClientHealth(i);
            if(!count){
                Format(line, sizeof line, "%s@%dHP ", g_sSIName[iClass], iHealth);
                
            }
            else{
                Format(sBuffer, sizeof sBuffer, "%s@%dHP", g_sSIName[iClass], iHealth);
                StrCat(line, sizeof line, sBuffer);
                SHpanel.DrawText(line);
            }
            count = !count;
        }
    }
    //说明总特感数为单数
    if(count)
        SHpanel.DrawText(line);
    
    for(int i = 1; i <= MaxClients; i++){
        if(IsValidSpec(i) && g_bSpecHud[i])
            SHpanel.Send(i, SpecHandler, 1);
    }
    delete SHpanel;
}

public int SpecHandler(Handle menu, MenuAction action, int param1, int param2){
    return 1;
}