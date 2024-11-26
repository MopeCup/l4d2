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
    int preSetClass[SI_MAX_SIZE];
    for (int i = 0; i < SI_MAX_SIZE; i++) {
        preSetClass[i] = CheckQueque(i);
        if (preSetClass[i] > g_iSpawnLimits[i]) {
            int num = preSetClass[i] - g_iSpawnLimits[i];
            ModifiedArray(num, i);
            preSetClass[i] = CheckQueque(i);
        }
    }
    if (preSetClass[class] + 1 <= g_iSpawnLimits[class]) {
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
        if (g_iSISpawnQueque[i] == class && num != 0) {
            g_iSISpawnQueque[i] = -1;
            num--;
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