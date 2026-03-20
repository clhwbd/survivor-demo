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

### 9. 程序执行面扩容
- 用户确认新增两个程序 Agent：
  - `godot-gameplay-programmer`
  - `godot-web-input-programmer`
- 目的：增强工作室内真正能稳定产出代码的执行单元，避免 main 再被迫亲自下场做细项开发
- 执行原则：main 负责拆解、调度、验收、汇报；新增 Agent 立即接手对应编码任务

### 10. 设计 / 动效 / PM 执行面扩容
- 用户确认新增：
  - `godot-ui-ux-designer`
  - `godot-vfx-animator`
- 同时新增并启用：
  - `game-pm`
- 其中 `game-pm` 正式接管工作室内的生产 / 交付管理职责，负责盯并行线、发现掉线任务、整理版本状态、向 main 提供补线与验收建议
- `game-pm` 职责已明确为**纯版本/交付管理**，只负责：版本状态文档维护、发布流程守护、交付风险识别、补线建议写入文档。**不做**：写代码、做策划、调度其他 Agent、对外汇报。
- main 保持对外沟通、最终调度、验收与汇报职责不变
- 用户新增规则：**后续所有与发布有关的事情，统一交给 `game-build` 负责**。包括：导出、发布包整理、正式静态托管、外链交付、发布验证与发布说明收口。

### 9. HUD / 文案 / 风格化第一轮落地（P1-5 / P2-7）
- 动作：收口 HUD 与提示层可用性，统一按钮、阶段名、目标提示、触控提示、战斗弹字语气，并给主 HUD / 顶部横幅 / 触控摇杆补第一轮古风 Q 版配色与视觉语言
- 涉及文件：
  - `game/scripts/main.gd`
  - `game/scripts/touch_joystick.gd`
  - `game/scenes/main.tscn`
  - `game/scenes/damage_popup.tscn`
  - `docs/ui-style-guide.md`
- 结果：demo 从英文原型 HUD 提升为中文化、可读性更强、氛围更统一的一版“西游记古风 Q 版”界面
- 验证：通过 Godot headless 语法检查主场景加载（见本次提交说明）

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

### 11. P1-4 战斗节奏与手感调优
- 动作：重做 3 分钟短局的波次配置与出怪压力，延后重装与精英的关键出场时机；同时补玩家成长曲线、击杀节奏反馈、刷怪公平性与受击/击杀手感
- 涉及文件：
  - `game/scripts/main.gd`
  - `game/scripts/player.gd`
  - `game/scripts/enemy_basic.gd`
- 具体改动：
  - 改为更明确的 6 段波次节奏：热身 → 追兵提速 → 精英试炼 → 重装入场 → 双精英压阵 → 终局冲阵
  - 敌人生成加入手工配置的 batch / alive / interval / fast_weight / tank_weight，降低前期乱压、提升中后期层次感
  - 精英改为从第 3 波开始，重装改为第 4 波登场，避免前期过早“硬卡手”
  - 低血量时自动减轻新一轮刷新压力，并降低快敌 / 重装占比，提升公平性
  - 新刷敌人加入短暂起手保护（spawn grace），避免刚刷出就贴脸判伤
  - 敌人受击增加短击退与缩放反馈，提升命中手感与读感
  - 玩家升级前几级所需经验下调，并增加 3 级加血上限 / 4 级加移速 / 升级回更多血，优化成长曲线
  - 新增连斩计数、12 连斩临时急速射击、分阶段目标文案与达成提示，强化短局目标感与滚雪球反馈
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 10`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 1200`
- 验证结果：两次 headless 运行均退出码 `0`；过程中发现 XP Orb 在物理查询刷新期直接 `add_child` 会报错，已改为 `call_deferred` 延迟生成并复验通过

### 12. HUD / 引导 / 结果反馈第二轮收口
- 动作：继续围绕“西游记古风 Q 版”方向做可验收收口，补右上状态卡、结果面板文案、横幅显隐一致性与弹字读感增强
- 涉及文件：
  - `game/scripts/main.gd`
  - `game/scripts/damage_popup.gd`
  - `game/scenes/main.tscn`
  - `docs/ui-style-guide.md`
- 具体改动：
  - 新增右上状态卡，用一句话动态提示“回命还差几斩 / 命火告急 / 终局压阵 / 可再闯一局”
  - 浏览器聚焦提示面板复用于失败 / 通关场景，补全局内结果说明与下一步操作引导
  - 顶部横幅背景与描金条改为随播报一起淡入淡出，避免标签消失后底板残留
  - 移动端提示补成情境化短句，在低血量和终局阶段自动切换为行动建议
  - 战斗弹字增加轻微放大动画，回血 / 伤害 / 修为获取更容易被看见
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 3`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 10`
- 验证结果：两次 headless 运行均退出码 `0`，主场景可正常加载，新增 HUD 节点与脚本逻辑未引入语法或装配错误

