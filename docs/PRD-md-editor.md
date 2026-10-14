# PaxMD 从"阅读器"到"轻量 MD 编辑器" · 需求 PRD

> 版本：v0.1 · 状态：Draft · 提交者：pax-orchestrate 编排产出（`doc_consult` 路由，`analyze` 分支）
> 生成时间：2026-10-14 15:10 (GMT+8)
> 目标：给现有 PaxMD 增补"文档生命周期"和"编辑交互"两条链路，使其能胜任"日常轻量 Markdown 编辑"，同时对齐 Typora 的核心使用体验，保持轻量与低学习成本。

---

## 1. 背景与动机

### 1.1 当前定位

PaxMD 是一个 Tauri 2 + React 19 的桌面 Markdown 阅读器，标签页为"为阅读而生"（`README.md` L3）。核心卖点：

- 沉浸阅读：无边框窗口、黑白灰主题、字号/边距/背景图调节（`src/components/TitleBar.tsx`）
- 双视图：渲染预览 / 源码高亮（`src/components/MarkdownView.tsx`，`viewMode: "preview" | "code"`）
- 编辑辅助：Ctrl+E 切换"编辑模式"，在预览内 `contentEditable` 就地编辑，源码视图可编辑 textarea（`src/components/MarkdownView.tsx` L60–L70）
- 多标签页、目录同步、Wiki 双链、Mermaid / Vega / Chart.js 富块渲染（`src/renderer/richBlocks.ts`）

现有代码里已经有若干"编辑相关"能力（保存、脏标记、外部修改冲突询问、未保存弹窗、图片缩放/替换、Wiki 双链跳转、演示模式），可以视作"阅读器 + 部分编辑"的混合形态。但按用户目标"从阅读器变成编辑器"，仍缺关键能力。

### 1.2 问题定义（两条链路）

**链路 A — 文档生命周期**：文件从"无"到"存"的完整闭环。当前只有"打开 → 保存 → 关闭"，缺少新建、另存、自动保存、崩溃恢复、版本历史、导出，因此 PaxMD 无法作为主编辑工具承接日常工作流。

**链路 B — 编辑交互**：编辑过程中"如何快"的完整体验。当前有即时编辑、撤销/重做、图片编辑、Wiki 双链，但**缺搜索/替换**（Ctrl+F / Ctrl+H）、**缺快捷键面板**、**缺格式化命令快捷键**、**缺表格编辑**、**缺命令面板**——这些是 Typora 的"手感"所在。

### 1.3 不做的事（明确边界）

以下能力**明确不进入本期**：

- 插件市场 / 生态系统（对齐用户目标"不是加插件生态"）
- 云同步、多人协作、实时协同
- 双链知识库 / 图谱（现有 `[[wiki-link]]` 支持保留，但不做 Obsidian 级图谱视图）
- 数学公式之外的 LaTeX 编译、复杂表格宏
- 富文本粘贴的完整保真（跨 Word / Web 的样式转换）
- 手写 / 语音输入

---

## 2. 目标与非目标

### 2.1 目标

1. **补齐链路 A（文档生命周期）**：让"新建 → 编辑 → 保存 → 关闭/导出"成为一等公民，覆盖 95% 的日常写作场景。
2. **补齐链路 B（编辑交互）**：达到 Typora 的核心手感——快捷键齐、搜索替换、格式化命令、表格编辑、图片粘贴。
3. **保持轻量**：安装包增量 < 5 MB，启动时间不劣化 > 10%，无新增重依赖。
4. **不打断现有阅读器体验**：所有编辑能力默认关闭或渐进开启，"打开即读"的默认路径不变。

### 2.2 非目标（Non-goals）

- 不做 WYSISYG 的"源码彻底隐藏"体验（Typora 默认隐藏源码）——PaxMD 保留"预览 + 源码双视图"作为差异化优势
- 不做命令面板（P2，视用户呼声）
- 不做导出到 PDF/DOCX/EPUB（P2；PDF 可延后通过 WebView2 打印实现）
- 不做拼写检查、语法检查
- 不做多语言拼写纠错
- 不做移动端（Tauri 桌面为主）

---

## 3. 用户与场景

### 3.1 目标用户

- **主力**：日常需要写技术文档、会议记录、读书笔记、周报等"个人轻量写作"的用户（Windows 桌面为主，兼顾 macOS/Linux）
- **次级**：从 Obsidian / Typora 迁移过来，希望有更透明（可见源码）但同样流畅的编辑器
- **不针对**：论文级写作（用 Zettlr）、企业知识库（用 Obsidian / Logseq）、开发者代码阅读（用 VS Code）

### 3.2 核心场景

| 场景 | 用户行为 | 现有能力 | 缺口 |
|---|---|---|---|
| 从零写一篇 | 新建文档 → 编辑 → 保存 | ❌ 无新建 | P0 |
| 快速修改 | 打开 → 找词 → 替换 → 保存 | 找词/替换缺失 | P0 |
| 长文写作 | 编辑 → 自动保存 → 忘记关应用 | 无自动保存 | P0 |
| 换个位置存 | 打开 → 另存到别的目录 | ❌ 无另存为 | P0 |
| 崩溃恢复 | 突然崩溃 → 重新打开拿回内容 | ❌ 无草稿持久化 | P1 |
| 分享文档 | 编辑完 → 导出 PDF/HTML | ❌ 无导出 | P2 |
| 快速格式化 | Ctrl+B/I/U/H 快捷键 | 有右键菜单无快捷键 | P0 |

---

## 4. 竞品对标

### 4.1 主流开源 MD 编辑器横向对比

调研范围覆盖 12 个编辑器（含 10 个开源 + 2 个商业/参考基准），调研时间 2026-10-14，数据源为各仓库 Star 链接、README 与官方站点。完整数据见附录 A。

#### 4.1.1 编辑器清单

