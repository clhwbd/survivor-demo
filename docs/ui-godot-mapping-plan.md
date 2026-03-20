# survivor-demo HUD / 结算页 Godot 节点映射与实装优先级建议

> 目标：把既有 `docs/ui-component-implementation-plan.md` 从“组件命名层”继续推进到**可直接对接当前 Godot 场景结构**的规划层。
>
> 范围：仅覆盖 **HUD（局内）** 与 **结算/暂停页**。
>
> 边界：
> - 本轮**不改运行逻辑**
> - 本轮**不要求改脚本行为**
> - 只做后续 UI 真正落地前的节点映射、承载边界与推荐顺序整理

---

## 1. 当前场景事实基线

当前主场景：`game/scenes/main.tscn`

当前 UI 不是空白场景，而是已经存在一套可运行的 HUD / 暂停 / 结算骨架，主要分布在两个层：

- `Main/HUD`（`CanvasLayer`）
  - 承担：局内 HUD、顶部播报、状态签、中部提示、暂停/结算覆盖层、底部操作带
- `Main/MobileControls`（`CanvasLayer`, `layer = 2`）
  - 承担：摇杆、闪避按钮、手机提示

这意味着后续 UI 实装**不该另起一套平行页面结构**，而应该优先沿着现有这两个层做：

1. **保留现有节点语义**
2. **把现有节点往容器化/组件化方向收口**
3. **在不破坏 `main.gd` 既有引用的前提下替换视觉承载方式**

---

## 2. 当前可直接承接的节点分区

## 2.1 HUD 主账本区（左上）

当前节点：

- `HUD/HudCardBg`
- `HUD/HudCardBorder`
- `HUD/MarginContainer`
- `HUD/MarginContainer/VBoxContainer`
  - `LevelLabel`
  - `HealthLabel`
  - `EnemyLabel`
  - `TimerLabel`
  - `KillLabel`
  - `MetaDivider`
  - `WaveLabel`
  - `WeaponLabel`
  - `ObjectiveDivider`
  - `ObjectiveLabel`
  - `TipLabel`
  - `XPLabel`
  - `XPBar`

### 结论
这块已经天然接近 `hud_main_panel`，只是目前仍偏“脚本直控 + Label 堆叠”的工程原型结构。

### 推荐映射
- `HudCardBg + HudCardBorder` → `ui_panel_base`
- `MarginContainer/VBoxContainer` → `hud_main_panel` 的内容容器
- `MetaDivider / ObjectiveDivider` → `ui_section_divider`
- 各类统计 Label → `ui_stat_row` 的第一轮文本承载

### 后续建议
如果要真正组件化，优先不是删掉这些节点，而是把这一区整理成：

- `HUD/HudMainPanel`（新容器壳）
  - `PanelBase`
  - `Content`
    - `HeaderRow`
    - `CoreStats`
    - `WaveBlock`
    - `ObjectiveBlock`
    - `XPBlock`

第一轮可接受的低风险做法是：
- **保留现有 Label 名称与脚本绑定**
- 只新增更稳定的父容器与装饰节点
- 等视觉骨架稳定后，再考虑把多个 Label 收进更细的可复用子场景

---

## 2.2 HUD 顶部播报条（顶部中央）

当前节点：

- `HUD/TopCenter`
  - `BannerBacking`
  - `BannerAccent`
  - `BannerLabel`
  - `BannerSubLabel`

### 结论
这块已经是 `hud_broadcast_banner` 的直接宿主，不需要推翻重做。

### 推荐映射
- `TopCenter` → `hud_broadcast_banner`
- `BannerBacking + BannerAccent` → `ui_title_plaque` 的中段底板 / 高亮条
- `BannerLabel` → 主标题
- `BannerSubLabel` → 副签 / 类别签

### 节点落地建议
后续如果要贴合“戏台战报风”，优先在 `TopCenter` 下补：

- `PlaqueHeadLeft`（可选 `TextureRect`）
- `PlaqueHeadRight`（可选 `TextureRect`）
- `BannerBacking` 改成更明确的中段可拉伸底板

也就是：

- 保留 `TopCenter` 为业务层锚点
- 在其内部补“牌匾头尾 + 中段底板 + 文本”结构
- 避免另起一个 `HUD/BroadcastBanner2` 之类的平行节点

---

