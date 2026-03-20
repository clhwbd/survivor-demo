# survivor-demo 保守模板开关 Playbook

> 目标：给后续 Godot Web 自编译模板准备一条**低风险裁剪方案**。这条线只处理保守开关，不碰激进文本栈替换，不改当前发布链，不影响现有中文字体、竖屏适配和正式交付脚本。

## 一句话判断

这批开关值得先试，因为它们都在**项目明确未使用**的能力上：3D、3D 物理、3D 导航、XR。对一个当前以 2D Web 试玩为主的项目来说，这是最接近“白捡”的模板瘦身入口。

---

## 1. 为什么它们值得先试

1. **和项目画像高度一致**
   - survivor-demo 当前是 2D 生存类 Web demo。
   - 主链依赖是 2D 场景、HUD、中文字体、竖屏布局、触控输入。
   - 3D / XR 不在当前玩法、UI、发布目标里。

2. **风险边界清楚**
   - 关闭的是 3D/XR 相关子系统，不会像 `module_text_server_adv_enabled=no` 那样直接触碰中文显示能力。
   - 即便实验失败，回退也只是切回官方模板，不需要改动项目逻辑。

3. **适合作为模板裁剪的第一刀**
   - 如果连这批保守开关都没有明显收益，就没必要急着去碰更激进的模块裁剪。
   - 反过来，如果它们能稳定拿到收益，后续才值得继续评估 `lto` 甚至 `build_profile`。

4. **不阻断主线发布**
   - 这条线是并行验证线。
   - 当前 `builds/web-release/`、`builds/web/`、`builds/pages-deploy/` 不需要改。

---

## 2. 本轮只做哪些开关

### 首批保守开关

1. `disable_3d=yes`
2. `disable_physics_3d=yes`
3. `disable_navigation_3d=yes`
4. `disable_xr=yes`

### 低风险构建优化（第二步再加）

5. `lto=thin`
6. `lto=full`（只做对照，不默认首发）

### 本轮明确不做

- `module_text_server_adv_enabled=no`
- 文本栈替换 / fallback-only 文本方案
- 激进模块删除
- 关闭 2D 物理 / 2D 导航 / advanced GUI
- 改中文字体、竖屏适配、发布链脚本

---

## 3. 每个开关的风险与预期收益

| 开关 | 为什么先试 | 风险 | 预期收益 | 结论 |
| --- | --- | --- | --- | --- |
| `disable_3d=yes` | 整个项目当前没有 3D 运行主链 | 低；未来若引入 3D 需换模板 | 这批里最大头之一 | **首批必试** |
| `disable_physics_3d=yes` | 当前没有 3D 碰撞/刚体 | 低；只影响 3D 物理功能 | 小到中等 | **首批必试** |
| `disable_navigation_3d=yes` | 当前没有 3D 导航网格或寻路 | 低；只影响 3D 导航能力 | 小幅叠加 | **首批必试** |
| `disable_xr=yes` | Web 验收链路完全不依赖 XR | 低；只影响 XR / WebXR | 小幅叠加 | **首批必试** |
| `lto=thin` | 链接期继续瘦身，风险较低 | 低；主要是构建更慢 | 数百 KB 到 1 MB+ 的机会 | **safe trim 稳定后追加** |
| `lto=full` | 比 thin 更激进一点，但仍属构建优化 | 中低；构建时间更长，可能有链接/兼容波动 | 额外再挤一点 | **对照项，不默认首发** |
| `build_profile=<path>` | 理论可继续剔模块 | 本轮不算保守；需要模块审计和更高回归成本 | 潜在收益不明 | **先评估，不进首批** |

### 对 `build_profile` 的判断

`build_profile` 不是不能做，而是**不适合放进“保守首批动作”**。

原因：
- 它通常要先梳理 Godot 模块依赖和项目节点使用面。
- 一旦 profile 过头，风险就从“关 3D 子系统”变成“误删某条运行链”。
- 所以本轮先把它定性为**后续候选**，不是现在就动手的第一梯队。

---

## 4. 推荐执行顺序

### Phase A：拿到自编译基线
先编一个基线模板，目的不是减包，而是确认：
- 构建工具链没问题
- 当前机器能出 Godot Web 自编译模板
- 后面 safe trim 有可靠对照组

命令模板：

```bash
scons platform=web target=template_release production=yes lto=thin
```

### Phase B：跑保守裁剪版
在基线上只加 4 个保守开关：

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

### Phase C：仅做一个 LTO 对照
如果 Phase B 跑通，再单独试一版：

