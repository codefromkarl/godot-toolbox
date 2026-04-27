# Shell Candidate Pack

这是 `Maaack's Game Template` 方向的候选 shell pack，当前仅作为可升级的 vendored upstream 与接入研究入口。

当前硬约束：

- **不在** `packs.manifest.json` 中
- **不参与** 默认 `bootstrap` 行为
- **不接管** 使用方项目的 `run/main_scene`、autoload、存档、运行时状态或业务流程
- 上游来源锁定在仓库根目录的 `upstreams.lock.json`，升级走仓库统一脚本

## 当前内容

- `godot/addons/maaacks_game_template/`
  vendored 的上游 Godot addon，来源于 `Maaack/Godot-Game-Template` 的 `v1.4.6-plugin` 标签。

## 定位

这个候选 pack 只用于评估和吸收通用 app shell 能力：

- 主菜单
- 选项/设置菜单
- 暂停菜单
- Credits
- Loading screen
- Opening scene
- 输入映射和持久设置的参考实现

它不应该成为任何具体游戏项目的业务真相源。已有项目接入时，应优先以插件模式复制到目标项目，再选择性吸收菜单、暂停、开场和加载壳层；不要整包覆盖目标项目的主场景、autoload 或运行时服务。

## Upstream / Upgrade

当前 vendored addon 的 upstream 已锁定为：

- repo: `https://github.com/Maaack/Godot-Game-Template.git`
- version: `v1.4.6-plugin`
- ref: `v1.4.6-plugin`
- source subdir: `addons/maaacks_game_template`

预演升级时，走仓库统一入口：

```bash
./scripts/update_plugin_from_upstream.sh --id=maaacks_game_template --dry-run
```

重新导入或升级后，至少运行：

```bash
bash ./scripts/verify_toolbox_layout.sh
./scripts/update_plugin_from_upstream.sh --id=maaacks_game_template --dry-run
```
