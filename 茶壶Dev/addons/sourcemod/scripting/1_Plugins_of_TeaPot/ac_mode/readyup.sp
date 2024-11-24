//服务器指令大全
static const char g_sCmd[][] = {
    "!slot xx - 开位",
    "!ready, !r, f1 - 准备",
    "!unready, !ur, f2 - 取消准备",
    "!show, !unshow - 打开, 关闭准备面板",
    "!spechud - 打开, 关闭旁观面板",
    "!forcestart, !fs - 管理员强制开始游戏",
    "",
};

//是否所有生还已准备
bool IsAllSurReady(bool IsFirst = true){
    //存在bot时
    if(GetSurNum(false) < GetSurNum(true)){
        return false;
    }
    //任一有效生还玩家未准备
    for(int i = 1; i <= MaxClients; i++){
        if(IsValidPlayer_Sur(i)){
            if(!g_bPlayerReady[i]){
                return false;
            }
        }
    }

    if(IsFirst){
        //传送并冻结
        for(int i = 1; i <= MaxClients; i++){
            if(IsValidPlayer_Sur(i)){
                ReturnPlayerToSafeRoom(i, false);
                SetClientFrozen(i, true);
            }
        }

        g_iCountDown = 3;
        for(int i = 1; i <= MaxClients; i++){
            if(IsValidClient(i) && !IsFakeClient(i)){
                EmitSoundToClient(i, SOUND_COUNTDOWN);
            }
        }
        CountDown();
    }
    
    return true;
}

void CountDown(){
    if(g_iCountDown > 0){
        PrintHintTextToAll("所有人已准备\n游戏将在%d秒后开始", g_iCountDown);
        g_iCountDown--;
        CreateTimer(1.0, Timer_CountDown);
    }
    else if(g_iCountDown == 0){
        for(int i = 1; i <= MaxClients; i++){
            if(IsValidClient(i) && !IsFakeClient(i)){
                EmitSoundToClient(i, SOUND_START);
            }
        }
        PrintHintTextToAll("游戏开始!");
        ReadyUp();
    }
}

void ReadyUp(){
    g_bReadyUp = true;
    g_cvGod.SetInt(0);
    if(g_hReadyUppanel != null)
        delete g_hReadyUppanel;
    //解除冻结
    for(int i = 1; i <= MaxClients; i++){
        if(IsValidPlayer_Sur(i)){
            //ReturnPlayerToSafeRoom(i, false);
            SetClientFrozen(i, false);
        }
    }
}

void Refresh_RUpanel(){
    if(g_bReadyUp)
        return;
    Panel ruPanel = new Panel();
    char line[128];

    //服务器指令
    Format(line, sizeof(line), "%s指 令: ", SYSMBOL_ARROW);
    char sBuffer[64];
    if(g_iCmd == sizeof g_sCmd)
        g_iCmd = 0;
    Format(sBuffer, sizeof(sBuffer), "%d.%s", g_iCmd + 1, g_sCmd[g_iCmd]);
    g_iCmd++;
    StrCat(line, sizeof(line), sBuffer);
    ruPanel.DrawText(line);

    //服务器名称
    Format(line, sizeof(line), "%s服务器: %s", SYSMBOL_ARROW, g_sServerName);
    ruPanel.DrawText(line);

    //玩家状态
    Format(line, sizeof(line), "%s玩 家: ", SYSMBOL_ARROW);
    int playerNum = GetPlayerNum();
    int playerSurNum = GetSurNum(false);
    int surNum = GetSurNum(true);
    int slotNum = g_cvMaxPlayers.IntValue;
    Format(sBuffer, sizeof(sBuffer), "%d(%d)/%d", playerSurNum, playerNum, slotNum);
    StrCat(line, sizeof(line), sBuffer);
    Format(sBuffer, sizeof(sBuffer), "[%s]", playerSurNum < surNum ? "缺人" : "满人");
    StrCat(line, sizeof(line), sBuffer);
    ruPanel.DrawText(line);
    ruPanel.DrawText(" ");

    //生还列表
    ruPanel.DrawText("1.生还者");
    for(int i = 1; i <= MaxClients; i++){
        if(IsValidPlayer_Sur(i)){
            char sPlayerName[32];
            GetClientName(i, sPlayerName ,sizeof sPlayerName);
            Format(line, sizeof(line), "%s %s", g_bPlayerReady[i] ? SYSMBOL_R : SYSMBOL_UR, sPlayerName);
            ruPanel.DrawText(line);
        }
    }
    ruPanel.DrawText(" ");

    //旁观列表
    ruPanel.DrawText("2.旁观者");
    int count = 1;
    for(int i = 1; i <= MaxClients; i++){
        if(IsValidSpec(i)){
            if(count <= 4){
                char sPlayerName[32];
                GetClientName(i, sPlayerName, sizeof sPlayerName);
                Format(line, sizeof line, "(s)%s", sPlayerName);
                ruPanel.DrawText(line);
                count++;
            }
            else{
                ruPanel.DrawText("...many...");
                break;
            }
        }
    }
    ruPanel.DrawText(" ");

    //路程
    Format(line, sizeof(line), "%s[Current ", SYSMBOL_ARROW);
    Format(sBuffer, sizeof(sBuffer), "%d%% ", GetAllFlow(2));
    StrCat(line, sizeof(line), sBuffer);
    char sPath[16];
    IntToString(GetAllFlow(0), sPath, sizeof sPath);
    StrCat(sPath, sizeof(sPath), "%");
    Format(sBuffer, sizeof(sBuffer), "|Tank %s ", GetAllFlow(0) != 0 ? sPath : "None");
    StrCat(line, sizeof(line), sBuffer);
    IntToString(GetAllFlow(1), sPath, sizeof sPath);
    StrCat(sPath, sizeof(sPath), "%");
    Format(sBuffer, sizeof(sBuffer), "|Witch %s]", GetAllFlow(1) != 0 ? sPath : "None");
    StrCat(line, sizeof(line), sBuffer);
    ruPanel.DrawText(line);

    for(int i = 1; i <= MaxClients; i++){
        if(IsValidClient(i) && !IsFakeClient(i))
            if(g_bReadypanel[i])
                ruPanel.Send(i ,DummyHandler, 1);
    }
    delete ruPanel;
}

public int DummyHandler(Handle menu, MenuAction action, int param1, int param2){
	return 1;
}

//处理玩家离开安全区的问题
public Action L4D_OnFirstSurvivorLeftSafeArea(int client){
    if(g_bReadyUp)
        return Plugin_Continue;
    g_cvGod.SetInt(1);
    ReturnPlayerToSafeRoom(client, false);
    CreateTimer(0.1, Timer_LagSetGod);
    return Plugin_Handled;
}

void RoUR_Hint(){
    if(IsAllSurReady(false) || g_bReadyUp)
        return;
    char sBuffer[128];
    for(int i = 1; i <= MaxClients; i++){
        if(IsValidPlayer_Sur(i)){
            Format(sBuffer, sizeof sBuffer, "你%s准备\n%s以%s", g_bPlayerReady[i] ? "已经" : "还未", g_bPlayerReady[i] ? "输入!unready/!ur或F2" : "输入!ready/!r或F1", g_bPlayerReady[i] ? "取消准备" : "准备");
            PrintHintText(i, "%s", sBuffer);
        }
    }
}