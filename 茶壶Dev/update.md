# 当前版本: 1.2.2

# 茶壶详细更新日志
### v1.2.2
* <details><summary>小型更新</summary>

    * 内容：
        
        1.  新增投票更改游戏模式
        2.  更改了动态服名游戏模式获取方式
        3.  slot能修改显示玩家数以及增加退出连接提示功能

    * 文件：

        * 新增addons/sourcemod/plugins/5_S/change_game_mode.smx
        * 改动addons/sourcemod/plugins/5_S/
        
            1. l4d2_dynamic_hostname.smx
            2. l4d2_teapot_commands.smx
        * 新增addons/sourcemod/scripting/1_P/change_game_mode.sp
        * 改动addons/sourcemod/scripting/1_P/
        
            1. l4d2_dynamic_hostname.sp
            2. l4d2_teapot_commands.sp
        * 新增addons/sourcemod/config/hostname/gamemode.txt
</details>

### v1.2.1
* <details><summary>小型优化</summary>

    * 内容:

        1.  非自动加入模式下无额外bot，旁观将不能加入生还
        2.  更改坦克是否激活的判定为left4dhooks内的函数，使得判定更加准确
        3.  安全屋回血后调一帧触发，以兼容其他插件

    * 文件：
        
        *  改动 addons/sourcemod/plugins/4_G/:

            1. bots.smx
            2. l4d2_tankfight.smx
            3. health_return.smx
        * 改动 addons/sourcemod/scripting/1_P/

            1. bots.sp
            2. l4d2_tankfight.sp
            3. health_return.sp
</details>

### v1.2.0
* <details><summary>死门更新</summary>

    * 内容：

        1.  新增礼物盒插件
        2.  新增双倍医疗
        3.  设置了死门专属多特配置
    * 文件：

        1.  新增 addons/sourcemod/data/gift
        2.  新增 addons/sourcemod/plugins/diabled/[DG]l4d2_gift_re.smx
        3.  新增 addons/sourcemod/plugins/diabled/[DG]l4d2_more_medicals.smx
        4.  改动 addons/sourcemod/data/config_DG.cfg
        5.  改动 cfg/vote/1_DG/deathGate.cfg
        6.  改动 cfg/vote/1_DG/unload.cfg
        7.  新增 cfg/vote/sINum/DG
</details>
