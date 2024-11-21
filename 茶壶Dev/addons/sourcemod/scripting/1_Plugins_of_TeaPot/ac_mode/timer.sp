Action Timer_ReadyUppanel(Handle timer){
    if(!g_bReadyUp){
        RoUR_Hint();
        Refresh_RUpanel();
    }
    return Plugin_Continue;
}

Action Timer_CountDown(Handle timer){
    if(IsAllSurReady(false))
        CountDown();
    else{
        //解除冻结
        for(int i = 1; i <= MaxClients; i++){
            if(IsValidPlayer_Sur(i)){
                //ReturnPlayerToSafeRoom(i, false);
                SetClientFrozen(i, false);
            }
        }
    }
    return Plugin_Stop;
}

Action Timer_LagSetGod(Handle timer){
    g_cvGod.SetInt(0);
    return Plugin_Stop;
}

Action Timer_Specpanel(Handle timer){
    if(!g_bReadyUp)
        return Plugin_Continue;
    Refresh_SHpanel();
    return Plugin_Continue;
}