#define SYSMBOL_READY "★"
#define SYSMBOL_UNREADY "☆"
#define SYSMBOL_ARROW "▶"
#define SOUND_COUNTDOWN "level/countdown.wav"
#define SOUND_START "level/scoreregular.wav"
#define SYSMBOL_R "♜"
#define SYSMBOL_UR "♖"

ConVar
    g_cvServerName,
    g_cvGod,
    g_cvMaxPlayers;

Handle
    g_hReadyUppanel,
    g_hSpecHudpanel;

bool
    //g_bLateLoad,
    g_bPointSystem,
    g_bReadyUp,
    g_bPlayerReady[MAXPLAYERS + 1],
    g_bReadypanel[MAXPLAYERS + 1],
    g_bSpecHud[MAXPLAYERS + 1];

int
    g_iCmd,
    g_iCountDown;

char
    g_sServerName[64];