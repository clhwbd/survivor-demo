# Web 验收版本说明

## 目标
把当前 demo 收口成一个可以稳定验收、稳定交接、稳定复现的 Web 版本，而不是只保留“某次偶然导出的网页包”。

## 当前版本分工

### 1. 验收基线版本
目录：`builds/web-release/`

用途：
- 作为当前版本的标准验收包
- 适合用任意静态服务器直接托管
- 适合 QA / 策划 / 负责人做基线验收

特点：
- 文件齐全，直接可被普通静态服务器提供
- 不依赖自定义压缩服务脚本
- 更适合当作“标准可复现产物”

### 2. 压缩交付版本
目录：`builds/web/`

用途：
- 作为后续部署优化的交付包
- 适合本地演示、内网演示、支持 gzip 的静态托管

特点：
- 保留未压缩文件，同时附带 `.gz` 资源
- 自带 `serve_compressed.py`
- 可验证 gzip 资源是否被正确返回

### 3. 自管正式发布版本（当前推荐）
目录：`builds/web/`

当前最短稳定交付方式：
- 先跑 `./tests/smoke/controlled_web_guard.sh`
- 再跑 `python3 scripts/package_controlled_web_release.py`
- 把生成的 tar.gz 直接交给目标机器部署
- 部署后用 `./tests/smoke/verify_controlled_web_remote.sh https://your-domain` 复验

用途：
- 作为当前最推荐的正式分享目录
- 适合自管 Nginx / 反向代理 / 对象存储前置网关这类可控静态服务

特点：
- 保留未压缩文件，同时附带 `.gz` 资源
- 可直接配合 `docs/deployment/nginx-web-controlled.conf` 使用
- 可用 `scripts/serve_controlled_web.py` 在本地按正式托管口径复验 gzip / wasm MIME / cache / CORS

### 4. Cloudflare Pages 发布版本（保留为旧备份链路）
目录：`builds/pages-deploy/`

用途：
- 作为旧平台备份链路
- 适合 Cloudflare Pages 这类支持 `_headers` 的静态托管

特点：
- `index.wasm / index.js / index.pck / audio worklet` 直接使用 gzip 后的字节内容
- 通过 `_headers` 显式声明 `Content-Encoding: gzip` 与 `application/wasm`
- 可继续作为 fallback，但不再是本轮推荐主线

## 已验证的导出命令
环境：
- Godot：`4.6.1.stable`
- 机器：本机 macOS

实际验证通过的命令：

```bash
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless \
  --path /Users/mac/game-studio/projects/survivor-demo/game \
  --export-release Web \
  /Users/mac/game-studio/projects/survivor-demo/builds/web-release/index.html
```

验证结果：
- 命令执行成功，退出码 `0`
- 重新生成了 `builds/web-release/` 下的 `index.html / index.js / index.wasm / index.pck` 等核心文件
- 导出过程可正常完成，不依赖 Godot 编辑器手点导出

## 2026-03-20 14:36 CST 复验结论
- 再次执行 Godot CLI 导出命令，退出码 `0`
- `builds/web-release/` 通过 `python3 -m http.server 18081` 复验，`index.html / index.js / index.wasm / index.pck` 全部返回 `200`
- `builds/web/` 通过 `python3 serve_compressed.py` 复验，使用 `GET` 与 `HEAD` 请求访问 `index.wasm` 时都可返回正确的 gzip / MIME 头
- 当前压缩版服务已可用于本地健康检查、自动化冒烟校验与浏览器实际加载
- 后续每次重导出 `builds/web-release/` 后，默认通过 `tests/smoke/sync_compressed_build.sh` 或 `tests/smoke/release_guard.sh` 自动把 `builds/web/` 对齐，避免两套交付目录内容漂移