### 12. 暂停 / 结算面板 + 角色敌人视觉统一第二轮
- 动作：补一轮对验收感知最强的 UI / 演出完善，重点收口暂停、失败、通关的“戏台战报”面板，并把主角与三类敌人从纯色几何块推进到更统一的西游 Q 版纸片戏轮廓。
- 涉及文件：
  - `game/scripts/main.gd`
  - `game/scripts/damage_popup.gd`
  - `game/scenes/main.tscn`
  - `game/scenes/player.tscn`
  - `game/scenes/enemy_basic.tscn`
  - `game/scenes/enemy_runner.tscn`
  - `game/scenes/enemy_tank.tscn`
  - `docs/ui-style-guide.md`
- 具体改动：
  - 新增暂停体系：支持 `Esc / P` 与 HUD 常驻“暂停”按钮，暂停时弹出中部战报面板，并提供“继续试炼 / 再闯一局”操作。
  - 失败 / 通关面板改成统一的中文战报样式，增加题头、评语、本局时辰 / 斩妖 / 头目 / 命火 / 当前劫波摘要，更适合网页验收与录屏截图。
  - 右上状态卡增加多状态底色 / 强调色切换，让低血量、终局压阵、暂停、通关等信息一眼更明显。
  - 玩家与三类敌人补阴影、脸谱 / 面甲、披风、冠饰、护甲、棍身等简部件，第一眼更统一到“西游记古风 Q 版”方向。
  - 修正敌人死亡时经验球在物理查询刷新阶段直接 `add_child` 产生的报错，改为 `call_deferred` 延迟挂载。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 10`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 600`
- 验证结果：两次 headless 运行均退出码 `0`；其中第二次复验确认经验球报错已消除。

### 13. 高优先级内容演出补强第三轮
- 动作：继续补强命中 / 击杀 / 连斩 / 暂停结算的演出读感，并给主角与三类敌人再加一层轻量动势与视觉部件，提升试玩版完成感。
- 涉及文件：
  - `game/scripts/main.gd`
  - `game/scripts/player.gd`
  - `game/scripts/enemy_basic.gd`
  - `game/scenes/main.tscn`
  - `game/scenes/player.tscn`
  - `game/scenes/enemy_basic.tscn`
  - `game/scenes/enemy_runner.tscn`
  - `game/scenes/enemy_tank.tscn`
- 具体改动：
  - 中部战报面板新增“战绩牌”行，暂停 / 失败 / 通关时会根据表现给出更直观的战绩称号，截图和结算观感更完整。
  - 补了快速连斩节奏读感：记录本局最长连斩，并在连斩达到关键节点时触发中心提示；状态卡会在短时间连杀时切到“连斩起势”文案。
  - 结算摘要新增“最长连斩”字段，让短局表现除了斩妖总数外，多一个更像动作试玩 demo 的结果指标。
  - 玩家新增淡金气场层，配合移动 / 闪避做呼吸与拉伸；基础敌 / 快敌 / 重装敌都补了背后飘带，使群怪在跑动时更有戏曲纸片人的动势。
  - 敌人脚本把飘带纳入摆动动画链路，保持三类敌人的动势统一。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 3`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 180`
- 验证结果：两次 headless 运行均退出码 `0`，主场景加载与新增结算 / 连斩 / 动势逻辑正常。
- 提交：
  - `0a9ee50` `feat: boost combat presentation and settlement feedback`
  - `6881473` `feat: add motion polish to player and enemies`

### 13. HUD / 状态签 / 横幅副标题 + 角色敌人细节第三轮
- 动作：继续沿“西游记古风 Q 版”方向做高优先级验收收口，这轮重点是 HUD 信息层级、状态签样式、横幅播报副标题、按钮主次，以及角色/敌人的第一眼识别细节。
- 涉及文件：
  - `game/scripts/main.gd`
  - `game/scenes/main.tscn`
  - `game/scenes/player.tscn`
  - `game/scenes/enemy_basic.tscn`
  - `game/scenes/enemy_runner.tscn`
  - `game/scenes/enemy_tank.tscn`
  - `docs/ui-style-guide.md`
- 具体改动：
  - 左上主 HUD 新增金/朱砂分隔条，把数值层、波次层、目标提示层拆开，信息块更像一页戏台账本。
  - 顶部横幅新增副标题位，关键播报从单句升级成“标题 + 小签注”的戏台播报结构。
  - 右上状态卡新增独立徽签文案（香火签 / 军令签 / 告急签 / 喝彩签等），与状态正文分离，读感和层级更清楚。
  - 继续试炼 / 暂停按钮切到次级深墨金边样式，`再闯一局` 与移动端 `筋斗闪` 维持高强调主按钮，结果页操作主次更明确。
  - 主角补眉眼、肩甲、下摆；基础怪补凶眉和肩甲；快怪补头焰与臂缠；重装怪补牙饰与腰甲，三类敌我更像同一套西游纸片戏角色。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 3`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 20`
