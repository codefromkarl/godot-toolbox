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

### `ai-testing`

- 插件：无，自研 architecture-test-kit
- 状态：可选 pack，默认不启用
- 用途：策略驱动探索测试、覆盖率追踪和 Bug 发现模板
- 适合：需要 AI 驱动的游戏机制探索、覆盖率引导的自动化测试或策略驱动的压力测试的项目
- 边界：提供测试框架和策略原语，不接管 gameplay 真相、存档、数据或主场景；消费者实现自己的 `TestEnvironment` 和 `HeuristicPolicy`
- 依赖：`automation` pack（提供 godot-e2e TCP 桥接）

### `input`

- 插件：`G.U.I.D.E`
- 版本：`0.12.0`
- 状态：可选 pack，默认不启用
- 用途：输入设备检测、映射上下文、重映射与输入提示表达
- 适合：需要跨键鼠、手柄或触屏表达输入语义的项目
- 边界：提供输入建模工具，不接管项目具体 action map、玩法输入真相或 UI 文案

### `rules-events-core`

- 插件：无，自研 architecture pack
- 状态：可选 pack，默认不启用
- 用途：事件、条件、效果执行 spine
- 适合：quest、dialogue、simulation hooks 或 gameplay trigger 需要共享事件边界的项目
- 边界：不替代 quest/dialogue/inventory 插件，不提供大型视觉脚本系统

### `ui-game-shell`

- 插件：无，自研 optional pack
- 状态：可选 pack，默认不启用
- 用途：菜单、暂停、modal、loading shell primitives
- 适合：需要 app shell 起点但不能让第三方模板接管主场景和业务状态的项目
- 边界：不接管 `run/main_scene`、FlowCore stack、save truth 或项目 UI 文案
- Recipe：`docs/ui-game-shell-recipe.md` 定义从 shell candidate 吸收菜单/暂停/设置/加载思路的受控路线

### `inventory`

- 插件：`GLoot`
- 版本：`v3.0.1`
- 状态：可选 pack，默认不启用
- 来源：<https://github.com/peter-kish/gloot>
- 用途：背包、物品槽、装备槽与 inventory authoring/runtime primitives
- 适合：RPG、模拟、战利品或装备系统需要成熟背包插件的项目
- 边界：不接管 RPG item truth、装备规则、奖励结算或 `save-core` snapshot 映射

### `quest`

- 插件：`QuestSystem`
- 版本：`2.0.1.4_4`
- 状态：可选 pack，默认不启用
- 来源：<https://github.com/shomykohai/quest-system>
- 用途：资源化 quest、objective、quest pool 与任务运行时
- 适合：需要任务 authoring/runtime，但仍希望通过 `rules-events-core` 和 `save-core` 持有项目真相的 RPG/冒险项目
- 边界：不接管 campaign truth、剧情状态、任务持久化格式或 gameplay event 语义

### `ai-behavior`

- 插件：`Beehave`
- 版本：`v2.9.2`
- 状态：可选 pack，默认不启用
- 来源：<https://github.com/bitbrain/beehave>
- 用途：行为树 AI authoring、运行时和调试
- 适合：NPC、敌人或模拟 actor 行为复杂到需要行为树的项目
- 边界：不接管基础回合制战斗 AI、回合顺序、奖励结算或存档真相

### `save-state-lite`

- 插件：`SaveState Lite`
- 版本：`v1.2.0`
- 状态：可选 pack，默认不启用
- 来源：<https://github.com/youssof20/savestate>
- 用途：SaveManager、atomic writer、save browser、saveable component 参考实现
- 适合：需要高级存档工具或组件式保存参考的项目
- 边界：与 `save-core` 互斥，因为双方都定义 `SaveSlot` 全局类；默认 RPG 模板路径仍使用 `save-core`

## Candidate Packs

Dialogic is tracked only as a future dialogue candidate/reference input in `docs/dialogue-pack-candidate-plan.md`; it is not vendored, not default-enabled, and cannot own campaign truth, save schema, or event truth.

### `dialogue`

- 插件：`Dialogue Manager`
- 版本：`v3.10.4`
- 状态：可选 pack，默认不启用
- 来源：<https://github.com/nathanhoad/godot_dialogue_manager>
- 用途：对话图/文本资源 authoring、运行时 line playback、choices 和 conversation-local variables
- 适合：需要对话 authoring/runtime，但仍希望通过 `rules-events-core`、`data-core` 和 `save-core` 持有项目真相的 RPG/冒险项目
- 边界：不接管 campaign truth、全局剧情进度、存档格式、持久事件历史或 quest/inventory 真相

### `shell`

- 插件：`Maaack's Game Template`
- 版本：`1.4.6`
- 状态：候选 pack，已锁定 upstream，但不在 `packs.manifest.json`
- 用途：主菜单、设置菜单、暂停菜单、Credits、加载页、开场页、输入映射和持久设置参考
- 适合：已有项目选择性吸收 app shell 能力，或新项目评估菜单/设置壳层起步方案
- 边界：不接管业务运行时、主场景、autoload、存档真相或玩法状态
- Recipe：`docs/ui-game-shell-recipe.md` 明确其仅为 candidate/reference，默认产品化路线是 `ui-game-shell`

## Excluded

### `gdterm`

- 原因：价值主要在编辑器内终端
- 结论：agent 已有 shell，不值得引入额外原生扩展维护面

### `UITextTokens Validator`

- 原因：设计思想正确，但实现强绑定单一项目的 `ui_text_tokens.gd`
- 结论：后续可抽象成 repo-specific validator scaffold，而不是直接 vendoring
