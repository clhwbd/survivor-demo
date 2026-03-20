# survivor-demo AI 出图提示词包（HUD + 结算页 / 第一轮）

> 目标：为后续 AI 出图、半自动界面探索、资产拆件提供结构化提示词，不再停留在“给一句概念词试试看”。
>
> 风格主轴：**戏台战报风**；辅助语汇：**云纹卷轴风**。

---

## 0. 使用原则
- 先出 **结构明确的界面概念图**，再出局部组件图，不要一开始就散着试。
- 提示词按 5 层组织：
  1. **全局风格基底**
  2. **页面级 prompt**
  3. **组件级 prompt**
  4. **负面 prompt**
  5. **生产约束 / 导出说明**
- 同一轮产图里，尽量固定：
  - 主色系
  - 标题语气
  - 边框语言
  - 画幅比例
  - 输出目标（整页 / 组件）

---

## 1. 全局风格基底（Master Prompt）

## 1.1 中文版
**基础风格 prompt：**

```text
西游记古风Q版游戏UI，戏台战报风为主，云纹卷轴风为辅，深墨褐底板，描金木框，朱砂题签，暖金分隔线，轻量云纹装饰，可爱但不幼稚，信息层级清晰，适合动作生存类游戏HUD与结算页，移动端可读性强，界面干净，不堆满装饰，像妖怪戏台上的战报与军令牌
```

## 1.2 英文版
```text
cute Journey to the West inspired game UI, Chinese fantasy chibi style, opera stage battle report theme, secondary cloud-scroll motif, dark brown panel, gold trim, cinnabar title tags, warm gold separators, subtle cloud patterns, readable action roguelike survivor HUD and result screen, clean information hierarchy, mobile friendly, elegant but playful, screenshot-worthy
```

---

## 2. 风格锚点词

### 2.1 必带正向锚点
- `opera stage battle report`
- `command tag`
- `wood plaque`
- `cloud scroll`
- `gold trim`
- `cinnabar accent`
- `dark brown panel`
- `cute Chinese fantasy`
- `readable mobile HUD`
- `clean UI hierarchy`

### 2.2 语气补充词
- `playful but disciplined`
- `storybook energy with battle readability`
- `ornamental only on the edges`
- `light theatrical atmosphere`
- `screenshot-friendly result screen`

---

## 3. 页面级 Prompt 模板

## 3.1 HUD 整页概念图

### 中文模板
```text
生成一张动作生存类游戏HUD概念图，主题为西游记古风Q版，戏台战报风主导，云纹卷轴风点缀。画面包含：左上主账本面板（命火、修为、斩妖、第几劫、当前目标），顶部中央信息播报条（主标题+副签），右上状态签（短徽签+一句战况提示），底部操作带（暂停、当前法术、辅助操作说明）。要求信息层级非常清楚，适合手机竖屏和桌面横屏共用设计语言，装饰集中在角部和边缘，不遮挡文字，不出现复杂角色插画背景，像戏台上的战报和军令系统。
```

### 英文模板
```text
concept art for a survivor-like action game HUD, Journey to the West chibi Chinese fantasy style, main theme opera stage battle report, secondary cloud-scroll accents. Include a top-left main report panel with health, xp, kills, wave and current objective, a top-center broadcast banner with title and subtitle tag, a top-right status tag with a short badge and one-line tactical advice, and a bottom action tray for pause, current skill and control hints. Clear hierarchy, mobile readable, desktop adaptable, decorative only on corners and borders, no heavy character illustration, looks like a theatrical battle report interface.
```

### HUD 变化版控制词
- 强化戏台感：`theatrical plaque`, `stage curtain hint`, `report board`
- 强化卷轴感：`silk scroll edge`, `paper texture`, `gold line dividers`
- 更偏产品 UI：`minimal clean layout`, `high usability`, `less ornament`

---

## 3.2 结算页整页概念图

### 中文模板
```text
生成一张动作生存类游戏结算页概念图，西游记古风Q版，戏台战报风。页面结构包含：顶部题头牌匾（今日凯旋 / 此劫未竟 / 暂歇戏台），中部大面积战报卷轴（时长、斩妖、最长连斩、第几劫、命火结余、战绩评语），印章位，以及底部CTA按钮区（继续试炼、再闯一局、返回主菜单）。要求像一张戏台战报，可截图传播，主次按钮清楚，金色和朱砂强调关键信息，整体干净，不像复杂MMO界面，不要现代科幻元素。
```

### 英文模板
```text
concept art for a result screen of a survivor action game, cute Journey to the West Chinese fantasy style, theatrical battle report theme. Include a top title plaque for victory, defeat or pause state, a large central report scroll with duration, kills, max combo, wave reached, remaining health and a short performance comment, a seal stamp area, and a bottom CTA section with continue, retry and back to menu. It should feel like a screenshot-worthy stage report, with clear call-to-action hierarchy, warm gold and cinnabar highlights, clean composition, no sci-fi, no MMORPG clutter.
```

### 结算页变化版控制词
- 胜利态：`celebratory but elegant`, `victory seal`, `warm heroic tone`
- 失败态：`restrained defeat`, `encouraging retry tone`, `darker cinnabar`
- 暂停态：`neutral pause report`, `calm theatrical intermission`

---

## 4. 组件级 Prompt 模板

