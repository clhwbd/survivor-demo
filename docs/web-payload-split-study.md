# survivor-demo Web 分包 / 降载专项研究

> 目标：把 survivor-demo 在 Godot 4.6.1 Web 导出下，哪些东西真能拆、哪些基本拆不动，做成**可复跑、可交接**的工程结论，而不是只停留在口头判断。

## 一句话结论

- **当前首开大头就是 Godot Web 模板 wasm，本质上是引擎运行时，不是项目资源。**
- 在 **Godot 4.6.1 官方模板** 下，`survivor-demo` 的 `index.wasm` 约 **35.94 MiB**；即使把项目内容裁到几乎空项目，wasm 仍然还是 **35.94 MiB**。
- 所以：
  - **项目分包能显著降的是 `pck`，不是当前这份 wasm 本体。**
  - **要缓解首开，当前最有效的是：压缩传输 + 合适托管/CDN + 更清楚的加载壳层。**
  - 若后续游戏内容继续膨胀，再做资源包拆分 / DLC pack / 首屏资源最小集才有更大收益。

---

## 1. Godot Web 下 wasm 为什么大

### 1.1 这份 wasm 里主要装的不是 survivor-demo 的玩法资源
当前 Web 导出里的 `index.wasm` 主要来自：
- Godot Web 导出模板本身
- 引擎运行时、渲染 / 音频 / 脚本 VM 等底层能力
- Emscripten / WebAssembly 打包后的运行环境

它**不是**“把项目里的贴图 / 场景 / 字体全塞进 wasm”那种结构。项目资源主要在 `index.pck`。

### 1.2 实测证明：空项目 vs 当前项目，wasm 一样大
我新增了可复跑实验脚本：
- `tests/smoke/web_payload_matrix.py`
- 输出：
  - `reports/web_payload_matrix.json`
  - `reports/web_payload_matrix.md`

其中最关键的一组对照：

| 对照项 | wasm | pck |
| --- | ---: | ---: |
| 当前 survivor-demo Web 预设 | `37,685,705 B` | `455,416 B` |
| 极简空项目对照 | `37,685,705 B` | `1,548 B` |

这说明：
- **pck 几乎可以被裁空**
- **wasm 仍然不动**
- 因而 wasm 大小主要由 **Godot 4.6.1 Web 模板** 决定

### 1.3 哪些能拆，哪些不能拆

**能拆 / 能明显下降的：**
- `index.pck` 中的项目资源
- 字体、图片、音效、特效、非首屏场景资源
- 发布壳层（HTML / JS 的提示、加载体验、分阶段说明）
- 网络传输体积（gzip / CDN / Pages / 边缘缓存）

**不能靠项目分包显著下降的：**
- 当前官方模板下的主 `index.wasm`
- 通过普通 `exclude_filter` / feature tag / 删项目资源 来“顺手变小”的 wasm

**只有模板 / 引擎构建级别才可能影响的：**
- 更换 Web 模板（如 `web_release.zip` vs `web_nothreads_release.zip`）
- dynamic linking 模板
- 自编译 Godot Web 模板，裁引擎模块

---

## 2. 我实际尝试了哪些策略

## 2.1 策略 A：项目资源收紧（已落地）

这条线不是本次新发明，但它已经在仓库里落成，并且本次研究里被纳入正式结论：

### 已落地内容
- 排除开发期资源：`addons/godot_mcp/*`、`tests/*`、`.godot/*`
- 中文字体改为 UI 子集字体：`survivor-ui-subset.ttf`
- 当前 Web 导出继续保留中文字体与竖屏适配，不回退

### 实际效果
此前已把 `index.pck` 压到当前约：
- `builds/web-release/index.pck = 455,416 B`
- `builds/web/index.pck.gz ≈ 184~240 KiB`（不同轮次与重建会有小抖动）

### 结论
- **有效，但作用对象是 pck，不是 wasm。**
- 对当前 survivor-demo 而言，这条线已经把首包里“项目可控那部分”压得比较狠了。

---

## 2.2 策略 B：只改 feature tag / custom_features（已实测）

实验方式：
- 在导出 preset 中只增加 `custom_features="payload_test,web_bootstrap"`
- 不动资源集，不动模板

实验结果：
- `index.wasm`: `37,685,705 B` → `37,685,705 B`（**完全不变**）
- `index.pck`: `455,416 B` → `455,480 B`（仅 +64B，近乎可忽略）

### 结论
- **无效**，至少对“缩 wasm”这件事无效。
- feature tag 只能帮助你做项目逻辑分支，不会自动把引擎 wasm 裁掉。

---

## 2.3 策略 C：更换导出模板到 `web_release.zip`（已实测）