## 2.3 HUD 状态签（右上）

当前节点：

- `HUD/StatusCardBg`
- `HUD/StatusCardAccent`
- `HUD/StatusBadge`
- `HUD/StatusLabel`

### 结论
这块就是 `hud_status_tag` 的当前实现位。

### 推荐映射
- `StatusCardBg` → 轻量 `ui_panel_base`
- `StatusCardAccent` → 状态高亮条 / 徽签顶边
- `StatusBadge` → `ui_badge_tag`
- `StatusLabel` → 状态正文

### 实装重点
这块后续不建议做复杂容器拆分，原因是：
- 信息量很少
- 状态变化频繁
- 当前 `main.gd` 已有大量直接引用

更合适的做法是：
- 保持节点数量轻
- 只增强“签头、底板、左右边距、文本层级”
- 让它稳定承担“此刻最重要的一句话”

换句话说，`hud_status_tag` 更像**强化现有节点**，不是大改结构。

---

## 2.4 HUD 底部操作带（Action Tray）

当前节点：

- `HUD/ActionTrayBg`
- `HUD/ActionTrayAccent`
- `HUD/ActionTrayLabel`
- `HUD/PauseButton`
- `HUD/ContinueButton`
- `HUD/RestartButton`

### 结论
当前这块已经同时承担了：
- 局内暂停入口
- 暂停/结算阶段 CTA
- 底部操作说明

它是 `hud_action_tray` 与 `settlement_cta_tray` 的**共用承载区**。

### 推荐映射
- `ActionTrayBg + ActionTrayAccent` → `ui_panel_base`
- `ActionTrayLabel` → `hud_action_tray` 的标题/说明行
- `PauseButton` → HUD 态按钮
- `ContinueButton + RestartButton` → 结算 / 暂停态 CTA

### 节点规划建议
后续真正收口时，建议明确分两层语义：

#### A. 常驻 HUD 操作层
- 以 `PauseButton` 为主
- 文案偏功能说明

#### B. Overlay CTA 层
- 以 `ContinueButton / RestartButton` 为主
- 文案偏结果页行为选择

但这两层**可以继续共用同一片底部容器区域**，不需要拆成两个完全独立页面。

---

## 2.5 暂停 / 结算覆盖层（中部）

当前节点：

- `HUD/FocusOverlay`
  - `Tint`
  - `PanelContainer`
    - `MarginContainer`
      - `VBoxContainer`
        - `BadgeLabel`
        - `TitleLabel`
        - `MedalLabel`
        - `DetailLabel`
        - `SettlementStamp`
        - `SummaryLabel`

### 结论
这里就是当前**暂停 / 失败 / 通关共骨架**的核心承载区，已经很接近 `settlement_report_panel`。

### 推荐映射
- `FocusOverlay/Tint` → 蒙层
- `PanelContainer` → `settlement_report_panel` 外层卷轴 / 战报面板
- `BadgeLabel` → 题头副签 / 类型签
- `TitleLabel` → `settlement_title_plaque` 主标题
- `MedalLabel` → 战绩评语 / 小结论行
- `DetailLabel` → 暂停态说明 / 引导说明
- `SettlementStamp` → `ui_stamp_badge`
- `SummaryLabel` → `settlement_report_panel` 的核心统计正文

### 节点落地建议
这块最值得作为后续 UI 实装的中心锚点，因为：
- 结构已经比较稳定
- 语义已经覆盖暂停 / 失败 / 通关三态
- 与 `main.gd` 的状态切换关系已存在

后续如果要继续贴合“戏台战报风”，建议优先把：

- `PanelContainer` 外观升级成卷轴/账页感
- `TitleLabel + BadgeLabel` 升成明确题头结构
- `SettlementStamp` 做成真正的印章视觉钉子
- `SummaryLabel` 做成更规整的统计版式

而不是先去新增一个完全独立的 `SettlementScene.tscn`。

---

## 2.6 中部瞬时提示（升级 / 阶段提示）

当前节点：

- `HUD/CenterNotice`
  - `Backing`
  - `Accent`
  - `Label`

### 结论
这块不属于本轮核心目标，但它和 HUD / 结算页共享同一套风格语言，应视为 `hud_broadcast_banner` 的次级组件。

### 推荐映射
- `CenterNotice` → `hud_broadcast_banner` 的短时中心版变体

