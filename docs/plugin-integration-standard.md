# Godot Plugin Integration Standard

## Purpose

这个文档约束 `godot-toolbox` 如何接纳外部 Godot 插件，避免把第三方 addon 直接演化成“默认真相源”。

## Admission Rules

1. 插件必须解决真实工程缺口。
2. 必须有明确 upstream 和固定版本/提交。
3. 不能把游戏真相、协议真相、业务真相隐藏进第三方插件内部。
4. 必须有本地验证路径，才能算“已接入”。
5. 纯 CLI 工具优先用 pinned package + 本地 wrapper，不优先 vendoring。

## Toolbox Policy

- `base` 只放自动化价值高、适合作为 Day 0 基线的能力。
- 调试、状态机、表现层插件进入可选 pack。
- repo-specific 校验器不原样进入通用工具箱，应先抽象成模板。
- 所有纳入结论都应同步更新 `docs/selection-framework.md`、`packs.manifest.json` 和 `upstreams.lock.json`。

## Selection Gate

在讨论“要不要纳入”之前，先问 3 个问题：

1. 它解决的是基线问题，还是场景化问题？
2. 它是否可以被脚本验证，而不是只能靠编辑器手工点击？
3. 它引入的维护面，是否小于它节省的重复工作？

只有这些问题回答清楚，才进入具体接入步骤。

## Layout Rules

### Base Template

- 放在 `templates/base/`
- 只包含默认基线
- 目标是新项目组装后即可 headless 跑通最小 smoke

### Optional Packs

- 放在 `packs/<pack_name>/`
- 每个 pack 只承载一个清晰主题
- 允许 vendored `godot/addons/<plugin>`，但不要混入项目私有业务代码

## Verification Ladder

1. 文件存在检查
2. 组装脚本可执行
3. 生成的 `godot/project.godot` 启用列表正确
4. 基线项目至少有一个 repo-owned smoke
5. 若插件进入默认开发流，则必须补 CI/自动化入口

## Local Patch Policy

- 默认不改 vendor 行为代码
- 若必须 patch，要记录原因、范围和升级时的重放方式
- 一旦出现行为 patch，就按“受维护 fork”看待
