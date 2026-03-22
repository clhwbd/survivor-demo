# Version: 2026-03-22 Sprint Build

> 今日冲刺版本冻结文档
> 生成时间：2026-03-22 09:51 CST
> Git HEAD：ec8d53c（fix: improve mobile readability and floating touch joystick）

## 版本号

**Sprint Build 2026-03-22-a**

## 构建时间

2026-03-22 09:51 CST

## Git 基线

```
ec8d53c fix: improve mobile readability and floating touch joystick
```

## 包含的功能

### 核心玩法
- 生存计时 + 击杀统计 + 难度爬升
- 武器成长（经验球 + 等级提升）
- 三种敌人：基础敌 / 快敌 / 重装敌
- 波次系统（6 段波次，2026-03-21 03:09 强化）
- 军令目标系统（survive / kills / elite）
- 喘息导演 + 速决赏功
- 精英敌群编组（双侧包夹 / 护送队）
- 连斩系统 + 急速射击

### 操作与手感
- 全屏摇杆（支持非 UI 区域长按起杆，浮动到触点）
- 闪避（Space / Right Shift / 移动端按钮）+ 无敌帧
- 失焦自动归零（防止 Web 端卡死）

### UI / HUD
- 左上主账本（命火 / 军令 / 波次 / 斩妖 / 修为）
- 顶部横幅 + 副标题（戏台播报结构）
- 右上状态签（徽签 + 正文分层）
- 底部操作带（暂停 / 继续 / 再闯）
- 连斩字牌 / 低血压屏 / 结算印章
- 戏台战报风格结算页
- 中文字体：SourceHanSansCN-Medium + 运行时子集
- 竖屏适配（360x800 / 390x844 / 430x932）

### 演出特效
- 斩击特效（SlashFx）
- RewardPulse 环形脉冲 + 扇形喝彩芒
- 敌人飘带动效
- 镜头震动
- 经验磁吸增强

### 地图表现
- 程序化地表（底纹 / 路痕 / 区块语汇）
- 中景锚点（石碑 / 经幡 / 残柱 / 灯桩 / 小树）
- 区域化锚点分布
- 轻量装饰组合

### Web 发布
- Web 导出（Godot 4.6.1）
- 阶段式加载壳层（wasm / pck / 初始化三阶段）
- gzip 压缩资源
- 受控 Web 服务链路（Controlled Web）

## 构建产物

- 验收目录：`builds/web-today/`
- wasm：~35.94 MiB（Godot 引擎模板固定成本）
- pck：见实际导出结果

## 已知问题（未在本次交付中解决）

- UI/HUD 最终落版未完成（半完成状态）
- 视觉资产最小替换包未完成（仅方向板，无实际资产）
- Pages 黑屏问题（iPhone Safari，实测 controlled web 隧道可用）

## 今日交付目标

- ✅ 版本冻结（09:51 CST）
- ✅ 构建到 `builds/web-today/`（09:52 CST）
- ✅ 可访问链接（Cloudflare Pages: https://survivor-demo.pages.dev）
- ⏳ UI/HUD 最终落版（godot-ui-ux-designer 跟进）
- ⏳ 视觉资产最小替换（如时间允许）