| # | 名称 | 仓库 / 地址 | Star（≈） | 技术栈 | 许可证 | 定位 |
|---|---|---|---|---|---|---|
| 1 | **AFFiNE** | toeverything/AFFiNE | 73.5k | Electron + Rust | MIT | "Notion + Miro" 开源知识库 |
| 2 | **marktext** | marktext/marktext | 62.6k | Electron + TS | GPL-3.0 | 最接近 Typora 的开源 WYSISYG |
| 3 | **Siyuan 思源** | siyan-note/siyuan | 46.8k | Go 后端 + Web 前端 | AGPL-3.0 | 隐私优先、块级数据库型知识空间 |
| 4 | **Logseq** | logseq/logseq | 45.2k | Electron + ClojureScript | AGPL-3.0 | block-based 双向链接 |
| 5 | **StackEdit** | benweet/stackedit | 23.1k | 纯浏览器 JS | MIT | 最早浏览器 WYSISYG（2023 停更） |
| 6 | **Zettlr** | Zettlr/Zettlr | 13.8k | Electron + TS | GPL-3.0 | 学术论文工作流 |
| 7 | **VNote** | vnotex/vnote | 13k | C++ 原生 | GPL-3.0 | 原生跨平台 MD 笔记 |
| 8 | **Milkdown** | Milkdown/milkdown | 12k | Web 组件库 | MIT | 插件式 WYSISYG 库（不是编辑器） |
| 9 | **Vditor** | Vanessa219/vditor | 11.4k | Web 组件 | Apache-2.0 | 三模编辑器（Typora 风格） |
| 10 | **Notepads** | 0x7c13/Notepads | 10.3k | .NET / UWP | MIT | Windows 现代轻量文本编辑器 |
| 11 | **Obsidian** | obsidian.md（闭源核心） | 官网 200w+ 用户 | Electron | 核心闭源 | PKM 行业标准 |
| 12 | **Typora** | typora.io（商业） | 商业 | 原生 C++（Win）/ Electron（其他） | 付费 | 纯 MD WYSISYG 标杆 |

#### 4.1.2 关键能力横向对比

| 能力项 | marktext | Zettlr | Logseq | Siyuan | AFFiNE | StackEdit | VNote | Notepads | Obsidian | VS Code+Foam | Typora |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 新建/打开/保存 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 自动保存 / 草稿 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ⚠️ | ✅ | ⚠️ | ✅ |
| 未保存标记 / 关闭确认 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ | ⚠️ | ✅ |
| 另存为 | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ✅ | ✅ | ⚠️ | ✅ | ✅ |
| 崩溃恢复 | ⚠️ | ⚠️ | ⚠️ | ✅ | ⚠️ | ❌ | ⚠️ | ⚠️ | ✅ | ⚠️ | ✅ |
| 版本历史 / 快照 | ❌ | ❌ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ⚠️ | ✅ | ⚠️ |
| 最近打开 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 多标签 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ❌ | ✅ | ✅ |
| 工作区 / Vault | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ⚠️ | ✅ | ✅ | ⚠️ |
| 云同步 | ⚠️ | ⚠️ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ✅（付费） | ⚠️ | ⚠️ |
| WYSISYG / 即时渲染 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ |
| 快捷键体系（>10） | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 大纲 / TOC | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ✅ | ✅ | ✅ |
| 图片：拖拽/粘贴/resize | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ⚠️ | ✅ | ⚠️ | ✅ |
| 数学公式（KaTeX） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ⚠️ | ✅ |
| 表格编辑 | ⚠️ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ⚠️ | ⚠️ | ✅ |
| 搜索替换 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 折叠块 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ✅ | ✅ | ⚠️ |
| 导出 PDF/HTML/Pandoc | ⚠️ | ✅ | ⚠️ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ⚠️ | ✅ | ✅ |
| 双向链接 / 图谱 | ⚠️ | ⚠️ | ✅ | ✅ | ✅ | ❌ | ⚠️ | ❌ | ✅ | ✅ | ❌ |
| 块级编辑 | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ⚠️ | ❌ | ✅ | ❌ | ❌ |
| 命令面板 | ⚠️ | ✅ | ✅ | ✅ | ✅ | ❌ | ⚠️ | ❌ | ✅ | ✅ | ❌ |
| 插件生态 | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | ✅（千家） | ✅（数万） | ❌ |

#### 4.1.3 体积 / 启动速度（相对 Typora）

| 编辑器 | 相对体积 | 冷启动 | 相对资源占用 |
|---|---|---|---|
| **Typora**（基准） | 1× | <1s | 1× |
| Obsidian | 3×（Electron） | <1s | 2-3× |
| marktext | 3-4× | 1-2s | 3-4× |
| Zettlr | 4-5× | 2-3s | 3-4× |
| Siyuan | 2×（Go 内核） | 1-2s | 2-3× |
| Logseq | 5× | 2-3s | 3-5× |
| AFFiNE | 5× | 2-3s | 4-5× |
| VNote | 0.7×（原生） | <1s | 0.5-1× |
| Notepads | 0.6×（原生） | <1s | 0.5× |
| VS Code | 5-8× | 3-5s | 3-5× |
| **PaxMD（当前）** | **~1×（Tauri 原生 + Web）** | **<1s** | **~1-1.5×** |

**关键洞察**：

1. **只有 Typora / VNote / Notepads 是原生架构**（体积 1× 以下），其余均为 Electron（体积 3-8 倍）。**PaxMD 基于 Tauri 2 + Rust，与 Notepads 同属原生阵营**，是"轻量 MD 编辑器"的差异化核心。这是本 PRD 最重要的战略优势。
2. **marktext** 是最接近 Typora 的开源 WYSISYG，但它仍是 Electron 系；PaxMD 用 Tauri 2 天然有体积优势。
3. **Obsidian / Logseq / Siyuan / AFFiNE** 都是知识库/块级路线，功能远超"编辑器"，与用户"不做插件生态"的诉求冲突，**明确不跟进**。
4. **VS Code + Markdown All in One** 编辑交互成熟但阅读体验差、冷启动 3-5s；PaxMD 保留阅读优势、补齐编辑短板即可。
5. **VNote / Notepads** 与 PaxMD 定位最接近（原生 + 轻量），但都缺 WYSISYG——**PaxMD 若能在保持原生的前提下做好"预览即时编辑"，就是差异化亮点**。

### 4.2 与 Typora 的核心能力对齐

以下是 Typora 官方列出的**核心编辑器能力**，逐一标注 PaxMD 当前状态与处置策略：

