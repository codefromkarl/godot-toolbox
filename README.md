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

另外保留一个**候选**方向：

- `packs/automation/`：`GodotE2E` 候选 PoC 骨架，当前**不在** `packs.manifest.json`，也**不参与**默认 bootstrap

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
- `scripts/bootstrap_toolbox_project.sh`：按 pack 组装新项目
- `scripts/verify_bootstrap_flow.sh`：验证真实产物链路，覆盖 bootstrap、headless import 和 `gdUnit4` smoke
- `scripts/verify_automation_pack_poc.sh`：验证 `packs/automation/` 候选 PoC 骨架，不接入默认验证链
- `scripts/import_plugin_from_upstream.sh`：首次从 upstream 导入插件子树
- `scripts/update_plugin_from_upstream.sh`：基于 lock 文件升级已纳入插件
- `scripts/verify_toolbox_layout.sh`：校验工具箱布局
- `docs/plugin-catalog.md`：插件目录与建议
- `docs/plugin-integration-standard.md`：插件接入标准
- `docs/maintenance-workflow.md`：维护、导入、升级、组装与验证手册
- `docs/selection-framework.md`：选型框架与当前归类理由
- `docs/research/`：外部参考项目速记、插件探索智能体说明、热门插件扫描快照
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

## 持续稳定验证

本地最小验证链：

```bash
bash ./scripts/verify_toolbox_layout.sh
bash ./scripts/verify_bootstrap_flow.sh
```

`verify_bootstrap_flow.sh` 会创建临时项目，默认叠加 `validation,debug,stateful,juice`，然后依次执行：

- bootstrap 临时项目
- `godot --headless --editor --quit-after 1 --import`
- 生成项目内的 `gdUnit4` smoke

CI 也跑同一条真实产物链。当前 workflow 固定使用官方 Linux 构建的 Godot `4.6.2`，本地建议保持 `4.6.x`，如果本机 Godot 不在 `PATH`，可通过 `GODOT_BIN=/path/to/godot` 显式指定。

候选 `automation` PoC 走独立入口：

```bash
bash ./scripts/verify_automation_pack_poc.sh
```

这个脚本只验证候选骨架和最小 bootstrap 前提，不会把 `automation` 接到默认 pack 清单里。

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

## 当前默认策略

- `gdUnit4` 进入基线模板
- `Godot Doctor` 作为验证 pack
- `Signal Lens` 作为调试 pack
- `Godot State Charts` 作为状态机/架构 pack
- `Sparkle Lite` 作为表现层 pack
- `gdterm` 不纳入工具箱
- `UITextTokens Validator` 不原样纳入，后续应抽象成 repo-specific validator scaffold
