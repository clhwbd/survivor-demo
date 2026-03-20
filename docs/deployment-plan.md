# 发布 / 托管方案建议

## 结论先行
当前最需要解决的问题不是“能不能跑起来”，而是**把分享链路从平台型静态托管切到真正可控的自管静态服务**。

当前推荐把发布链路分成三层：

1. **验收层**：`builds/web-release/`
   - 给项目负责人、策划、QA 验收
   - 任何静态服务器都能直接打开

2. **交付层 / 自管正式目录**：`builds/web/`
   - 包含 `.gz` 预压缩资源
   - 直接作为 Nginx 自管正式站点目录

3. **备份平台层**：`builds/pages-deploy/`
   - 仅保留为旧平台备份链路
   - 不再作为本轮推荐主线

---

## 2026-03-20 可控 Web 主线结论

### 可行候选对比（按当前“可控度”排序）
1. **自管 Nginx 静态站 + `builds/web/`（当前推荐主线）**
   - 优势：header、gzip、MIME、缓存、CORS、健康检查都能写进仓库并本地等价复验
   - 已落地：`docs/deployment/nginx-web-controlled.conf`、`scripts/serve_controlled_web.py`、`tests/smoke/controlled_web_guard.sh`
   - 风险：这台机器当前没有现成公网 Nginx / 域名 / HTTPS，因此本轮只能把方案、脚本和本地验证链路补齐，不能直接给新的公网正式链接

2. **Cloudflare Pages + `builds/pages-deploy/`（保留为旧备份链路）**
   - 优势：当前机器已实发成功，稳定地址仍可访问
   - 问题：本轮任务已经明确不再把 Pages 作为推荐主线，因为 `_headers`、缓存和静态分发细节仍受平台规则约束

3. **GitHub Pages / jsDelivr（放弃）**
   - 问题：要么无法稳定给 gzip 版 wasm/pck 做正确返回，要么核心资源请求直接失败，不再适合作为完整版本主链路

### 当前最终推荐理由
- **控制面回仓库**：Nginx 模板、受控本地服务、冒烟校验都在项目内，不再靠平台“帮忙处理”。
- **能提前发现黑屏根因**：本地现在不只是看 `200`，而是验证 `application/wasm`、`Content-Encoding: gzip`、`Vary: Accept-Encoding`、缓存策略、CORS / OPTIONS。
- **更适合当前 Godot 固定文件名产物**：新的自管模板把 `index.html` 设为 `no-cache`，把 `js/wasm/pck` 设为 `max-age=600, must-revalidate`，避免旧版本长缓存导致的假黑屏。

### 当前可执行链路（已打通）
1. `./tests/smoke/release_guard.sh`
2. `./tests/smoke/controlled_web_guard.sh`
3. 本地预览：`python3 scripts/serve_controlled_web.py --port 18084`
4. 目标服务器套用：`docs/deployment/nginx-web-controlled.conf`
5. 把 `builds/web/` 上传到 `/srv/survivor-demo/builds/web/` 后 reload Nginx

### 本轮验证结果
- `controlled_web_guard.sh` 已本地通过：
  - `index.html` 返回 `Cache-Control: no-cache, max-age=0, must-revalidate`
  - `index.wasm` 返回 `Content-Type: application/wasm`、`Content-Encoding: gzip`、`Vary: Accept-Encoding`
  - `index.js / index.pck` 返回 gzip 与受控缓存头
  - `OPTIONS` 返回 `204`
  - `/healthz` 返回 `ok`
- 这说明当前仓库已经具备“自管正式站点”的最小可执行链路，只差目标公网机器 / 域名接手上线

---

## 为什么不建议继续依赖临时隧道
临时隧道的典型问题：
- 地址易变化
- 稳定性受第三方中转状态影响
- 峰值时延和加载失败率不可控
- 不利于 QA 做固定回归地址
- 出问题时很难区分：是游戏包有问题，还是隧道链路有问题

对于 Web Game Demo，这种链路会把“资源加载问题”和“网络分发问题”混在一起，验收体验很差。

---

## 推荐方案分级

## 方案 A：本机 / 局域网验收（最低成本）
适用场景：
- 同办公室 / 同内网演示
- 本地快速给人试玩
- 不需要公网长期地址

做法：
- 验收时直接使用 `builds/web-release/` + `python3 -m http.server`
- 若要测试压缩资源，则用 `builds/web/serve_compressed.py`

优点：
- 0 成本
- 最少变量
- 适合当前阶段持续验收

缺点：
- 不适合跨地域分享
- 没有稳定公网地址

---

## 方案 B：Cloudflare Pages（当前最推荐）
适用场景：
- 需要一个成本低、能直接公开分享的正式试玩地址
- 托管平台对原始 wasm 大小有限制，但接受压缩后文件体积
- 希望少配服务器，直接走静态站

推荐目录：
- 直接发布 `builds/pages-deploy/`
- 其中 `index.wasm / index.js / index.pck / audio worklet` 都已经替换成 gzip 后字节，并通过 `_headers` 指定 `Content-Encoding: gzip`
- 当前 Web 壳已收回完整版本口径：保留完整 build，仅在加载页中提示“优先切换更合适托管”，不再默认对手机 / 窄屏切轻量模式

