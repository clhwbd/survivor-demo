# Smoke Tests

当前 `tests/smoke/` 目录不再只做早期玩法级冒烟，而是优先承接**发布 / 交付口径的最小自动化复验**。

## 当前脚本

### `release_guard.sh`
用途：把当前可试玩交付链路里最容易脱节的几件事串起来复验。

### `sync_compressed_build.sh`
用途：把 `builds/web-release/` 当前验收基线同步到 `builds/web/`，并重建压缩交付版所需的 `.gz` 资源，避免两套交付目录静默漂移。

覆盖范围：
- Godot headless 加载 `game/scenes/main.tscn`
- Godot CLI 重导出 `builds/web-release/`
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
- 正式托管前，默认至少跑一遍 `release_guard.sh`
