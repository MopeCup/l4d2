int g_iSISpawnQueque[32];

//取出一位待位特感
int GenerateIndex() {
    int sIClass = g_iSISpawnQueque[0];
    ArrayMoveForward();
    return sIClass;
}

void ArrayMoveForward() {
    for (int i = 0; i < 32; i++) {
        if (i != 31) {
            g_iSISpawnQueque[i] = g_iSISpawnQueque[i+1];
        }
        else {
            g_iSISpawnQueque[31] = -1;
        }
    }
}

//将一只死亡特感写入待位特感
void WriteIntoSpawnQueque(int class){
    class = class - 1;
    int quequeClass[SI_MAX_SIZE];
    GetSITypeCount();
    for (int i = 0; i < SI_MAX_SIZE; i++) {
        quequeClass[i] = CheckQueque(i);
        int num = quequeClass[i] + g_iSpawnCounts[i] - g_iSpawnLimits[i];
        if (i == class)
            num++;
        //如果没有变动，不进行修正
        if (num == 0)
            continue;
        //存在多余特感
        else if (num > 0) {
            ModifiedArray(num, i);
        }
        else if (num < 0) {
            ModifiedArray(num, i);
        }
        quequeClass[i] = CheckQueque(i);
    }
    //写入
    if (quequeClass[class] + 1 <= g_iSpawnLimits[class]) {
        for (int i = 0; i < 32; i++) {
            if (g_iSISpawnQueque[i] == -1) {
                g_iSISpawnQueque[i] = class;
                break;
            }
        }
    }
}

//计算待位特感每种特感的数量
int CheckQueque(int class){
    int count = 0;
    for (int i = 0; i < 32; i++) {
        if (g_iSISpawnQueque[i] == class)
            count++;
    }
    return count;
}

//修正待位特感的种类
void ModifiedArray(int num, int class){
    //清除不需要的特感
    for (int i = 31; i >= 0; i--) {
        //特感数大于设定数
        if (g_iSISpawnQueque[i] == class && num > 0) {
            g_iSISpawnQueque[i] = -1;
            num--;
        }
        //特感数小于设定数
        if (g_iSISpawnQueque[i] == -1 && num < 0) {
            g_iSISpawnQueque[i] = class;
            num++;
        }
    }
    //如果有0在中间把特感往前移动一位填补
    for (int i = 0; i < 32; i++) {
        if (g_iSISpawnQueque[i] != -1)
            continue;
        for (int j = i + 1; j < 32; j++) {
            if (g_iSISpawnQueque[j] == -1)
                continue;
            g_iSISpawnQueque[i] = g_iSISpawnQueque[j];
            g_iSISpawnQueque[j] = -1;
            break;
        }
        //说明后面没有特感存入
        if (g_iSISpawnQueque[i] == -1)
            break;
    }
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