# l4d2
茶壶的开服插件以及部分由我编写或修改的自用插件

## my plugins
由我编写的插件放在此处

### 安装注意事项
1.  sp 文件放在addons/sourcemod/scripting/
2.  smx 文件放在addons/sourcemod/plugins/
3.  其余文件请按插件安装介绍安装

## 茶壶Dev
由我整合的服务器插件包，包含四种游戏模式(默认, 推进(未完成), 死门(未完成), 多特， 训练),通过投票菜单切换

### 服务器特性
1.  准星对准地图上武器摁R(换弹键)可以补充备弹
2.  玩家间近距离无友伤(距离可调), 初次离开安全区域前无友伤, 玩家被控时不受到友伤.
3.  克局无限尸潮停刷，推进路程刷新

### 安装注意事项
请确保系统为linux系统

#### plugins内各项分类:
1.  1_Pre 用于存放前置插件
2.  2_Fix 用于存放修复类插件
3.  3_AntiCheat 用于存放反作弊插件
4.  4_General 用于存放功用性插件
5.  5_Server 用于存放服务器设置插件

#### cfg分类
1.  vote 投票用配置文件存放于此
2.  1_Server.cfg 对应server.cfg原版cvar放于此处
3.  1_ServerPlugins.cfg 对应server.cfg插件提供cvar放于此处
4.  2_ServerCfgOnce.cfg 放置只执行一次的cvar(原版)
5.  2_PluginsCfgOnce.cfg 放置只执行一次的cvar(插件)

### 服务器常用指令
1.  !vt / !vote 打开投票菜单
2.  !sich       打开特感刷新控制菜单
3.  !chmap      换图
