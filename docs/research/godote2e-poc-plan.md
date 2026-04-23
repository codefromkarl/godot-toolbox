# GodotE2E PoC Plan

## Snapshot

- 日期：`2026-04-23`
- 目标：评估 `GodotE2E` 是否值得作为 `godot-toolbox` 的候选 pack 继续推进
- 结论：值得做 **pack 级 PoC**，但暂不进入 `base`

## Why This Candidate

`GodotE2E` 当前最贴合仓库主线的地方，不是“功能很多”，而是它直接补在：

- agent 可驱动的黑盒回归
- CI 场景下的 UI / 交互端到端验证
- 与 `gdUnit4` 的能力互补

当前工具箱已经具备：

- 静态检查
- 布局检查
- bootstrap 产物验证
- `gdUnit4` smoke

但还缺“从外部进程驱动 Godot 游戏并做端到端断言”这一层。
`GodotE2E` 正好落在这个空白区。

## Selection Framework Fit

### 自动化价值

高。

它明确面向 out-of-process E2E，且以 Python/pytest 作为测试入口，适合 CI 和 agent 工作流。

### 复用面

中高。

不是所有 Godot 项目都需要 E2E，但一旦项目有 UI、输入映射、主流程回归、菜单交互需求，它就有稳定价值。

### 领域耦合

低到中。

它更像测试能力，而不是业务能力。
真正的项目真相仍然留在 Godot 项目本身。

### 维护成本

中。

它会引入 Python 侧依赖、Godot 启动参数约定以及 CI 运行面，但相比把测试逻辑塞进项目内部，这种成本是可控的。

### 真相边界风险

低。

它不应该接管项目内容、资源或编辑器工作流，只是暴露自动化测试接口。

## Why Not Base

暂不适合进 `base`，原因很明确：

- 会引入新的 Python 侧测试栈
- 会增加 CI 运行时间
- 不是每个项目 Day 0 都需要 E2E
- 对许多原型项目来说，`gdUnit4` smoke 已经足够

所以它更适合作为：

- `automation`
- 或 `e2e`

这样的可选 pack。

## Proposed Shape

建议先按一个独立候选 pack 设计：

```text
packs/automation/
  godot/
    addons/
      <godot_e2e_addon_if_vendored>
  python/
    requirements-e2e.txt
  examples/
    tests/
      test_smoke_ui.py
  README.md
```

说明：

- 如果 `GodotE2E` 的 Godot 侧和 Python 侧是分离的，不应强行全塞进 `godot/addons/`
- Python 依赖应与主模板依赖解耦
- pack 的验证入口应独立于 `base` 默认验证链

## PoC Success Criteria

PoC 不要求完整集成，只要求证明这条路径成立。

最小成功标准：

1. 能启动一个由 `godot-toolbox` bootstrap 出来的临时项目
2. 能通过 `GodotE2E` 建立连接
3. 能做至少一条简单断言，例如：
   - 等待根节点出现
   - 切换场景
   - 模拟输入
   - 读取一个节点属性
4. 能在 CI 里跑通一条最小 E2E 用例

## PoC Non-Goals

第一轮 PoC 不做这些：

- 不纳入 `base`
- 不强行修改现有 `verify_bootstrap_flow.sh`
- 不承诺所有 pack 组合都支持 E2E
- 不引入复杂测试矩阵

## Risks

主要风险有 4 个：

1. Python 侧依赖管理变复杂
2. Godot 启动参数与 Autoload 约定需要统一
3. CI 运行时间增长
4. Linux 无显示环境下可能仍需要 `xvfb-run` 或额外 runner 适配

## Recommended Next Step

下一步不是直接 vendoring，而是先做一个小 PoC 分支：

1. 为 `GodotE2E` 建一个候选 pack 目录草稿
2. 写一条最小 E2E 测试
3. 在临时 bootstrap 项目上跑通
4. 再决定是否进入 `packs.manifest.json`

## Decision

当前结论：

- **值得推进**
- **进入候选 pack PoC**
- **暂不进入 `base`**
- **暂不修改现有默认验证链**
