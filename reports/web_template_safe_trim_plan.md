# survivor-demo 保守 Web 模板裁剪计划

- 生成时间：
  - 2026-03-21 00:20:11 CST
- 脚本：
  - tests/smoke/godot_web_safe_trim_matrix.sh
- 当前项目运行时基线：
  - builds/web-release/index.wasm = 37685705 B
  - builds/web-release/index.pck = 455416 B

## 当前机器环境判断

- Python3：3.13.3（>= 3.8 要求：yes）
- scons：/Users/mac/.local/bin/scons
- emcc：/Users/mac/game-studio/deps/emsdk/upstream/emscripten/emcc
- em++：/Users/mac/game-studio/deps/emsdk/upstream/emscripten/em++
- emar：/Users/mac/game-studio/deps/emsdk/upstream/emscripten/emar
- emranlib：/Users/mac/game-studio/deps/emsdk/upstream/emscripten/emranlib
- cmake：missing
- ninja：missing
- pkg-config：/usr/local/bin/pkg-config
- GODOT_SOURCE_DIR：/Users/mac/game-studio/deps/godot-4.6.1-stable
- 是否可直接进入自编译：**yes**

## 为什么这批保守开关值得先试

1. survivor-demo 当前是 2D Web 项目，3D / XR / 3D physics / 3D navigation 明显不在运行主链上。
2. 这些开关位于 Godot 模板构建层，属于“砍未使用子系统”的低风险裁剪，不会像文本栈替换那样直接碰中文显示。
3. 这批开关对项目代码、字体、竖屏适配和现有发布脚本都是旁路实验，不需要改当前主发布链。
4. 如果这一层收益都不明显，就能尽早止损，不必继续碰更激进的模块裁剪。

## 开关风险 / 预期收益矩阵

| 开关 | 为什么先试 | 风险 | 预期收益 |
| --- | --- | --- | --- |
| disable_3d=yes | 直接剔除整条 3D 子系统，最符合 2D 项目画像 | 低；若项目未来引入 3D 节点需换回模板 | 本轮最主要减包来源之一 |
| disable_physics_3d=yes | survivor-demo 不走 3D 物理 | 低；仅影响 3D 物理能力 | 小到中等，配合 disable_3d 叠加 |
| disable_navigation_3d=yes | 当前没有 3D 导航链路 | 低；仅影响 3D 导航能力 | 小幅叠加收益 |
| disable_xr=yes | Web 验收链路完全不依赖 XR | 低；仅影响 XR / WebXR | 小幅叠加收益 |
| lto=thin | 低风险链接优化，官方常规可接受 | 低；主要是编译更慢 | 数百 KB 到 1 MB+ 的可能性 |
| lto=full | 仅在 safe trim 稳定后追加验证 | 中低；编译时间更长，可能引入链接/兼容波动，需要单独复验。 | 比 thin 再多挤一点体积 |
| build_profile=<path> | 理论可继续裁模块 | 当前先不默认启用；需要先做模块白名单审计，否则已超出“保守”范围 | 潜在收益不明，本轮不作为首批执行项 |

## 本轮建议执行顺序

1. 先编 baseline：确认本机自编译产物能正常出包。
2. 再编 safe trim：只加 disable_3d / disable_physics_3d / disable_navigation_3d / disable_xr。
3. safe trim 跑通且导出可用后，再单独试 lto=full。
4. build_profile 暂不进入首批动作；只有在 safe trim 收益明显、且主线愿意再投入一轮模块审计时再开。

## 可直接执行的命令模板

### baseline-template

- 开关：（无，基线）
- 风险：基线，仅用于验证自编译环境与官方模板等价输出。
- 预期收益：不追求减包，目标是拿到可对比的自编译基线。
- 命令：
  mkdir -p /Users/mac/game-studio/projects/survivor-demo/builds/template-safe-trim/baseline-template && cd ${GODOT_SOURCE_DIR:-/ABS/PATH/TO/godot-4.6.1-stable} && scons platform=web target=template_release production=yes lto=thin && python3 misc/scripts_app/make_zip.py platform=web target=template_release archive=/Users/mac/game-studio/projects/survivor-demo/builds/template-safe-trim/baseline-template/web_baseline-template.zip
- 当前脚本捕获到的产物：
  - wasm：not built
  - js：not built
  - zip：not built

### safe-trim

