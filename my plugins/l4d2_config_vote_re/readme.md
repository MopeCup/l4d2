原作者:fdxx
修改:MopeCup

修改了fdxx的旧版的l4d2_config_vote.sp的配置文件读取方式，使其具有更高的自定义性：
新增一条Cvar: l4d2_config_vote_file 提供给自定义配置文件路径，例如
默认 l4d2_config_vote_file "data/l4d2_config_vote.cfg" 此时其会读取默认配置文件 l4d2_config_vote.cfg
服务端修改 l4d2_config_vote_file "data/test.cfg" 此时会读取位于data下的配置文件 test.cfg

使用此方法我们可以做到同一命令在不同模式选项下生成不同的投票菜单。比如默认状态下菜单里只有选项 "开启多特" ，当我们启用它后，再次打开菜单就会出现 "特感数量" "刷新时间" ... "关闭多特" 等选项

由于未知的原因，本插件仅在旧版l4d2_nativevote.smx下有效