实验方式：
- 强制将 release 模板从当前默认结果切到 `web_release.zip`

实验结果：
- `index.wasm`: `37,685,705 B` → `37,003,942 B`
- 下降：`681,763 B`（约 **-1.8%**）
- `index.pck`: **无变化**

### 结论
- **有一点点效果，但远远不是“分包级”改善。**
- 可作为“模板级微优化”备选，但不是当前主解。
- 如果主线愿意承受一轮更严格的浏览器 / 托管复验，可以把它列为**可选项**；但我不建议把希望押在这 0.68MB 上。

---

## 2.4 策略 D：dynamic linking 模板（已实测）

实验方式：
- 强制切到 `web_dlink_nothreads_release.zip`

实验产物：
- `index.wasm = 1,509,558 B`
- `index.side.wasm = 41,113,842 B`
- `index.js = 5,552,570 B`
- `index.pck = 455,416 B`

gzip 后运行时总量：
- 基线：`9,641,156 B`
- dlink：`11,244,653 B`

### 观察
- 看起来像“把 wasm 分裂了”，但本质上只是把主体搬到了 `index.side.wasm`。
- 总运行时下载量**没有更小，反而更大**。
- `index.js` 也明显变大。
- 这条线不是“把首开真正拆成可延迟的业务分包”，更像“换了一种引擎装配方式”。

### 结论
- **对 survivor-demo 当前目标无效，甚至更差。**
- 可以说它是“技术上拆成两个 wasm 文件了”，但**不是当前要的那种有效 Web 分包**。
- 不建议主线接入。

---

## 2.5 策略 E：极简空项目对照（已实测）

实验方式：
- 用 Godot 4.6.1 建一个只含空 `Node2D` 的极简 Web 项目
- 同样导出 Web release

结果：
- `index.wasm = 37,685,705 B`
- `index.pck = 1,548 B`

### 结论
- 这是本次研究里最重要的“做实结论”实验。
- 它直接证明：
  - **wasm 不会因为你把 survivor-demo 的项目内容拆掉就明显变小**
  - 真正能分的是项目资源，不是当前这份引擎 wasm

---

## 2.6 策略 F：Web 壳层加载体验改造（已落地代码）

本次除了实验，我还继续把 Web 壳层往“对 wasm 首开更诚实、更可感知”方向补了一刀。

### 落地文件
- `tests/smoke/patch_web_index.py`

### 新增内容
导出后自动给 `index.html` 补：
- 当前阶段提示：
  - 引擎 wasm
  - 游戏资源 pck
  - 初始化场景与首屏 UI
- 当前体积构成提示：
  - `wasm xx MB`
  - `pck xx MB`
- 慢加载时更明确地告诉后续接入方：
  - 现在更可能卡在 wasm 首包或 gzip / CDN 没打中
  - 若当前托管仍是 GitHub Pages，应优先切 Cloudflare Pages

### 结论
- **这不会缩小 wasm 本体**。
- 但它能明显改善“首开卡住时用户完全不知道在发生什么”的问题。
- 这条线是当前最安全、最容易接入、不会碰玩法与 UI 的体验增强。

---

## 3. 哪些有效，哪些无效

## 有效
1. **资源瘦身 / 资源排除**
   - 对 `pck` 有效
   - 已经实际把项目可控资源压到较小范围

2. **gzip + Cloudflare Pages / 正确 CDN 托管**
   - 对传输体积极其有效
   - 当前 `builds/web/index.wasm.gz` 约 **9.1 MiB**，远小于原始 35.94 MiB
   - 这是当前最现实的首开缓解手段

3. **加载壳层分阶段提示**
   - 对“感知可用性”有效
   - 不减小体积，但能减少“像死了一样”的观感

4. **模板级微调（`web_release.zip`）**
   - 有小幅效果
   - wasm 约再降 **0.68 MB**
   - 只能算边角收益

## 无效 / 不建议
1. **feature tag / custom_features 指望缩 wasm**
   - 无效

2. **dynamic linking 当作主线 wasm 分包方案**
   - 形式上拆了，结果上更重
   - 不建议接入

3. **指望项目分包让 Godot 4.6.1 官方模板 wasm 大幅下降**
   - 结论已做实：**基本不成立**

---

## 4. 关键产物大小对比

来自 `reports/web_payload_matrix.md`：

| 方案 | wasm | side.wasm | pck | gzip 运行时总量 |
| --- | ---: | ---: | ---: | ---: |
| 当前仓库 Web 预设 | `37,685,705 B` | - | `455,416 B` | `9,641,156 B` |
| 仅增加 feature tags | `37,685,705 B` | - | `455,480 B` | `9,641,184 B` |
| 强制 `web_release.zip` | `37,003,942 B` | - | `455,416 B` | `9,636,662 B` |
| dynamic linking nothreads | `1,509,558 B` | `41,113,842 B` | `455,416 B` | `11,244,653 B` |
| 极简空项目对照 | `37,685,705 B` | - | `1,548 B` | `9,456,269 B` |

