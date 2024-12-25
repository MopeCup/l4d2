# 插件描述
杀特回血、过关回血

* 依赖

    1.  [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)
    2.  [cup_function](https://github.com/MopeCup/l4d2/tree/main/my%20plugins/cup)

* <details><summary>ConVar</summary>

    * cfg/sourcemod/health_return.cfg
    ```php
    //回复生命值累型<0: 实血, 1: 虚血>
    hr_return_type "0"
    //过关后低于此血量将回复到此<0: 不回复>
    hr_saferoom_naps "50"
    //基础回复血量
    hr_base_return "0.0"
    //技巧击杀提供回血倍率(推荐1.5)
    hr_skill_rate "1.0"
    //近战击杀提供回血倍率(推荐1.2)
    hr_melee_rate "1.0"
    //多远会被判定为远距离
    hr_far_distance "550.0"
    //远距离击杀提供的回血倍率(推荐1.5)
    hr_far_rate "1.0"
    //危险击杀提供的回血倍率(推荐2.0)
    hr_danger_rate "1.0"
    //爆头击杀提供的回血倍率(推荐2.0)
    hr_headshot_rate "1.0"
    //最大生命值
    hr_max_health "100"
    ```
</details>

* <details><summary>指令</summary>
    
    None
</details>

# 更新日志

* 2024.12.25 - v1.0.5

    1.  安全屋回血后调一帧触发，以兼容其他插件
    
* 2024.11.24 - v1.0.0

    1.  插件发布