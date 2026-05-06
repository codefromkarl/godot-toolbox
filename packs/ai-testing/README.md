# AI Testing Optional Pack

AI 自动化测试框架 pack，提供策略驱动探索、覆盖率追踪和 Bug 发现模板。构建在 automation pack 的 godot-e2e TCP 桥接之上。

## 架构分层

```
Layer 3: ai-testing pack  (Python 策略、runner、覆盖率、Bug 发现)
         │  GodotE2EEnv implements TestEnvironment protocol
Layer 2: automation pack  (godot-e2e Python TCP client)
         │  JSON commands over length-prefixed binary framing
Layer 1: automation pack  (AutomationServer autoload in Godot)
```

## 当前内容

### Python 模块 (`python/ai_testing/`)

- **contracts.py** -- `TestEnvironment` 协议、`StepResult`、`EpisodeResult`、`Policy` 协议
- **policies.py** -- `RandomPolicy`、`ScriptedPolicy`、`HeuristicPolicy`（抽象基类）、`EpsilonGreedyPolicy`
- **runner.py** -- `EpisodeRunner`（编排 episode、收集遥测、写 artifact）
- **summary_report.py** -- Markdown/JSON 报告生成
- **artifacts.py** -- Episode artifact 目录结构管理
- **coverage_tracker.py** -- 探索覆盖率追踪（observation keys + event types）
- **bug_discovery.py** -- 后置 Bug 候选发现（stuck state / reward anomaly / unexplored action）
- **scenario_variant.py** -- 参数化场景变体生成（Cartesian product）
- **godot_e2e_env.py** -- `TestEnvironment` ↔ godot-e2e TCP 桥接适配器

### GDScript (`godot/addons/godot_toolbox_architecture/ai_testing/`)

- **ai_testing.gd** -- 最小 autoload stub（标记 pack 已启用）
- **interaction_test_helper.gd** -- 输入模拟、UI 交互、截图工具（`class_name InteractionTestHelper`）

### 示例 (`examples/`)

- **environments/toy_button_env.py** -- 最小 `TestEnvironment` 示例（纯 Python）
- **tests/** -- 框架 smoke 测试（无需 Godot 运行时）

## 依赖

- **automation** pack（提供 godot-e2e TCP 桥接基础设施）
- Python 依赖见 `python/requirements.txt`

## 使用方式

### 纯 Python 框架 smoke（无需 Godot）

```bash
bash packs/ai-testing/scripts/run_ai_testing_smoke.sh
```

### 实现 TestEnvironment 消费框架

```python
from ai_testing.contracts import TestEnvironment, StepResult, EpisodeResult

class MyGameEnv:
    """Implement the TestEnvironment protocol for your game."""
    action_space = ("move", "attack", "defend")

    def reset(self, seed=None):
        return {"hp": 100, "valid_actions": list(self.action_space)}

    def step(self, action):
        # ... interact with your game ...
        return StepResult(observation={}, reward=0.0, done=False, info={})

    @property
    def result(self):
        return self._result
```

### 连接 Godot 运行时

```python
from godot_e2e import GodotE2E
from ai_testing import GodotE2EEnv, EpisodeRunner, EpisodeConfig, RandomPolicy

with GodotE2E.launch(project_path) as client:
    env = GodotE2EEnv(
        client=client,
        actions={"click": lambda c: c.click_node("/root/Main/Button")},
    )
    runner = EpisodeRunner("build/ai-testing")
    runner.run_episode(
        EpisodeConfig("demo-001", "button", "random"),
        env, RandomPolicy(seed=42),
    )
    runner.finalize()
```

## 硬约束

- `default=false` -- 不参与默认 bootstrap
- **不接入** 默认验证链
- 只能通过显式 `--packs=ai-testing` 进入生成项目
- 消费者实现自己的 `TestEnvironment` 和 `HeuristicPolicy`

## 仓库内验证

```bash
bash scripts/verify_ai_testing_pack.sh
```