| Typora 能力 | PaxMD 现状 | 处置 |
|---|---|---|
| WYSISYG 行内渲染 | 预览即时编辑（`contentEditable` + 段落级 LinePatch） | 保留，完善边界 |
| 一键切换源码 | ✅ 已有 `viewMode` 切换 + `hljs` 高亮 | 保留 |
| Ctrl+S 保存 | ✅ 已有 | 保留 |
| **Ctrl+N 新建** | ❌ 无 | **P0 新增** |
| **Ctrl+Shift+S 另存为** | ❌ 无 | **P0 新增** |
| **Ctrl+F 搜索** | ❌ 无 | **P0 新增** |
| **Ctrl+H 替换** | ❌ 无 | **P0 新增** |
| Ctrl+Z/Y 撤销重做 | ✅ 已有（自建栈 + 原生双栈） | 保留 |
| **Ctrl+B/I/U/S 格式快捷键** | 有右键菜单无快捷键 | **P0 新增** |
| **Ctrl+1-6 标题快捷键** | ❌ 无 | **P0 新增** |
| **Ctrl+Shift+7/8/9 引用/列表快捷键** | ❌ 无 | **P1 新增** |
| **Ctrl+K 插入链接** | 有右键菜单，快捷键缺 | **P0 新增** |
| **Ctrl+Alt+C 插入代码块** | 有右键菜单，快捷键缺 | **P1 新增** |
| 图片拖拽/粘贴归档 | ✅ 已有 `importImage` + 缩放宽替换 | 完善粘贴剪贴板路径 |
| 图片 resize（拖角） | ✅ 已有 `resizeImage` | 保留 |
| 数学公式 KaTeX | ✅ 已有 | 保留 |
| Mermaid / 图表 | ✅ 已有 Mermaid / Vega / Vega-Lite / Chart.js / Graphviz | 保留（超越 Typora） |
| Wiki 双链 `[[...]]` | ✅ 已有 `resolveWikiTarget` | 保留（超越 Typora） |
| **表格编辑（可视化）** | ❌ 无（仅能写 markdown 表格文本） | **P1 新增** |
| **自动保存** | ❌ 无（仅手动 Ctrl+S） | **P0 新增** |
| **崩溃恢复** | ❌ 无 | **P1 新增** |
| **恢复上次会话** | ❌ 明写不自动恢复 | **P1 新增**（默认关闭可开） |
| **版本历史 / 快照** | ❌ 无 | **P2 新增**（可选） |
| **回收站** | ❌ 无 | **P2 新增**（可选） |
| **命令面板（Ctrl+P）** | ❌ 无 | **P2 新增**（可选） |
| **导出 PDF/HTML** | ❌ 无 | **P2 新增**（可选） |
| 大纲 / TOC | ✅ 已有（滚动同步 + 源码视图标题） | 保留 |
| 多标签页 | ✅ 已有 | 保留 |
| 多主题 / 亮暗切换 | ✅ 已有 | 保留 |
| 边距 / 字号调节 | ✅ 已有（超越 Typora） | 保留 |
| 全局搜索文件 | ❌ 无 | **P2 新增**（工作区搜索） |

**对齐统计**：Typora 核心能力 ~30 项，PaxMD 当前已覆盖 ~14 项（47%），本期 PRD 计划补齐 P0+P1 共 12 项 → 达到 ~26 项（87%）。P2 三项可选。

### 4.3 差异化定位

对 Typora 的差异化（保持“轻量 + 核心”定位下的真实优势）：

1. **开源（GPL-3.0）+ 免费**：Typora 付费 $14.99（永久）
2. **原生体量与 Typora 相当**：Tauri 2 + Rust，安装体积 ≈ 1× Typora；marktext / Obsidian / Zettlr 均 3-8×
3. **预览 + 源码双视图透明**：PaxMD 用户随时能看源码；Typora 默认隐藏源码需手动切换
4. **富块渲染领先**：Mermaid / Vega / Vega-Lite / Chart.js / Graphviz / KaTeX 全内建，Typora 仅支持 Mermaid + KaTeX（无内置 Graphviz / Vega / Chart.js）
5. **Wiki 双链支持**：内置 `[[target]]` / `![[target]]` 工作区解析；Typora 需插件，Obsidian 有但属于知识图谱体系
6. **阅读体验优势**：字号 / 边距 / 背景图 / 主题 / 阅读模式，与 Notepads / VNote 相比更接近“专用阅读器 + 编辑器”一体

---

## 5. 功能范围

按 P0 / P1 / P2 三级。P0 = 必须做（不做就无法称为"编辑器"）；P1 = 强烈建议（对齐 Typora 手感的关键项）；P2 = 可选（视用户呼声，不阻塞发版）。

### 5.1 链路 A：文档生命周期

| ID | 功能 | 优先级 | 验收要点（摘要） | 现有基础 |
|---|---|---|---|---|
| A1 | **新建文档**（Ctrl+N） | **P0** | 生成空文档，标题栏显示 `未命名-1.md`，可编辑，Ctrl+S 触发"另存为"对话框 | 无（无 `path` 的 tab） |
| A2 | **另存为**（Ctrl+Shift+S） | **P0** | 弹保存对话框，用户选路径+文件名；保存后切到新文件，旧 tab 可保留也可关闭（视状态） | 无 |
| A3 | **自动保存** | **P0** | 编辑内容变化 3s 后自动落盘（不覆盖外部改动）；设置项可关闭；保存后 dirty 归零 | 有 `saveTab`，无定时器 |
| A4 | **草稿持久化（崩溃恢复）** | **P1** | 应用启动时若发现某 tab 上次未保存的 draft 未落盘（`localStorage` 或 `%APPDATA%/pax-md-drafts/<hash>.md`），弹窗询问"恢复 / 丢弃" | 无 |
| A5 | **恢复上次会话** | **P1** | 设置项，默认关闭；开启后重启恢复上次所有标签（未保存草稿恢复） | 无（README 明写不恢复） |
| A6 | **版本历史 / 快照** | P2 | 每次保存自动生成快照（`.pax-md/history/<hash>.md.<n>`），可在标签栏菜单"历史"里回看/还原 | 无 |
| A7 | **回收站** | P2 | 用户"删除"文件时先进本地回收站（`%APPDATA%/pax-md-trash/`），可一键恢复 | 无 |
| A8 | **导出 HTML** | P2 | 单文件 HTML（内联 CSS/JS），一键导出到文档目录 | 无 |
| A9 | **导出 PDF** | P2 | 通过 Tauri `WebviewWindow` 打印到 PDF（Windows）或 `window.print()`（跨平台） | 无 |
| A10 | **首页显示最近文档** | P0（保留） | 已实现（`useRecent`），本期确认无回退 | ✅ |
| A11 | **关闭应用前询问** | P0（保留） | 已实现（`UnsavedDialog` + `CloseDialog`），本期确认无回退 | ✅ |
| A12 | **外部修改冲突询问** | P0（保留） | 已实现（`diskChanged` + `overwriteDiskChanged` 询问），本期确认无回退 | ✅ |

