# survivor-demo 自定义 Godot Web 模板裁剪验证

> 目标：验证“自定义 Godot Web 导出模板 / 剔除无用引擎代码”这条线，是否**真能**让 survivor-demo 的 wasm 明显下降，而不是停留在 preset 层猜测。

## 结论先说

### 主判断
- **当前结论：C. 需要特定环境后再做。**
- 但这不是“没价值”。更准确地说：
  - **现成 export preset 层几乎不能继续明显缩 wasm。**
  - **如果要继续降 wasm，只能进入 Godot 模板源码构建层。**
  - **这条线理论上有中等收益空间，但当前机器缺关键构建环境，今晚无法把“自编译裁剪模板”完整跑完。**

### 面向主线的一句话
- **不要再把时间花在 preset 小开关上。**
- 如果后续愿意专门给半天到一天的构建窗口，补齐 Emscripten + SCons 环境后，值得做一轮**最小自编译模板实验**；预期收益大概率是 **数 MB 级**，但不是从 36 MB 直接砍到个位数 MB。

---

## 1. 为什么现成 export preset 层不能明显剔除 wasm 代码

这次不是凭经验说，而是直接对着 Godot 4.6.1 源码和本机模板看的。

### 1.1 本项目当前 preset 实际只是在“选模板”，不是在“裁引擎”
本仓库当前 Web preset：
- 文件：`game/export_presets.cfg`
- 当前关键项：
  - `custom_template/debug=""`
  - `custom_template/release=""`
  - `variant/extensions_support=false`
  - `html/...` 若干壳层选项
  - 没有任何模块裁剪项

源码证据（Godot 4.6.1 `platform/web/export/export_plugin.cpp`）：
- 导出选项里真正和模板有关的只有：
  - `custom_template/debug`
  - `custom_template/release`
  - `variant/extensions_support`
  - `variant/thread_support`
- 导出时逻辑是：
  - 如果没填 `custom_template/*`，就根据 `extensions_support` / `thread_support` 去找对应官方模板 zip
  - 然后直接把模板 zip 解出来导出

也就是说：
- **preset 负责“挑哪个 zip”**
- **不是按项目需求重新编译 wasm**
- 所以 `exclude_filter`、feature tag、删资源、换 HTML 壳层，都不会把引擎 wasm 本体切掉

### 1.2 `exclude_filter` 能裁的是 pck，不是 wasm
本项目已经实测过：
- `builds/web-release/index.wasm = 37,685,705 B`
- `builds/web-release/index.pck = 455,416 B`

之前的极简空项目对照已经证明：
- 空项目 `index.pck` 可降到 `1,548 B`
- 但 `index.wasm` 仍然是 `37,685,705 B`

所以 survivor-demo 现在的 36 MB 级 wasm，绝大部分是：
- 官方 Godot Web 模板
- 引擎运行时
- Emscripten / Web 运行支撑代码

不是项目资源。

---

## 2. 如果要剔除 wasm，Godot 模板层需要动什么

真正能影响 wasm 的，不在 export preset，而在 **Godot 源码构建参数**。

### 2.1 Godot 4.6.1 源码里明确存在的模板级裁剪项
源码证据：`SConstruct`

可直接影响模板内容/体积的开关包括：
- 通用裁剪：
  - `disable_3d=yes`
  - `disable_advanced_gui=yes`
  - `disable_physics_2d=yes`
  - `disable_physics_3d=yes`
  - `disable_navigation_2d=yes`
  - `disable_navigation_3d=yes`
  - `disable_xr=yes`
- 模块裁剪：
  - `module_<name>_enabled=yes/no`
- 构建画像：
  - `build_profile=<path>`
- 优化相关：
  - `production=yes`
  - `optimize=size`
  - `lto=thin|full`

源码证据：`platform/web/detect.py`

Web 平台还有这些构建级参数：
- `threads=yes/no`
- `dlink_enabled=yes/no`
- `javascript_eval=yes/no`
- `use_closure_compiler=yes/no`
- `wasm_simd=yes/no`
- `initial_memory=...`

