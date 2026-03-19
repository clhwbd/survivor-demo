# survivor-demo

Godot 4.x 2D 割草 Roguelike 样板项目。

## 当前可玩内容
- 玩家 8 向移动
- 两种敌人：基础敌人 / 快速敌人
- 敌人周期生成与追踪
- 玩家自动发射投射物攻击最近敌人
- 武器成长：升级后提升伤害、射程、多重射击、穿透
- 击杀敌人掉落经验
- 玩家拾取经验后升级，升级时小幅回血
- 生存计时、击杀统计、难度爬升
- 基础反馈：受击闪白、升级闪光、经验与掉血浮字
- Game Over 与 `R` 重开
- 基础 HUD：等级 / 血量 / 场上敌人数 / 时间 / 击杀 / 武器 / 经验条
- 已接入 Godot MCP
- 已导出 Web 试玩版到 `builds/web/`

## 运行方式
### 本地 Godot 运行
```bash
/Applications/Godot.app/Contents/MacOS/Godot --path ./game
```

### 本地预览 Web 版
在项目根目录启动一个静态服务器：
```bash
cd /Users/mac/game-studio/projects/survivor-demo/builds/web
python3 -m http.server 8000
```
然后浏览器打开：`http://localhost:8000`