本机已验证：
- `tests/smoke/sync_pages_build.sh` 可从当前 `builds/web/` 自动生成最新 `builds/pages-deploy/`
- `tests/smoke/pages_release_guard.sh` 已验证文件存在、gzip 内容一致、`_headers` 规则齐全
- 当前机器的 `wrangler pages dev` 受 macOS `12.6.0` 限制不能完整启动 `workerd`，但不影响 Pages 目录产物生成与校验

优点：
- 直接绕开“原始 wasm 太大”带来的 Pages / 静态托管限制
- 部署最省事
- 带缓存头和 gzip 头，适合正式分享
- 比 GitHub Pages 更贴合当前包体现实：手机端无需再硬吃约 `35.94 MiB` 原始 wasm

缺点：
- 依赖 `_headers` 这类平台能力
- 本机无法在当前 macOS 上完整模拟 Pages 运行时

---

## 方案 C：对象存储静态托管 + CDN
适用场景：
- 需要完全控制缓存、压缩、域名、HTTPS
- 后续可能继续挂多个 demo
- 需要一条长期稳定的团队验收地址

当前仓库已附：`docs/deployment/nginx-web-release.conf`
- 默认对齐当前统一验收目录 `builds/web-release/`
- 已带 `index.html` 短缓存、`js/wasm/pck` 长缓存、`application/wasm` MIME 口径
- 若后续切到 `builds/web/`，再在此基础上补 `gzip_static on;`

推荐部署方式：
- 1 台轻量云主机 / 家用常开主机 / NAS
- 用 Nginx 或 Caddy 托管静态目录
- 域名指向固定地址，走 HTTPS

### Nginx 示例（适合 `builds/web/`）
```nginx
server {
    listen 80;
    server_name demo.example.com;
    root /srv/survivor-demo/web;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.wasm$ {
        types { application/wasm wasm; }
        add_header Cache-Control "public, max-age=31536000, immutable";
        gzip_static on;
    }

    location ~* \.(js|pck)$ {
        add_header Cache-Control "public, max-age=31536000, immutable";
        gzip_static on;
    }

    location = /index.html {
        add_header Cache-Control "no-cache";
    }
}
```

优点：
- 最稳定
- 最可控
- 后续好扩展

缺点：
- 有轻度运维成本
- 需要自己管域名、HTTPS、服务器

---

## 当前项目推荐落地顺序

### 第一阶段：先把验收链路稳定下来
- 统一把 `builds/web-release/` 作为验收包
- 本地 / 内网先验证一轮
- 文档、README、状态页全部指向同一个验收目录

### 第二阶段：准备一个正式分享地址
优先建议二选一：
1. **Cloudflare Pages + `builds/pages-deploy/`**：当前最贴合这次 wasm 瓶颈
2. **对象存储 + CDN**：运维最轻
3. **Caddy / Nginx 静态站**：长期最稳

### 第三阶段：再决定是否切换到压缩交付版
- 如果试玩人群变多、跨地域访问更多
- 再把 `builds/web/` 作为正式部署目录
- 重点确认 gzip、缓存、MIME 是否都正确

---

## 真正上线托管前的最小发布清单
正式把 demo 放到固定地址前，至少再过一遍：`docs/release-minimum-checklist.md`

其中最关键的最小项只有六个：
1. 源码主场景能正常加载，`game/scenes/main.tscn` 与 `game/scripts/main.gd` 没脱节
2. 用 Godot CLI 重新导出 `builds/web-release/`，确保托管包和当前源码一致
3. 本地静态服务复验 `index.html / index.js / index.wasm / index.pck` 全部返回 `200`
4. 跑一次 `tests/smoke/release_guard.sh`，把导出 / `builds/web-release/` → `builds/web/` 同步 / 资源返回 / gzip / 文档口径串起来复验
5. 托管侧确认 `application/wasm`、缓存策略、固定分享地址
6. 在 `docs/worklog.md` 留下本次导出、验证与提交记录

---

## 版本与目录建议
建议保持下面的约定，不要混用：

- `builds/web-release/` = 验收基线
- `builds/web/` = 部署优化版

这样可以避免两个常见问题：
1. 验收和部署用的是不同文件，但没人知道差异
2. 导出后覆盖了线上目录，却没有可回退的验收基线

---

## 最终建议
如果只选一个“更稳”的方案：

**短期推荐：Cloudflare Pages，直接发布 `builds/pages-deploy/`。**

原因：
- 直接利用当前已经准备好的 gzip 资源和 `_headers`，把正式托管体积压到 Pages 更容易接受的区间
- 比临时隧道稳很多
- 比自管服务器省心
- 如果后续不走 Pages，再退回 `builds/web-release/` / `builds/web/` 也很容易

如果后续会连续做多个 demo、想长期积累统一试玩站点：

**中期推荐：上 Caddy / Nginx 静态站，形成固定 demo 域名。**

## 一句话执行口径
- 现在本地给人验收：跑 `builds/web-release/`
- 现在准备对外正式分享：优先托管 `builds/pages-deploy/`
- 若平台不用 Pages：退回先托管 `builds/web-release/`
- 以后需要更可控部署：再切 `builds/web/` 或自管静态站