## 2026-03-20 14:45 CST 一致性复核
- 发现 `game/scripts/main.gd` 新一轮 HUD / 战报收口改动一度存在语法错误，导致源码与 `builds/web-release/` 出现暂时脱节
- 已修正阻断导出的语法问题，并把主场景节点装配重新对齐到当前脚本版本
- 处理后主场景可再次通过 headless 加载，并重新导出 `builds/web-release/`，最新四个核心文件时间戳已刷新到 `2026-03-20 14:45:28 CST`
- 通过 `python3 -m http.server 18081` 复验时，`index.html / index.js / index.wasm / index.pck` 仍全部返回 `200`
- 补充注意：Python 简易静态服务对 `index.wasm` 返回的是 `application/octet-stream`，可用于本地快速验收，但正式托管时仍应显式配置为 `application/wasm`
- 真正上线托管前，先过 `docs/release-minimum-checklist.md`

## 本地访问验证

### A. 验收基线版本验证
启动方式：

```bash
cd /Users/mac/game-studio/projects/survivor-demo/builds/web-release
python3 -m http.server 18081
```

已验证：
- `http://127.0.0.1:18081/index.html` 返回 `200`
- `index.js` 返回 `200`
- `index.wasm` 返回 `200`
- `index.pck` 返回 `200`

说明：
- 这说明验收版所需核心文件齐全
- 普通静态服务器即可托管当前验收基线

### B. 压缩交付版本验证
启动方式：

```bash
cd /Users/mac/game-studio/projects/survivor-demo/builds/web
python3 serve_compressed.py
```

已验证：
- 请求 `index.wasm` 时，返回 `Content-Encoding: gzip`
- 返回头中包含 `Vary: Accept-Encoding`
- `Content-Type` 被正确设置为 `application/wasm`

说明：
- 当前压缩版具备“预压缩资源可被正确提供”的基本条件
- 后续若上正式静态托管，只需确保平台支持 gzip 静态资源或边缘压缩策略即可

## 2026-03-20 17:19 CST Pages 发布目录复验
- 已执行 `tests/smoke/sync_pages_build.sh`，把 `builds/web/` 当前 `.gz` 运行时资源同步为 `builds/pages-deploy/` 的正式文件名
- 复验后 `builds/pages-deploy/index.wasm` 为 `9,377,158 B`，`index.pck` 为 `99,653 B`，比原始 `builds/web-release/` 产物显著更小
- `tests/smoke/pages_release_guard.sh` 已在本机通过：确认 Pages 目录文件存在、gzip 内容与 `builds/web/*.gz` 一致、`_headers` 包含 `Content-Encoding: gzip` / `application/wasm` / 缓存策略
- 本机尝试 `wrangler pages dev` 时，Wrangler 能解析 `_headers`，但 Cloudflare `workerd` 因 macOS `12.6.0` 低于最低要求 `13.5+` 无法完整启动；因此当前机器上可完成“目录正确性验证”，但不能完成真正的 Pages 本地运行时预览

## 2026-03-20 22:20 CST 完整版本托管纠偏结论
- 用户已明确要求：**不要轻量版，只保留完整版本。**
- 因此本轮网页验收目标重新收敛为：**基于当前完整 build 寻找更适合中国大陆访问的托管路径**，而不是对手机默认切轻量模式。
- 根因仍然成立：当前“长时间打不开”的核心问题主要是 **GitHub Pages 路线无法给当前 Godot Web 运行时提供压缩交付**；用户实际会先吃到约 `35.94 MiB` 的原始 `index.wasm`。
- 当前完整版本导出后关键文件尺寸：
  - `builds/web-release/index.wasm`：`37,685,705 B`（约 `35.94 MiB`）
  - `builds/web/index.wasm.gz` / `builds/pages-deploy/index.wasm`：`9,377,158 B`
  - `builds/web-release/index.pck`：`455,416 B`
  - `builds/web/index.pck.gz` / `builds/pages-deploy/index.pck`：`185,634 B`
- 当前构建守卫口径已改为：
  - `tests/smoke/build_ui_font_subset.py` 继续负责字体子集构建
  - `tests/smoke/patch_web_index.py` 仅补完整版本的加载进度 / 慢加载提示 / 托管指引，不再默认切轻量模式
- 当前结论：**更适合大陆访问的完整版本正式分享路径已经切到 Cloudflare Pages + `builds/pages-deploy/`。**

## 2026-03-20 22:18 CST Cloudflare Pages 实际发布复验
- 已使用当前机器现成的 Cloudflare 登录态直接执行：
  - `./tests/smoke/sync_pages_build.sh`
  - `./tests/smoke/pages_release_guard.sh`
  - `npx wrangler pages deploy builds/pages-deploy --project-name survivor-demo --commit-dirty=true`
