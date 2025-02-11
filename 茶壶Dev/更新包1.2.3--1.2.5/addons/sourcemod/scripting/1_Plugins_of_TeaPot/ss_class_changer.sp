static int g_iSIQuequeType[6] = {2, 4, 5, 0, 1, 3}; 

//生成特感队列
void GenerateIndex(int spawnSize) {
    int len = g_aSIDeath.Length;
    int spawnType[SI_MAX_SIZE];
    int surNum = 0;
    int count = 0;
    for (int i = 0; i < SI_MAX_SIZE; i++) {
        count += g_iSpawnLimits[i];
    }
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && GetClientTeam(i) == 2)
            surNum++;
    }
    int maxSpawnSize = surNum > 4 ? g_cBaseSize.IntValue + (surNum - 4) * g_cExtraSize.IntValue : g_cSpawnSize.IntValue;
    //初次生成+卡特初始化
    if (maxSpawnSize == spawnSize && len == 0) {
        InitSISpawnQueque();
        return;
    }
    for (int i = len - 1, num = count - maxSpawnSize; num > 0 && i >= 0; i--, num--) {
        int class = g_aSIDeath.Get(i) - 1;
        spawnType[class]++;
    }
    GetSITypeCount();
    for (int i = 0; i < spawnSize; i++) {
        for (int j = 0; j < SI_MAX_SIZE; j++) {
            int class = g_iSIQuequeType[j];
            if (g_iSpawnLimits[class] - g_iSpawnCounts[class] - spawnType[class] > 0) {
                g_iSISpawnQueque[i] = class;
                spawnType[class]++;
                break;
            }
        }
    }
    g_aSIDeath.Clear();
}

void InitSISpawnQueque() {
    for (int i = 0; i < 32; i++) {
        g_iSISpawnQueque[i] = -1;
    }
    int count = 0, counts[SI_MAX_SIZE];
    for (int i = 0; i < SI_MAX_SIZE; i++) {
        count += g_iSpawnLimits[i];
        counts[i] = g_iSpawnLimits[i];
    }
    for (int i = 0; i < count; i++) {
        for (int j = 0; j < SI_MAX_SIZE; j++) {
            if (counts[j] > 0) {
                g_iSISpawnQueque[i] = j;
                counts[j]--;
                break;
            }
        }
    }
    SortIntegers(g_iSISpawnQueque, count, Sort_Random);
}

Action cmdQueque(int client, int args) {
    PrintQueque();
    return Plugin_Handled;
}

void PrintQueque() {
    char sBuffer[128], sTest[4];
    for (int i = 0; i < 32; i++) {
        Format(sTest, sizeof sTest, "%d ", g_iSISpawnQueque[i]);
        StrCat(sBuffer, sizeof sBuffer, sTest);
    }
    PrintToChatAll("%s", sBuffer);
}