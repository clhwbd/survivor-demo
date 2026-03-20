# Status

当前状态：**玩法 demo 已成型，工程交付面已补齐到“可验收 / 可本地托管 / 可继续拆分协作”的阶段；但版本冻结与口径收口还没彻底完成。**

## 当前阶段判断
- 已完成：项目初始化
- 已完成：玩家移动基础
- 已完成：敌人生成与追踪
- 已完成：自动攻击基础
- 已完成：经验掉落与升级成长
- 已完成：基础 HUD
- 已完成：武器成长（多发 / 穿透 / 伤害成长）
- 已完成：第二种敌人（快速敌人）
- 已完成：第三种敌人（重装敌人）
- 已完成：偶数波精英敌人
- 已完成：基础受击与击杀反馈
- 已完成：30 秒一波的节奏推进与 3 分钟 demo 通关目标
- 已完成：网页端操作适配（触控摇杆 / 浏览器聚焦提示 / 网页交互提示）
- 已完成：主动闪避（键盘 `Space` / `Right Shift`、移动端闪避按钮）
- 已完成：Godot MCP 接入与验证
- 已完成：Web 导出配置与 Web 构建产出
- 已完成：验收版本说明、发布/托管方案文档、UI/美术拆分建议

## 当前可交付物
- 验收基线：`builds/web-release/`
- 压缩交付版：`builds/web/`
- Pages 正式发布目录：`builds/pages-deploy/`
- 验收说明：`docs/release-acceptance.md`
- 发布方案：`docs/deployment-plan.md`
- Nginx 托管模板：`docs/deployment/nginx-web-release.conf`
- 自管正式托管模板：`docs/deployment/nginx-web-controlled.conf`
- 正式托管前清单：`docs/release-minimum-checklist.md`
- 发布冒烟脚本：`tests/smoke/release_guard.sh`
- 字体子集脚本：`tests/smoke/build_ui_font_subset.py`
- Web 壳后处理脚本：`tests/smoke/patch_web_index.py`
- 压缩交付同步脚本：`tests/smoke/sync_compressed_build.sh`
- Pages 发布目录同步脚本：`tests/smoke/sync_pages_build.sh`
- Pages 发布校验脚本：`tests/smoke/pages_release_guard.sh`
- 自管 Web 校验脚本：`tests/smoke/controlled_web_guard.sh`
- 自管 Web 线上复验脚本：`tests/smoke/verify_controlled_web_remote.sh`
- 受控本地预览脚本：`scripts/serve_controlled_web.py`
- 受控交付打包脚本：`scripts/package_controlled_web_release.py`
- 临时验收运行手册：`docs/temporary-web-acceptance-runbook.md`
- Web 交付故障排查：`docs/web-delivery-troubleshooting.md`
- UI / 美术 agent 拆分建议：`docs/ui-art-agent-split.md`
- 工程日志：`docs/worklog.md`

## 当前验收 / 交付判断
- 当前统一验收目录：`builds/web-release/`
- 当前最佳本地验收方式：`python3 -m http.server 18081`
- 当前最佳后续正式托管方式：自管 Nginx 静态站直接发 `builds/web/`，并套用 `docs/deployment/nginx-web-controlled.conf`
- 当前最短稳定交付方式：执行 `python3 scripts/package_controlled_web_release.py` 生成受控交付 tar.gz，把包交给目标机器解包 + Nginx 挂载
- 当前仓库内一键自管校验命令：`./tests/smoke/controlled_web_guard.sh`
- 当前线上复验命令：`./tests/smoke/verify_controlled_web_remote.sh https://your-domain`
- 当前本地等价预览命令：`python3 scripts/serve_controlled_web.py --port 18084`
- 当前 Web 壳发布口径已收回到完整版本：保留完整 build，通过更可控的静态服务解决 wasm / gzip / header / 黑屏问题
- `builds/web/` 现在就是推荐的自管正式站点目录
- Cloudflare Pages 链路保留为旧备份方案，当前稳定地址仍是：`https://survivor-demo.pages.dev`
- GitHub Pages 不再建议作为当前完整版本验收主链路：原始 `index.wasm` 仍约 `35.94 MiB`，且 header / gzip 细节不可控
- `2026-03-20 14:36 CST` 已再次完成 Godot CLI Web 导出复验与本地 HTTP 校验
- `2026-03-20 14:45 CST` 已补一轮源码 / 场景一致性修正：主场景脚本恢复可加载，HUD 新节点与脚本口径重新对齐，并重导出 `builds/web-release/`
- 压缩版本地服务现已支持 `HEAD`，可直接接入健康检查或自动化探测
- `release_guard.sh` 现会先调用 `tests/smoke/sync_compressed_build.sh`，把 `builds/web/` 与最新 `builds/web-release/` 自动对齐，降低双目录交付漂移风险
- 真正上线托管前，默认再过一次 `docs/release-minimum-checklist.md`，并建议跑 `tests/smoke/release_guard.sh`

## 当前结论
这个项目现在更像一个**已可交接的 Web demo 样板**，而不再只是“玩法原型”；
但从 PM 视角看，当前最大问题已经不是“内容不够”，而是**当前已验版本还没有完全收成单一提交口径**。

接下来最值得做的不是继续补第四、第五套玩法系统，而是：
1. 先做版本冻结 / 口径收口，把当前验过的源码、场景、构建产物收成同一个版本号
2. 再收口 UI/HUD 的信息层级与视觉统一
3. 按“西游记古风 Q 版”方向补角色、敌人、图标、按钮、面板和轻演出
4. 选定一个稳定的静态托管方案，替代临时隧道式分享

## PM 补充观察（2026-03-20）
- 当前发布冒烟脚本 `./tests/smoke/release_guard.sh` 已再次跑通，说明**当前工作区状态**仍可导出、可校验、可本地托管。
- 但 PM 接管盘点时，工作区并非 clean tree，说明“当前已验证状态”与 Git `HEAD` 仍存在收版风险。
- 已新增 `docs/pm-production-status.md`，专门记录：
  - 当前并行线判断
  - 近几轮提交解读
  - 完成 / 半完成 / 未完成矩阵
  - 版本口径风险与下一步优先级

## 下一步建议
- P0：先完成版本冻结 / 口径收口，明确当前未提交的场景与构建产物是否属于本轮交付
- P1：完成 UI/HUD 收口与视觉最小替换包
- P1：给敌人 / 玩家 / 经验球 / 投射物建立统一美术命名与替换清单
- P1：补一轮正式公开试玩前的轻量性能回归与移动端触控回归
- P2：在版本口径和视觉风格都稳定后，再决定是否扩武器分支、Boss、音效与更重演出