### 2.2 对 survivor-demo 最值得试的裁剪方向
结合当前项目是 **2D + HUD + 中文字体 + 无 GDExtension**，最像样的裁剪组合是：

#### 第一层：低风险、基本该关
- `disable_3d=yes`
- `disable_physics_3d=yes`
- `disable_navigation_3d=yes`
- `disable_xr=yes`

这层最合理，因为当前项目不依赖 3D / XR。

#### 第二层：中风险、值得实验
- `module_text_server_adv_enabled=no`
- 尝试仅保留 fallback text server

原因：
- `modules/text_server_adv/SCsub` 明显会拉进 HarfBuzz / ICU / Graphite / ThorVG 等一大坨第三方代码
- 这是 Web 模板里一个很可疑的“固定大户”

但风险也清楚：
- 中文基础显示大概率还行
- 复杂文本排版、某些脚本 shaping、字体高级特性可能退化
- survivor-demo 当前只需要 HUD/按钮/数字/短句中文，**有机会能扛住**

#### 第三层：谨慎项
- `disable_advanced_gui=yes`：**不建议**，本项目大量依赖 Control / HUD
- `disable_physics_2d=yes`：**不建议**，当前战斗/碰撞是 2D 游戏核心
- `disable_navigation_2d=yes`：当前项目如果未用导航系统，可做实验，但优先级低于 3D/XR 裁剪
- `dlink_enabled=yes`：已证实不适合作为当前减包方案

---

## 3. 这次实际验证了哪些路径

## 3.1 路径 A：本机官方模板变体对照
本机 Godot 4.6.1 官方模板目录：
- `~/Library/Application Support/Godot/export_templates/4.6.1.stable/`

实际查到的模板：
- `web_release.zip`
- `web_nothreads_release.zip`
- `web_dlink_release.zip`
- `web_dlink_nothreads_release.zip`
- 以及对应 debug 版

本机直接解包观察到的关键大小：

| 模板 | godot.wasm | godot.js | 说明 |
| --- | ---: | ---: | --- |
| `web_nothreads_release.zip` | `37,685,705 B` | `315,759 B` | 当前 survivor-demo 基线实际就是这一路 |
| `web_release.zip` | `37,003,942 B` | `358,439 B` | 比 nothreads 小约 `681,763 B` |
| `web_dlink_nothreads_release.zip` | `1,509,558 B` | `5,552,570 B` | 主 wasm 很小，但还有 `41,113,842 B` 的 `godot.side.wasm` |
| `web_dlink_release.zip` | `1,605,674 B` | `5,724,461 B` | 同理，不是真正减总量 |

结论：
- **官方模板内部不同变体的差异，当前可见最大也就是 0.68 MB 级别的微调，远非“明显瘦身”。**
- `dlink` 不是这轮要的答案，只是把体积搬家。

## 3.2 路径 B：项目导出产物对照
实际查看本仓库：

| 产物 | 大小 |
| --- | ---: |
| `builds/web-release/index.wasm` | `37,685,705 B` |
| `builds/web-release/index.pck` | `455,416 B` |
| `builds/web/index.wasm.gz` | `9,377,158 B` |
| `builds/pages-deploy/index.wasm` | `9,377,158 B` |

说明：
- 当前分享链路已经主要靠 gzip/CDN 压下载体积
- 但原始 wasm 本体仍然是 36 MB 级，首开 CPU/解压/编译成本依旧重

## 3.3 路径 C：Godot 4.6.1 源码与构建参数核对
本次没有只看文档，而是直接拉取并核对了这些源码文件：
- `SConstruct`
- `platform/web/detect.py`
- `platform/web/export/export_plugin.cpp`
- `modules/text_server_adv/SCsub`
- `modules/text_server_fb/SCsub`
- `modules/freetype/SCsub`

