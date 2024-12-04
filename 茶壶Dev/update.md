# 茶壶详细更新日志
### v1.1.6
* <details><summary>多人更新</summary>

    * 内容：

        1. 合并l4d2_bot_manager与bots为bots
        2. 将多人投票指令独立出来(!slot与!sbot)
    
    * 文件：

        1. 新增 addons/sourcemod/scripting/bots_manager.sp
        2. 改动 addons/sourcemod/data/
        3. 改动 cfg/2_PluginsCfgOnce.cfg
        4. 改动 cfg/vote/serverSetting/kickBots.cfg
        5. 删除 cfg/vote/serverSetting/killAllBots.cfg
        6. 删除 cfg/vote/multiplePlayer/
        7. 新增 cfg/vote/multiplePlayer/autoJoin_on.cfg
        8. 新增 cfg/vote/multiplePlayer/autoJoin_off.cfg

* <details><summary>备弹更新</summary>

    * 内容：
    
        1. 新增模式MS投票10倍备弹
        2. 删除模式DG备弹投票，改为默认无限备弹
    
    * 文件：

        1. 新增 cfg/vote/ammo/ammo_x10.cfg
        2. 改动 addons/sourcemod/data/config_vote_MS.cfg
        3. 改动 addons/sourcemod/data/config_vote_DG.cfg
        4. 改动 cfg/vote/1_DG
</details>

* <details><summary>HT与TR新增投票</summary>

    * 内容：模式HT与TR新增子弹设置投票

    * 文件：

        1.  新增 cfg/vote/ammo/ammoIf_On.cfg
        2.  新增 cfg/vote/ammo/ammoIf_Off.cfg
        3.  改动 addons/sourcemod/data/config_vote_TR.cfg
        4.  改动 addons/sourcemod/data/config_HT.cfg
        5.  改动 cfg/vote/1_TR/train.cfg
</details>

* <details><summary>新增一条管理员指令</summary>

    * 内容: 新增!lazer与!ls为管理员获取镭射

    * 文件:

        1.  addons/sourcemod/plugins/5_Server/
        2.  addons/sourcemod/scripting/1_Plugins_of_TeaPot/
</details>

* <details><summary>修改了l4d2_tankfight的克局刷新配置变更</summary>

    * 内容：克局修改刷特数量由拦截刷特改为自杀以兼容ss的轮换刷特

    * 文件：
       
        1.  addons/sourcemod/plugins/4_General/
        2.  addons/sourcemod/scripting/1_Plugins_of_TeaPot/
</details>

* <details><summary>优化了了ss特感轮换的逻辑</summary>

    * 内容：写入现在会读取场上特感了

    * 文件：

        1.  addons/sourcemod/plugins/disabled/
        2.  addons/sourcemod/scripting/1_Plugins_of_TeaPot/
</details>