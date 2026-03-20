# Smoke Tests

当前 `tests/smoke/` 目录不再只做早期玩法级冒烟，而是优先承接**发布 / 交付口径的最小自动化复验**。

## 当前脚本

### `release_guard.sh`
用途：把当前可试玩交付链路里最容易脱节的几件事串起来复验。

### `build_ui_font_subset.py`
用途：从 `SourceHanSansCN-Medium.ttf` 自动生成仅保留当前 UI 所需字形的 `survivor-ui-subset.ttf`，把中文显示保留下来，同时尽量压低 `builds/web-release/index.pck`。

### `patch_web_index.py`
用途：在 Godot 每次重导出后，给 `builds/web-release/index.html` 自动补上加载进度、慢加载提示、wasm/pck 阶段提示与完整版本托管指引，不再默认切轻量模式。

### `web_payload_matrix.py`
用途：导出 baseline / feature tag / 模板切换 / dynamic linking / 极简空项目对照矩阵，把“wasm 为什么大、哪些能拆、哪些不能拆”做成可复跑报告。

### `godot_web_safe_trim_matrix.sh`
用途：为 Godot Web 自编译模板准备保守裁剪实验矩阵；先检查 Python / SCons / Emscripten / Godot 源码目录是否齐全，再生成 `disable_3d / disable_physics_3d / disable_navigation_3d / disable_xr` + `lto` 的命令模板与计划报告。环境补齐后可直接带 `RUN_BUILD=1` 顺序执行 baseline / safe trim / full LTO 对照。

### `sync_compressed_build.sh`
用途：把 `builds/web-release/` 当前验收基线同步到 `builds/web/`，并重建压缩交付版所需的 `.gz` 资源，避免两套交付目录静默漂移。

### `sync_pages_build.sh`
用途：把 `builds/web/` 的 `.gz` 运行时资源同步成 `builds/pages-deploy/` 的正式文件名，并重写 `_headers`，供 Cloudflare Pages 直接发布。

### `pages_release_guard.sh`
用途：校验 `builds/pages-deploy/` 与当前压缩交付目录一致、目标文件确实为 gzip 内容、`_headers` 配置齐全，并做一轮本地静态服务可访问性检查。

覆盖范围：
- 导出前先运行 `build_ui_font_subset.py`，确保字体子集始终与当前 UI 文案同步
- Godot headless 加载 `game/scenes/main.tscn`
- Godot CLI 重导出 `builds/web-release/`
- 导出后运行 `patch_web_index.py`，确保完整版本加载提示与托管指引不会被 Godot 导出覆盖掉
- 用 `sync_compressed_build.sh` 把 `builds/web/` 与最新 `builds/web-release/` 对齐，并重建 `.gz` 资源
- 校验 `builds/web-release/` 与 `builds/web/` 的共享文件没有漂移
- `builds/web-release/` 四个核心文件 `index.html / index.js / index.wasm / index.pck` 的本地 `200` 校验
- `builds/web/` 的 gzip / `HEAD` / `Content-Type` 校验
- README / release 文档 / 最小清单 / Nginx 模板 / smoke README 的关键口径存在性检查

运行方式：
```bash
cd /Users/mac/game-studio/projects/survivor-demo
chmod +x tests/smoke/release_guard.sh
./tests/smoke/release_guard.sh
```

保守模板裁剪准备线：
```bash
cd /Users/mac/game-studio/projects/survivor-demo
chmod +x tests/smoke/godot_web_safe_trim_matrix.sh
./tests/smoke/godot_web_safe_trim_matrix.sh
# 环境补齐后再执行真正构建
RUN_BUILD=1 GODOT_SOURCE_DIR=/ABS/PATH/TO/godot-4.6.1-stable ./tests/smoke/godot_web_safe_trim_matrix.sh
```

默认端口：
- `builds/web-release/`：`18081`
- `builds/web/`：`18082`

可覆盖环境变量：
- `GODOT_BIN`
- `RELEASE_PORT`
- `COMPRESSED_PORT`

## 当前执行口径
- `builds/web-release/` = 当前统一验收 / 首发目录
- `builds/web/` = 压缩交付 / 部署优化目录
- `builds/pages-deploy/` = Cloudflare Pages 正式发布目录
- 正式托管前，默认至少跑一遍 `release_guard.sh`；若走 Pages，再补一遍 `pages_release_guard.sh`
