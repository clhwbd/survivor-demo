# survivor-demo

Godot 4.x 2D 割草 Roguelike 样板项目，当前已从原型推进到可在桌面浏览器 / 手机浏览器试玩的 demo 版。

## 当前可玩内容
- 玩家 8 向移动，支持键盘与网页端触控摇杆
- 新增主动闪避：桌面端 `Space` / 右 Shift，移动端右下角闪避按钮
- 浏览器首次进入 / 失焦后会给出聚焦提示
- 三种敌人：基础敌人 / 快速敌人 / 重装敌人
- 偶数波加入精英敌人，拥有更高压迫感与更高经验奖励
- 分波次推进：每 30 秒进入下一波，敌人密度与组合升级
- 玩家自动发射投射物攻击最近敌人
- 武器成长：升级后提升伤害、射程、多重射击、穿透
- 击杀敌人掉落经验，拾取升级后会小幅回血
- 连杀补给：每 25 击回复 1 点生命
- 生存目标：撑到 03:00 即完成本轮 demo
- 基础反馈：受击闪白、升级横幅、经验与掉血浮字、阶段提示、轻量镜头震动
- Game Over / Demo Clear 后支持 `R` 或按钮重开
- HUD 扩展：等级 / 血量 / 场上敌人数 / 时间 / 击杀 / 波次 / 目标 / 武器 / 经验条
- 已接入 Godot MCP
- 已导出 Web 试玩版到 `builds/web/`，Release 版到 `builds/web-release/`

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

### 当前验证过的本地访问方式
```bash
cd /Users/mac/game-studio/projects/survivor-demo/builds/web
python3 -m http.server 18080
```
然后访问：`http://127.0.0.1:18080/index.html`
