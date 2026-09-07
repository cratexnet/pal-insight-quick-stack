# Quick Stack 发布流程

本文是 Quick Stack 从候选版本到 Nexus Mods、CurseForge 和 Steam Workshop
公开发布的唯一操作清单。收到“发布”“准备发布”或同义请求时，先读本文，再执行
任何版本、构建、打包或平台操作。

## 不可跳过的原则

- 以玩家实际可下载的上一公开版本为 Changelog 差异基线，不以开发分支、提交记录、
  标签或同名本地包代替。必要时交叉核对 Nexus、CurseForge、Steam 和已有发布记录。
- Changelog 只记录玩家能观察到的版本差异。开发期间出现并在发布前修掉的崩溃、
  错位、白色图标、措辞调整和实现返工不作为公开新增或修复。
- 最终 Changelog 必须交给维护者审核。未经维护者明确确认，不得把它定稿、同步到
  17 种游戏内语言、转换成平台格式、填写发布表单或上传公开版本。
- 平台 Changelog 只允许做 Markdown、BBCode 或单行列表的格式转换，不得二次改写、
  拆分、合并或增加新的事实主张。Steam 投票反馈不写入 Changelog。
- 升级版本号的当刻记录 UTC 时间，并立即写入游戏内版本记录。不得用提交时间代替；
  后续只有在需要对齐权威平台时间时才更新，并保留来源具有的时间精度。
- 已公开且可下载的版本视为不可变。发布前发现错误可以撤回草稿并重新上传；公开后
  发现包体错误必须停止发布、告知维护者并决定是否升补丁版本，不能静默替换同版本。
- 不把 `Baking`、`Under Review`、病毒扫描中或仅已提交描述成“已发布”。
- 未取得相应环境的实机证据时，只报告静态验证，不宣称 Game Pass、多人、专服或
  co-op 已验证。

## 权限边界

维护者说“发布”表示启动本文流程，不自动跨过以下独立边界：

1. 升级版本号。
2. 构建、打包或同步到游戏/Steam 发布器目录。
3. Git commit。
4. Git push 和 tag push。
5. Nexus、CurseForge 或 Steam 的最终提交。

每个边界遵循 `AGENTS.md`。通过网页执行上传、归档、删除或最终提交时，还要在实际
动作前满足界面操作的确认要求。Steam Workshop 默认由维护者完成最终上传；代理负责
准备并核验发布器目录、包体和 BBCode。

## 1. 冻结候选版本

1. 确认目标版本符合 SemVer：新增向后兼容功能升 minor，兼容性修复升 patch，破坏性
   变化升 major。
2. 确认维护者对候选版的实机测试结论；只记录实际覆盖的平台和模式。
3. 查看工作区、当前提交、远端状态和已有 tag，保护所有无关未提交改动。
4. 核对上一公开版本在 Nexus、CurseForge 和 Steam 上的文件、版本、时间与说明。
   平台不一致时先记录差异，不能静默选择一个基线。
5. 查看新评论、问题和贡献记录，提出可能需要加入感谢名单的人及理由；排除已经列入
   名单的人。名单变更仍需维护者确认。

## 2. 升级版本并记录时间

取得升级版本号的明确许可后：

1. 立即读取当前 UTC 时间，记录到秒；该时刻就是版本升级时间。
2. 更新并交叉核对所有版本源，至少包括：
   - `Scripts/main.lua` 的 `VERSION`；
   - `packaging/release.json` 的 `version`；
   - `packaging/workshop/Info.json` 的 `Version`；
   - `README.md` 的当前版本；
   - `Scripts/release_notes.lua` 的版本索引和 `dateUtc`；
   - 发布门禁中对当前版本及历史顺序的断言。
3. 此时只建立版本与时间，不把未经审核的 Changelog 当作最终内容。

## 3. 起草并审核 Changelog

