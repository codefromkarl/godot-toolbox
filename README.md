# godot-toolbox

面向 AI 工作流的 Godot 工程基线与插件 pack 组装仓库。

这个仓库不预设某一种游戏类型，也不试图自己变成“唯一模板源”。
它的职责是把外部模板思路、外部插件和本地验证脚本整理成可重复的工程基线。

当前的分层是：

- `base`：`gdUnit4` + `godot-gdscript-toolkit` 脚本 + 最小 smoke
- `validation`：`Godot Doctor`
- `debug`：`Signal Lens`
- `stateful`：`Godot State Charts`
- `juice`：`Sparkle Lite`
- `automation`：`GodotE2E`，显式选择时提供运行时 UI/E2E 自动化入口，默认不启用
- `input`：`G.U.I.D.E`，显式选择时提供跨设备输入映射与提示能力，默认不启用
- `flow-core` / `simulation-core` / `data-core` / `save-core` / `flow-test-kit`：自研复杂游戏架构 scaffold，提供 flow、tick、data registry、save snapshot 与 flow smoke fixture 的最小合约
- `rules-events-core`：自研 event / condition / effect spine，给 quest、dialogue、simulation hooks 提供稳定事件边界
- `ui-game-shell`：自研菜单、暂停、modal 与 loading shell primitives，不接管主场景、存档或业务运行时真相
- `inventory`：`GLoot`，显式选择时提供背包、物品槽与装备相关 addon 能力，默认不启用
- `quest`：`QuestSystem`，显式选择时提供资源化任务 addon 能力，默认不启用
- `ai-behavior`：`Beehave`，显式选择时提供行为树 addon 能力，默认不启用
- `save-state-lite`：`SaveState Lite`，显式选择时提供 SaveManager、atomic writer 与 save browser 参考能力，默认不启用

另外保留一个**候选**方向：

- `packs/shell/`：`Maaack's Game Template` 候选 shell pack，当前**不在** `packs.manifest.json`，也**不接管**默认主场景、autoload 或运行时状态
  但其 vendored upstream 已记录在 `upstreams.lock.json`，用于评估菜单、设置、暂停、加载等通用壳层能力

## 设计原则

- 默认只启用适合自动化和 CI 的基线能力。
- 玩法、调试、表现层插件做成可选 pack，不强绑到每个新项目。
- vendored addon 与仓库自有脚本、测试、文档分离管理。
- 选型优先看自动化价值、复用面、耦合度和维护成本，而不是“功能多不多”。

## 仓库定位

- 不是官方 demo 镜像仓库
- 不是单一游戏 starter
- 是 `选择 + 固定版本 + 组装 + 验证 + 发行` 的控制仓库

## 合理选型

选型框架见：

- `docs/selection-framework.md`
- `docs/maintenance-workflow.md`
- `packs.manifest.json`
- `upstreams.lock.json`

## 目录

- `templates/base/`：基础项目模板
- `packs/`：可选插件 pack
- `packs/automation/`：`GodotE2E` 可选 pack，显式选择后注入 `AutomationServer` autoload 并提供 pytest E2E smoke
- `packs/input/`：`G.U.I.D.E` 可选 pack，显式选择后注入 `GUIDE` autoload 并提供输入映射上下文能力
- `packs/inventory/`：`GLoot` 可选 pack，显式选择后提供 inventory/equipment addon
- `packs/quest/`：`QuestSystem` 可选 pack，显式选择后提供 quest addon
- `packs/ai-behavior/`：`Beehave` 可选 pack，显式选择后提供 behavior-tree addon
- `packs/save-state-lite/`：`SaveState Lite` 可选 pack，显式选择后提供 advanced save tooling/reference addon
- `packs/shell/`：候选 shell pack，当前仅锁定 `Maaack's Game Template` 上游与接入策略，不参与默认组装
- `scripts/bootstrap_toolbox_project.sh`：按 pack 组装新项目
- `scripts/verify_bootstrap_flow.sh`：验证真实产物链路，覆盖 bootstrap、headless import 和 `gdUnit4` smoke
- `scripts/verify_game_architecture_packs.sh`：验证自研架构 packs 的 manifest contract、dry-run report、autoload 注入与 bootstrap 产物
- `scripts/verify_automation_pack_poc.sh`：验证 `packs/automation/` opt-in bootstrap 与 E2E smoke，不接入默认验证链
- `scripts/import_plugin_from_upstream.sh`：首次从 upstream 导入插件子树
- `scripts/update_plugin_from_upstream.sh`：基于 lock 文件升级已纳入插件或候选 PoC 的 vendored 子树
- `scripts/verify_toolbox_layout.sh`：校验工具箱布局
- `docs/plugin-catalog.md`：插件目录与建议
- `docs/plugin-integration-standard.md`：插件接入标准
- `docs/maintenance-workflow.md`：维护、导入、升级、组装与验证手册
- `docs/selection-framework.md`：选型框架与当前归类理由
- `docs/research/`：外部参考项目速记、插件探索智能体说明、热门插件扫描快照
- `docs/open-source-architecture-links.md`：复杂游戏架构方向的开源候选链接与当前纳入边界
- `docs/rpg-template-absorption-plan.md`：RPG 模板外部吸收、自研边界与落地计划
- `upstreams.lock.json`：上游来源与版本锁定
- `packs.manifest.json`：pack 定义、默认策略和适用场景

