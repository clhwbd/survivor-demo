# 可控 Web 发布链路（自管静态服务）

## 最终推荐路线
**自管 Nginx 静态站，直接托管 `builds/web/`，并把 header / gzip / MIME / 缓存策略写进仓库。**

这条链路不再依赖 GitHub Pages / Cloudflare Pages 这类平台特性，而是把关键行为收回到项目内：
- 构建基线：`builds/web-release/`
- 压缩交付目录：`builds/web/`
- 自管服务模板：`docs/deployment/nginx-web-controlled.conf`
- 本地等价预览：`scripts/serve_controlled_web.py`
- 冒烟验证：`tests/smoke/controlled_web_guard.sh`

## 为什么它比 Pages 更可控
1. **header 是你自己定的，不是平台帮你“猜”的**
   - `application/wasm`
   - `Content-Encoding: gzip`
   - `Cache-Control`
   - CORS / OPTIONS
   - `Vary: Accept-Encoding`

2. **本地验证和线上行为更接近**
   - 以前 `python3 -m http.server` 只能证明“文件 200 了”
   - 现在 `scripts/serve_controlled_web.py` 会按正式托管口径返回 gzip / wasm MIME / CORS / cache，能更早发现“200 但黑屏”的 header 问题

3. **不再依赖平台私有规则**
   - Pages 需要 `_headers`
   - GitHub Pages 基本不给你细抠 gzip / wasm 细节
   - Nginx 配置就在仓库里，换机器也能复现

4. **更适合排查黑屏问题**
   - Godot Web 黑屏常见根因不是“文件不存在”，而是 wasm MIME、gzip 头、缓存漂移、旧资源缓存、CORS 这类分发问题
   - 现在这些点都可直接 curl / 脚本化校验

## 当前已落地的关键点
### 1. wasm MIME
- Nginx 模板：`application/wasm`
- 本地受控服务：对 `.wasm` 强制返回 `Content-Type: application/wasm`

### 2. gzip 预压缩传输
- 继续复用 `builds/web/` 下现有 `.gz` 资源
- Nginx 模板使用 `gzip_static on;`
- 本地受控服务在 `Accept-Encoding: gzip` 时直接返回对应 `.gz`
- 同时补 `Vary: Accept-Encoding`

### 3. 缓存策略
- `index.html`：`no-cache, max-age=0, must-revalidate`
- `index.js / index.wasm / index.pck / audio worklet`：`public, max-age=600, must-revalidate`
- 这样做的原因：当前 Godot Web 文件名固定为 `index.*`，不适合再配 `immutable`，否则很容易在重新发布后命中旧缓存，出现“线上还是黑屏 / 还是旧版本”的假故障

### 4. CORS / 预检
- 返回：
  - `Access-Control-Allow-Origin: *`
  - `Access-Control-Allow-Methods: GET, HEAD, OPTIONS`
  - `Access-Control-Allow-Headers: Content-Type, Range`
- 受控服务与 Nginx 模板都支持 `OPTIONS`

### 5. 健康检查
- 新增 `/healthz`
- 可用于本机、反向代理或负载均衡健康探针

## 本地可执行链路
### 一键验证
```bash
cd /Users/mac/game-studio/projects/survivor-demo
chmod +x tests/smoke/controlled_web_guard.sh
./tests/smoke/controlled_web_guard.sh
```

它会：
1. 先跑 `tests/smoke/release_guard.sh`
2. 确认 `builds/web-release/` → `builds/web/` 已同步
3. 检查 Nginx 模板关键字段是否存在
4. 启动 `scripts/serve_controlled_web.py`
5. 校验 `index.html / index.js / index.wasm / index.pck` 的 header
6. 校验 `OPTIONS` 与 `/healthz`

### 本地手动预览
```bash
cd /Users/mac/game-studio/projects/survivor-demo
python3 scripts/serve_controlled_web.py --port 18084
```

打开：
```text
http://127.0.0.1:18084/index.html
```

## 最短上线步骤（无公网链接时）
如果当前机器还不能直接暴露公网，最短上线步骤就是这 5 步：

1. 在仓库机上准备最新产物
```bash
cd /Users/mac/game-studio/projects/survivor-demo
./tests/smoke/controlled_web_guard.sh
```

2. 把 `builds/web/` 上传到目标机器
```bash
rsync -av builds/web/ user@your-server:/srv/survivor-demo/builds/web/
```

3. 把 Nginx 模板上传到目标机器并按域名改 `server_name`
```bash
scp docs/deployment/nginx-web-controlled.conf user@your-server:/etc/nginx/conf.d/survivor-demo.conf
```

4. 在目标机器 reload Nginx
```bash
sudo nginx -t && sudo systemctl reload nginx
```

5. 上线后立刻复验
```bash
curl -I https://your-domain/index.html
curl -I -H 'Accept-Encoding: gzip' https://your-domain/index.wasm
curl -I -H 'Accept-Encoding: gzip' https://your-domain/index.js
curl -I -H 'Accept-Encoding: gzip' https://your-domain/index.pck
curl https://your-domain/healthz
```

## 这条链路怎么解释“为什么不再只是 200 但黑屏”
因为现在验收标准已经从“文件存在”升级成“运行时关键分发条件完整”：
- HTML 可访问
- JS 可访问
- WASM 可访问且 `Content-Type` 正确
- 预压缩资源返回 `Content-Encoding: gzip`
- `Vary: Accept-Encoding` 存在
- 缓存策略可控，不会因为固定文件名长期缓存旧版本
- CORS / OPTIONS 明确，不再靠平台默认行为

这就是“可控 Web”的意义：
**不只验证包存在，而是验证浏览器拿到的响应头是否真的符合 Godot Web 运行需要。**