- 验证结果：两次 headless 运行均应为退出码 `0`；本轮还额外检查场景装配是否能正确加载新增 HUD 节点与角色细节 Polygon。

### 13. 交付文档二次收口 + Web 复验复核
- 动作：再次统一 README / status / release-acceptance / deployment-plan 的交付口径，明确 `builds/web-release/` 与 `builds/web/` 的职责，并补一轮现有 Web 构建复验结果。
- 涉及文件：
  - `README.md`
  - `docs/status.md`
  - `docs/release-acceptance.md`
  - `docs/deployment-plan.md`
  - `docs/worklog.md`
- 具体改动：
  - 在 README 中新增“当前最佳交付路径”，把本地验收、正式托管、压缩版使用条件拆开写清楚。
  - 在 `docs/status.md` 中固化当前统一验收目录和后续正式托管建议，避免后续混用 `web/` 与 `web-release/`。
  - 在 `docs/release-acceptance.md` 中追加 `2026-03-20 14:36 CST` 复验结论，写明压缩版应以 `GET` 而不是 `HEAD` 校验 gzip 返回。
  - 在 `docs/deployment-plan.md` 中补“一句话执行口径”，降低后续交接成本。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --export-release Web /Users/mac/game-studio/projects/survivor-demo/builds/web-release/index.html`
  - `python3 -m http.server 18081`（目录：`builds/web-release/`）
  - `python3 serve_compressed.py`（目录：`builds/web/`）
  - `curl -I http://127.0.0.1:18081/index.html`
  - `curl -I http://127.0.0.1:18081/index.js`
  - `curl -I http://127.0.0.1:18081/index.wasm`
  - `curl -I http://127.0.0.1:18081/index.pck`
  - `curl -D - -H 'Accept-Encoding: gzip' http://127.0.0.1:8000/index.wasm -o /dev/null`
- 验证结果：Godot CLI 导出退出码 `0`；验收版四个核心文件均返回 `200`；压缩版 `GET index.wasm` 返回 `Content-Encoding: gzip` / `Vary: Accept-Encoding` / `Content-Type: application/wasm`。

### 14. 源码 / Web 验收包一致性修正 + 最小发布清单
- 动作：承接上一轮验收 / 发布准备线，继续收口当前可试玩版本的交付质量，重点修源码与场景脱节、统一文档口径，并补真正上线托管前的最小清单。
- 涉及文件：
  - `game/scripts/main.gd`
  - `game/scenes/main.tscn`
  - `README.md`
  - `docs/status.md`
  - `docs/release-acceptance.md`
  - `docs/deployment-plan.md`
  - `docs/release-minimum-checklist.md`
  - `docs/worklog.md`
- 具体改动：
  - 修正 `main.gd` 中阻断主场景加载 / Web 导出的语法错误。
  - 调整 `main.tscn` 的主场景节点装配，让当前脚本引用重新与场景结构对齐。
  - 在 README、status、release-acceptance、deployment-plan 中补充“上线前先过清单”的统一口径。
  - 新增 `docs/release-minimum-checklist.md`，把源码一致性、本地回归、移动端最低体验、托管配置、交付留痕拆成最小可执行清单。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --scene res://scenes/main.tscn --quit-after 3`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --export-release Web /Users/mac/game-studio/projects/survivor-demo/builds/web-release/index.html`
  - `python3 -m http.server 18081`（目录：`builds/web-release/`）
  - `curl -I http://127.0.0.1:18081/index.html`
  - `curl -I http://127.0.0.1:18081/index.js`
  - `curl -I http://127.0.0.1:18081/index.wasm`
  - `curl -I http://127.0.0.1:18081/index.pck`
- 验证结果：主场景 headless 加载恢复正常；重导出后 `builds/web-release/` 与当前源码重新对齐；四个核心静态资源均返回 `200`。

### 15. 高优先级战斗精修第三轮：喘息窗口 / 编组压迫 / 波次小目标
- 动作：继续在现有战斗基线上做高优先级可玩性精修，不动 P0 摇杆；这一轮重点补战斗导演、公平性缓冲、成长奖励和短局目标感。
- 涉及文件：
  - `game/scripts/main.gd`
  - `game/scenes/main.tscn`
  - `docs/worklog.md`
