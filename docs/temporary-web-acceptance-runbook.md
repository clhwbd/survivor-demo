# 临时 Web 验收运行手册

> 目标：在**没有固定服务器**的前提下，尽快把 survivor-demo 的 controlled web 交付链路复用起来，形成一套“本机可起、临时可分享、用户可验、出问题可回滚到本机排查”的操作口径。

> 范围：只覆盖交付运营与验收操作，不涉及游戏逻辑修改。

## 1. 适用场景
- 要把当前完整 Web 版本临时发给负责人 / 测试 / 外部验收方
- 当前没有长期固定域名或正式运维环境
- 需要先在本机确认资源头、gzip、缓存策略都正常，再决定是否挂临时外链
- 遇到“黑屏 / 一直加载 / 打不开 / 像旧版本”的时候，希望能快速判断问题是在**包本身**、**本机服务**还是**临时外链**

## 2. 本轮默认口径
- **本地受控正式目录**：`builds/web/`
- **本地等价服务脚本**：`scripts/serve_controlled_web.py`
- **本地一键守卫**：`tests/smoke/controlled_web_guard.sh`
- **线上复验脚本**：`tests/smoke/verify_controlled_web_remote.sh`
- **临时交付打包脚本**：`scripts/package_controlled_web_release.py`
- **受控 Nginx 模板**：`docs/deployment/nginx-web-controlled.conf`
- **旧备份链路**：`builds/pages-deploy/` / Cloudflare Pages

结论先写清楚：

**临时验收主线 = 先本机受控服务验证，再决定是否挂临时外链。不要反过来。**

如果本机都没验证过，就直接丢临时外链，后面很难区分是资源头问题、缓存问题，还是隧道问题。

## 3. 开始前准备
在项目根目录执行：

```bash
cd /Users/mac/game-studio/projects/survivor-demo
```

确认以下内容存在：
- `builds/web/`
- `scripts/serve_controlled_web.py`
- `tests/smoke/controlled_web_guard.sh`
- `tests/smoke/verify_controlled_web_remote.sh`

## 4. 临时验收标准流程

### 步骤 A：先跑本地守卫
```bash
./tests/smoke/controlled_web_guard.sh
```

这一步的意义不是“走流程”，而是先确认：
- `builds/web-release/` 与 `builds/web/` 没漂移
- `index.html` 缓存策略正确
- `index.wasm` 的 `Content-Type: application/wasm` 正确
- `index.js / index.wasm / index.pck` 的 gzip 头存在
- `OPTIONS` / CORS / `/healthz` 正常

如果这一步不过，**不要挂临时外链**，先排查本机问题。

### 步骤 B：起本机受控服务
```bash
python3 scripts/serve_controlled_web.py --port 18084
```

本机访问：
```text
http://127.0.0.1:18084/index.html
```

本机手动确认至少 4 件事：
1. 首页能打开
2. 加载页有阶段提示，不是纯空白
3. 能进入游戏
4. 首次进场可操作（键盘或触控）

### 步骤 C：决定临时分享方式
优先级建议：

1. **最优：有可控机器时，按 `docs/deployment/nginx-web-controlled.conf` 挂临时站点**
2. **次优：本机起受控服务，再用临时隧道/临时外链转发**
3. **保底：旧 Pages 备份链路 `https://survivor-demo.pages.dev`**

注意：
- 临时隧道只适合“短时验收”，不适合当长期稳定链接
- 如果只是给 1~2 个人做一轮临时验收，本机受控服务 + 临时外链通常是最快路径
- 如果临时外链不稳定，优先把问题定位成“隧道问题”，不要立刻怀疑游戏包坏了

### 步骤 D：外链起来后立刻做线上复验
```bash
./tests/smoke/verify_controlled_web_remote.sh https://your-domain
```

只要外链可访问，就必须做这一步。它能比“我手机上点开看一下”更快判断是不是 header 漂了。

### 步骤 E：把链接发给验收方
发链接时，不要只丢 URL，至少附上：
- 推荐浏览器
- 首开可能慢的预期
- 遇到卡住时先怎么处理
- 回传问题时要带什么信息

可直接复用下面模板：

```text
这是 survivor-demo 当前临时验收链接：
https://your-domain

建议：
1. 优先用手机系统浏览器或 Chrome 打开
2. 首次打开会先加载引擎与资源，第一次通常最慢
3. 如果 30~60 秒仍停在加载页，请先刷新一次
4. 如果看起来还是旧版本，请强刷或换无痕模式重开
5. 如果仍异常，请把“卡在哪个阶段 + 截图 + 手机型号/浏览器”发回
```