还可以结合当前仓库构建目录理解：

| 当前仓库产物 | 大小 |
| --- | ---: |
| `builds/web-release/index.wasm` | ~`35.94 MiB` |
| `builds/web-release/index.pck` | ~`444.7 KiB` |
| `builds/web/index.wasm.gz` | ~`9.1 MiB` |
| `builds/pages-deploy/index.wasm` | ~`9.0 MiB` |

---

## 5. 对“资源分包 / 延迟加载 / 外部 pack”的判断

## 5.1 对当前 survivor-demo：技术上可做，但收益主要在未来内容扩张，不在当前 wasm

当前项目已经把 `pck` 压到不足 0.5 MiB。此时再强做资源分包：
- 能证明“项目资源可外置”
- 但对**当前首开核心瓶颈**帮助不大，因为最大头仍是 wasm

所以这件事的优先级应该是：
- **中期可做，为后续内容扩张预埋结构**
- **不是当前首开问题的第一主解**

## 5.2 真正适合后续拆出去的内容
如果 survivor-demo 后续继续长大，更适合外置的会是：
- 大图集 / 立绘 / 背景图
- 更多音效 / BGM
- 非首屏特效资源
- 更完整字体包
- 后续章节 / 模式 / 关卡包

## 5.3 当前不建议为了“分包”而重构主循环
原因很简单：
- 现在 `pck` 已经不大
- 重构外部 pack / 远程加载 / fallback 处理的工程成本，已经接近“为 0.4MB 再做一套发布系统”
- 性价比不高

---

## 6. 给主线的最短可接入建议

### 建议 1：把本次研究脚本和报告收进常规链路
直接可用：
- `tests/smoke/web_payload_matrix.py`
- `reports/web_payload_matrix.md`
- `reports/web_payload_matrix.json`

主线后续只要跑一遍，就能知道：
- wasm 还是不是模板主导
- 改模板有没有新收益
- 未来某轮资源膨胀后，pck 是否重新变成首包主瓶颈

### 建议 2：继续把正式外链建立在压缩托管上，不要回退到原始 wasm 直出
当前最短口径依然是：
- `builds/web-release/` = 验收基线
- `builds/web/` = 压缩交付目录
- `builds/pages-deploy/` = 正式托管目录

也就是说：
- **验收看 web-release**
- **正式分享走 pages-deploy / gzip / CDN**

### 建议 3：保留当前壳层补丁
- `tests/smoke/patch_web_index.py` 本轮已增强
- 主线只需继续复用它，不要删
- 它对 wasm 首开虽然不是“降大小”，但对“看起来是否像卡死”很关键

### 建议 4：若主线愿意再赌一轮模板复验，可单独开分支验证 `web_release.zip`
优先级不高，但可作为备选：
- 潜在收益：约 `-0.68 MB wasm`
- 前提：再做浏览器兼容 / 托管复验
- 不建议把它当成主方案，只能当作小补丁

### 建议 5：除非后续内容量明显上涨，否则先不要为外部 pack 重构主游戏
当 `pck` 重新膨胀到数 MB 甚至十几 MB，再上：
- 首屏最小资源集
- 二段资源包
- 可选外部 DLC pack

当前这件事的 ROI 还不高。

---

## 7. 本次研究落地物

### 新增 / 更新文件
- `tests/smoke/web_payload_matrix.py`
- `reports/web_payload_matrix.json`
- `reports/web_payload_matrix.md`
- `tests/smoke/patch_web_index.py`（增强加载阶段提示）
- `docs/web-payload-split-study.md`

### 复验建议
```bash
cd /Users/mac/game-studio/projects/survivor-demo
python3 tests/smoke/web_payload_matrix.py
./tests/smoke/release_guard.sh
```

---

## 8. 最终结论

### 做实后的结论
- **Godot 4.6.1 官方 Web 模板下，survivor-demo 当前 `index.wasm` 不能靠项目分包显著下降。**
- **可以被有效拆的是项目资源 `pck`、字体、交付形态和加载体验。**
- **当前最有效、最短可接入的路线不是继续纠结“拆 wasm”，而是：压缩传输 + 合适托管 + 更清楚的加载壳层。**

### 面向主线的一句话执行建议
> 先把这次研究产物收进去，正式链接继续走 `pages-deploy` / gzip / CDN；若后续内容再膨胀，再把“资源二段包 / 外部 pack”作为下一阶段工程项，而不是现在硬拆 wasm。
