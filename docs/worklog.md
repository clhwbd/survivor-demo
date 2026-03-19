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
