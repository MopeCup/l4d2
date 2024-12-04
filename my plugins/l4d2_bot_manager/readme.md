依赖
    bots.   https://forums.alliedmods.net/showthread.php?p=2405322#post2405322(注，此插件有修改请参照文件夹内的源码)(不装也能正常使用)

功能
    提供对于游戏中人机的相关优化:
    1. 当玩家死亡后，若生还队伍内没有存活的玩家或闲置Bot，则处死所有生还以重启游戏
    2. 提供一个离开安全区域自动处死Bot的指令
    3. 提供一个联动 bots.sp 用于踢出Bot的指令

更新日志
2024.8.16 - v1.0.0
    插件创建
2024.8.18 - v1.1.0
    添加离开安全区域后处死所有Bot功能
    添加联动Bot.sp的踢出多余人机功能
2024.8.23 - v1.1.1
    修改了Event_PlayerDeath下的IsValidSur判定，修复插件报错问题
2024.9.5  - v1.2.0
    针对各种bot加智商插件的bot进行削弱，取消bot的爆头伤害奖励
2024.10.21 - v1.2.1
    更改离开安全区域处死人机为，离开安全区域处死多余的人机

指令与Cvars
    sm_allbot  - 是否允许全Bot队伍，开启后队伍仅剩Bot时不会重启(默认关闭)
    sm_killbot - 离开安全区域处死额外Bot(默认关闭)
    sm_kickbot - 踢出人机(sm_kickbot 0 - 踢出所有人机, sm_kickbot 1 - 仅踢出超过cvar bots_join_limit (bot.sp)值的Bot)

    lbm_reduce_headshot_dmg - 是否启用取消bot爆头增伤<0 - 否, 1 - 是>

# 注意
l4d2_bot_manager已停止维护!!!   请使用bots_manager和bots一起编译