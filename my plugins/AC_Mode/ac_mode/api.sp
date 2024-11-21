//======================================================================================
//=                                 native
//======================================================================================
//-----point_system-----
native int GetPlayerMoney(int client);
native int GetTeamPoints();

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){
    MarkNativeAsOptional("GetPlayerMoney");
    MarkNativeAsOptional("GetTeamPoints");
    //g_bLateLoad = late;
    return APLRes_Success;
}

public void OnAllPluginsLoaded(){
    g_bPointSystem = LibraryExists("point_system");
}

public void OnLibraryAdded(const char[] sName){
    if(StrEqual(sName, "point_system"))
        g_bPointSystem = true;
}

public void OnLibraryRemoved(const char[] sName){
    if(StrEqual(sName, "point_system"))
        g_bPointSystem = false;
}