# 插件描述
允许玩家设置无限弹药以及无限备弹
* 依赖
    1.  [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)

* <details><summary>ConVar</summary>

    * cfg/sourcemod/ammo_set.cfg
    ```php
    //弹药设置类型<0: 正常, 1: 无限备弹, 2: 无限子弹>
    as_infinite_ammo_type "0"
    //初次离开安全区域前是否无限子弹<0: 否, 1: 是>
    as_safearea_infinite_ammo "1"
    ```
</details>

* <details><summary>指令</summary>
    
    None

</details>

* 更新日志

    * 2024.11.16 - v1.0.1

        1.  修复设置无限子弹时，使用副武器时主武器前置弹药多一发的问题
        2.  新增副武器无限子弹特性

    * 2024.11.15 - v1.0.0

        1.  插件创建