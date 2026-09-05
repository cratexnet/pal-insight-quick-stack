# 面向玩家的 Changelog / Release Notes 写作原则

## 研究问题

为 Quick Stack 1.2.0 判断：发布说明应该记录什么、排除什么；应该按
`Added / Changed / Fixed` 还是按功能分组；以及当前候选条目中哪些真正属于
1.2.0。

## 结论

1. **比较基线必须是玩家能下载到的上一公开版本，而不是开发分支、提交或开发过程。**
   Changelog 记录的是版本之间“值得用户知道的差异”，不是实现步骤。Keep a
   Changelog 明确把 changelog 定义为每个版本的、经过筛选的显著变化列表，并反对
   直接把提交日志当 changelog，因为提交描述的是源码演进步骤，而 changelog 应把
   多个步骤归纳成对最终用户清楚的差异。
   [Keep a Changelog — What is a changelog / Commit log diffs](https://keepachangelog.com/en/1.1.0/)
2. **条目以用户可观察的能力、行为变化、兼容性风险为单位。** 新功能写“现在能做
   什么”，必要时补充默认状态、入口和安全语义；已有功能的真实行为变化才放
   `Changed`；玩家在上一公开版可复现、这次被修复的问题才放 `Fixed`。开发中出现
   又在发布前修掉的错位、白块、文案迭代、输入回归等不属于版本差异。
3. **Quick Stack 1.2.0 的仓库 Changelog 应继续采用 Keep a Changelog 分类，且本次
   只需要 `Added`。** Keep a Changelog 推荐把同类变化分组，并定义 `Added` 为新功能、
   `Changed` 为已有功能变化、`Fixed` 为错误修复。没有相应显著变化时，不应为了版式
   强行创建空的或含混的 `Changed / Fixed`。
   [Keep a Changelog — Guiding principles and types of changes](https://keepachangelog.com/en/1.1.0/)
4. **平台 Release Notes 可以比仓库 Changelog 更像产品介绍，但两者不能改变事实
   基线。** GitHub 允许按自定义标签建立类别，也要求发布前检查自动生成内容是否只
   包含应出现的信息；VS Code 和 Godot 的官方发布页则先给用户价值摘要，再按产品
   区域或功能主题展开。因此，长版本可以按功能分组；只有一个主题的 1.2.0 用两条
   `Added` 更清楚，不必拆成“自动出售 / 保留列表 / 设置与结果”三个小节。
   [GitHub Docs — Automatically generated release notes](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes),
   [VS Code 1.110 release notes](https://code.visualstudio.com/updates/v1_110),
   [Godot 4.4 release notes](https://godotengine.org/releases/4.4/index.html)
5. **1.2.0 是合理的 minor release。** SemVer 规定，向后兼容地加入新功能应提升
   minor 版本；minor release 也可以同时包含 patch 级修复。不过“可以包含修复”不
   意味着应把发布前内部修复写成对外修复。
   [Semantic Versioning 2.0.0, rules 6–8](https://semver.org/spec/v2.0.0.html)

## 优秀项目呈现出的共同模式

### Keep a Changelog：仓库事实记录

- 以版本和日期为边界，最新版本在前。
- 只记录 notable changes，并按变化类型归类。
- 条目描述版本间的最终差异，不复制 commit/PR 流水账。
- 重大兼容性、弃用和移除必须醒目；小到不影响用户的内部清理可以省略。

来源：[Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/)

### VS Code：先给价值摘要，再按产品区域展开

VS Code 的月度发布说明先用一段话概括本版给用户带来的价值，再列出可扫描的亮点，
正文按 `Agent controls`、`Accessibility`、`Editor Experience` 等产品区域组织。
具体功能会说明“用户现在能做什么”以及必要的设置入口，而不是描述实现过程。

来源：[VS Code 1.110 release notes](https://code.visualstudio.com/updates/v1_110)

### Godot：功能名 + 用户收益 + 必要限制

Godot 4.4 先展示 Highlights，随后按 General、Platforms、Scripting、Systems 等区域
展开。单个亮点会说明它解决的用户问题、如何启用，以及平台限制或升级注意事项。
这说明“默认关闭”“需要在哪开启”“仅支持哪些范围”可以写，但前提是它们帮助用户
正确使用或安全升级。

来源：[Godot 4.4 release notes](https://godotengine.org/releases/4.4/index.html)

### BepInEx：风险优先，流水账退居其次

BepInEx 的普通维护版可以使用精简的 `What's Changed` 并链接完整比较；但重大预发布
版本会先放兼容性警告和升级建议，再列 changelog。这说明类别和篇幅要随发布风险
调整：没有升级风险的小型模组 minor release 不需要仿照大版本堆叠章节。

来源：[BepInEx official releases](https://github.com/BepInEx/BepInEx/releases)

## 应记录与应排除

| 判断 | 应记录 | 应排除 |
|---|---|---|
| 用户价值 | 新增可完成的任务、可配置行为、可见结果 | 内部函数、数据表、RPC、缓存和布局实现 |
| 使用方法 | 新入口、默认状态、选择语义、必要范围 | 已有入口的重复说明、完整使用手册 |
| 行为变化 | 相对上一公开版真实改变的既有行为 | 新功能内部本来就应具备的实现顺序，被伪装成独立 `Changed` |
| 修复 | 上一公开版用户能遇到的 bug | 开发期间出现并在发布前消失的错位、白块、崩溃、措辞调整 |
| 安全/升级 | 破坏性变化、迁移步骤、已知限制、数据风险 | 与本版无关的长期设计不变量 |
| 精度 | 能帮助用户理解范围的数量和类别 | 对使用没有帮助的静态 ID、类名和技术证据 |

## 功能分组还是 Added / Changed / Fixed

两种结构服务不同目的：

- **`CHANGELOG.md`：** 版本历史和事实索引，采用 `Added / Changed / Fixed` 最稳定，
  也与当前项目既有格式一致。
- **商店页 / GitHub Release：** 可以先有一句利益导向摘要，再按功能主题组织；当发布
  只有一个核心主题时，直接复用简短 changelog 即可。
- **不要混用来制造篇幅。** “自动出售”“保留列表”“设置与结果”其实是同一功能的
  能力、控制方式和反馈，不一定各自成为一级分组。对本版而言，两条 `Added` 足以保留
  完整信息，又不会把产品说明写成开发日志。

## Quick Stack 1.2.0 候选条目审计

本地存在两个内容不同、名称都为 `1.1.0` 的包：

- `archive/pre-small-incubator-1.1.0/.../Pal-Insight-Quick-Stack-1.1.0.zip`
  不含自动出售模块；
- `release/nexus/Pal-Insight-Quick-Stack-1.1.0.zip` 已含高价品和弹药自动出售，但不含
  帕鲁球和钓饵自动出售。

SemVer 明确规定已发布版本的内容不得被修改，任何修改都应作为新版本发布。
[Semantic Versioning 2.0.0, rule 3](https://semver.org/spec/v2.0.0.html)
因此最终发布说明必须以**用户实际获得的 1.1.0 下载物**为准，而不能仅以
`v1.1.0` 标签或某个同名本地压缩包为准。以下判断采用当前 `release/nexus` 包作为
上一公开版基线；如果平台上的真实 1.1.0 不同，需要重新计算差异。

| 候选内容 | 决定 | 理由 |
|---|---|---|
| 帕鲁球自动出售 | 保留 | 相对该 1.1.0 基线的新玩家能力 |
| 钓饵自动出售 | 保留 | 相对该 1.1.0 基线的新玩家能力 |
| 两项默认关闭 | 保留，但并入第一条 | 影响升级后的实际行为，可消除“更新后自动卖掉物品”的担忧 |
| 10 种帕鲁球、4 种钓饵的图标保留列表 | 保留 | 是用户控制新功能的主要方式；数量说明支持范围 |
| 勾选表示保留 | 保留，但并入保留列表条目 | 这是容易误解且后果较大的交互语义 |
| 名称跟随游戏语言、覆盖 17 种语言 | 保留，但作为保留列表的从句 | 对新列表是实际可见能力，不值得单独拔高为一个功能 |
| 出售先于归箱 | 可写入第一条的行为描述，不单列 | 对理解结果有价值，但既有出售阶段已经如此，不是独立新增 |
| `Tab → R` 排除物品不出售 | 不作为 `Added` | 是既有安全规则，不是本版新增；如商店页需要，可放功能说明或安全提示 |
| 高价品、弹药自动出售 | 排除 | 当前 1.1.0 发布包已经包含 |
| 设置分类重排 | 排除 | 当前 1.1.0 发布包已经包含，且不是本版核心差异 |
| 自动结果窗口/文字摘要 | 排除 | 既有结果机制，不是本版新增 |
| 持续按键和手柄导航 | 排除 | 当前 1.1.0 发布体验已有；本轮属于开发验证/修整 |
| 行横向位移、白色图块、文案、缓存 `F5` | 排除 | 是 1.2.0 开发期间发现并在发布前修掉的问题，不是上一公开版回归 |

## 推荐的 1.2.0 仓库 Changelog

```markdown
## 1.2.0 - YYYY-MM-DD

### Added

- Added optional automatic selling for Pal Spheres and fishing bait before
  Quick Stack stores the remaining items. Both options are disabled by default.
- Added icon-assisted keep lists for all 10 current Pal Sphere types and 4
  current fishing baits. Checked items stay in the backpack, and item names
  follow the current game language across all 17 supported interface languages.
```

对应中文审阅稿：

```markdown
## 1.2.0 - YYYY-MM-DD

### 新增

- 新增帕鲁球和钓饵自动出售选项，在一键归箱前出售符合条件的物品，再归箱剩余物品。
  两个选项均默认关闭。
- 为当前全部 10 种帕鲁球和 4 种钓饵新增带图标的保留列表。勾选的物品会留在背包中，
  物品名称跟随当前游戏语言，并支持全部 17 种界面语言。
```

这两条分别回答玩家最关心的两个问题：**本版新增了什么能力**，以及**如何准确控制
哪些物品不被出售**。实现顺序、默认状态、本地化和数量被保留下来，但都依附于对应的
玩家能力，没有被包装成虚假的独立新增或修复。

## 发布流程建议

1. 在发布前记录各平台实际公开的 1.1.0 文件哈希，并把它定为差异基线。
2. 以后发布后不替换同版本内容；任何行为变化都升新版本。SemVer 要求版本化包不可变。
3. 仓库 `CHANGELOG.md` 保持简洁事实记录；Steam/Nexus/CurseForge 页面可以在相同两条
   事实之上增加截图和简短使用提示，但不要加入新的“变化”主张。
4. GitHub 自动生成的 PR 列表只作素材，发布前人工筛选。GitHub 官方也要求确认生成
   内容包含全部且仅包含需要的信息。

来源：[Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html)、
[GitHub Docs — Automatically generated release notes](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes)