### 5.2 链路 B：编辑交互

| ID | 功能 | 优先级 | 验收要点（摘要） | 现有基础 |
|---|---|---|---|---|
| B1 | **搜索面板**（Ctrl+F） | **P0** | 顶部下拉浮层，输入关键词高亮所有匹配；上下箭头切换；Esc 关闭；计数显示 `3/15` | 无 |
| B2 | **替换面板**（Ctrl+H） | **P0** | 搜索下方追加替换行；"替换一个 / 替换全部"；大小写敏感、正则开关 | 无 |
| B3 | **快捷键面板** | **P0** | 顶栏菜单/设置里可展开，列出全部快捷键；支持搜索过滤 | 无 |
| B4 | **格式快捷键**：Ctrl+B / I / U / Shift+X | **P0** | 选中文字 → 加粗 / 斜体 / 下划线 / 删除线；无选区时插入占位符包裹 | 有右键菜单无快捷键 |
| B5 | **标题快捷键**：Ctrl+1-6 | **P0** | 当前行（或光标所在行）转换为 `#` ~ `######` | 无 |
| B6 | **插入链接**：Ctrl+K | **P0** | 有选区则包裹为链接；无选区则插入 `[ ]()` 模板并把光标定位到 `]` 之间 | 有右键菜单无快捷键 |
| B7 | **引用 / 列表快捷键**：Ctrl+Shift+7/8/9 | P1 | 引用块、有序列表、无序列表（Tab 缩进 = 嵌套） | 无 |
| B8 | **代码块插入**：Ctrl+Alt+C | P1 | 插入三反引号围栏，光标进入；可选语言 | 无 |
| B9 | **任务列表**：Ctrl+Shift+T | P1 | 当前行前置 `- [ ] `，光标定位到方括号后 | 无 |
| B10 | **粘贴图片**（Ctrl+V 剪贴板 → 归档） | **P0** | 剪贴板检测到图片 → 走 `importImage` 归档 → 在光标处插入 | 已有右键菜单手动路径 |
| B11 | **拖拽图片到文档** | P0（保留） | 已支持，本期确认无回退 | ✅ |
| B12 | **表格可视化编辑** | P1 | 光标停在表格 → 出现边框与调整按钮；右键"插入行/列、删除行/列、切换对齐"；markdown 语法保真 | 无 |
| B13 | **命令面板**（Ctrl+P / Ctrl+Shift+P） | P2 | 全局命令搜索，覆盖所有快捷键与顶栏动作 | 无 |
| B14 | **工作区文件搜索**（Ctrl+Shift+F） | P2 | 搜索整个工作区文件内容 | 无 |
| B15 | **预览即时编辑**（WYSISYG 主编辑路径） | P0（保留） | 已实现（`contentEditable` + `LinePatch`），本期完善边界：表格、列表缩进、代码块内编辑、多段跨块选择 | ✅ 核心已完成 |
| B16 | **源码视图编辑** | P0（保留） | 已实现（textarea + hljs 高亮覆盖层） | ✅ |
| B17 | **撤销 / 重做** | P0（保留） | 已实现（自建栈 + 原生双栈），本期确认所有快捷键场景下不冲突 | ✅ |
| B18 | **大纲 / TOC 侧栏** | P0（保留） | 已实现（滚动同步 + 源码视图标题），本期确认无回退 | ✅ |
| B19 | **图片缩放 / 替换 / alt / title** | P0（保留） | 已实现 | ✅ |
| B20 | **Wiki 双链跳转** | P0（保留） | 已实现 | ✅ |
| B21 | **折叠块**（`Ctrl+Shift+[/]`） | P1 | 折叠标题下内容直到下一个同级标题；折叠状态不入 markdown | 无 |
| B22 | **拼写检查** | P2 | 通过 WebView2 内置拼写检查；非中文场景可选 | 无 |
| B23 | **多标签组**（Tab Groups） | P2 | 拖拽标签分组，独立工作集 | 无 |

### 5.3 优先级汇总

- **P0（必须做，共 15 项）**：A1, A2, A3, A10, A11, A12, B1, B2, B3, B4, B5, B6, B10, B11, B15, B16, B17, B18, B19, B20
  - 新增 8 项：A1, A2, A3, B1, B2, B3, B4, B5, B6, B10（含 B10 剪贴板路径）
  - 保留 12 项：A10-A12, B11, B15-B20
- **P1（强烈建议，共 8 项）**：A4, A5, B7, B8, B9, B12, B21
- **P2（可选，共 9 项）**：A6, A7, A8, A9, B13, B14, B22, B23

---

## 6. 关键交互设计

### 6.1 新建文档流程

```
用户按 Ctrl+N
  │
  ├─ 无打开的工作区：
  │   ├─ 新建 tab，path=null，name="未命名-1.md"（序号递增）
  │   ├─ draft 为空字符串
  │   ├─ 顶栏"保存"按钮启用，点击触发 Ctrl+Shift+S 路径
  │   └─ 用户保存时走 A2 另存为流程
  │
  └─ 有打开的工作区：
      ├─ 新建 tab，path 初始为 null（同上一分支）
      ├─ 保存到工作区时，默认目录为工作区根目录
      └─ 保存到工作区后，workspace store 的 children 刷新，树里能立即看到
```

