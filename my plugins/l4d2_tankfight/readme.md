# 依赖
1.  left4dhooks https://forums.alliedmods.net/showthread.php?t=321696
2.  multicolors https://github.com/Bara/Multi-Colors
3.  NekoSpecials https://himeneko.cn/nekospecials
4.  specialspawner https://github.com/umlka/l4d2/tree/main/specialspawner (推荐使用茶壶Dev插件包中的修改版)

# 功能
1.  停止克局中的无限尸潮事件(不包括胆汁吸引的尸潮), 并提供了跑图惩罚防止玩家跳过本阶段的克局(玩家每推进5%的路程，就会刷出一波尸潮，推进到最大允许路程后，插件将不再工作)
2.  修改克局中刷新特感配置(仅限Neko与SpecialSpawner)

# 更新日志
## v1.7.0
1.  现在克局起始路程由激怒坦克时的路程作为起点，而非坦克生成时的路程
2.  修复了由路程计算错误导致的路程播报刷屏的问题，但现在路程播报坏掉了
3.  优化了对坦克总数量的计算方法，相对以前更准确
## 2024.8.25 - v1.7.1
1.  重写克局开始与结束判定
## 2024.11.10 - v1.8.0
1.  整合TankFight SI Controller并更名为l4d2 tankfight
2.  修复了恢复刷新路程不再播报的问题

# 指令与Cvar
1.  !p, !tank, !t 查询玩家当前的百分比路程
2.  tfsic_sinum_rule 克局刷出特感上限衰减数量<-1: 按坦克刷出数量衰减, >=0: 按给定数量衰减
3.  tfsic_sitime_rule 克局刷出特感间隔修改数值<实际值等于此值加上刷特插件设置值>