- Wrangler 返回的本次部署地址：`https://d33168fa.survivor-demo.pages.dev`
- 项目稳定域名：`https://survivor-demo.pages.dev`
- 线上复验结果：
  - 首页返回 `HTTP 200`
  - `index.wasm` 返回 `HTTP 200`
  - `GET /index.wasm` 已确认带 `Content-Type: application/wasm` 与 `Content-Encoding: gzip`
- 结论：当前版本已经不只是“具备 Pages 发布目录”，而是**已经实际在线发布可验收**

## 2026-03-20 23:58 CST 可控 Web 主线复验
- 用户已明确要求切换到 **A：可控 Web**，因此本轮把推荐正式发布链路从 Pages 改为 **自管 Nginx + `builds/web/`**。
- 已新增：
  - `docs/deployment/nginx-web-controlled.conf`
  - `scripts/serve_controlled_web.py`
  - `tests/smoke/controlled_web_guard.sh`
- `tests/smoke/verify_controlled_web_remote.sh https://your-domain`
- `python3 scripts/package_controlled_web_release.py`
- 旧备份链路若必须继续用 Pages，也要确认 `tests/smoke/sync_pages_build.sh` 生成的 `_headers` 已把 runtime 资源缓存改成 `public, max-age=600, must-revalidate`，避免固定文件名 + immutable 导致旧缓存假黑屏
  - `docs/deployment-controlled-web.md`
- 本轮本地复验命令：
  - `./tests/smoke/controlled_web_guard.sh`
  - `python3 scripts/serve_controlled_web.py --port 18084`
- 本地复验结果：
  - `index.html` 返回 `Cache-Control: no-cache, max-age=0, must-revalidate`
  - `index.wasm` 返回 `Content-Type: application/wasm`、`Content-Encoding: gzip`、`Vary: Accept-Encoding`
  - `index.js / index.pck` 返回 gzip 与受控缓存头
  - `OPTIONS /index.wasm` 返回 `204`
  - `/healthz` 返回 `ok`
- 结论：当前仓库已经具备一条**不依赖 Pages 平台 header 规则**的完整可控 Web 发布链路；若当前机器没有公网入口，只差把 `builds/web/` + Nginx 模板搬到目标服务器即可上线。

## 产物说明

### `builds/web-release/`
建议视为：
- 当前版本验收包
- 回归测试基线
- 对外分享前的最终检查包

### `builds/web/`
建议视为：
- 部署优化包
- 内网 / 本地演示包
- 未来接入静态托管/CDN 的候选目录

## 已知注意事项
1. 当前 Godot 导出预设里只有一个 `Web` 预设
   - `builds/web-release/` 是通过 CLI 输出路径覆盖导出的
   - 这没有问题，但需要在 README / 文档中明确写死命令，避免后续误导出到别的目录

2. 自定义压缩服务脚本当前已同时支持 `GET` / `HEAD`
   - 可直接用于浏览器加载验证
   - 也可用于健康检查或自动化冒烟探测
   - 压缩版验收时建议同时保留 `GET` 和 `HEAD` 两种校验：`GET` 看真实返回，`HEAD` 看响应头是否正确

3. 临时隧道不适合继续作为正式验收链路
   - 它适合临时演示
   - 不适合当成团队稳定验收地址

## 验收建议清单
每次准备交付时，至少确认以下事项：
- [ ] `builds/web-release/` 能被普通静态服务器打开
- [ ] 首页可正常进入游戏
- [ ] 键盘移动 / 闪避正常
- [ ] 触控摇杆 / 闪避按钮在移动端浏览器可操作
- [ ] `03:00` Demo Clear 流程正常
- [ ] `R` / 按钮重开正常
- [ ] 浏览器重新聚焦提示仍可正常工作
- [ ] 波次、击杀、经验、升级 HUD 正常刷新

## 结论
当前项目已经具备一个**可复现导出、可本地验收、可继续托管规划**的 Web 交付基线。后续工作重点应切到 UI/HUD 收口与美术方向落地，而不是继续把玩法复杂度往前推。