**关键决策**：新建文档的 tab 与文件 tab 使用同一数据模型（`path: null` 表示新建未命名），避免两套状态。这与 VS Code 的 `Untitled` 概念一致。

### 6.2 自动保存流程

```
编辑触发 → draft 变化 → debounce 3s
  │
  ├─ 3s 内无新编辑 → 触发 saveTab(id)
  │   ├─ 检查 tab.diskChanged
  │   │   ├─ true：跳过自动保存，仅显示"文件已被外部修改，请手动处理"提示条
  │   │   └─ false：写入磁盘，lastSavedAt=Date.now()
  │   └─ 更新 tab.content = draft；tab.draft = null
  │
  └─ 3s 内有新编辑 → 重置计时器
```

**关键决策**：自动保存不询问外部冲突（避免弹窗打断），仅当 `diskChanged=true` 时静默跳过并提示。用户手动 Ctrl+S 仍走完整冲突流程。

### 6.3 搜索 / 替换流程

```
用户按 Ctrl+F
  │
  ├─ 显示搜索浮层（顶栏下方，绝对定位）
  │   ├─ 搜索框：输入关键词
  │   ├─ 计数：`3/15`
  │   ├─ 上一个 / 下一个按钮
  │   └─ 关闭按钮 / Esc
  │
  ├─ 高亮：预览视图用 `<mark>` 包裹匹配；源码视图用 textarea 高亮层叠加
  │
  └─ Ctrl+H 展开替换区
      ├─ 替换输入框
      ├─ "替换"按钮（当前匹配）
      ├─ "替换全部"按钮
      ├─ 大小写敏感复选框
      └─ 正则复选框
```

**关键决策**：搜索基于 markdown 源文本（不是渲染后 DOM），这样：

1. 能匹配到未渲染的语法符号（`**bold**` 匹配 `bold` 也能匹配 `**bold**`）
2. 搜索与预览/源码两个视图一致（同一个 haystack）
3. 替换后走 `setDraft`，与预览编辑走同一草稿链路

### 6.4 快捷键面板

- 入口：顶栏菜单（"?"按钮）或 Ctrl+/ 快捷键
- 内容：所有已启用快捷键的表格，含搜索框过滤
- 分类：文件 / 编辑 / 视图 / 格式 / 插入 / 面板

### 6.5 状态机：tab 生命周期

```
              ┌──────────┐
   Ctrl+N ───▶│  UNTITLED │── Ctrl+S ──▶ SAVE AS 对话框 ──▶ SAVING
              └──────────┘                                              │
                    ▲                                                   ▼
                    │                                              ┌──────────┐
                    │                                              │  SAVED   │
              Ctrl+O│   openPath                                    │(path 已定)│
                    │                                              └──────────┘
                    │                                                   │
                    │     ┌───────────────────────────────────────────┐│
                    │     │  EDITING (draft !== null)                ││
                    │     │     │                                     ││
                    │     │     ├─ Ctrl+S / 自动保存 ──▶ SAVING      ││
                    │     │     ├─ 外部修改 ──▶ DISK_CHANGED         ││
                    │     │     └─ Ctrl+W ──▶ 未保存询问 ──▶ CLOSE   ││
                    │     └───────────────────────────────────────────┘│
                    │                                                  │
                    └──────────── 新建一个 tab ◀──────────────────────┘
```

---

## 7. 验收标准（EARS）

EARS = Easy-to-read Requirements Syntax。每条需求用"WHEN / WHILE / WHERE / THE X SHALL …"句式。

### 7.1 链路 A（文档生命周期）

**A1 新建文档**

- WHEN 用户按 Ctrl+N OR 点击顶栏"新建"按钮 THEN PaxMD SHALL 在当前活动 tab 右侧插入一个新 tab，其 `path=null`，`name="未命名-{n}.md"`（`n` 为本会话内未命名序号从 1 递增），`draft=""`，并将焦点切换到新 tab。
- THE 新建 tab SHALL 支持在预览视图或源码视图立即编辑，与文件 tab 无视觉差异。
- WHEN 用户按下 Ctrl+S 且当前活动 tab 是未命名 tab THEN PaxMD SHALL 触发"另存为"对话框（A2）而非静默保存。
- WHEN 用户按 Ctrl+W 且当前活动 tab 是未命名 tab 且 `draft` 为空 THEN PaxMD SHALL 直接关闭该 tab 且不询问。
- WHEN 用户按 Ctrl+W 且当前活动 tab 是未命名 tab 且 `draft` 非空 THEN PaxMD SHALL 弹出未保存弹窗（A11）。

**A2 另存为**

- WHEN 用户按 Ctrl+Shift+S OR 点击顶栏"另存为"菜单项 THEN PaxMD SHALL 弹出原生保存对话框（`.md` 扩展名默认为当前 tab 的 `name` 去掉 `.md`），用户选择后写入文件。
- WHEN 用户选择的路径已存在同名文件 THEN PaxMD SHALL 询问"覆盖 / 取消 / 重命名"三选一；覆盖前先备份原文件到 `<path>.bak.<timestamp>`。
- AFTER 保存成功 THEN PaxMD SHALL 更新 tab.path、tab.name、tab.content，清空 tab.draft，并将新路径加入最近打开列表。
- IF 用户取消保存对话框 THEN PaxMD SHALL 保持 tab 为未命名状态。

**A3 自动保存**

- WHILE 用户正在编辑已命名 tab（`path !== null`）且设置项"自动保存"为开启状态，WHEN 距上次保存间隔 ≥ 3s THEN PaxMD SHALL 自动调用 `saveTab(id)`。
- IF 触发自动保存时 `tab.diskChanged === true` THEN PaxMD SHALL 跳过本次保存，并在状态栏显示"外部已修改，自动保存已暂停"3 秒。
- THE 自动保存的间隔阈值 SHALL 可在设置中调整为 0（关闭）/ 3 / 5 / 10 / 30 秒。

**A4 崩溃恢复**

- IF 应用启动时发现 `%APPDATA%/pax-md-drafts/<hash>.md` 存在且其内 `saved_at` 与磁盘同名文件的 `mtime` 不一致 THEN PaxMD SHALL 弹出"检测到未保存的草稿"弹窗，提供"恢复 / 丢弃"两个选项。
- WHILE 应用运行中，每次触发手动或自动保存成功时，PaxMD SHALL 删除对应的草稿文件。

