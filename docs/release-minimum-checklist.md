# 正式托管前最小发布清单

> 目标：在真正把 demo 放到稳定静态托管地址前，用最小成本确认“源码、构建、文档、托管参数”没有明显脱节。

## A. 源码 / 构建一致性
- [ ] `game/scenes/main.tscn` 与 `game/scripts/main.gd` 可正常加载主场景
- [ ] 用 Godot CLI 重新导出 `builds/web-release/`
- [ ] 导出后确认 `index.html / index.js / index.wasm / index.pck` 时间戳已刷新
- [ ] 本次准备上线的托管目录已明确：当前默认 `builds/web-release/`
- [ ] README、`docs/status.md`、`docs/release-acceptance.md`、`docs/deployment-plan.md` 对交付目录的口径一致

## B. 本地访问回归
- [ ] `python3 -m http.server 18081` 可正常提供 `builds/web-release/`
- [ ] `index.html / index.js / index.wasm / index.pck` 返回 `200`
- [ ] 首页可进入游戏，不会卡在空白页或资源加载失败
- [ ] 键盘移动、自动攻击、升级、受击、闪避、暂停 / 结算流程正常
- [ ] `03:00` Demo Clear、`R` / 按钮重开正常

## C. 网页 / 移动端最低体验项
- [ ] 浏览器首次进入 / 失焦后的聚焦提示仍可正常唤起
- [ ] 触控摇杆与闪避按钮可操作
- [ ] HUD 左上 / 顶部横幅 / 右上状态卡文案无缺失、无遮挡、无明显错位
- [ ] 结果面板（暂停 / 失败 / 通关）文案与按钮状态正确

## D. 托管前配置项
- [ ] 准备固定分享地址，不再依赖临时隧道
- [ ] `index.wasm` 的 MIME 为 `application/wasm`
- [ ] `index.html` 使用短缓存或 `no-cache`
- [ ] `index.js / index.wasm / index.pck` 使用长缓存，并配合版本替换
- [ ] 若改用 `builds/web/`，已确认托管平台支持 gzip 静态资源或边缘压缩

## E. 交付留痕
- [ ] 在 `docs/worklog.md` 记录本次导出、验证与结论
- [ ] 重要收口成果已提交 Git
- [ ] 若给他人验收，明确本次验收地址、目录版本、验证时间

## 当前执行口径
- **当前统一验收 / 首发目录：** `builds/web-release/`
- **当前本地复验方式：** `python3 -m http.server 18081`
- **当前正式托管建议：** 先上对象存储静态托管 + CDN，稳定后再考虑压缩部署版 `builds/web/`