得到的硬证据：
1. **preset 层只是在选模板 zip，不会按项目剔模块。**
2. **真正的裁剪开关在 SCons 构建层。**
3. **text_server_adv 确实会带进大量第三方文本排版代码，是后续最值得怀疑的“固定成本”之一。**
4. **Web 构建默认已经是 `optimize=size`，所以不是“官方模板忘了开 size 优化”。**

## 3.4 路径 D：本机自编译可行性核对
本机现状实查：
- Godot 编辑器：有，`/Applications/Godot.app/Contents/MacOS/Godot`
- 版本：`4.6.1.stable.official.14d19694e`

但自编译关键依赖缺失/不满足：
- `scons`：无
- `emcc`：无
- `em++`：无
- `pkg-config`：无
- `cmake`：无
- `ninja`：无
- `llvm-ar`：无
- `python3`：当前是 `3.7.3`，而 Godot `SConstruct` 要求 **Python >= 3.8**
- `clang`：有
- `node` / `npm`：有

所以当前机器今晚卡住的真实位置很明确：
- **不是项目不会导出**
- **不是不知该怎么裁**
- **而是缺 Web 模板源码构建工具链，尤其 Emscripten + SCons + 合格 Python**

---

## 4. 最小实验与体积变化

### 4.1 已完成的最小实验：官方模板变体替换
这是当前机器上已经跑到结论的最小模板实验。

#### 实验 1：`web_nothreads_release.zip`（当前基线）
- `index.wasm = 37,685,705 B`

#### 实验 2：强制切 `web_release.zip`
- `index.wasm = 37,003,942 B`
- 变化：`-681,763 B`（约 `-1.8%`）

#### 实验 3：切 `web_dlink_nothreads_release.zip`
- `index.wasm = 1,509,558 B`
- `index.side.wasm = 41,113,842 B`
- `index.js = 5,552,570 B`
- 结果：**总运行时更重，不适合当前目标**

### 4.2 还没能跑完的最小自编译实验
如果工具链齐全，最小实验应该是两组：

#### Baseline 自编译基线
```bash
scons platform=web target=template_release production=yes lto=thin
```

#### 裁剪版最小实验
```bash
scons \
  platform=web \
  target=template_release \
  production=yes \
  lto=thin \
  disable_3d=yes \
  disable_physics_3d=yes \
  disable_navigation_3d=yes \
  disable_xr=yes
```

如果第一轮能正常导出 survivor-demo，再做第二轮：
```bash
scons \
  platform=web \
  target=template_release \
  production=yes \
  lto=thin \
  disable_3d=yes \
  disable_physics_3d=yes \
  disable_navigation_3d=yes \
  disable_xr=yes \
  module_text_server_adv_enabled=no
```

然后把编出来的 zip 填到：
- `game/export_presets.cfg` 的 `custom_template/release`

再导出一次 survivor-demo，比较：
- `index.wasm`
- gzip 后 wasm
- 首开耗时
- 中文/HUD 是否损坏

---

## 5. 收益、风险、是否值得继续

## 5.1 收益判断
### 不值得继续的部分
- **preset 层继续抠开关：不值得。**
- 原因：已被源码和实测共同证伪，几乎不会再有明显 wasm 收益。

### 值得继续的部分
- **自编译模板裁剪：有条件时值得做一轮最小实验。**
- 原因：
  - 现在 36 MB wasm 里，大头就是官方模板固定成本
  - 既然固定成本来自模板，唯一还能继续动刀的地方也只能是模板
  - 3D / XR / 3D physics / 3D navigation 对 survivor-demo 明显不关键
  - 文本高级栈也存在进一步裁剪可能

## 5.2 风险判断
主要风险不是“编不过”，而是“编出来后项目功能退化”：
- 关错模块导致导出成功但运行时报缺类
- 文本栈裁过头导致中文/HUD 显示退化
- 过激裁剪造成后续功能扩展时又得回滚模板

