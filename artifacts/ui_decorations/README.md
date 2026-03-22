# 戏台战报风 · 视觉资产包说明

> 风格主轴：戏台战报风（方向板文档：`docs/ui-direction-board-xiyou-q.md`）
> 辅助语汇：云纹卷轴风
> 本包目标：最小可见资产包，让关键界面（HUD、结算页）有东西可看

---

## 目录结构

```
artifacts/ui_decorations/
├── stamp_victory.tscn     # 胜利印章（朱砂红 + 暖金）
├── stamp_defeat.tscn       # 败阵印章（深墨褐）
├── stamp_pause.tscn        # 暂歇印章（暖金）
├── badge_tag.tscn          # 状态签标签（5种类型）
├── panel_corner_lu.tscn    # 面板左上角花（云纹 + 铜钉）
├── plaque_head.tscn        # 牌匾头装饰（戏台匾额感）
├── enemy_icon_basic.tscn   # 敌人小图标占位符
├── button_style.tscn       # 统一按钮样式（主/次/辅三种权重）
├── preview_reference.tscn  # 预览参考总览
└── design_tokens.md        # 本文件：设计 token 与使用指南
```

---

## 设计 Token

### 颜色 Token

| Token | 值 | 用途 |
|-------|-----|------|
| `cinnabar` | `#CC293E` (0.80, 0.16, 0.12) | 胜利/告急强调 |
| `gold_warm` | `#F0D180` (0.94, 0.82, 0.55) | 边框/装饰/次要强调 |
| `ink_brown` | `#1F1410` (0.12, 0.08, 0.06) | 面板底色/主背景 |
| `ink_brown_soft` | `#2E1E18` (0.18, 0.12, 0.10) | 弱化面板底 |
| `shadow_earth` | `#1C1108` (0.11, 0.07, 0.05) | 阴影 |
| `earth_red` | `#C6553B` (0.776, 0.333, 0.231) | 基础敌人色 |
| `moss_green` | `#598C4D` (0.35, 0.55, 0.30) | 快敌人色 |
| `purple_brown` | `#664799` (0.40, 0.28, 0.60) | 重装敌人色 |

### 字号 Token

| Token | 基准值 | 用途 |
|-------|-------|------|
| `fs_xs` | 11px | 印章副标题/注释 |
| `fs_sm` | 13px | 次要按钮文字 |
| `fs_md` | 14px | 主按钮/签条文字 |
| `fs_lg` | 18px | 印章主标题 |
| `fs_xl` | 22px | HUD 数值 |
| `fs_2xl` | 28px | HUD 等级/标题 |

### 间距 Token

| Token | 用途 |
|-------|------|
| `gap_xs = 4px` | 紧密元素间 |
| `gap_sm = 8px` | 同组元素 |
| `gap_md = 16px` | 面板内边距 |
| `gap_lg = 24px` | 组件间距 |
| `gap_xl = 40px` | 大区块间距 |

---

## 组件使用指南

### 1. 印章（结算页）

实例化对应场景，设置 `stamp_title` 和 `stamp_sub`：

```gdscript
var stamp = preload("res://artifacts/ui_decorations/stamp_victory.tscn").instantiate()
stamp.stamp_title = "凯旋"
stamp.stamp_sub = "大圣护场"
add_child(stamp)
```

### 2. 状态签（HUD）

```gdscript
var badge = preload("res://artifacts/ui_decorations/badge_tag.tscn").instantiate()
badge.tag_type = "urgent"  # military | urgent | upgrade | praise | neutral
badge.tag_text = "告急"
add_child(badge)
```

### 3. 按钮（统一样式）

```gdscript
var btn = preload("res://artifacts/ui_decorations/button_style.tscn").instantiate()
btn.button_label = "再闯一局"
btn.button_weight = "primary"  # primary | secondary | ghost
btn.pressed.connect(_on_restart_pressed)
add_child(btn)
```

### 4. 敌人图标

```gdscript
var icon = preload("res://artifacts/ui_decorations/enemy_icon_basic.tscn").instantiate()
icon.enemy_type = "basic"  # basic | runner | tank
add_child(icon)
```

### 5. 面板角花

```gdscript
var corner = preload("res://artifacts/ui_decorations/panel_corner_lu.tscn").instantiate()
# 放置在面板左上角，position = panel.position
add_child(corner)
```

### 6. 牌匾头

```gdscript
var head = preload("res://artifacts/ui_decorations/plaque_head.tscn").instantiate()
# 放在标题文字左侧
add_child(head)
```

---

## 状态变体速查

### badge_tag 状态

| tag_type | 背景色 | 用途 |
|----------|--------|------|
| `military` | 暖金 | 军令签 |
| `urgent` | 朱砂红 | 告急签 |
| `upgrade` | 暖金半透明 | 修为/升级 |
| `praise` | 亮金 | 喝彩签 |
| `neutral` | 墨褐 | 战报/中性 |

### button_style 状态

| button_weight | 视觉 | 用途 |
|----------------|------|------|
| `primary` | 朱砂底 + 暖金边框 + 金纹 | 主 CTA |
| `secondary` | 墨褐底 + 暖金边框 | 次 CTA |
| `ghost` | 半透明墨褐 + 弱边框 | 辅 CTA |

---

## 接入建议

1. **先程序化**：所有装饰都基于 Polygon2D 程序绘制，无需外部图片资源
2. **接入点**：在 `main.tscn` 的 `HUD` CanvasLayer 下实例化，或在 `settlement_comment_stamp_row` 替换现有占位
3. **替换顺序**：
   - ① 结算页印章（`SettlementStamp` Label → stamp scene）
   - ② HUD 状态签（`StatusBadge` → badge_tag scene）
   - ③ 面板角花（装饰性，优先级最低）
4. **颜色统一**：现有 `main.gd` / `main.tscn` 中硬编码的颜色值，建议迁移到本 token 表

---

## 后续扩展方向

- 牌匾尾装饰（`plaque_tail.tscn`）
- 结算页战报卷轴头尾（卷轴风格）
- 敌人详细图标（大尺寸版）
- 主菜单背景氛围层 SVG 稿
- 升级弹窗 3 选 1 卡片样式
