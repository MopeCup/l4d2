# 插件描述
茶壶推进赛模式(AC_Mode)计分插件

* 包含:

    1.  生还者计分系统: 由生还本局击杀特感，小尸与路程综合得出的评分
    2.  积分商店系统: 生还可以通过杀死特感，小尸获取积分，用于在安全区域购买武器与道具

* <details><summary>ConVar</summary>

    ```php
    //是否开启分数商店<0:否, 1:是>
    ps_pointshop "0"
    ```
</details>


* <details><summary>指令</summary>

    ```php
    //查询当前分数
    sm_point
    sm_bonus
    //打开积分商店(也可以使用E+R)
    sm_buy
    sm_b
    //管理员给予自己积分
    sm_givemoney <num>
    ```
</details>

* <details><summary>API</summary>

    ```php
    /**
    * 获取玩家当前持有的积分
    * 
    * @param client 	玩家索引
    * @return 有效生还返回持有积分，无效生还返回-1
    */
    int GetPlayerMoney(int client)

    /**
     * 获取团队总计分数
    * @remark 总计分数为路程与累计获取积分之积, 不会被消耗
    * 
    * @return 返回生还团队获取的总分
    */
    int GetTeamPoints()
    ```
</details>

* 更新日志

    * 2024.11.19 - v1.1.1

        1.  更新积分商店，重写路程记录

    * 2024.11.21 - v1.2.0

        1.  修复bug
        2.  新增根据实血计算的奖励系数