- 具体改动：
  - 新增“喘息窗口”导演逻辑：换波和玩家掉血后会短暂减轻刷新量，并压低快怪 / 重装占比，降低被连续贴脸滚死的挫败感。
  - 新增两种敌群编组：双侧包夹与重装护送队，让中后期不只是随机堆数，而是更像有意图的妖潮组合压迫。
  - 新增每波“小目标”系统（稳住阵脚 / 斩妖数 / 伏诛头目），完成后给回命或短时火力奖励，把 3 分钟短局拆成更明确的小段目标。
  - 新增临时节奏奖励：小目标达成后会触发急速 / 额外伤害 / 连发 / 穿透强化，并同步回写武器 HUD，成长反馈更直接。
  - HUD 补状态徽签、目标文案和分隔条，让“当前该做什么 / 奖励还剩多久 / 现在是回气还是压阵”更一眼可读。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 3`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 12`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 45`
- 验证结果：三次 headless 运行均退出码 `0`；包含跨波次与中时长运行复验，确认新增目标逻辑、HUD 节点装配与战斗导演代码未引入场景加载错误。

### 16. Presentation-pass 严格执行补齐：斩击特效资源落地 + 验收构建回写
- 动作：补齐主循环里已经接入但仓库缺失的斩击特效资源，确保命中 / 击杀 / 连斩 / 升级 / 受击等演出真正有可实例化的场景与脚本，而不是只停留在主逻辑调用；同时回写一轮当前验收包产物。
- 涉及文件：
  - `game/scenes/slash_fx.tscn`
  - `game/scripts/slash_fx.gd`
  - `builds/web-release/index.html`
  - `builds/web-release/index.pck`
  - `docs/worklog.md`
- 具体改动：
  - 新增 `SlashFx` 特效脚本与场景，使用弧形斩光、亮边与火花线实现短时刀光感，供命中、击杀、连斩、升级、受击等节点复用。
  - 补齐 `main.gd` / `main.tscn` 已引用的 `res://scenes/slash_fx.tscn` 资源缺口，避免“逻辑已写、资源不存在”的半成品状态。
  - 重新让当前工程资源与 `builds/web-release/` 产物保持一致，保证网页验收包能带上本轮新增特效资源引用。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --scene res://scenes/main.tscn --quit-after 3`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --scene res://scenes/main.tscn --quit-after 20`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --scene res://scenes/main.tscn --quit-after 45`
- 验证结果：三次 headless 均退出码 `0`，主场景可稳定加载并进入运行；说明本轮补齐的特效场景 / 脚本已被正确解析，未引入装配错误。

### 16. 发布基线补强：冒烟脚本 / Nginx 模板 / 压缩服务 HEAD 支持
- 动作：继续承接发布收口线，把“最小发布清单”里原本偏手工的步骤补成可执行工程项，不改玩法基线、不碰 P0 摇杆。
- 涉及文件：
  - `builds/web/serve_compressed.py`
  - `tests/smoke/release_guard.sh`
  - `docs/deployment/nginx-web-release.conf`
  - `README.md`
  - `docs/status.md`
  - `docs/release-acceptance.md`
  - `docs/release-minimum-checklist.md`
  - `docs/deployment-plan.md`
  - `docs/worklog.md`
- 具体改动：
  - 给 `serve_compressed.py` 补 `HEAD` 支持，压缩版本地服务现在既能给浏览器正常加载，也能接健康检查 / 自动化探测。
  - 新增 `tests/smoke/release_guard.sh`，把主场景 headless 加载、Godot CLI 导出、`builds/web-release/` 四个核心资源 `200` 校验、`builds/web/` 的 gzip / `HEAD` / MIME 校验、文档口径存在性检查串成一键冒烟流程。
  - 新增 `docs/deployment/nginx-web-release.conf`，把当前统一验收目录 `builds/web-release/` 的缓存策略与 `application/wasm` MIME 落成可直接改路径套用的 Nginx 模板。
  - 更新 README / status / release-acceptance / release-minimum-checklist / deployment-plan，统一把“自动化冒烟校验 + Nginx 模板”纳入当前发布口径。
- 验证：
  - `chmod +x tests/smoke/release_guard.sh`
  - `./tests/smoke/release_guard.sh`
- 验证结果：脚本完整跑通，退出码 `0`；已串行通过主场景加载、Web 验收版重导出、`builds/web-release/` 核心资源 `200` 校验、`builds/web/` 的 `GET` / `HEAD` gzip 头与 `application/wasm` 校验。

### 17. Presentation-pass 第四轮：连斩字牌 / 低血压屏 / 结算印章动效补强
- 动作：承接 slash / burst 资源线继续往“更像可试玩演示版”的方向补反馈，不碰 P0 摇杆；这轮重点把击杀连段、升级奖励、受击告警、结算落版做成更容易被玩家第一眼感知的演出。
- 涉及文件：
  - `game/scripts/main.gd`
  - `game/scripts/reward_pulse.gd`
  - `builds/web-release/index.html`
  - `builds/web-release/index.pck`
  - `docs/worklog.md`
- 具体改动：
  - 新增连斩字牌的二段弹出/淡出控制，让 4 连以上击杀节奏会在屏幕上方给出更明确的“起势 / 起煞 / 压场 / 破阵”读感。
  - 补结算印章入场动画，暂停 / 败阵 / 通关时会用更像戏台盖印的方式落到战报面板里，提升截图与结算完成感。
  - 继续强化 `RewardPulse` 绘制：在原有环形脉冲外再叠一层扇形喝彩芒，用于升级、击杀、受击、结算节点，观感比单圈扩散更饱满。
  - 重新导出 `builds/web-release/`，让当前网页验收包与本轮演出脚本保持一致。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --scene res://scenes/main.tscn --quit-after 3`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --scene res://scenes/main.tscn --quit-after 45`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --export-release Web /Users/mac/game-studio/projects/survivor-demo/builds/web-release/index.html`
