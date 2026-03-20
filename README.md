# survivor-demo

Godot 4.x 2D 割草 Roguelike 样板项目。

当前目标不是继续堆玩法，而是把现有 demo 收口成一个**可验收、可交接、可继续分工推进**的工程基线。

## 当前可玩内容
- 玩家 8 向移动，支持键盘与网页端触控摇杆
- 主动闪避：桌面端 `Space` / 右 Shift，移动端右下角闪避按钮
- 浏览器首次进入 / 失焦后会给出聚焦提示
- 三种敌人：基础敌人 / 快速敌人 / 重装敌人
- 偶数波加入精英敌人，拥有更高压迫感与更高经验奖励
- 每 30 秒进入下一波，敌人密度与组合升级
- 玩家自动发射投射物攻击最近敌人
- 武器成长：升级后提升伤害、射程、多重射击、穿透
- 击杀敌人掉落经验，拾取升级后会小幅回血
- 连杀补给：每 25 击回复 1 点生命
- 生存目标：撑到 `03:00` 即完成本轮 demo
- 基础反馈：受击闪白、升级横幅、经验与掉血浮字、轻量镜头震动
- Game Over / Demo Clear 后支持 `R` 或按钮重开
- HUD：等级 / 血量 / 场上敌人数 / 时间 / 击杀 / 波次 / 目标 / 武器 / 经验条

## 交付结构
- `game/`：Godot 工程
- `builds/web-release/`：验收基线版本（未预压缩，适合任意静态服务器直接托管）
- `builds/web/`：交付/部署版本（附带 `.gz` 资源和 `serve_compressed.py`，适合本地演示或支持 gzip 的静态托管）
- `builds/pages-deploy/`：Cloudflare Pages 正式托管目录（把 `.gz` 运行时资源改名为正式文件名，并配好 `_headers`）
- `docs/release-acceptance.md`：验收版本说明、验证结果、构建命令
- `docs/deployment-plan.md`：更稳的发布 / 托管方案建议
- `docs/release-minimum-checklist.md`：真正上线托管前的最小发布清单
- `docs/deployment/nginx-web-release.conf`：当前验收基线目录的 Nginx 静态托管模板
- `docs/ui-art-agent-split.md`：后续 UI / 美术 agent 拆分建议
- `docs/status.md`：项目当前状态收口
- `docs/worklog.md`：工程操作与交付日志
- `tests/smoke/release_guard.sh`：把导出 / 两套 Web 目录同步 / 本地服务 / gzip 返回 / 文档口径串起来的一键发布冒烟检查
- `tests/smoke/sync_compressed_build.sh`：把 `builds/web-release/` 同步到 `builds/web/` 并重建 `.gz` 资源，避免交付目录漂移
- `tests/smoke/sync_pages_build.sh`：把 `builds/web/` 的预压缩运行时资源同步成 `builds/pages-deploy/` 的 Pages 可发布目录
- `tests/smoke/pages_release_guard.sh`：验证 `builds/pages-deploy/` 的文件对齐、gzip 资源和 `_headers` 口径

## 运行方式
### 1) 本地 Godot 运行
```bash
/Applications/Godot.app/Contents/MacOS/Godot --path ./game
```

### 2) 本地预览验收版（推荐先验收这个）
```bash
cd /Users/mac/game-studio/projects/survivor-demo/builds/web-release
python3 -m http.server 18081
```
浏览器打开：`http://127.0.0.1:18081/index.html`

### 2.5) 一键跑发布冒烟检查
```bash
cd /Users/mac/game-studio/projects/survivor-demo
chmod +x tests/smoke/release_guard.sh
./tests/smoke/release_guard.sh
```

这会串行完成：
- 主场景 headless 加载
- Web 验收版重导出
- 把 `builds/web/` 与最新 `builds/web-release/` 自动同步，并重建 `.gz` 资源
- `builds/web-release/` 四个核心文件 `200` 校验
- `builds/web/` gzip / `HEAD` / `Content-Type` 返回校验
- README / status / release-acceptance / deployment-plan 的关键交付口径存在性检查

### 3) 本地预览压缩交付版
```bash
cd /Users/mac/game-studio/projects/survivor-demo/builds/web
python3 serve_compressed.py
```
浏览器打开：`http://127.0.0.1:8000/index.html`

## 重新导出 Web 验收版
已在本机用 Godot `4.6.1.stable` 验证下面命令可成功导出：

```bash
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless \
  --path /Users/mac/game-studio/projects/survivor-demo/game \
  --export-release Web \
  /Users/mac/game-studio/projects/survivor-demo/builds/web-release/index.html
```

说明：
- 当前 `export_presets.cfg` 中已有 `Web` 预设
- 验收版通过 CLI 指定输出路径导出到 `builds/web-release/`
- 若需要对外托管，优先参考 `docs/deployment-plan.md`，不要再依赖临时隧道做正式验收链路

## 当前最佳交付路径
### 本地 / 当下验收
- 优先使用 `builds/web-release/`
- 启动命令：`python3 -m http.server 18081`
- 适合作为负责人 / QA / 策划的统一验收基线
- 优点：不依赖额外脚本，任意普通静态服务器都能直接托管

### 后续正式分享 / 正式托管
- 第一选择：Cloudflare Pages，直接发布 `builds/pages-deploy/`
- 第二选择：对象存储静态托管 + CDN，先上传 `builds/web-release/`
- 第三选择：自管 Caddy / Nginx 静态站，稳定后再考虑切到 `builds/web/`
- 若走 Nginx，可直接参考 `docs/deployment/nginx-web-release.conf`
- 当前机器可本地执行 `tests/smoke/pages_release_guard.sh` 验证 Pages 发布目录；但 `wrangler pages dev` 受本机 macOS 12.6 限制，无法完整跑起 Cloudflare 本地运行时
- 不建议继续把临时隧道当正式验收链路
- 真正上线前，先过一遍 `docs/release-minimum-checklist.md`，并建议执行 `tests/smoke/release_guard.sh` 与 `tests/smoke/pages_release_guard.sh`

### `builds/web/` 什么时候用
- 用于部署优化、本地压缩回归、后续正式站点带宽优化
- 只有在托管平台确认支持 gzip 静态资源或边缘压缩后，再作为正式线上目录

## 当前工程结论
- 已具备一个可本地验收的 Web demo 基线
- 已具备一个适合后续静态托管的压缩交付版本
- 已在 `2026-03-20 14:45 CST` 完成一轮源码 / 场景一致性修正后的 Web 重导出与本地服务复验
- 下一阶段更适合拆成 **UI/HUD 收口** 与 **美术风格落地** 两条线并行推进，而不是继续把玩法往前堆
