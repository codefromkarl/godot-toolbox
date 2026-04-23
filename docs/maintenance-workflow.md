# Maintenance Workflow

## Purpose

这份文档定义 `godot-toolbox` 的维护流程，目标是让模板、插件、pack、脚本和验证都围绕同一套步骤演进，而不是靠记忆维持。

## Scope

这份流程覆盖 5 类活动：

1. 评估一个新模板或插件是否值得纳入
2. 首次把一个上游插件导入工具箱
3. 升级一个已经纳入的插件
4. 用工具箱组装一个新项目
5. 验证本次改动是否维持了工具箱闭环

## Source Of Truth

维护时优先以这些文件为准：

- `docs/selection-framework.md`
- `docs/plugin-integration-standard.md`
- `packs.manifest.json`
- `upstreams.lock.json`

如果实际行为发生变化，这四处内容必须同步。

## A. 评估适配度

引入新模板或插件前，先回答这些问题：

1. 它解决的是 `base` 问题还是场景化 `pack` 问题？
2. 它是否适合脚本化、headless、CI 和 agent 调用？
3. 它是否强绑定某个项目的玩法、文案或业务真相？
4. 它的升级与维护成本是否可控？
5. 它是否能通过本地脚本验证，而不是只能靠编辑器手工点击？

结论只有 5 种：

- 进入 `base`
- 进入某个 `pack`
- 先作为候选 `pack / PoC`
- 只保留为外部参考
- 暂不纳入

### 进入 `base`

必须同时满足：

- 自动化价值高
- 复用面广
- 领域耦合低
- 有稳定的本地验证路径
- 不依赖重度人工编辑器操作

### 进入 `pack`

满足以下大部分即可：

- 在一个明确主题内价值高
- 不适合所有项目默认启用
- 可以按项目需要叠加
- 不会接管项目核心真相

### 候选 `pack / PoC`

如果方向值得继续，但还不适合进入 `packs.manifest.json`，先按候选 PoC 处理：

- 目录可以先放在 `packs/<name>/`
- 必须明确标注“未纳入正式 pack”
- 不修改默认 `bootstrap` 行为
- 不接入默认验证链
- 通过独立验证脚本证明这条路径值得继续

## B. 首次导入上游插件

首次导入时，按下面流程执行：

1. 确认 upstream 来源和版本可固定
2. 决定它进入 `base` 还是某个 `pack`
3. 运行导入脚本
4. 更新 lock / manifest / 文档
5. 跑验证

### 导入命令

```bash
./scripts/import_plugin_from_upstream.sh \
  --id=<plugin_id> \
  --repo=<git_url> \
  --target=<repo_relative_target_dir> \
  --pack=<base|validation|debug|stateful|juice> \
  --version=<display_version>
```

必要时补充：

- `--ref=<git_ref>`
- `--source-subdir=<path_inside_upstream>`
- `--note=<text>`
- `--dry-run`

### 导入后必须确认

- 目标目录下有 `plugin.cfg`
- `upstreams.lock.json` 写入了正确条目
- `packs.manifest.json` 中 pack 与插件归属一致
- README 或相关文档反映了这个新能力

## C. 升级已纳入插件

升级时，优先基于 lock 文件，而不是手工复制 vendor 目录。

### 升级命令

```bash
./scripts/update_plugin_from_upstream.sh --id=<entry_id> --version=<display_version>
```

建议先预演：

```bash
./scripts/update_plugin_from_upstream.sh --id=<entry_id> --version=<display_version> --dry-run
```

### 升级时的原则

- 如果只是验证能否切到某个版本，先用 `--dry-run`
- 如果显式传了 `--version`，应优先按新版本解析 ref
- 无效版本应直接报错，而不是回退默认分支
- `tool-only` 条目只更新 lock metadata，不自动改写目标文件

### 升级后必须确认

- `upstreams.lock.json` 中的 `version/ref` 与实际 checkout 一致
- vendor 目录或 tool metadata 没有意外回退
- 所有验证仍通过

## D. 组装一个新项目

组装入口是：

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/new-project --packs=validation,debug
```

组装过程是：

1. 复制 `templates/base/`
2. 叠加所选 `packs/<pack>/`
3. 从 `packs.manifest.json` 读取 `base_template.default_enabled_plugins` 和 `packs[].plugins`
4. 生成目标项目的 `godot/project.godot`
5. 写入 `.toolbox-packs`

### 组装时的原则

- `bootstrap` 不在脚本里硬编码 `pack -> plugin.cfg`
- pack 是否存在，以 `packs.manifest.json` 为准
- pack 在 manifest 中存在但目录缺失，应立即报错

## E. 验证闭环

每次维护至少跑下面三层：

### 1. 静态检查

```bash
bash -n scripts/*.sh templates/base/scripts/*.sh
python3 -m json.tool packs.manifest.json >/dev/null
python3 -m json.tool upstreams.lock.json >/dev/null
```

### 2. 布局检查

```bash
./scripts/verify_toolbox_layout.sh
```

### 3. 真实产物检查

```bash
bash ./scripts/verify_bootstrap_flow.sh
```

如果本轮改动的是候选 `automation` PoC，再补：

```bash
bash ./scripts/verify_automation_pack_poc.sh
```

如果本轮改动涉及 `import/update`，还应补：

```bash
./scripts/import_plugin_from_upstream.sh ... --dry-run
./scripts/update_plugin_from_upstream.sh --id=<entry_id> --dry-run
```

## F. 提交前检查

提交前至少确认：

- `git status --short` 里只有本轮相关文件
- 改动的行为和文档一致
- 如果调整了选型或归类，相关 manifest 和文档已同步
- 如果加入了新 pack 或新插件，README 至少有入口说明

## G. 推荐节奏

日常维护建议按这个顺序：

1. 先评估适配度
2. 再 dry-run 导入或升级
3. 再执行真实导入或升级
4. 再做 bootstrap + import + smoke 验证
5. 最后提交并推送

这样可以把选型错误、版本错误、路径错误和验证错误尽量提前暴露。

## H. CI 基线

仓库级 CI 入口在 `.github/workflows/ci.yml`，当前固定跑 4 类检查：

1. 布局检查：`bash ./scripts/verify_toolbox_layout.sh`
2. Shell 语法检查：`bash -n scripts/*.sh templates/base/scripts/*.sh`
3. JSON 语法检查：`python3 -m json.tool ...`
4. 真实产物检查：`bash ./scripts/verify_bootstrap_flow.sh`

当前 workflow 显式安装官方 Linux Godot `4.6.2` 构建，并在该版本上运行 headless import 与 `gdUnit4` smoke。
本地开发建议维持 `4.6.x`；如果本机二进制路径不标准，统一通过 `GODOT_BIN` 注入。