### 对后续的意义
后续做 UI 真落地时，最好让它和顶部播报条共用：
- 相同的颜色 token
- 相同的牌匾中段底板语言
- 相同的文字层级规则

这样 HUD 看起来才像同一家族，不会一个像游戏内系统条、一个像临时 debug 提示。

---

## 2.7 手机提示与触控区

当前节点：

- `MobileControls/TouchJoystick`
- `MobileControls/DashButton`
- `MobileControls/MobileHintBg`
- `MobileControls/MobileHintAccent`
- `MobileControls/MobileHintTitle`
- `MobileControls/MobileHint`

### 结论
这块不属于结算页主体，但与 HUD 落地顺序强相关，因为移动端 UI 必须与触控区共存。

### 推荐映射
- `MobileHintBg + MobileHintAccent` → 轻量 `ui_panel_base`
- `MobileHintTitle` → `ui_badge_tag` / 小标题签
- `MobileHint` → 状态说明正文

### 关键边界
后续 HUD 实装必须默认遵守：
- `MobileControls` 是**更高层**（`layer = 2`）
- HUD 新增的装饰不应反压摇杆与闪避按钮
- 任何底部操作带改造，都要先看这层的安全区

也就是说，移动端约束是 HUD 真落地的前置条件之一，不是最后再补。

---

## 3. 推荐的组件 → 现有节点映射表

| 目标组件 | 当前 Godot 承载节点 | 建议做法 |
|---|---|---|
| `hud_main_panel` | `HUD/HudCardBg` + `HUD/MarginContainer` | 直接沿用现有主账本区做容器化升级 |
| `ui_panel_base` | `HudCardBg` / `StatusCardBg` / `ActionTrayBg` / `FocusOverlay/PanelContainer` | 同一视觉语言，多处复用 |
| `ui_section_divider` | `MetaDivider` / `ObjectiveDivider` | 保留节点语义，后续换表现即可 |
| `ui_stat_row` | 左上主账本内各 `Label` | 第一轮先不拆场景，先统一排版与字重 |
| `hud_broadcast_banner` | `HUD/TopCenter/*` | 直接在现节点内补牌匾头尾与底板 |
| `ui_title_plaque` | `TopCenter` / `FocusOverlay` 题头区 | HUD 与结算共用同家族牌匾语言 |
| `hud_status_tag` | `HUD/StatusCard*` | 轻量强化，不建议大拆 |
| `hud_action_tray` | `HUD/ActionTray*` + `PauseButton` | 保持底部功能区承载 |
| `settlement_report_panel` | `HUD/FocusOverlay/PanelContainer` | 作为后续结算页主面板核心锚点 |
| `ui_stamp_badge` | `SettlementStamp` | 后续最适合补资产识别度的点 |
| `settlement_cta_tray` | `ActionTray*` + `ContinueButton` + `RestartButton` | 与底部操作带共区复用 |

---

## 4. 节点映射重点：哪些地方最值得优先做

## 4.1 第一重点：`FocusOverlay` 不是临时提示层，而是未来结算页主骨架

这是本轮最关键的判断。

原因：
- 它已经承接了暂停 / 失败 / 通关三态
- 已有题头、正文、印章、总结四类信息槽位
- `main.gd` 已围绕它组织状态切换

所以后续如果做结算页，不应该重做新页面优先，而应该优先把：

- `FocusOverlay/PanelContainer`
- `BadgeLabel`
- `TitleLabel`
- `SettlementStamp`
- `SummaryLabel`

这五块打磨成真正的“戏台战报页”。

## 4.2 第二重点：左上主账本可以继续沿用，但要开始按“分区”思考

当前左上 HUD 信息已经足够多。

如果不先做分区，后续只会继续堆 Label，导致：
- 桌面端还勉强可读
- 手机端越来越难压缩
- 美术风格一上去就容易显得乱

推荐最先明确 4 个子分区：
- 角色/难度头部（`LevelLabel`）
- 核心资源区（`HealthLabel` / `XPLabel` / `XPBar`）
- 战况区（`EnemyLabel` / `TimerLabel` / `KillLabel` / `WaveLabel`）
- 目标区（`ObjectiveLabel` / `TipLabel`）

## 4.3 第三重点：底部操作带要明确“HUD 功能区”与“结算 CTA 区”的双身份