**A5 恢复上次会话**

- WHEN 用户开启"恢复上次会话"设置并重启应用 THEN PaxMD SHALL 恢复上次关闭前打开的所有标签（含未命名 tab 与其草稿），按上次顺序和焦点状态。
- THE 默认值 SHALL 为关闭，与 README 现有约定一致（"启动固定停留在首页(不自动恢复上次会话)"）。

### 7.2 链路 B（编辑交互）

**B1 搜索面板**

- WHEN 用户按 Ctrl+F THEN PaxMD SHALL 在标题栏下方展开搜索浮层，输入框获焦，光标定位到文本末尾。
- WHILE 搜索浮层打开，WHEN 用户在搜索框输入字符 THEN PaxMD SHALL 在 100ms 内高亮所有匹配，并在浮层显示 `n/N`（当前匹配 / 总数）。
- WHEN 用户按 Enter OR ↓ THEN PaxMD SHALL 跳转到下一个匹配并将预览/源码视图滚动到该位置；Shift+Enter OR ↑ 跳转到上一个。
- WHEN 用户按 Esc THEN PaxMD SHALL 关闭浮层并清除所有高亮。
- THE 搜索 SHALL 作用于 markdown 源文本，预览视图与源码视图共享同一份结果。

**B2 替换面板**

- WHEN 用户按 Ctrl+H THEN PaxMD SHALL 展开搜索浮层并追加替换区（替换输入框 + 两个按钮 + 两个复选框：大小写敏感、正则）。
- WHEN 用户点击"替换" THEN PaxMD SHALL 仅替换当前高亮的匹配，跳转到下一个。
- WHEN 用户点击"替换全部" THEN PaxMD SHALL 一次性替换所有匹配，状态栏提示"已替换 N 处"。
- THE 正则模式 SHALL 支持 `\1` 反向引用；正则语法错误时，替换按钮禁用并在浮层显示错误提示。

**B3 快捷键面板**

- WHEN 用户按 Ctrl+/ OR 点击顶栏"?"按钮 THEN PaxMD SHALL 展开快捷键面板，展示全部已注册快捷键，含搜索框。
- WHILE 用户在搜索框输入关键词 THEN PaxMD SHALL 过滤出匹配的动作（按动作名、快捷键、分类三字段模糊匹配）。

**B4 格式快捷键**

- WHEN 用户在预览视图或源码视图选中文字并按 Ctrl+B THEN PaxMD SHALL 用 `**...**` 包裹选中内容（预览视图走 contentEditable 命令，源码视图直接修改 draft 文本）。
- WHEN 用户无选区时按 Ctrl+B THEN PaxMD SHALL 插入占位符 `**文本**` 并将光标定位到 `文本`。
- THE 其他格式快捷键 SHALL 保持一致语义：Ctrl+I（`*...*`）、Ctrl+U（`<u>...</u>`，因 markdown 无下划线原生语法，走 HTML 标签）、Ctrl+Shift+X（`~~...~~`）。

**B5 标题快捷键**

- WHEN 用户按 Ctrl+1..6 THEN PaxMD SHALL 将光标所在行（或选中范围的首行）转换为对应级别的 ATX 标题（`#` 到 `######`）；已是同级标题时再按一次 SHALL 去掉标题前缀。

**B6 插入链接**

- WHEN 用户按 Ctrl+K 且有选区 THEN PaxMD SHALL 将选区包裹为 `[选区](url)`，光标定位到 `url`。
- WHEN 用户按 Ctrl+K 且无选区 THEN PaxMD SHALL 插入 `[文本](url)`，光标定位到 `文本`。
- THE 链接地址栏支持粘贴图片、文件路径、Wiki 目标（`[[target]]` 会被规范化）。

**B7 引用 / 列表快捷键**

- WHEN 用户按 Ctrl+Shift+7 THEN PaxMD SHALL 在光标行前追加 `> `；多行选中时逐行追加。
- WHEN 用户按 Ctrl+Shift+8 THEN PaxMD SHALL 在光标行前追加 `1. `（有序列表）。
- WHEN 用户按 Ctrl+Shift+9 THEN PaxMD SHALL 在光标行前追加 `- `（无序列表）。
- WHILE 光标在列表内，WHEN 用户按 Tab THEN PaxMD SHALL 增加 2 空格缩进；Shift+Tab 减少 2 空格。

**B8 代码块插入**

- WHEN 用户按 Ctrl+Alt+C THEN PaxMD SHALL 在当前行插入：
  ```
  ```
  
  ```
  ```
  光标定位到内层空行。
- WHEN 用户在代码块语言提示处（三反引号后）输入字符 THEN PaxMD SHALL 允许语言标识（如 `js`、`ts`、`python`、`bash`），源码视图自动高亮该语言。

**B9 任务列表**

- WHEN 用户按 Ctrl+Shift+T THEN PaxMD SHALL 在光标行前追加 `- [ ] `，光标定位到方括号后。

**B10 粘贴图片**

- WHEN 用户按 Ctrl+V 且系统剪贴板包含图片数据 THEN PaxMD SHALL 调用 `importImage(documentPath, imagePath)` 将图片归档到文档目录的 `docs/` 子目录（已在文档目录内则原地引用），并在光标位置插入 `![alt](docs/<name>.png)` 或已归档路径。
- IF 归档失败 THEN PaxMD SHALL 提示错误但不阻断粘贴（回退为纯文本粘贴）。

**B12 表格可视化编辑**

- WHEN 光标停在 markdown 表格内 THEN PaxMD SHALL 在预览视图中显示表格边框（虚线），单元格可点击定位。
- WHEN 用户右键点击表格单元格 THEN PaxMD SHALL 显示表格操作菜单："插入行（上/下）"、"插入列（左/右）"、"删除行"、"删除列"、"切换对齐（左/中/右）"。
- THE 所有表格编辑操作 SHALL 生成符合 GitHub Flavored Markdown 的表格语法。

**B21 折叠块**