1. 比较上一公开下载物与候选版，按用户可见影响整理候选事实。
2. 采用 `Added / Changed / Performance / Fixed` 中实际需要的分组；不为排版制造空分组。
3. 每条说明用户现在能做什么，并在会影响安全使用时写明范围、数量、默认状态、入口
   或回退行为。不要写实现类名、RPC、缓存和开发过程。
4. 先向维护者展示完整英文稿及忠实的简体中文译文，明确哪些候选项被排除及原因。
5. 根据反馈继续审计，不因要求“完整”而堆入开发流水账，也不因要求“精简”而删除
   必要的类别、数量、默认状态或安全语义。
6. 维护者明确确认内容后，才写入 `CHANGELOG.md`，并把同一事实同步到
   `Scripts/release_notes.lua` 的全部 17 种语言。1.2.0 及以后版本不得在游戏内再做
   第二次编辑性改写。
7. 生成最终平台载荷：
   - Nexus：每个正式条目一行；
   - CurseForge：Markdown；
   - Steam：BBCode，保存为 `docs/STEAM-CHANGELOG-<version>.bbcode.txt`。
8. 把最终完整平台 Changelog 再交给维护者审核。只有明确确认后的文本才能用于发布。

## 4. 发布前内容核对

逐项判断是否需要更新，不能默认只换 ZIP：

- `README.md`、安装说明和兼容性声明；
- Nexus 的 Description 与置顶 Sticky Post；
- CurseForge 和 Steam 的主描述及版本亮点；
- `CREDITS.md` 和游戏内特别感谢；
- 截图、图标、依赖、游戏版本、标签及安装路径；
- Steam、Nexus、CurseForge 和 Game Pass 的渠道差异；
- 当前公开页面是否仍显示旧版本专属文案。

若某项无需修改，在发布记录中写明已检查且无变化。任何新兼容性主张都必须有对应
实机证据。

Nexus Description 与 Sticky Post 是两个独立的公开文案，发布前必须分别：

1. 分别进入 Nexus Description 编辑器和 Sticky Post 的 `Edit post` 编辑器，读取
   文本框中的原始 BBCode 源码。公开页渲染文本、可访问文本、截图和仓库中的旧副本
   都不能替代源码；
2. 以线上原始 BBCode 为唯一排版底稿。必须保留开头及正文中的 `[center]`、图片、
   字号、颜色、链接、列表和嵌套标签；不能根据渲染结果重新拼写整页格式；
3. 将线上源码与仓库文案源比较，明确指出缺失、过期或仅在线上存在的内容；
4. 在原始 BBCode 上做最小修改，并与新版本功能、默认值、安装渠道、兼容性和已审核
   Changelog 交叉核对；
5. 生成可直接粘贴的完整 BBCode 全文，不能只给标题、更新段或差异补丁；
6. 把两份完整 BBCode 交给维护者审核；
7. 只有维护者明确确认后，才允许修改线上 Description 或 Sticky Post；
8. 修改后重新读取编辑器源码和公开渲染页，确认版本标题、标签结构、正文、图片、链接
   和格式均已生效；
9. 将获批的完整源码同步回项目内对应文案源，避免下一版再次依赖过期副本。若项目尚无
   Sticky Post 源文件，应在 `packaging/nexus/` 下建立并维护一个。

即使判断其中一处无需修改，也要明确向维护者报告核对结果；不能因为文件已经上传或
另一处文案已更新而跳过。

## 5. 静态验证、提交与推送

使用最窄但完整的现有发布检查：

```powershell
node .\toolchain\tools\release\pal_insight_quick_stack_release_inventory.js prebuild --root .
git diff --check
git status --short
git diff
```

取得 commit 许可前，展示暂存文件、拟用中文提交信息以及 hooks 是否运行。提交后再
单独取得 push 许可。需要 tag 时使用 `v<version>`，并把创建及推送 tag 作为独立授权
动作；若本次不创建 tag，必须在发布记录中明确写出，不能默认为已完成。

## 6. 构建和打包

取得构建、打包许可后：

```powershell
& .\native\steam_vote\build.ps1
node .\build_release.js
```

核对 `release/release-manifest.json` 和 `release/SHA256SUMS.txt`：