## 5. 推荐验证顺序

### 5.1 运营侧验证顺序
严格按这个顺序，排查成本最低：

1. `controlled_web_guard.sh` 本地过没过
2. 本机 `127.0.0.1:18084` 能不能正常进入
3. 临时外链能不能打开 `/healthz`
4. `verify_controlled_web_remote.sh` 头校验过没过
5. 再让用户打开正式链接

### 5.2 用户侧验收顺序
建议引导用户按这个顺序反馈：

1. 能不能看到加载页提示文字
2. 卡在“请求 wasm / 下载 wasm / 请求 pck / 下载 pck / 初始化运行时”的哪一步
3. 刷新一次后是否改善
4. 换浏览器 / 无痕模式是否改善
5. 是否只有蜂窝网络或某个 Wi‑Fi 环境打不开

这比笼统说“打不开”更容易定位。

## 6. 临时外链操作建议

### 6.1 什么时候适合挂临时外链
- 当天要给负责人做临时验收
- 只需要稳定撑一小段时间
- 目标是先确认“当前 build 能不能被目标用户打开”

### 6.2 什么时候不适合挂临时外链
- 需要长期稳定地址
- 需要多人反复访问
- 需要严格缓存控制与可观测性
- 需要给非技术同学反复回归

这种情况应尽快切回可控机器上的 Nginx 静态站，而不是一直靠隧道硬撑。

### 6.3 临时外链的最低要求
无论你用什么隧道/临时转发，只要它指向本机 `18084`，都应满足：
- `GET /healthz` 返回 `ok`
- `HEAD /index.wasm` 能看到 `Content-Type: application/wasm`
- 带 `Accept-Encoding: gzip` 请求时，`index.wasm / index.js / index.pck` 能返回 `Content-Encoding: gzip`

如果这些条件不成立，这条外链就不应进入正式验收。

## 7. 用户提示口径

### 7.1 首次发送链接时怎么说
建议统一口径：
- 这是**临时验收链接**，不是长期正式站
- 首开通常最慢
- 若卡住先刷新一次
- 若疑似旧缓存先强刷 / 无痕
- 若仍失败请反馈“阶段 + 截图 + 设备环境”

### 7.2 避免使用的模糊说法
不要再用：
- “你再等等看”
- “应该快好了”
- “我这边能开，可能你网络问题”

改成更可执行的话：
- “如果停在阶段 1/3 超过 60 秒，请先刷新一次”
- “如果刷新后还是旧页面，请开无痕模式再试”
- “如果无痕也不行，我这边会先复验外链 header 和健康检查”

## 8. 临时验收失败时的回退顺序
当临时验收地址出问题，建议按下面顺序回退：

1. **先保留本机受控服务**，确认本机正常
2. **复验临时外链**：`./tests/smoke/verify_controlled_web_remote.sh https://your-domain`
3. **如果判断是隧道不稳，直接切备份链路**：`https://survivor-demo.pages.dev`
4. **如果连备份链路也异常，再回头检查 build 与缓存口径**

核心原则：

**先区分“包坏了”还是“链路坏了”，不要把所有异常都归类成黑屏。**

## 9. 交付打包口径
如果需要把当前临时验收方案快速交给别人复用：

```bash
python3 scripts/package_controlled_web_release.py
```

产物会带上：
- `builds/web/`
- `docs/deployment/nginx-web-controlled.conf`
- `tests/smoke/verify_controlled_web_remote.sh`
- `manifest-sha256.txt`
- `DELIVERY_README.md`

适用场景：
- 把包直接交给临时运维 / 测试同学
- 切到另一台机器临时挂站
- 需要保留一次“可追溯的验收交付包”

## 10. 临时验收完成后的最小收尾
验收结束后建议至少记录：
- 使用的是哪条链接
- 本机端口是什么
- 用户端主要设备 / 浏览器
- 是否出现黑屏 / 慢加载 / 旧缓存 / 隧道失效
- 最终切到了哪条回退链路

这些信息应继续写入：
- `docs/worklog.md`

## 11. 一页式速查

### 起服务
```bash
python3 scripts/serve_controlled_web.py --port 18084
```

### 本地守卫
```bash
./tests/smoke/controlled_web_guard.sh
```

### 外链复验
```bash
./tests/smoke/verify_controlled_web_remote.sh https://your-domain
```

### 打交付包
```bash
python3 scripts/package_controlled_web_release.py
```

### 备份链路
```text
https://survivor-demo.pages.dev
```

---

如果你只记住一句话：

**先在本机把 controlled web 跑通，再挂临时外链；先验证 header，再让用户反复重试。**
