# 茶壶详细更新日志
### v1.1.4
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