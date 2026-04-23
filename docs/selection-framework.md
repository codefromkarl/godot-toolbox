# Selection Framework

## Purpose

这个文档定义 `godot-toolbox` 如何做“合理选型”。

目标不是收集最多的模板和插件，而是为后续 Godot 项目维持一套：

- 可自动化
- 可复用
- 可验证
- 可升级

的工程基线。

## Five Axes

每个候选模板或插件都先沿这 5 个维度判断：

1. 自动化价值
   - 是否适合脚本化、headless、CI、agent 调用
2. 复用面
   - 是否能覆盖大多数 Godot 项目，而不是只服务单一玩法
3. 领域耦合
   - 是否强绑定某个项目的业务模型、UI 文案、玩法结构
4. 维护成本
   - 升级、兼容、排错和 patch 的成本是否可控
5. 真相边界
   - 是否会把关键业务真相藏进第三方插件或不可见配置里

## Admission Gates

### 进入 `base`

必须同时满足：

- 自动化价值高
- 复用面广
- 领域耦合低
- 有稳定的本地验证路径
- 不要求重度人工编辑器操作才能体现价值

### 进入可选 `pack`

满足以下大部分即可：

- 在一个明确主题内价值高
- 不适合所有项目默认启用
- 可以通过场景/团队需要选择性叠加
- 不会强行接管项目核心真相

### 暂不纳入

命中以下任一项则默认不纳入：

- 主要价值只存在于人工编辑器交互
- 强绑定单一项目约定
- 来源或版本无法固定
- 带来明显维护面，但收益不足

## Current Decisions

### Base

- `godot-gdscript-toolkit`
  - 原因：最适合自动化 lint/format，能直接进入 CI 和 agent 工作流
- `gdUnit4`
  - 原因：最适合做 repo-owned smoke 和回归入口

### Optional Packs

- `Godot Doctor` → `validation`
  - 原因：把资源/场景约束变成可执行验证，但不是所有项目都需要
- `Signal Lens` → `debug`
  - 原因：调试价值高，但主要是开发期工具
- `Godot State Charts` → `stateful`
  - 原因：适合状态图架构项目，但不应强绑到所有 starter
- `Sparkle Lite` → `juice`
  - 原因：表现层价值明显，但属于特定主题能力

### Excluded / To Be Abstracted

- `gdterm`
  - 原因：主要提供编辑器内终端，agent 已有 shell，不值得引入额外维护面
- `UITextTokens Validator`
  - 原因：思路正确，但实现强绑定单一项目文本协议
  - 处理：后续抽象成 `repo-specific validator scaffold`

## Selection Workflow

引入一个新候选时，按以下顺序执行：

1. 先判断它解决的是 `base` 问题还是 `pack` 问题
2. 再判断它是否有稳定 upstream 与可锁定版本
3. 再判断它是否能被脚本验证
4. 最后决定：
   - 进入 `base`
   - 进入某个 `pack`
   - 只保留为外部参考
   - 不纳入
