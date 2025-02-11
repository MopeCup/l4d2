# 茶壶开服包

### 服务器指令
* <details><summary>玩家指令</summary>

    * 通用
    ```php
        !vt / !vote       基础投票指令
        !s / !afk         快捷闲置
        !vm / !votemode   投票更改游戏模式
        !away / !spec     加入旁观
        !join             加入生还
        !slot             开位(不会增加生还数量)
        !sbot / !setbot   投票设置开局bot数量
        !chmap            投票换图
        !mapvote          投票选取下一关地图
        !tkbot            接管bot
        !teams            显示团队菜单
        !kill / !zs       自杀
        !tank / !p / !t   显示当前路程(含有多特时能显示坦克与女巫路程)
    ```
    * 推进
    ```php
        !ready / !r       准备
        !unready / !ur    取消准备
        !show             显示准备面板
        !hide             隐藏准备面板
        !spechud          打开或关闭旁观面板
    ```
    * 训练
    ```php
        !sich             调整特感种类
        !mgod             开启或关闭无敌模式
        !mos              开启或关闭一击必杀模式(玩家被控一次直接去世)
    ```
</details>

* <details><summary>管理指令</summary>

    * 通用
    ```php
        !bot              管理员设置开局人机
        !kickbots / !kb   管理员踢出所有人机
        !bom              管理员炸服
        !killall          管理员杀死所有玩家
        !addcvar          管理员更改服务器ConVar
        !lazer / !ls      管理员为武器添加镭射
    ```
    * 推进
    ```php
        !fs / !forcestart 管理员强制开启游戏
    ```
</details>

# 仓库当前版本: 1.2.5

# 茶壶详细更新日志
### v1.2.5
* <details><summary>小型优化</summary>

    * 内容：

        1. 新增小尸溶解插件
        2. 当幸存者附近存在特感时将取消友伤
        3. 修复安全屋回血对死亡玩家不生效的问题
        4. 增加配置文件夹及对应投票"快捷设置"
        5. 修改模式训练模式的特感数量配置
        6. 新增趣味投票/特感高亮

    * 文件：

        * 改动addons/sourcemod/plugins/4_G/

            1. l4d_ff_manager.smx
            2. health_return.smx
        * 改动addons/sourcemod/scripting/1_P/
        
            1. l4d_ff_manager.sp
            2. health_return.sp
        * 新增addons/sourcemod/plugins/4_G/l4d_dissolve_infected.smx
        * 新增addons/sourcemod/scripting/1_P/

            1. l4d_dissolve_infected.sp
            2. infected_glow.sp
        * 改动addons/sourcemod/data/

            1. l4d2_config_vote.cfg
            2. config_vote_TR.cfg
            3. config_vote_MS.cfg
            4. config_vote_DG.cfg
            5. config_HT.cfg
        * 新增cfg/vote/

            1. fastSetting
            2. sINum/train
            3. funVote/sIGlow_on.cfg
            4. funVote/sIGlow_off.cfg
        * 删除cfg/vote/sINum/sINumForTrain
        * 新增addons/sourcemod/plugins/diabled/[FV]infected_glow.smx

### v1.2.4
* <details><summary>多特调整</summary>

    * 内容：
        
        1. 新增随机刷特功能，并提供一个切换投票(仅限多特)
        2. 死门默认随机刷特
        3. 修复有关安全屋回血的bug
        4. 采用新算法以修复轮换刷特规则下卡特问题
        5. 现在子弹堆旁将会有50%概率刷新镭射
        6. 添加了出生点增加安全区功能
    
    * 文件：

        * 改动addons/sourcemod/plugins/diabled/[GM]specialspawner.smx
        * 改动addons/sourcemod/scripting/1_P/
            1. specialspawner.sp
            2. health_return.sp
            3. ss_class_change.sp
        * 改动addons/sourcemod/data/config_vote_MS.cfg
        * 新增cfg/vote/spawnRule
        * 改动cfg/vote/1_DG/deathGate.cfg
        * 改动addons/sourcemod/plugins/4_G/health_return.smx
        * 新增addons/sourcemod/plugins/4_G/lfd_coop_laserStackSpawn.smx
        * 新增addons/sourcemod/plugins/2_F/l4d_start_safe_area.smx
        * 新增addons/sourcemod/gamedata/l4d_start_safe_area.txt
        * 新增addons/sourcemod/scripting/1_P/
            1. l4d_start_safe_area.sp
            2. lfd_coop_laserStackSpawn.sp
</details>

### v1.2.3
* <details><summary>小型更新与报错修复</summary>

    * 内容:

        1. 修复了l4d2_teapot_commands连接与退出不正常工作的问题
        2. 修复specialspawner, bots, l4d2_kill-si_announce的报错问题
        3. 现在受伤，被控均会中断连杀, 爆头击杀与击杀的提示做了分别
        4. 新增投票刷新服务器
        5. 新增投票多倍医疗
        6. 将投票杀特回血，过关回血设置为通用投票
        7. 修复投票提出人机不生效的问题

    * 文件：
        * 删除addons/sourcemod/plugins/disabled/[DG]l4d2_more_medicals.smx
        * 新增addons/sourcemod/plugins/4_G/l4d2_more_medicals.smx
        * 改动addons/sourcemod/data/

            1. l4d2_config_vote.cfg
            2. config_vote_DG.cfg
            3. config_vote_MS.cfg
            4. config_HT.cfg
            5. config_vote_TR.cfg

        * 改动addons/sourcemod/plugins/5_S/l4d2_teapot_commands.smx
        * 改动addons/sourcemod/plugins/4_G/

            1. bots.smx
            2. l4d2_kill-special_announce.smx
        * 改动addons/sourcemod/plugins/disabled/[GM]specialspawner.smx
        * 改动addons/sourcemod/scripting/1_P/

            1. l4d2_teapot_commands.sp
            2. bot_manager.sp
            3. specialspawner.sp
            4. l4d2_kill-special_announce.sp

        * 新增cfg/vote/serverSetting/refreshServer.cfg
        * 新增cfg/vote/moreMedicals
        * 改动cfg/vote/1_DG
        * 改动cfg/vote/serverSetting/kickbots.cfg
</details>

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