```bash
scons \
  platform=web \
  target=template_release \
  production=yes \
  lto=full \
  disable_3d=yes \
  disable_physics_3d=yes \
  disable_navigation_3d=yes \
  disable_xr=yes
```

---

## 5. 当前机器状态与阻塞点

本机当前已确认的阻塞：

- `python3` = `3.7.3`
- Godot Web 自编译要求 Python >= 3.8
- 缺：`scons`
- 缺：`emcc`
- 缺：`em++`
- 缺：`emar`
- 缺：`emranlib`
- 也未确认有可用的 Godot 4.6.1 源码目录

所以当前机器**不能直接进入自编译**，但已经可以把后续执行所需的：
- 命令模板
- 依赖清单
- 先后顺序
- 验收方式
- 回退方式

全部落成仓库内工程产物。

---

## 6. 已落地的可执行工程产物

### 脚本
- `tests/smoke/godot_web_safe_trim_matrix.sh`

用途：
- 检查当前机器是否满足 Godot Web 自编译模板要求
- 输出保守开关的构建矩阵
- 在环境齐全时，按顺序执行 baseline / safe trim / safe trim + full LTO
- 生成报告：
  - `reports/web_template_safe_trim_plan.md`
  - `reports/web_template_safe_trim_plan.json`

### 当前建议先跑

```bash
cd /Users/mac/game-studio/projects/survivor-demo
chmod +x tests/smoke/godot_web_safe_trim_matrix.sh
./tests/smoke/godot_web_safe_trim_matrix.sh
```

如果环境后来补齐，再跑：

```bash
RUN_BUILD=1 \
GODOT_SOURCE_DIR=/ABS/PATH/TO/godot-4.6.1-stable \
./tests/smoke/godot_web_safe_trim_matrix.sh
```

---

## 7. 最短可执行后续步骤

如果主线要继续推进，这就是最短路径：

1. **补 Python 3.8+**
   - 先让 `python3 --version` 达标。

2. **补 SCons 4+**
   - 没它就没法走 Godot 模板构建。

3. **补 Emscripten 工具链**
   - 至少确保：`emcc`、`em++`、`emar`、`emranlib` 可用。

4. **准备 Godot 4.6.1 stable 源码**
   - 并设置：
     ```bash
     export GODOT_SOURCE_DIR=/ABS/PATH/TO/godot-4.6.1-stable
     ```

5. **先生成计划，不直接编译**
   - 跑：
     ```bash
     ./tests/smoke/godot_web_safe_trim_matrix.sh
     ```

6. **再执行构建矩阵**
   - 跑：
     ```bash
     RUN_BUILD=1 GODOT_SOURCE_DIR=... ./tests/smoke/godot_web_safe_trim_matrix.sh
     ```

7. **只在临时导出目录验证模板，不动主发布链**
   - 把自编译 zip 临时指给 `custom_template/release`
   - 导出到单独目录，比如：
     ```bash
     /Applications/Godot.app/Contents/MacOS/Godot \
       --headless \
       --path ./game \
       --export-release Web \
       ./builds/web-safe-trim-check/index.html
     ```

8. **做最小验收**
   - 必验：
     - `index.wasm` 是否变小
     - 页面能否进入主场景
     - 中文字体显示是否正常
     - 竖屏 HUD / 触控摇杆 / 暂停结算是否正常

---

## 8. 验收标准

这轮只要满足下面 4 条，就算“保守模板裁剪值得继续”：

1. 自编译 baseline 能稳定产出模板 zip
2. safe trim 版能正常导出 survivor-demo Web
3. 中文 / HUD / 竖屏 / 输入链路不坏
4. wasm 有实打实下降（哪怕先只是 1~4 MB 级）

如果第 4 条没有成立，就应该及时止损，不继续往更激进方向挖。

---

## 9. 回退方式

- 实验失败时，只需要：
  1. 取消 `custom_template/release`
  2. 切回官方模板
  3. 重导出当前正式交付包

因为本轮不改主项目逻辑、不改字体、不改竖屏、不改现有发布脚本，所以回退成本非常低。

---

## 10. 最终建议

### 本轮最值得先试的就是：

- `disable_3d=yes`
- `disable_physics_3d=yes`
- `disable_navigation_3d=yes`
- `disable_xr=yes`
- 以及其后的 `lto=thin`

### 暂时不要先碰的：

- `module_text_server_adv_enabled=no`
- 文本栈替换
- 激进模块剔除
- `build_profile` 实操落地

一句话：

> 先把 3D/XR 这批“白给的未用子系统”砍掉做一轮 spike；如果这都没有像样收益，就别急着碰更激进的模板手术。 