- 验证结果：短时加载、中时长运行、Web 验收导出三项均退出码 `0`；说明本轮连斩 / 结算 / 奖励脉冲脚本改动未引入装配或导出错误。

### 17. 发布文档/模板一致性补强：Smoke README 回写 + 模板口径守卫
- 动作：承接 `release_guard.sh` 落地后的下一轮收口，继续补发布并行线里仍容易漂移的地方，优先消除 smoke README 仍停留在早期玩法测试口径的问题，并把 Nginx 模板关键字段纳入自动检查。
- 涉及文件：
  - `tests/smoke/README.md`
  - `tests/smoke/release_guard.sh`
  - `docs/worklog.md`
- 具体改动：
  - 重写 `tests/smoke/README.md`，明确当前 smoke 目录的职责已经升级为“发布 / 交付最小自动化复验”，不再停留在“项目可启动 / Player 可移动”的原型期描述。
  - 在 smoke README 中补齐 `release_guard.sh` 的覆盖范围、运行方式、默认端口、可覆盖环境变量，以及 `builds/web-release/` / `builds/web/` 的当前执行口径。
  - 扩展 `tests/smoke/release_guard.sh`，新增对 smoke README 与 `docs/deployment/nginx-web-release.conf` 关键字段的存在性校验，防止发布脚本、托管模板、说明文档后续再出现静默漂移。
- 验证：
  - `./tests/smoke/release_guard.sh`
- 验证结果：脚本再次完整跑通，退出码 `0`；除原有导出 / 本地服务 / gzip 校验外，新增通过 smoke README 与 Nginx 模板关键口径检查。

### 17. 短局可玩性精修第四轮：军令目标 / 喘息导演 / 编组压迫
- 动作：继续只做玩法程序侧精修，不碰网页摇杆；这一轮重点是把 3 分钟短局拆成更有节奏的“换波喘息 → 接军令 → 吃奖励压回去”的循环。
- 涉及文件：
  - `game/scripts/main.gd`
  - `docs/worklog.md`
- 具体改动：
  - 新增“军令目标”系统：每波会给出不同小目标（稳住阵脚 / 清妖试锋 / 伏诛头目），HUD 会实时显示进度，达成后立即发放临时奖励。
  - 新增成长奖励组合：根据军令类型发放回命、急速、额外伤害、额外连发、额外穿透，让短局成长不只靠升级，也靠波内表现滚雪球。
  - 新增“喘息导演”逻辑：开波和玩家受伤后，会短暂下调刷新量并压低快怪 / 重装占比，减少连续贴脸硬滚死的不公平感。
  - 新增更明确的敌群编组：从第三波开始插入双侧包夹；第四波开始额外插入护送队，让中后期敌人不只是随机堆数，而是更像有意图的组合压迫。
  - 新增敌群构成约束：同屏快怪 / 重装过多时会自动下调对应权重，避免单一类型在短时间内过度堆叠。
  - 武器 HUD 现在会联动显示军令奖励状态（如急速），方便玩家读到当前爆发窗口。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 3`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 45`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 95`
- 验证结果：三次 headless 运行均退出码 `0`，覆盖了主场景加载、跨多个波次推进与军令/喘息逻辑在中时长运行下的稳定性。

### 18. Web / 触控输入兜底：修复摇杆失焦卡死，并补 headless 回归脚本
- 动作：专门处理网页 / 触控输入链路里最容易把试玩直接卡死的问题，补齐摇杆在失焦、暂停、结算、隐藏时的强制复位逻辑，并新增一份可 headless 跑的触控冒烟脚本。
- 涉及文件：
  - `game/scripts/touch_joystick.gd`
  - `game/tests/touch_joystick_smoke.gd`
  - `docs/worklog.md`
- 具体改动：
  - `TouchJoystick` 新增 `cancel_input()`，并在窗口失焦、应用失焦、节点隐藏、退出树时自动归零，避免 Web 端丢失手指抬起事件后角色持续自走。
  - 新增 `game/tests/touch_joystick_smoke.gd`，headless 下直接模拟触控按下，并验证“失焦归零 / 隐藏归零”两条关键回归场景。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --script res://tests/touch_joystick_smoke.gd`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 5`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --export-release Web /tmp/.../index.html`
- 验证结果：
  - 触控冒烟脚本输出 `touch_joystick_smoke: ok`，退出码 `0`
  - 主场景 headless 加载退出码 `0`
  - Web 导出成功，生成 `index.html / index.js / index.wasm / index.pck`，退出码 `0`

### UI/HUD 第三轮补充
- 2026-03-20：继续强化顶部横幅副标题、右上状态签、结果页按钮主次与 HUD 分隔条，验收目标是更像西游 Q 版戏台战报。