当前底部条已经在做两件事。

这不是问题，问题是后续实装时如果不先写清楚，会出现：
- 视觉上一套样式却承担不同权重
- 按钮主次混乱
- 手机端和 overlay 态互相抢位置

建议后续严格按状态切：
- 战斗态：以 `PauseButton` 为主
- 暂停/结算态：以 `ContinueButton` / `RestartButton` 为主
- `ActionTrayLabel` 只负责说明当前区块语义，不承载过多剧情文案

---

## 5. 推荐落地顺序（面向真正 UI 实装）

## P1：先把“最能接现有场景”的骨架做稳

### 1. `settlement_report_panel`
优先对象：`HUD/FocusOverlay/PanelContainer`

原因：
- 结构已存在
- 状态已接通
- 最容易在不碰运行逻辑的前提下显著提升完成感

### 2. `hud_main_panel`
优先对象：`HUD/HudCardBg` + `HUD/MarginContainer`

原因：
- 左上 HUD 是局内最长驻留区
- 与当前脚本绑定多，但视觉替换空间也最大

### 3. `hud_broadcast_banner`
优先对象：`HUD/TopCenter`

原因：
- 节点少、语义清晰
- 补牌匾感的性价比很高

### 4. `hud_status_tag`
优先对象：`HUD/StatusCard*`

原因：
- 小而关键
- 适合快速统一风格语言

### 5. `settlement_cta_tray`
优先对象：`HUD/ActionTray*` + `ContinueButton` + `RestartButton`

原因：
- 已有功能位
- 只需明确主次与排布，不需要改行为

---

## P2：在骨架稳住后补风格钉子

### 推荐补位
1. `SettlementStamp` 的印章资产
2. `TopCenter` 的牌匾头尾
3. 左上 HUD / 结算面板的角花与分段纹样
4. `StatusBadge` / `MobileHintTitle` 的签头造型

这批东西都适合：
- 小面积贴片
- 高识别度
- 不重压 Web 体量

---

## P3：最后再做更彻底的可复用场景化

等前两层稳定后，再考虑把以下部分独立成子场景：
- `hud_main_panel.tscn`
- `hud_broadcast_banner.tscn`
- `hud_status_tag.tscn`
- `settlement_report_panel.tscn`
- `settlement_cta_tray.tscn`

原因很简单：
- 当前 `main.gd` 对具体节点名依赖较重
- 过早场景化容易把工作从“规划落地”推成“重构脚本引用”
- 先做视觉承载和父容器整理，更稳

---

## 6. 给后续执行线的实装约束

## 6.1 不要先删旧节点再重搭

更稳的做法是：
- 先新增承载容器
- 把旧节点逐步收进去
- 确认 `main.gd` 引用不丢
- 最后再决定是否改名 / 抽子场景

## 6.2 先统一承载语言，再补细装饰

统一的优先级应该是：
1. 面板边界
2. 文本层级
3. 间距与分区
4. 状态色
5. 小装饰

不要反过来先加很多角花和印章，结果基础布局没稳。

## 6.3 所有 HUD 改造都要同时过移动端安全区视角

尤其要盯：
- `ActionTray`
- `MobileControls`
- `TopCenter`
- `StatusCard`

原因：当前场景已经存在针对竖屏和触控的布局逻辑，后续 UI 只要忽略这一层，就很容易再次出现：
- 播报条压状态签
- 操作带压摇杆
- 提示区压闪避按钮

---

## 7. 本轮结论

### 新判断 1
HUD 与结算页并不是“从零设计页面”，而是**围绕当前 `main.tscn` 已有 UI 骨架继续收口**。

### 新判断 2
后续最值得优先实装的不是整套新页面，而是：
- `FocusOverlay` 这套结算/暂停骨架
- 左上主账本
- 顶部播报条
- 右上状态签
- 底部操作带

### 新判断 3
如果目标是“后续真正落地 UI 时可以直接对接现有场景结构”，最佳路线不是大重构，而是：

1. **沿现有节点做组件语义映射**
2. **先稳容器与承载**
3. **再补小型高识别资产**
4. **最后才考虑抽成独立子场景**

这条路线最符合当前 survivor-demo 的状态：
- 不改运行逻辑
- 能直接接现有场景
- 后续 UI / Godot / 美术三条线都能拿这份文档继续干