所以建议策略是：
1. **先做低风险 3D/XR 裁剪版**
2. survivor-demo 导出 + 冒烟
3. 再做文本栈裁剪版
4. 逐轮记录体积变化与功能退化

## 5.3 最终判断
### 当前选择：C. 需要特定环境后再做
原因：
- 当前机器缺构建工具链，无法当晚完成自编译模板对照
- 但从源码结构看，这条线不是假命题，确实是 wasm 继续下降的唯一正路
- 只是**收益上限大概率是“数 MB 级到一成多”**，不是神话级砍半

---

## 6. 最短后续方案

### 6.1 环境准备
补齐这些后再开工：
- Python 3.8+
- SCons 4+
- Emscripten 4.0+
- `emcc` / `em++` / `emar` / `emranlib`
- 最好也补：`cmake`、`ninja`、`pkg-config`

### 6.2 半天内可完成的最小冲刺
1. 拉 Godot 4.6.1 源码
2. 先编一个“等价官方 baseline” release web template
3. 再编一个 `disable_3d + disable_physics_3d + disable_navigation_3d + disable_xr` 裁剪版
4. 用 `custom_template/release` 导出 survivor-demo
5. 记录 wasm 变化和是否破坏中文 / 竖屏 / HUD / 发布脚本

### 6.3 我对收益的保守预估
- **低风险裁剪版**：有机会拿到 **1~4 MB** 级下降
- **加上文本高级栈裁剪**：若 survivor-demo 可承受，可能进一步到 **数 MB 级**
- **但不太像能把 36 MB 直接打到 10 MB 以下**

---

## 7. 给主线的执行建议

### 现在就能定的
1. **把“preset 继续抠 wasm”这条线关掉。**
2. 继续把正式分享建立在 gzip/CDN 上，不要把精力浪费在 `exclude_filter` 幻觉上。
3. 真要继续降 wasm，只开一条新线：**自编译模板裁剪实验**。

### 什么时候值得开这条线
- 当用户明确把“网页首开速度/可用性”列为高优先级阻塞项时
- 或者 survivor-demo 要进入更正式的 H5 分发阶段时

### 我的建议口径
- **不是马上全面投入大规模改模板**
- **而是补齐环境后做 1 次最小裁剪 spike**
- 如果第一轮只能降几百 KB，就立即止损
- 如果第一轮能稳定降到数 MB，而且功能不坏，再继续深入

---

## 8. 本次结论摘要

- **现成 export preset 层为什么不能明显剔除 wasm 代码：**因为 Godot Web preset 本质只是在选模板 zip，不会按项目重编译引擎；`exclude_filter` 只能减 `pck`，减不了 wasm 主体。
- **如果要剔除，Godot 模板层需要动什么：**要进 Godot 4.6.1 源码构建，用 `SConstruct` 的 `disable_3d`、`disable_xr`、`module_<name>_enabled`、`build_profile`、`lto` 等开关重编译 web template。
- **实际验证了哪些路径：**
  - 本机官方 Web 模板变体（`web_release` / `web_nothreads_release` / `web_dlink_*`）
  - survivor-demo 当前导出产物大小
  - Godot 4.6.1 源码文件 `SConstruct` / `platform/web/detect.py` / `platform/web/export/export_plugin.cpp`
  - 文本相关模块 `text_server_adv` / `text_server_fb` / `freetype`
  - 本机自编译工具链可用性
- **若可行，最小实验与体积变化：**当前机器已完成的最小模板实验只有官方模板替换，其中 `web_release.zip` 相比 `web_nothreads_release.zip` 仅降 `681,763 B`；真正值得测的是自编译裁剪版，但当前缺工具链。
- **当前机器/时间窗口下的最短后续方案与风险/收益判断：**补齐 Python 3.8+、SCons、Emscripten 后，用低风险 3D/XR 裁剪版先做一次 spike；预期收益为数 MB 级，风险主要是中文/HUD/节点可用性退化，需要逐轮导出冒烟。
