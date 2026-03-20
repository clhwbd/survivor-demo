# 发布 / 托管方案建议

## 结论先行
当前最需要解决的问题不是“能不能跑起来”，而是**把分享链路从临时隧道切到稳定的静态托管方案**。

建议把发布链路分成三层：

1. **验收层**：`builds/web-release/`
   - 给项目负责人、策划、QA 验收
   - 任何静态服务器都能直接打开

2. **交付层**：`builds/web/`
   - 包含 `.gz` 预压缩资源
   - 用于部署优化和带宽节省

3. **正式分享层**：稳定静态托管 + HTTPS + 明确缓存策略
   - 不再依赖临时隧道

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

## 方案 B：对象存储静态托管 + CDN（推荐）
适用场景：
- 稳定分享给远端同事 / 外部试玩人员
- 不想维护整台服务器
- 希望把运维复杂度压到最低

推荐形态：
- 腾讯云 COS / 阿里云 OSS / Cloudflare R2（任选其一）
- 前面挂 CDN / Pages / Edge 平台
- 产物优先上传 `builds/web-release/`，稳定后再切换到 `builds/web/`

重点要求：
- `index.html`：短缓存或不缓存
- `index.js / index.wasm / index.pck`：长缓存，版本更新时替换文件或带版本号
- `index.wasm` MIME 需正确，建议 `application/wasm`
- 若使用 `builds/web/`，需确认平台支持：
  - gzip 静态资源直出，或
  - 边缘压缩
- 若走自管 Nginx，可直接从 `docs/deployment/nginx-web-release.conf` 起步

优点：
- 稳定
- 成本低
- 易分享
- 比临时隧道更适合持续验收

缺点：
- 需要处理缓存与 MIME 类型
- 第一次配置要稍微细一点

---

## 方案 C：Nginx / Caddy 静态站（最稳、可控性最高）
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
1. **对象存储 + CDN**：运维最轻
2. **Caddy / Nginx 静态站**：长期最稳

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

**短期推荐：对象存储静态托管 + CDN，用 `builds/web-release/` 先上线。**

原因：
- 比临时隧道稳很多
- 比自己维护服务器省心
- 足够满足这个 demo 阶段的分享和验收
- 后续如果访问量上来，再切到 `builds/web/` + 压缩策略也不晚

如果后续会连续做多个 demo、想长期积累统一试玩站点：

**中期推荐：上 Caddy / Nginx 静态站，形成固定 demo 域名。**

## 一句话执行口径
- 现在本地给人验收：跑 `builds/web-release/`
- 现在准备对外正式分享：先托管 `builds/web-release/`
- 以后需要压带宽 / 做部署优化：再切 `builds/web/`