### 19. 发布交付同步补位：压缩部署包自动对齐验收基线
- 动作：承接 release doc / template guards 之后继续补交付线，重点处理 `builds/web-release/` 与 `builds/web/` 容易在多次导出后静默漂移的问题，把压缩部署包同步收进自动化链路。
- 涉及文件：
  - `tests/smoke/sync_compressed_build.sh`
  - `tests/smoke/release_guard.sh`
  - `tests/smoke/README.md`
  - `README.md`
  - `docs/status.md`
  - `docs/release-acceptance.md`
  - `docs/release-minimum-checklist.md`
  - `docs/deployment-plan.md`
  - `docs/worklog.md`
- 具体改动：
  - 新增 `tests/smoke/sync_compressed_build.sh`，把 `builds/web-release/` 的共享产物同步到 `builds/web/`，并用确定性 gzip 方式重建 `.gz` 资源，避免部署优化包继续落后于当前验收基线。
  - 扩展 `tests/smoke/release_guard.sh`，在完成 Web 验收版导出后自动调用同步脚本，再校验 `builds/web-release/` 与 `builds/web/` 共享文件无漂移、`.gz` 资源不是旧文件，然后才继续做本地 HTTP / gzip / MIME 检查。
  - 更新 smoke README、README、status、release-acceptance、release-minimum-checklist、deployment-plan，把“压缩交付目录要与当前验收基线自动对齐”写成当前发布口径，避免后续只更新 `builds/web-release/` 却忘了 `builds/web/`。
- 验证：
  - `chmod +x tests/smoke/sync_compressed_build.sh tests/smoke/release_guard.sh`
  - `./tests/smoke/release_guard.sh`
- 验证结果：脚本完整跑通，退出码 `0`；已串行通过主场景加载、Web 验收版重导出、`builds/web-release/` → `builds/web/` 同步、共享文件一致性校验、`.gz` 新鲜度校验，以及两套目录的本地 HTTP / gzip / MIME 复验。

### 20. 短局可玩性精修第五轮：军功成长 / 压力导演 / 编组意图增强
- 动作：继续承接上一轮军令/奖励/编组系统，只补玩法程序，不碰网页摇杆；这一轮重点是把“完成军令后的成长反馈”做成更明确的常驻收益，同时让导演在高压局面下主动收手，减少中后期不公平堆怪。
- 涉及文件：
  - `game/scripts/main.gd`
  - `docs/worklog.md`
- 具体改动：
  - 继续沿用现有“军功 / 压力导演 / 偏好编组”主干，在其上新增**军令导向刷怪**：`survive / kills / elite` 三类军令现在会直接改写快怪/重装权重，让“稳住阵脚”更偏保守、“清妖试锋”更偏侧翼清线、“伏诛头目”更偏前场护送压阵，目标和敌群构成终于开始对上口径。
  - 重写 `_queue_wave_spawn_patterns()`：原先通用的波次队列改成按军令类型分流，生存军令优先给单侧缓压与正面基础怪，清怪军令会刻意给双侧清线口，头目军令则更稳定地推送“前场领队 + 护送”组合，提升短局里的读题感和打法差异。
  - 新增**速决赏功**：记录每波起始时刻，若玩家在半波内完成军令，除了原有奖励外还会追加一笔修为与一段更长急速，并在 HUD/飘字里明确提示“速决赏”，把奖励节奏从“完成了”推进到“早点完成更赚”。
  - 顺手补齐攻速一致性：军功提供的常驻攻速收益现在会同时作用在升级回调和实时攻击计时器，不再出现 HUD 看起来变强了、但出手节奏没完全跟上的落差。
  - 连斩阶段额外补一层 reward pulse 反馈，让中期滚雪球时的成长反馈更明显，也更方便玩家读到自己是否正处在压回去的窗口。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 3`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 45`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 95`
- 验证结果：三次 headless 运行均退出码 `0`，覆盖了主场景加载、跨多个波次推进、军令导向刷怪、速决赏功与实时攻速结算在中长时段运行下的装配稳定性。

### 20. Presentation-pass 第五轮：RewardPulse 扇芒层 + 连斩整段脉冲补强
- 动作：继续沿 slash / burst 后的反馈线补演出，不碰 P0 摇杆；这次重点是让升级 / 击杀脉冲更像“戏台喝彩”，并把连斩节奏从单点弹字拉成更完整的一段反馈。
- 涉及文件：
  - `game/scripts/reward_pulse.gd`
  - `game/scripts/main.gd`
  - `builds/web-release/index.html`
  - `builds/web-release/index.pck`
  - `docs/worklog.md`
- 具体改动：
  - `RewardPulse` 新增扇形喝彩芒绘制，不再只有环形/射线，升级、击杀、受击、结算节点的脉冲更饱满。
  - 连斩达到 4 的倍数时，会额外在玩家身上补一次整段奖励脉冲，把“起势 → 起煞 → 压场”从局部命中扩到角色中心，更适合录屏和试玩直觉感受。
  - 在 `main.gd` 里顺手补了一处 `Dictionary` 显式类型声明，避免 headless 校验把 Variant 推断警告当错误卡住验证链路。
  - 重新导出 `builds/web-release/`，让当前网页验收包与本轮脉冲脚本一致。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --scene res://scenes/main.tscn --quit-after 3`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --scene res://scenes/main.tscn --quit-after 45`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --export-release Web /Users/mac/game-studio/projects/survivor-demo/builds/web-release/index.html`