- 开关：disable_3d=yes disable_physics_3d=yes disable_navigation_3d=yes disable_xr=yes
- 风险：低风险；仅关闭 survivor-demo 明确未使用的 3D / XR 相关子系统。
- 预期收益：优先争取 1~4 MB 级 wasm 下降，且不碰 2D/GUI/文本主链。
- 命令：
  mkdir -p /Users/mac/game-studio/projects/survivor-demo/builds/template-safe-trim/safe-trim && cd ${GODOT_SOURCE_DIR:-/ABS/PATH/TO/godot-4.6.1-stable} && scons platform=web target=template_release production=yes lto=thin disable_3d=yes disable_physics_3d=yes disable_navigation_3d=yes disable_xr=yes && python3 misc/scripts_app/make_zip.py platform=web target=template_release archive=/Users/mac/game-studio/projects/survivor-demo/builds/template-safe-trim/safe-trim/web_safe-trim.zip
- 当前脚本捕获到的产物：
  - wasm：not built
  - js：not built
  - zip：not built

### safe-trim-full-lto

- 开关：disable_3d=yes disable_physics_3d=yes disable_navigation_3d=yes disable_xr=yes
- 风险：中低风险；在 safe trim 基础上把 LTO 从 thin 提到 full，构建时间更长，可能带来浏览器兼容/链接波动，需要单独复验。
- 预期收益：在 safe trim 基础上继续争取数百 KB 到 1 MB+ 的附加下降，代价是构建时间和不确定性上升。
- 命令：
  mkdir -p /Users/mac/game-studio/projects/survivor-demo/builds/template-safe-trim/safe-trim-full-lto && cd ${GODOT_SOURCE_DIR:-/ABS/PATH/TO/godot-4.6.1-stable} && scons platform=web target=template_release production=yes lto=full disable_3d=yes disable_physics_3d=yes disable_navigation_3d=yes disable_xr=yes && python3 misc/scripts_app/make_zip.py platform=web target=template_release archive=/Users/mac/game-studio/projects/survivor-demo/builds/template-safe-trim/safe-trim-full-lto/web_safe-trim-full-lto.zip
- 当前脚本捕获到的产物：
  - wasm：not built
  - js：not built
  - zip：not built

## 导出 / 验收步骤（不改当前发布链）

1. 保持现有 builds/web-release/、builds/web/、builds/pages-deploy/ 链路不动。
2. 先把自编译模板 zip 放到单独目录，例如：builds/template-safe-trim/safe-trim/web_safe-trim.zip。
3. 手动在 game/export_presets.cfg 的 custom_template/release 临时指向该 zip，或在一份临时副本里验证；不要直接覆盖主线发布脚本。
4. 用 Godot CLI 单独导出到临时目录，比如：
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path ./game --export-release Web ./builds/web-safe-trim-check/index.html
5. 对比以下指标：
   - index.wasm 原始大小
   - gzip 后 wasm 大小
   - 首开是否仍可进主场景
   - 中文 HUD / 竖屏布局 / 触控摇杆 / 暂停结算是否正常
6. 验收通过后，再决定是否把 custom template 接入主线发布流程。

## 回退方式

- 任何一步只要发现导出失败、浏览器报错、中文/HUD 异常：
  1. 清空 custom_template/release
  2. 回到官方模板重新导出
  3. 保留实验产物与对比数据，不覆盖当前正式交付目录
- 因为本轮不改 gameplay / 字体 / 竖屏脚本，回退成本接近零。

## 当前机器不能直接编译时，最短可执行后续步骤

1. 安装 Python 3.8+，并让 python3 --version 达标。
2. 安装 SCons 4+。
3. 安装并激活 Emscripten（至少提供 emcc/em++/emar/emranlib）。
4. 准备 Godot 4.6.1 stable 源码目录，并设置：
   export GODOT_SOURCE_DIR=/ABS/PATH/TO/godot-4.6.1-stable
5. 先跑：
   RUN_BUILD=0 ./tests/smoke/godot_web_safe_trim_matrix.sh
   确认计划与命令正确。
6. 再跑：
   RUN_BUILD=1 GODOT_SOURCE_DIR=... ./tests/smoke/godot_web_safe_trim_matrix.sh
7. 最后用临时 custom_template/release 导出 survivor-demo，按上面的验收清单比对。

## 结论口径

- 这轮最值得先试的是：disable_3d=yes、disable_physics_3d=yes、disable_navigation_3d=yes、disable_xr=yes，再配合 lto=thin。
- lto=full 可以作为 safe trim 稳定后的追加对照；build_profile 先只评估、不纳入首批执行。
- 当前机器因 Python / SCons / Emscripten / Godot 源码目录未就绪，暂不具备直接自编译条件，但主线接手所需命令、顺序、验收口径和回退方式已整理齐全。