- WHEN 用户按 Ctrl+Shift+[ THEN PaxMD SHALL 折叠光标所在标题下的所有子内容直到下一个同级或更高级别标题。
- WHEN 用户按 Ctrl+Shift+] THEN PaxMD SHALL 展开光标处最近的折叠块。
- THE 折叠状态 SHALL 仅存在于运行时（不写入 markdown 文件），关闭 tab 后丢失。

### 7.3 通用非功能验收

- **性能**：搜索 / 替换在 10k 行的 markdown 文档上，首次搜索响应 < 300ms，替换单个匹配 < 100ms。
- **内存**：编辑 10k 行文档时，内存增量 < 50 MB。
- **兼容性**：Windows 10/11、macOS 12+、Ubuntu 22.04+ 均可运行；行尾 CRLF / LF 保持原样。
- **可访问性**：所有新 UI 组件带 `aria-label`；快捷键覆盖鼠标不可达场景。
- **回归**：现有 60+ 测试用例（`pnpm test`）保持通过；新增单元测试覆盖率 ≥ 80%。

---

## 8. 技术约束与依赖

### 8.1 约束

- **Tauri 2 API 稳定**：新增 Tauri command 必须向后兼容（新增 optional 参数、禁止删除参数）。
- **草稿序列化格式**：草稿文件必须是纯文本 markdown（不是 JSON 包裹），确保用户手工也能查看。
- **无新增运行时依赖**：搜索高亮 / 表格编辑 / 折叠块均用原生 DOM + CSS 实现，不引入 CodeMirror / Monaco。
- **保持 GPL-3.0**：不引入非 GPL 兼容的库（如 AGPL、商业许可）。

### 8.2 依赖复用

- **搜索高亮**：直接用 `<mark>` 包裹 + CSS 样式；不需要额外库
- **表格编辑**：复用现有 `markdown-it-multimd-table` + Turndown 的表格规则
- **折叠块**：CSS `details` / `summary` 或自定义折叠状态（不进 markdown）
- **PDF 导出**：Tauri `WebviewWindow` + `Webview.print()`（Windows / 部分 Linux）；macOS 走 `window.print()`

### 8.3 状态存储位置

| 数据 | 位置 | 生命周期 |
|---|---|---|
| Tab 状态 | Zustand `useTabs` | 会话内存 |
| Settings | `%APPDATA%/pax-md/pax-md-settings.json`（zustand persist） | 持久 |
| 草稿（未保存） | `%APPDATA%/pax-md/pax-md-drafts/<hash>.md` | 会话内存 + 持久兜底 |
| 版本历史 | `<文档目录>/.pax-md/history/<hash>.md.<n>` | 与文档同目录 |
| 回收站 | `%APPDATA%/pax-md/pax-md-trash/` | 持久 |

---

## 9. 里程碑与分期

### M1（第 1 迭代，1-2 周）— 链路 A P0

- A1 新建文档
- A2 另存为
- A3 自动保存

**交付物**：能完整"新建 → 编辑 → 自动保存"，Ctrl+N / Ctrl+S / Ctrl+Shift+S 全部接通。

### M2（第 2 迭代，2-3 周）— 链路 B P0

- B1 搜索面板
- B2 替换面板
- B3 快捷键面板
- B4 格式快捷键
- B5 标题快捷键
- B6 插入链接
- B10 粘贴图片

**交付物**：Ctrl+F / Ctrl+H / Ctrl+/ 生效，格式快捷键齐，Typora 的"手感"初具。

### M3（第 3 迭代，2-3 周）— P1 增强

- A4 崩溃恢复
- A5 恢复上次会话
- B7/B8/B9 引用列表代码块任务列表快捷键
- B12 表格可视化编辑
- B21 折叠块

**交付物**：对齐 Typora 的完整编辑体验，可以真正作为主编辑工具。

### M4（可选，视用户呼声）— P2

- A6 版本历史
- A7 回收站
- A8/A9 导出 HTML / PDF
- B13 命令面板
- B14 工作区文件搜索
- B22 拼写检查
- B23 多标签组

**交付物**：完善性增强，不阻塞任何主线。

---

## 10. 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|
| R1: 自动保存与外部修改冲突处理不当 | 中 | 高（用户数据丢失） | 遵循现有 `diskChanged` + `overwriteDiskChanged` 语义；自动保存遇冲突静默跳过并提示，不主动覆盖 |
| R2: `contentEditable` 编辑边界情况（跨块选择、复杂粘贴） | 中 | 中 | 保持现有"fallback 整篇转换"兜底（`previewEdit.ts:res.fallback`）；新增场景优先走 fallback 而非强写 |
| R3: 表格编辑引入 markdown-it 插件冲突 | 低 | 中 | 现有 `markdown-it-multimd-table` 已支持；编辑操作只做 DOM 变换后转回文本，不新增渲染插件 |
| R4: 快捷键与用户已绑定的浏览器/系统快捷键冲突 | 中 | 中 | 面板里可禁用单个快捷键；文档中列出所有冲突可能性 |
| R5: PDF 导出跨平台差异 | 中 | 低 | Windows 走 Tauri print；macOS/Linux 走 `window.print()` 用户自选打印机；本期降级为 P2 |
| R6: 草稿持久化与隐私 | 低 | 高 | 草稿与文档同目录存储（用户可见、可控、可删除）；不上传任何内容 |
| R7: 打包体积增长 | 低 | 低 | 无新增运行时依赖；预计增量 < 2 MB |
| R8: 与开源许可证兼容 | 低 | 高 | 不引入非 GPL 兼容库；保持 GPL-3.0 |

---

## 11. 附录

### 附录 A：竞品清单与关键定位

> 详细对比表见 §4.1。本附录列出与 PaxMD 定位最相关的编辑器及其“学/不学”的结论。

