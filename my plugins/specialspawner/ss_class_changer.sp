//生成特感队列
void GenerateIndex(int spawnSize) {
    int len = g_aSIDeath.Length;
    int spawnType[SI_MAX_SIZE];
    GetSITypeCount();
    int count = 0;
    for (int i = 0; i < SI_MAX_SIZE; i++) {
        count += g_iSpawnLimits[i];
    }
    // for (int i = 0; i < SI_MAX_SIZE; i++) {
    //     spawnType[i] = g_iSpawnLimits[i] - g_iSpawnCounts[i];
    // } 
    for (int i = len - 1, num = count - spawnSize; num > 0 && i >= 0; i--, num--) {
        int class = g_aSIDeath.Get(i) - 1;
        spawnType[class]++;
    }
    for (int i = 0; i < spawnSize; i++) {
        for (int j = 0; j < SI_MAX_SIZE; j++) {
            if (g_iSpawnLimits[j] - g_iSpawnCounts[j] - spawnType[j] > 0) {
                g_iSISpawnQueque[i] = j;
                spawnType[j]++;
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
    delete g_aSIDeath;
    g_aSIDeath = new ArrayList(count);
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