# survivor-demo Worklog

> 目的：记录项目内所有代码、优化、导出、发布与重要工程操作，保证后续可以追溯“工程中发生了什么”。

## 记录规则
- 每次重要开发动作都要补一条记录
- 至少记录：时间、动作、影响范围、验证方式、提交号（如有）
- 包括但不限于：
  - 功能开发
  - 数值/手感优化
  - Web 导出
  - Godot MCP 接入
  - 发布/预览链接变更
  - 性能与加载优化

---

## 2026-03-20

### 1. 接入前快照
- 动作：为项目建立 Git 仓库并做接入前快照
- 目的：给 Godot MCP 接入和后续玩法迭代提供可回退基线
- 提交：`b5bc8c6` `chore: snapshot before Godot MCP integration`

### 2. Godot MCP 接入
- 动作：安装并启用 `godot_mcp` addon，完成 editor / server 连通验证
- 结果：项目已具备 Godot MCP 辅助开发能力
- 提交：`aaf0ad7` `chore: integrate Godot MCP addon`

### 3. 第一轮可玩闭环增强
- 动作：补齐生存计时、击杀统计、难度爬升、Game Over、R 重开
- 结果：从基础原型推进到短局可玩的 V0
- 提交：`10c97d1` `feat: improve playable game loop`

### 4. 第二轮玩法扩展 + Web 导出
- 动作：补武器成长、第二种敌人、受击/经验反馈，并完成 Web build 导出
- 结果：产生 `builds/web/`，可本地网页试玩
- 提交：`991d5fc` `feat: expand combat loop and export web build`

### 5. 第三轮网页端可操作 + demo 节奏化
- 动作：增加触控摇杆、网页聚焦提示、移动端提示、30 秒一波、03:00 Demo Clear、阶段横幅、重装敌人、连杀补给
- 结果：从“能跑”推进到“更像 demo 的短局试玩”
- 提交：`c9bee51` `feat: add web controls and wave-based demo polish`

### 6. 第四轮操作手感与精英节奏
- 动作：增加闪避（桌面端 `Space` / `Right Shift`，移动端右下角按钮）、短暂无敌、精英敌人波次、镜头震动、经验磁吸增强
- 结果：网页/移动端操作容错更高，战斗演出与波次压迫感更强
- 提交：`25fc2ec` `feat: add dash controls and elite wave polish`

### 7. Web 加载优化
- 动作：对 `index.wasm` / `index.js` / `index.pck` 做 gzip 压缩，并提供 `serve_compressed.py`
- 结果：关键资源体积显著下降，便于后续正式静态托管或压缩服务
- 备注：临时隧道链路仍不稳定，外网访问瓶颈主要在隧道服务而不是游戏资源本体

### 8. UI / 视觉方向确认
- 用户确认：项目风格方向为 **西游记古风 Q 版**
- 后续影响范围：UI、角色造型、敌人设计、按钮/面板、提示文案、演出氛围均需向该方向统一
- 执行策略：先在交互与玩法持续推进的同时，逐步把 HUD、提示层、敌人命名/演出语言往“西游记古风 Q 版”靠拢，再整理成正式视觉规范

### 9. 工程交付面收口（验收版 / 发布方案 / 文档）
- 动作：补齐 README、`docs/status.md`、`docs/worklog.md`，新增 Web 验收版本说明、发布/托管方案文档、UI/美术 agent 拆分建议文档
- 结果：项目从“有网页包的玩法 demo”收口为“有验收基线、有部署建议、有后续分工接口”的可交接工程包
- 新增文档：
  - `docs/release-acceptance.md`
  - `docs/deployment-plan.md`
  - `docs/ui-art-agent-split.md`
- 备注：明确 `builds/web-release/` 作为验收基线，`builds/web/` 作为压缩交付版

### 10. Web 验收构建复验
- 动作：使用 Godot 4.6.1 CLI 实测执行 `--headless --export-release Web`，重新导出到 `builds/web-release/index.html`
- 验证结果：导出成功，退出码 `0`
- 本地校验：
  - `python3 -m http.server 18081` 可正常提供 `builds/web-release/`
  - `index.html / index.js / index.wasm / index.pck` 均返回 `200`
  - `builds/web/serve_compressed.py` 可正确返回 gzip 版 `index.wasm`
- 发现：`serve_compressed.py` 当前未实现 `HEAD`，因此 `curl -I` 会返回 `501`，但不影响浏览器实际加载
