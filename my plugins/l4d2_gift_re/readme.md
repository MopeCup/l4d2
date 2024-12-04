# 插件描述
本插件改自fdxx的[l4d2_gift](https://github.com/fdxx/l4d2_plugins/blob/main/l4d2_gift.sp)
在此基础上对掉落概率与掉落类型做了重做处理

* 依赖

    1. [multicolors](https://github.com/fdxx/l4d2_plugins/blob/main/multicolors.sp)
    2. [l4d2_weapons_spawn](https://github.com/fdxx/l4d2_plugins/blob/main/include/l4d2_weapons_spawn.inc)
    3. [cup/cup_function](https://github.com/MopeCup/l4d2/tree/main/my%20plugins/cup)

* <details><summary>ConVar</summary>

    * cfg/sourcemod/l4d2_gift_re.cfg
    ```php
    //掉落物的类型<0: 掉落物品, 1: 掉落礼物盒>
    l4d2_gr_drop_type "1"
    //每种特感产生掉落物概率
    l4d2_gr_drop_chance "0.3 0.3 0.3 0.3 0.3 0.3"
    //掉落物存在的时间
    l4d2_gr_drop_time "75.0"
    //爆头击杀提供的掉落率提升
    l4d2_gr_headshot_boost "0.2"
    ```
</details>

* <details><summary>指令</summary>

    None
</details>

# 更新日志
* 2024.12.04 - v1.0.1

    1. 初次发布

# 安装注意
1. gift 放置在 addons/sourcemod/data/
2. l4d2_gift_re.txt 放置在 addons/sourcemod/gamedata/