- Nexus 与 CurseForge 的 Steam/Win64 ZIP 字节一致；
- Nexus 与 CurseForge 的 Game Pass/WinGDK ZIP 字节一致；
- 每个 ZIP 能安全解压，文件清单与源目录一致；
- Game Pass 根目录是 `Pal/Binaries/WinGDK/...`；
- Workshop 包通过门禁且不包含 `enabled.txt`；
- 诊断开关关闭，Workshop 专属投票组件只出现在 Workshop 包；
- 记录标准包和 Game Pass 包的 SHA-256。

打包输出不是源代码。除非项目约定改变，不把 `release/`、中间装配目录或临时上传
目录提交到 Git。

## 7. Nexus Mods

取得 Nexus 最终提交许可后分别处理：

1. 先完成并取得 Nexus Description 与 Sticky Post 两份完整 BBCode 的审核确认。
2. Steam/Win64 包更新现有 Main 文件，文件显示名固定为
   `Pal Insight: Quick Stack`；Game Pass Optional 文件显示名固定为
   `Game Pass Experimental (WinGDK)`。不得在显示名后附加版本号。
3. 版本号只填写到 Nexus Version field。版本化的本地 ZIP 文件名保持不变；
   versioned ZIP filename 表示构建产物身份，不是 Nexus 文件显示名。
4. Steam/Win64 和 Game Pass/WinGDK 都更新现有的同渠道文件；确认替代文件可用后，
   再归档旧文件。
5. Main 文件负责更新项目版本；Optional 文件不能意外把项目版本改回旧值。
6. 两个文件都使用已审核的 Nexus 单行 Changelog，不临场改写。
7. 保存后核对公开文件列表中的名称、类别、版本、上传时间和可下载/扫描状态。
8. 按获批全文更新 Description 与 Sticky Post，并读取公开页验证结果。
9. 记录 Nexus 文件 ID；能取得公开哈希时与本地包核对。

旧文件默认归档而不是删除。错误草稿或错误包的删除必须明确指出目标，并取得删除
确认。

## 8. CurseForge

Quick Stack 当前不是开源项目。项目后台的 **Source** 标签必须保持
`The source code is not publicly available`；未经维护者另行明确决定，不得填写 GitHub
或其他公开源码仓库。

发布前必须进入 CurseForge 作者后台的 Description 编辑器，读取编辑字段中的完整原始
源码。公开页渲染文本、可访问文本、截图、Nexus/Steam 文案和仓库旧副本均不能代替
CF 源码。以线上源码为唯一排版底稿，保留所有图片、链接、标题、列表、空行及平台特有
结构，只做新版本所需的最小修改。

本文及发布沟通中所说的“给 CF source code”，默认专指在 **Description 富文本编辑器中
切换到 HTML Source Code 视图后取得的完整 HTML**，不表示公开项目源码，也不表示填写
Source 标签。Markdown 编辑器值、由页面反向拼出的 Markdown 和渲染结果都不是这里所说
的 CF source code。

交付时必须把 HTML 全文放入纯文本代码块，使 `<h1>`、`<p>`、`<ul>`、`<a>`、`<img>`、
内联样式、属性和实体保持原样并可直接复制；不得使用会渲染内容的 Writing Block、普通
Markdown 正文、页面预览、截图、摘要或仅提供文件链接来代替源码全文。

修改后的完整 Description source code 必须先交给维护者审核，不能只给渲染效果、摘要、
新增段落或差异。维护者确认后才允许保存线上 Description；保存后同时读取编辑器源码与
公开渲染页复核，并将获批全文同步回 `packaging/curseforge/description.md`。若 CurseForge
编辑器使用 HTML 或其他源码格式，必须原样保留该格式，不能擅自转换成 Markdown。

取得 CurseForge 最终提交许可后分别上传 Steam/Manual 和 Game Pass 包：