| 编辑器 | 定位 | 与 PaxMD 关系 |
|---|---|---|
| **Typora**（付费） | WYSISYG 标杆 | **对齐基准**（本 PRD §4.2） |
| **marktext**（62.6k, GPL-3.0, Electron） | 开源 Tauri 风 WYSISYG | 同类竞品，Electron 体量大 3-4×；PaxMD 走 Tauri 2 天然轻量 |
| **VNote**（13k, C++ 原生, GPL-3.0） | 原生轻量 MD 笔记 | 定位最接近但缺 WYSISYG，可参考它的“原生体量 + MD 能力”平衡 |
| **Notepads**（10.3k, .NET UWP, MIT） | Windows 现代轻量 | 同属原生阵营，仅 Win；PaxMD 多平台但保持原生体量 |
| **Siyuan 思源**（46.8k, Go+Web, AGPL-3.0） | 块级知识库 | 不做（与轻量 MD 定位冲突，AGPL 商用顾虑） |
| **Logseq**（45.2k, Electron, AGPL-3.0） | block-based 笔记 | 不做（范式不同） |
| **Obsidian**（官网 200w+ 用户） | PKM 行业标准 | 不做（不追插件生态、图谱） |
| **AFFiNE**（73.5k, Electron+Rust, MIT） | Notion 替代品 | 不做（重平台定位） |
| **Zettlr**（13.8k, Electron, GPL-3.0） | 学术论文工作流 | 不做（目标用户不同） |
| **StackEdit**（23.1k, 浏览器, MIT） | 浏览器即开即用 | 参考（已停更，PaxMD 不采用云存路径） |
| **Milkdown**（12k, Web 库, MIT） | WYSISYG 库 | 不作为依赖（自研 contentEditable + Turndown 已可工作） |
| **Vditor**（11.4k, Web 库, Apache-2.0） | 三模编辑器库 | 不作为依赖（同上） |
| **VS Code + Foam** | IDE 内建 | 互补；用户要专业编辑会自己去 VS Code |

**对调研子 Agent 提出的 P0 清单的回应**：

子 Agent 将“崩溃恢复 / 本地版本历史 / 命令面板 / 导出 PDF/HTML”列为轻量 MD 编辑器的 P0，与 PaxMD 本 PRD 判定不同。理由：

- 崩溃恢复（A4）已归为 **P1**，因需新增文件草稿目录且涉及隐私边界，MVP 可不先上；
- 版本历史（A6）已归为 **P2**，因与用户当前习惯（git 管理文档目录）重叠，可延后；
- 命令面板（B13）已归为 **P2**，因 PaxMD 顶栏与快捷键已能覆盖 90% 日常操作，不阻塞主链路；
- 导出 PDF/HTML（A8/A9）已归为 **P2**，因用户可用“复制粘贴到 Word / Pandoc / Typora 导出”过渡。

若后续用户呼声强烈（例如 GitHub issue 集中反映），可上提至 P1。

### 附录 B：源码证据索引

**已具备的能力（README + 源码行号）**：

- 双视图与编辑模式：`src/components/MarkdownView.tsx` L60–L120，`src/stores/settings.ts` `viewMode` / `editMode`
- 预览即时编辑：`src/renderer/previewEdit.ts`（LinePatch + applyLinePatches）
- HTML → Markdown 反解：`src/renderer/backconvert.ts`（Turndown 配置）
- 保存：`src/stores/tabs.ts:saveTab`（保留原行尾，冲突询问，1.5s 抑制窗口）
- 未保存弹窗：`src/components/UnsavedDialog.tsx`
- 外部监听：`src-tauri/src/watcher.rs` + `App.tsx`（100ms 合并）
- 目录同步：`src/components/TocSidebar.tsx` + `src/stores/toc.ts`
- 工作区树：`src/components/WorkspaceTree.tsx` + `src/stores/workspace.ts`
- 图片归档：`src-tauri/src/commands.rs:import_image`（复制到 docs/ 目录）
- 富块渲染：`src/renderer/richBlocks.ts`（Mermaid / Vega / Vega-Lite / Chart.js / Graphviz）
- Wiki 双链：`src/renderer/wiki.ts` + `src-tauri/src/commands.rs:resolve_wiki_target`
- 演示模式：`src/components/PresentationMode.tsx`（Marp）
- 撤销/重做双栈：`src/components/MarkdownView.tsx` `imgUndoRef` / `imgRedoRef`
- 图片缩放替换：`src/components/MarkdownView.tsx` `resizeImage` / `replaceImage`

**明确缺失的能力（grep 结果）**：

- 无 `new_file` / `save_as` / `export` / `pdf` / `search` / `replace` / `command_palette` 相关 Tauri command
- 无 `autosave` / `draft` 持久化（草稿仅存于 Zustand 内存）
- 无 `openFile` 保存对话框（`@tauri-apps/plugin-dialog` 只用到 `open`，未用 `save`）
- 无键盘监听器处理 Ctrl+F / Ctrl+H / Ctrl+Shift+S / Ctrl+N
- 无表格编辑组件
- 无折叠块组件
- 无命令面板组件

### 附录 C：术语

| 术语 | 说明 |
|---|---|
| WYSISYG | What You See Is What You Get，所见即所得。Typora 默认范式，PaxMD 通过预览即时编辑实现半 WYSISYG |
| LinePatch | PaxMD 预览编辑的实现概念：一段 line 范围的替换，见 `src/renderer/previewEdit.ts:LinePatch` |
| draft | Tab 的编辑缓冲，未保存的编辑都写在 `draft`，`content` 是最后保存的快照 |
| dirty | 派生状态：`draft !== null && draft !== content` |
| diskChanged | 派生状态：外部修改导致磁盘内容与 draft 不一致，保存前需询问 |
| EARS | Easy-to-read Requirements Syntax，需求表达方式：WHEN / WHILE / WHERE / IF / THE X SHALL |
| P0/P1/P2 | 优先级：必须做 / 强烈建议 / 可选 |

### 附录 D：不做清单（再次强调）

- 不做插件市场 / 插件系统
- 不做云同步 / 多人协作 / 实时协同
- 不做双链知识库 / 图谱视图（保留 `[[wiki-link]]` 基础跳转）
- 不做 WYSISYG 的"完全隐藏源码"体验（保留双视图优势）
- 不做移动端适配
- 不做拼写检查（P2 可选）

---

## 变更历史

| 版本 | 日期 | 变更 |
|---|---|---|
| v0.1 | 2026-10-14 | 初稿：源码基线调研 + Typora 对齐 + 竞品摘要 + P0/P1/P2 分级 + EARS 验收 + 里程碑 |

