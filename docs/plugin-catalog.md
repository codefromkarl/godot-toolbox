# Plugin Catalog

## Base

### `gdUnit4`

- 角色：Godot 测试框架
- 版本：`6.1.2`
- 状态：默认纳入 `base`
- 原因：最适合做 repo-owned smoke 与 agent 可执行验证

### `godot-gdscript-toolkit`

- 角色：GDScript lint/format 工具链
- 版本：`4.5.0`
- 状态：默认纳入 `base`
- 原因：适合 headless、脚本化、CI 和 agent 工作流

## Optional Packs

### `validation`

- 插件：`Godot Doctor`
- 版本：`2.1.2`
- 用途：场景/资源规则校验
- 适合：需要把资源约束转成 CLI 可验证 contract 的项目

### `debug`

- 插件：`Signal Lens`
- 版本：`1.4.1`
- 用途：运行时 signal 图调试
- 适合：大量依赖 signal 编排的项目

### `stateful`

- 插件：`Godot State Charts`
- 版本：`0.22.3`
- 用途：显式状态机/状态图架构
- 适合：行为复杂、需要清晰状态转换语义的项目

### `juice`

- 插件：`Sparkle Lite`
- 版本：`1.0.0`
- 用途：打击感、反馈编排、表现层 authoring
- 适合：需要快速建立 game-feel 工作流的项目

### `automation`

- 插件：`GodotE2E`
- 版本：`1.1.0`
- 状态：可选 pack，默认不启用
- 用途：Python/pytest 驱动的运行时 UI/E2E 自动化
- 适合：需要从外部进程启动 Godot、等待节点/信号、断言运行中 UI 或主流程的项目
- 边界：只提供测试自动化入口，不接管玩法、存档、数据或主场景真相

### `input`

- 插件：`G.U.I.D.E`
- 版本：`0.12.0`
- 状态：可选 pack，默认不启用
- 用途：输入设备检测、映射上下文、重映射与输入提示表达
- 适合：需要跨键鼠、手柄或触屏表达输入语义的项目
- 边界：提供输入建模工具，不接管项目具体 action map、玩法输入真相或 UI 文案

## Candidate Packs

### `shell`

- 插件：`Maaack's Game Template`
- 版本：`1.4.6`
- 状态：候选 pack，已锁定 upstream，但不在 `packs.manifest.json`
- 用途：主菜单、设置菜单、暂停菜单、Credits、加载页、开场页、输入映射和持久设置参考
- 适合：已有项目选择性吸收 app shell 能力，或新项目评估菜单/设置壳层起步方案
- 边界：不接管业务运行时、主场景、autoload、存档真相或玩法状态

## Excluded

### `gdterm`

- 原因：价值主要在编辑器内终端
- 结论：agent 已有 shell，不值得引入额外原生扩展维护面

### `UITextTokens Validator`

- 原因：设计思想正确，但实现强绑定单一项目的 `ui_text_tokens.gd`
- 结论：后续可抽象成 repo-specific validator scaffold，而不是直接 vendoring