- 验证结果：三项均退出码 `0`；说明本轮 RewardPulse / 连斩脉冲改动未引入场景加载或 Web 导出错误。

### 21. HUD / 结果页 / 移动端操作区第五轮收口
- 动作：继续按“西游记古风 Q 版”统一界面层，重点强化 HUD 信息层次、底部操作带、结果页按钮主次与移动端提示区，不优先处理 P0 摇杆。
- 涉及文件：
  - `game/scenes/main.tscn`
  - `game/scripts/main.gd`
  - `docs/ui-style-guide.md`
  - `docs/worklog.md`
- 具体改动：
  - 右上状态卡补成更完整的“状态签 + 正文”结构，`StatusBadge` 单独占一行，和正文信息拆层展示，读感更像戏台签条。
  - 底部新增“戏台操作”带状区，把 `暂停 / 继续试炼 / 再闯一局` 收进统一操作带；在结算和窄屏场景下显性显示，结果页主次关系更清楚。
  - 调整 `ContinueButton / RestartButton / PauseButton` 为同一底部布局，主 CTA `再闯一局` 固定位于右侧，更适合试玩截图、网页验收和移动端认知。
  - 移动端提示区新增金边标题签（`掌中戏台 · 身法提示 / 本劫军令 / 告急提醒 / 压阵提醒 / 暂歇战报`），正文只保留下一步行动建议，减少信息糊成一团。
  - 新增 `_refresh_hud_layout()`，在窗口尺寸变化时对左上主账本、右上状态卡和底部操作带做轻量重排，让窄屏 / 小窗下的信息层级更稳。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --scene res://scenes/main.tscn --quit-after 3`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --scene res://scenes/main.tscn --quit-after 20`
- 验证结果：两次 headless 运行均退出码 `0`，主场景可正常加载；新增 HUD 节点、窄屏布局逻辑与按钮重排未引入装配或语法错误。
- 补充：本轮顺手修掉了一处 `Dictionary` 推断为 `Variant` 的 headless 校验告警，避免后续自动化回归被脚本告警中断。

### 21. 短局可玩性精修第六轮：军令导向刷怪深化 / 速决赏功 / 攻速一致性
- 动作：承接上一轮的军功与压力导演主干，继续只补玩法程序；这一轮重点不是再堆新系统，而是把“当前军令是什么”真正翻译到敌群构成和奖励节奏里，让玩家更能读懂这波该怎么打。
- 涉及文件：
  - `game/scripts/main.gd`
  - `docs/worklog.md`