## 4.1 左上主账本面板
```text
Chinese fantasy game HUD subcomponent, top-left battle report panel, dark brown base, gold trim, small cinnabar labels, compact readable data layout for health, xp, kills, wave and objective, opera stage report style, subtle cloud corner details, clean typography area, mobile friendly
```

## 4.2 顶部播报条
```text
Chinese opera themed game UI broadcast banner, centered top notification bar, title plus small category tag, cinnabar and gold accents, theatrical but readable, slim horizontal layout, for wave alert, level up or battle status
```

## 4.3 右上状态签
```text
game HUD status tag in cute Chinese fantasy style, small badge plus one-line urgent message, command slip design, gold frame, dark ink base, cinnabar badge, concise and tactical, suitable for top-right corner
```

## 4.4 底部操作带
```text
bottom action tray for a mobile-friendly action game UI, Chinese fantasy theatrical style, low visual weight, pause hint, current skill label and control support, dark brown strip with warm gold separators, simple and clear
```

## 4.5 结算页题头牌匾
```text
victory defeat pause title plaque for a Chinese fantasy game result screen, theatrical wooden plaque with gold trim and cinnabar callout, cute Journey to the West flavor, readable central title area, elegant and bold
```

## 4.6 战报卷轴主体
```text
report scroll panel for a game result screen, Chinese fantasy cute style, opera battle report motif with cloud-scroll influence, central stat sheet layout, gold line separators, warm paper texture, space for duration, kills, combo, wave and comment, clean and organized
```

## 4.7 印章 / 徽签资产
```text
seal stamp and tactical badge assets for a Journey to the West inspired game UI, cinnabar seal, gold edge, theatrical report system, compact decorative asset sheet, clean background, multiple variations
```

---

## 5. 负面 Prompt（建议固定带）

## 5.1 通用负面词
```text
photorealistic, realistic wood carving, overly detailed background, messy layout, tiny unreadable text, MMORPG UI clutter, sci-fi HUD, cyberpunk, western medieval, modern military, too many icons, heavy illustration behind text, dark unreadable contrast, generic mobile casino style, childish kindergarten style
```

## 5.2 HUD 专用负面词
```text
full screen decoration, obstructed gameplay area, giant portrait character art, floating random ornaments, too many numbers, overlapping panels, unreadable battle area
```

## 5.3 结算页专用负面词
```text
shop interface, loot box screen, inventory grid, rank leaderboard clutter, dense reward icons, overblown particle effects, modern glossy buttons
```

---

## 6. 出图组织方式（推荐流程）

## 6.1 第 1 轮：整页方向确认
- 每页先出 3 张：
  - A1：戏台战报更重
  - A2：戏台与卷轴平衡
  - B1：卷轴更轻一点
- 共 6 张即可，不要一口气 20 张。
- 对比维度：
  - 信息层级
  - 装饰密度
  - 截图感
  - 手机可读性

## 6.2 第 2 轮：组件拆件
- 从选中的 HUD / 结算页版本里拆 5 类组件：
  1. 主账本
  2. 播报条
  3. 状态签
  4. 题头牌匾
  5. 战报卷轴 / 印章
- 输出目标：适合后续做 9-slice / SVG 参考。

## 6.3 第 3 轮：变体补齐
- 只补必要状态：
  - HUD：常态 / 告急 / 升级播报 / 终局压阵
  - 结算页：胜 / 败 / 暂停
- 保持同一构图，不要每种状态都重画一套完全不同的 UI。

---

## 7. 资产分组建议

### 7.1 按页面分组
- `hud/fullpage/`
- `settlement/fullpage/`

### 7.2 按组件分组
- `components/main-panel/`
- `components/broadcast-banner/`
- `components/status-tag/`
- `components/title-plaque/`
- `components/report-scroll/`
- `components/seals-badges/`

### 7.3 按状态分组
- `normal`
- `urgent`
- `upgrade`
- `victory`
- `defeat`
- `pause`

---

## 8. 给程序 / UI 落地的使用说明
- 整页图只用于定风格和层级，不直接生硬切整张图。
- 组件图优先服务：
  - 边框样式
  - 签条样式
  - 印章样式
  - 角花与装饰头
- 程序化优先项：
  - 底色
  - 分隔线
  - 纯色按钮底
  - 文本与数值结构
- AI / 美术优先项：
  - 戏台牌匾头尾
  - 卷轴边头
  - 云纹角花
  - 印章 / 徽签贴片

---

## 9. 推荐首批实测 Prompt 套餐

## 套餐 A：HUD 主探索
- Master Prompt
- HUD 页面模板
- 组件强调：`main report panel`, `broadcast banner`, `status tag`
- Negative Prompt 通用 + HUD 专用
- 目标：先看信息层级是否站得住

## 套餐 B：结算页主探索
- Master Prompt
- 结算页页面模板
- 组件强调：`title plaque`, `report scroll`, `seal stamp`
- Negative Prompt 通用 + 结算页专用
- 目标：先看“戏台战报感”和 CTA 主次是否成立

## 套餐 C：组件补图
- 固定 Master Prompt
- 单独调用组件 prompt
- 背景要求：`plain light background`, `asset sheet presentation`
- 目标：给后续切图和可复用控件参考

---

## 10. 本文可直接衔接的下一步
- 进入 **HUD / 结算页首轮 AI 出图**
- 选 1 套主方向图后，进一步整理成 **Godot 组件落地清单**
- 再下一步才是把可程序化区域和必须出图区域彻底拆开