## 组装一个新项目

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/new-project --packs=validation,debug
```

这会：

- 复制 `base` 模板
- 叠加所选 pack 的 `godot/addons/`
- 根据 `packs.manifest.json` 里的 `base_template.default_enabled_plugins` 和 `packs[].plugins` 生成目标项目的 `godot/project.godot`

`bootstrap_toolbox_project.sh` 不再在脚本里硬编码 `pack -> plugin.cfg` 映射。
如果请求的 pack 不存在于 `packs.manifest.json`，脚本会直接报错。

预览某组 pack 会注入哪些 autoload、project settings 和验证入口：

```bash
./scripts/bootstrap_toolbox_project.sh /tmp/preview \
  --packs=flow-core,simulation-core,data-core,save-core,flow-test-kit \
  --dry-run-report
```

RPG 相关 opt-in pack 建议先用 dry-run report 确认依赖、autoload 和冲突关系：

```bash
./scripts/bootstrap_toolbox_project.sh /tmp/preview \
  --packs=inventory,data-core,save-core \
  --dry-run-report

./scripts/bootstrap_toolbox_project.sh /tmp/preview \
  --packs=quest,data-core,save-core,rules-events-core \
  --dry-run-report

./scripts/bootstrap_toolbox_project.sh /tmp/preview \
  --packs=ai-behavior \
  --dry-run-report

./scripts/bootstrap_toolbox_project.sh /tmp/preview \
  --packs=save-state-lite \
  --dry-run-report
```

`save-state-lite` 是独立存档工具/reference pack，不能与 `save-core` 同时启用；默认 RPG 路径仍通过 `data-core,save-core` 保存项目自有状态。

## 持续稳定验证

本地最小验证链：

```bash
bash ./scripts/verify_toolbox_layout.sh
bash ./scripts/verify_game_architecture_packs.sh
bash ./scripts/verify_rules_events_core_pack.sh
bash ./scripts/verify_ui_game_shell_pack.sh
bash ./scripts/verify_pack_matrix.sh --all
bash ./scripts/verify_specialized_pack_candidates.sh
bash ./scripts/verify_input_pack_poc.sh
bash ./scripts/verify_bootstrap_flow.sh
```

`verify_bootstrap_flow.sh` 会创建临时项目，默认叠加 `validation,debug,stateful,juice`，然后依次执行：

- bootstrap 临时项目
- `godot --headless --editor --quit-after 1 --import`
- 生成项目内的 `gdUnit4` smoke

CI 也跑同一条真实产物链。当前 workflow 固定使用官方 Linux 构建的 Godot `4.6.2`，本地建议保持 `4.6.x`，如果本机 Godot 不在 `PATH`，可通过 `GODOT_BIN=/path/to/godot` 显式指定。

可选 `automation` pack 走独立验证入口：

```bash
bash ./scripts/verify_automation_pack_poc.sh
```

这个脚本验证 `automation` 仍然是显式 opt-in：默认 bootstrap 不包含 `GodotE2E`，而 `--packs=automation` 会复制 addon、启用插件、注入 `AutomationServer` autoload，并运行 pack-local E2E smoke。

## 维护工具箱

首次纳入一个 git upstream 插件：

```bash
./scripts/import_plugin_from_upstream.sh \
  --id=signal_lens \
  --repo=https://github.com/yannlemos/signal-lens \
  --target=packs/debug/godot/addons/signal_lens \
  --pack=debug \
  --version=1.4.1
```

升级一个已纳入的插件：

```bash
./scripts/update_plugin_from_upstream.sh --id=signal_lens --version=1.4.1 --dry-run
```

可选 `automation` pack 的上游也已锁定，可以独立预演升级：

```bash
./scripts/update_plugin_from_upstream.sh --id=godot_e2e --dry-run
```

候选 `shell` pack 的上游也已锁定，可以独立预演升级：

```bash
./scripts/update_plugin_from_upstream.sh --id=maaacks_game_template --dry-run
```

## 当前默认策略

- `gdUnit4` 进入基线模板
- `Godot Doctor` 作为验证 pack
- `Signal Lens` 作为调试 pack
- `Godot State Charts` 作为状态机/架构 pack
- `Sparkle Lite` 作为表现层 pack
- `GodotE2E` 作为显式 opt-in automation pack，不进入默认 bootstrap
- `G.U.I.D.E` 作为显式 opt-in input pack，不进入默认 bootstrap
- `GLoot` 作为显式 opt-in inventory pack，不进入默认 bootstrap
- `QuestSystem` 作为显式 opt-in quest pack，不进入默认 bootstrap
- `Beehave` 作为显式 opt-in ai-behavior pack，不进入默认 bootstrap
- `SaveState Lite` 作为显式 opt-in save-state-lite pack，不进入默认 bootstrap，且不替换 `save-core`
- `gdterm` 不纳入工具箱
- `UITextTokens Validator` 不原样纳入，后续应抽象成 repo-specific validator scaffold

## RPG 模板方向

RPG 相关第三方来源、vendor 版本、本地路径、吸收边界和后续任务清单见：

- `docs/rpg-template-absorption-plan.md`

当前已吸收为非默认 pack 的来源包括：

- `GLoot`：<https://github.com/peter-kish/gloot>
- `QuestSystem`：<https://github.com/shomykohai/quest-system>
- `Beehave`：<https://github.com/bitbrain/beehave>
- `SaveState Lite`：<https://github.com/youssof20/savestate>

RPG 核心规则仍计划自研，包括 `rpg-core`、`rpg-battle-core`、`rpg-save-adapter` 和 `rpg-test-kit`。这些内容负责角色成长、战斗规则、奖励、队伍状态和存档格式，不应由第三方插件直接持有项目真相。