- 具体改动：
  - 给 `_get_enemy_spawn_weights()` 增加军令导向调权：生存军令会主动压低快怪 / 重装，清怪军令会更偏清线型组合，头目军令则更强调头阵与护送，让军令和妖潮构成开始形成因果关系。
  - 重写 `_queue_wave_spawn_patterns()` 的军令分流：不再只按波次统一排模板，而是按 `survive / kills / elite` 三类目标分别组织单侧缓压、双侧清线、前场护送与头阵组合，短局的敌群意图更清楚。
  - 新增“速决赏功”：记录每波开场时间，若在半波内完成军令，则追加小额修为与更长急速，并明确飘字提示“速决赏”，把奖励节奏做成“越早完成越赚”。
  - 补齐军功攻速一致性：实时攻击计时器现在也会吃到军功攻速收益，不再出现升级回调和实际出手频率不完全同步的手感偏差。
  - 连斩每逢 4 的倍数时，额外在角色中心补一层 reward pulse，强化中段滚雪球的成长反馈。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 3`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 45`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 95`
- 验证结果：三次 headless 运行均退出码 `0`，主场景能稳定跨越多个波次推进；说明本轮军令导向刷怪、速决赏功与攻速一致性补丁未引入装配或运行时错误。

### 22. PM 接管首轮：版本盘点 / 并行线分层 / 风险清单补齐
- 动作：按 `game-pm` 职责对当前项目做首轮生产 / 交付接管，重点盘点近几轮提交、当前并行线、任务完成度、交付口径和执行面风险，并补一份 PM 视角总表。
- 涉及文件：
  - `docs/pm-production-status.md`
  - `docs/status.md`
  - `docs/worklog.md`
- 具体改动：
  - 新增 `docs/pm-production-status.md`，把当前版本状态、近几轮提交解读、完成 / 半完成 / 未完成矩阵、关键风险、下一步并行线建议集中收口。
  - 在 `docs/status.md` 中补充 PM 视角：明确当前项目已具备可验收基线，但版本冻结 / 口径收口还没彻底完成，当前 P0 应先做版本收版而不是继续扩功能。
  - 明确指出当前最大风险不是玩法不够，而是“当前已验证状态”和 Git `HEAD` 仍可能不是同一个干净版本号；后续 QA / main / 交付取版时必须先处理这个问题。
- 验证：
  - `git status`
  - `git log --oneline -8`
  - `./tests/smoke/release_guard.sh`
- 验证结果：
  - 已确认当前分支为 `main`，并完成近几轮提交盘点；
  - `release_guard.sh` 再次跑通，退出码 `0`，说明当前工作区状态下导出 / 本地服务 / gzip 校验链路可用；
  - 同时确认工作区并非 clean tree，因此已在 PM 文档中把“版本口径未完全收死”列为当前首要风险。

### 23. UI/UX 收口第六轮：状态签分层 / 底部操作带 / 窄屏重排
- 动作：继续按 godot-ui-ux-designer 方向收 HUD、结果页和移动端操作区，不碰 P0 摇杆；这轮重点是让“该看哪里、该点哪里”更清楚。
- 涉及文件：
  - `game/scenes/main.tscn`
  - `game/scripts/main.gd`
  - `docs/ui-style-guide.md`
  - `docs/worklog.md`
- 具体改动：
  - 右上状态卡补 `StatusBadge`，把徽签与正文拆层，统一到“戏台签条 + 解释内容”的信息结构。
  - 底部新增 `ActionTray` 视觉带，把暂停 / 继续 / 再闯收进同一操作区，并在结算与窄屏下显性化，强化按钮主次与位置预期。
  - 移动端提示区新增标题签与描金分隔，让“身法提示 / 本劫军令 / 告急提醒 / 压阵提醒 / 暂歇战报”这些状态拥有统一入口。
  - 新增 `_refresh_hud_layout()`，在窗口尺寸变化时轻量调整左上主 HUD、右上状态卡与底部操作带，优先保住信息层次。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --scene res://scenes/main.tscn --quit-after 3`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path /Users/mac/game-studio/projects/survivor-demo/game --scene res://scenes/main.tscn --quit-after 20`
- 验证结果：两次 headless 运行均退出码 `0`，主场景可正常加载；新增 HUD 节点、按钮重排与窄屏布局逻辑未引入装配错误。

### 24. 首包优化 P0：排除开发期资源并收紧 Web 导出基线
- 动作：对当前 Web 首包做一轮 P0 审计与收口，只处理体积来源、无用开发内容排除和导出配置，不改玩法逻辑。
- 审计结论：
  - 当前 Web `index.wasm` 约 `35.94 MiB`，几乎全部来自 Godot Web 导出模板本体，这轮工程侧几乎没有安全可削空间。
  - 真正可控的是 `index.pck`；旧导出规则会把 `addons/godot_mcp/*`、`tests/*`、`.godot/*` 一并打进包里，其中包含开发调试桥、编辑器缓存、测试脚本与导出缓存场景，属于发布版不应进入首包的内容。
  - 通过 Godot 导出日志可直接看到旧包在保存 `res://addons/godot_mcp/*.gdc`、`res://tests/touch_joystick_smoke.gdc`、`res://.godot/exported/*` 等文件；这些就是本轮首包的主要可疑来源。
- 涉及文件：
  - `game/export_presets.cfg`
  - `builds/web-release/*`
  - `builds/web/*`
  - `docs/worklog.md`
- 具体改动：
  - 把 `Web` 导出 preset 的 `exclude_filter` 收紧为 `addons/godot_mcp/*,tests/*,.godot/*`，明确排除开发期 addon、测试脚本和编辑器缓存。
  - 把 preset 的默认 `export_path` 改为 `../builds/web-release/index.html`，让编辑器默认导出目标与当前“验收基线目录”一致，再由压缩同步脚本生成 `builds/web/`。
  - 重新导出 `builds/web-release/`，并同步刷新 `builds/web/` 压缩交付目录，避免收紧配置后两套目录口径再次漂移。
- 验证：
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --scene res://scenes/main.tscn --quit-after 5`
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --export-release Web /tmp/survivor-web-size-baseline/index.html`（旧规则基线）
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --export-release Web /tmp/survivor-web-size-optimized/index.html`（新规则对比）
  - `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path ./game --export-release Web ./builds/web-release/index.html`
  - `./tests/smoke/sync_compressed_build.sh`
- 验证结果：
  - 主场景 headless 运行退出码 `0`。
  - Web 导出成功，收紧前后 `index.wasm` 均为 `37,685,705 B`（`35.94 MiB`），确认 wasm 体积主要由引擎模板决定。
  - `index.pck` 从 `763,524 B`（`745.6 KiB`）降到 `349,740 B`（`341.5 KiB`），减少 `413,784 B`（约 `404.1 KiB`，`-54.2%`）。
  - `builds/web-release/` 与 `builds/web/` 已按新规则重建完成。
