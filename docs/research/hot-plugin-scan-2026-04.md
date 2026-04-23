# Hot Plugin Scan 2026-04

## Snapshot

这是 `2026-04` 的最小可用扫描快照。

- 目标：优先收敛已经确认存在活跃信号、且和 `godot-toolbox` 路线相符的候选
- 范围：Godot 4.x 生态
- 方法：优先看 `Godot Asset Library`、GitHub 仓库主页、GitHub release 信号

## 结论先行

本轮不建议新增进入 `base`。

最值得推进 pack 级 PoC 的候选只有 3 个：

1. `GodotE2E`
2. `G.U.I.D.E`
3. `Dialogue Manager`

其余候选更适合作为外部参考或明确不纳入。

## 分级短名单

### Base

#### 本轮无新增推荐

原因：

- 当前 `base = gdUnit4 + godot-gdscript-toolkit` 的自动化价值和低耦合度仍然最优
- 本轮看到的新候选，要么与现有基线重叠，要么需要额外运行时 / 强编辑器耦合，不适合作为所有项目的默认 Day 0 依赖

### New Or Existing Pack

#### P1: `GodotE2E`

- 分类：`new pack`
- 建议 pack：`automation` 或 `e2e`
- 判断：值得做第一优先 PoC
- 原因：
  - 明确面向端到端 UI 自动化，和当前仓库“把当前稳定推进到持续稳定”的主线高度一致
  - 比纯编辑器辅助插件更贴近 agent / CI / 回归自动化
  - 不适合进 `base`，因为会引入额外测试栈和使用门槛
- 内化建议：
  - 先做可选 pack
  - 只验证最小场景：启动项目、驱动 UI、断言结果
- 来源：
  - Godot Asset Library：`Godot UI Automation`
  - GitHub：`RandallLiuXin/godot-e2e`

#### P1: `G.U.I.D.E`

- 分类：`new pack`
- 建议 pack：`ui-input`
- 判断：值得做第一优先 PoC
- 原因：
  - 解决输入设备识别、图标提示和 UI 输入映射表达，复用面比单一玩法插件更广
  - 适合做“模板化 UI 输入工作流”能力，而不是业务逻辑能力
  - 不适合进 `base`，因为并非所有项目都需要
- 内化建议：
  - 做独立 pack
  - 先验证和现有 starter 的兼容性，以及是否能保持内容真相仍在项目内
- 来源：
  - Godot Asset Library：`G.U.I.D.E - Godot Unified Input Detection Engine`
  - GitHub：`godotneers/G.U.I.D.E`

#### P2: `Dialogue Manager`

- 分类：`new pack`
- 建议 pack：`dialogue`
- 判断：适合做第二优先级 PoC
- 原因：
  - Godot 4 兼容明确，脚本化和文本驱动特征比重编辑器型对话系统更适合 `godot-toolbox`
  - 适合需要对话能力但不想强绑大型 narrative 编辑器的项目
  - 不适合进 `base`，因为领域面仍偏内容生产
- 内化建议：
  - 优先于 `Dialogic` 进入候选池
  - 只做可选 pack，不进默认基线
- 来源：
  - Godot Asset Library：`Dialogue Manager`
  - GitHub：`nathanhoad/godot_dialogue_manager`

### External Reference

#### P2: `LimboAI`

- 分类：`external-reference`
- 关联方向：可作为未来 `stateful` / `behavior` 路线的高级参考
- 判断：先观察，不直接纳入
- 原因：
  - 行为树与状态机能力强，生态认知度也高
  - 但相较当前仓库的 pack 策略，它的原生依赖和架构接管程度更高
  - 更适合作为“复杂 AI 项目参考方案”，而不是通用工具箱默认能力
- 来源：
  - Godot Asset Library：`LimboAI`
  - GitHub：`limbonaut/limboai`

#### P3: `Importality`

- 分类：`external-reference`
- 关联方向：资源管线 / 美术导入工作流
- 判断：记录为资源管线方向参考，不进入近期主线
- 原因：
  - 资源导入和模板化工作流有明显价值
  - 但它更偏内容生产效率，不是当前仓库最紧迫的“持续稳定”主线
  - 适合等 CI、产物验证、pack 策略更稳后再评估
- 来源：
  - Godot Asset Library：`Importality`
  - GitHub：`nklbdev/godot-importality`

### Not Recommended

#### P2: `Godot-MCP`

- 分类：`not-recommended`
- 判断：不建议内化到当前仓库
- 原因：
  - 方向上非常贴近 AI / agent 协作，但它依赖外部运行时、MCP 服务和桌面协作环境
  - 更像“开发环境能力”，不是适合 vendoring 到每个 Godot 项目的模板能力
  - 适合作为外部开发配套，而不是 `godot-toolbox` 的项目 pack
- 来源：
  - Godot Asset Library：`Godot-MCP`
  - GitHub：`ee0pdt/Godot-MCP`

#### P2: `Dialogic`

- 分类：`not-recommended`
- 判断：本轮不建议纳入
- 原因：
  - 生态成熟、功能丰富，但编辑器工作流和内容系统较重
  - 对 `godot-toolbox` 来说，真相边界和维护面都高于 `Dialogue Manager`
  - 如果未来真的要支持大型 narrative authoring，再单独评估也不晚
- 来源：
  - Godot Asset Library：`Dialogic`
  - GitHub：`dialogic-godot/dialogic`

## 推荐顺序

如果只做最小下一步，建议顺序如下：

1. `GodotE2E`
2. `G.U.I.D.E`
3. `Dialogue Manager`
4. `LimboAI`
5. `Importality`

## 对当前仓库的直接建议

本轮扫描后的最小结论是：

- `base` 暂不变
- 可以考虑新增两个候选 pack 方向：
  - `automation/e2e`
  - `ui-input`
- `dialogue` 方向可以保留为第二梯队
- `AI / MCP` 类插件暂不做 vendoring，只作为外部开发环境参考

## 来源类型

本轮只使用了以下来源类型：

- `Godot Asset Library`
- GitHub 仓库主页
- GitHub release / tag 信号

## 候选清单速记

| 候选 | 优先级 | 分级 | 建议 |
| --- | --- | --- | --- |
| GodotE2E | P1 | new pack | 先做 `automation/e2e` PoC |
| G.U.I.D.E | P1 | new pack | 先做 `ui-input` PoC |
| Dialogue Manager | P2 | new pack | 放入 `dialogue` 候选池 |
| LimboAI | P2 | external-reference | 先观察，不 vendoring |
| Importality | P3 | external-reference | 记录为资源管线参考 |
| Godot-MCP | P2 | not-recommended | 不进入项目 pack |
| Dialogic | P2 | not-recommended | 暂不纳入 |