- 显示名、文件名和版本必须一致；
- Release Type 选择 `Release`；
- 选择审核通过后自动发布；
- 游戏版本沿用当前项目支持的已核对值；
- 使用已审核的 Markdown Changelog；
- 不添加未经确认的依赖或 Related Projects。

提交后分别记录文件 ID 和 `Baking`、`Under Review`、`Approved` 等真实状态。只有
`Approved` 且公开页可下载才算 CurseForge 已发布。若重传，先辨别文件仍是草稿、
审核中还是已公开；不要把“等待审核”误当成需要再传一个包。

## 9. Steam Workshop

Quick Stack Workshop 条目 ID 固定为 `3792968111`。不要通过 Palworld 游戏启动入口
寻找发布功能；使用独立发布器：

```text
D:\Workspace\pal-insight\toolchain\tools\palworld-mod-uploader\PalworldModUploader.exe
```

### Quick Stack 的 Steam 本地化顺序

Steam Description 必须按 Quick Stack 线上条目已经使用的顺序交付，不能套用 Pal Insight
或游戏运行时 17 种语言的顺序：

1. English (`english`)
2. Simplified Chinese (`schinese`)
3. Traditional Chinese (`tchinese`)
4. Japanese (`japanese`)
5. Korean (`koreana`)
6. German (`german`)
7. Spanish (Spain) (`spanish`)
8. French (`french`)
9. Portuguese (Brazil) (`brazilian`)
10. Russian (`russian`)

分批交付时固定为：英文；简中与繁中；日语、韩语与德语；西班牙语、法语与巴西葡萄牙语；
最后俄语。未经维护者明确要求，不得在中间插入其他语言。

2026-09-06 通过 Steam Workshop 公开页的 `l=<language>` 参数逐项核对条目
`3792968111`。以下第一行标题是线上基线，翻译无误时必须逐字保留：

```text
English: Pal Insight: Quick Stack - Move Backpack Items to Storage with One Key
Simplified Chinese: Pal Insight: Quick Stack - 背包物品一键收纳
Traditional Chinese: Pal Insight: Quick Stack - 背包物品一鍵收納
Japanese: Pal Insight: Quick Stack - バックパックのアイテムをワンキー収納
Korean: Pal Insight: Quick Stack - 가방 아이템 원키 정리
German: Pal Insight: Quick Stack – Rucksackgegenstände per Tastendruck einlagern
Spanish (Spain): Pal Insight: Quick Stack - Guarda los objetos de la mochila con una tecla
French: Pal Insight: Quick Stack – Rangez les objets du sac en une seule touche
Portuguese (Brazil): Pal Insight: Quick Stack - Guarde os itens da mochila com uma tecla
Russian: Pal Insight: Quick Stack — Сложить предметы из рюкзака одной клавишей
```

同次核对中，Thai、Italian、Polish、Turkish 和 Vietnamese 均回退为英文标题，不能据此
声称 Stack 已有这些 Steam Description 本地化，也不能把它们插入上述交付顺序。

更新主 Description 前，必须读取线上条目的原始 BBCode。优先读取作者编辑字段；无法
登录编辑页时，可读取 Steam Workshop API 的条目 `description` 原始字段，并记录条目 ID、
返回时间和字符数。公开页渲染文本、自动翻译文本和仓库旧副本不能代替线上 BBCode。
以线上 BBCode 为排版底稿，保留已有图片、链接、标题和列表，只做当前版本所需的最小
修改。修改后的完整 BBCode 必须先用纯文本代码块交给维护者审核；确认后才可更新线上，
并将获批全文同步回 `packaging/workshop/description.md`。

Steam Description 的 8000 限制是硬门禁，7500 是内部发布预算。每个语言版本都必须对
最终待粘贴的完整源码同时检查字符数和 UTF-8 字节数（换行按 CRLF 计算），两者都必须
小于等于 7500 才能正常交付；任何一项超过 8000 都是无条件失败。交付前还必须检查
BBCode 标签配对及规定图片是否完整，并逐份报告字符数、UTF-8 字节数和剩余额度，不能
只检查可见字符数。需要压缩本地化文案时，优先删减重复正文，不得为了腾额度改动翻译
正确的第一行 `[h1]...[/h1]`。
每次处理前后都要比较第一行；如确需修正 `h1`，必须向维护者单独列出修改前、修改后和
原因，不能静默修改。

