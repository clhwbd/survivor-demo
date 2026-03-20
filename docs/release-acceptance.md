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

2. 自定义压缩服务脚本当前只实现了 `GET`
   - 因此用 `curl -I` 发 `HEAD` 请求会得到 `501`
   - 这不影响浏览器正常加载
   - 若后续需要接健康检查或自动化探测，可补一个 `do_HEAD`

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