发布器读取同目录的 `workshop_path.txt`。准备时：

1. 解析并显示实际 Workshop 根目录，目标必须是其下的 `3792968111`；不得凭记忆使用
   某个带日期的暂存路径。
2. 备份并保留目标目录的 `.workshop.json`。必须核对：
   - `publishedfileid` 是 `3792968111`；
   - `last_published_version` 是上一公开版本；
   - 正式 `Info.json` 的 `Version` 是待发布新版本，且两者不同。
3. 用 `release/workshop/PalInsightQuickStack` 同步条目目录。同步前比较双方文件清单；
   如存在仅在目标端的额外文件，先报告并取得删除许可，不能直接镜像删除。
4. 同步后逐文件比较 SHA-256；除 `.workshop.json` 外，清单和内容必须与正式包一致。
5. 重新加载或重新启动发布器，再次核对条目、版本、依赖、标签、缩略图和安装规则。
6. 给维护者提供已审核的完整 BBCode，并打开正确发布器及包目录。
7. 维护者点击 `Upload To Steam` 并完成最终提交。上传后核对 Workshop 页面版本、
   更新时间、改动说明、依赖和文件大小。

仅仅“打开发布器”不算准备完成；未完成条目 ID、版本差、文件清单和哈希核对时，必须
明确说明尚未就绪。

## 10. 发布后核验与记录

1. 重新打开三个公开页面，核对版本、文件、Changelog、说明、依赖和时间。
2. 交叉验证 Nexus、CurseForge、Steam 与仓库 `CHANGELOG.md` 的事实一致性。
3. 对处于扫描或审核中的渠道继续报告真实状态；未经请求不反复上传。
4. 新建 `docs/RELEASE-<version>-<YYYY-MM-DD>.md`，至少记录：
   - 版本升级 UTC 时间及来源；
   - Changelog 审核结论；
   - 发布提交、push 和 tag 状态；
   - 四个 ZIP 的文件名、SHA-256 和平台文件 ID；
   - Steam 条目 ID 及包目录；
   - 各平台最终状态和仍待人工处理的事项；
   - 实际执行的检查及未完成的实机验证。
5. 发布记录本身需要 commit/push 时，再遵守独立授权和提交前展示要求。

## 异常处理

- 任一门禁、哈希、版本或条目 ID 不一致：停止，不上传。
- 一个渠道已发布而另一渠道失败：保留已完成事实，停止后续危险动作并报告部分发布
  状态；不要谎称整体完成。
- 浏览器表单丢失：先查看公开文件列表，确认是否已经保存，避免重复上传。
- 上传显示 `0 B` 或 `Failed to fetch`：先核对绝对路径和文件存在性，再重试。
- 发布器显示旧版本：检查 `workshop_path.txt` 指向的实际条目目录，先同步和哈希验证，
  不要只重开程序。
- 平台要求删除、归档、重传或覆盖：明确说明对象与后果，并取得对应确认。

## 完成定义

发布任务只有在以下结果均被准确交付后才结束：

- 最终 Changelog 已由维护者审核确认；
- 版本、UTC 时间、17 种游戏内语言和平台载荷一致；
- Git、构建、包体及哈希状态已记录；
- Nexus 的 Main 与 Game Pass 文件状态已核验；
- CurseForge 两个文件的真实审核/公开状态已核验；
- CurseForge Source 标签保持“源码不公开”，Description 的完整原始代码已审核；
- Steam 发布器目录已正确准备，且维护者的最终上传状态已记录；
- 公开说明、感谢名单、依赖、兼容性与已知限制已经检查；
- Nexus Description 与 Sticky Post 的完整 BBCode 已审核，并分别核对线上结果；
- 发布记录清楚区分已完成、审核中、未验证和需要维护者处理的事项。
