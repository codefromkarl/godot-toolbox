# Automation Optional Pack

这是 `GodotE2E` 方向的 opt-in automation pack。它已经纳入 `packs.manifest.json`，但默认不启用；只有显式选择 `--packs=automation` 时才会复制 addon、启用插件并注入 `AutomationServer` autoload。

当前硬约束：

- `default=false`
- **不参与** 默认 `bootstrap` 行为
- **不接入** 当前默认验证链
- 只能通过显式 `--packs=automation` 进入生成项目
- 上游来源单独锁定在仓库根目录的 `upstreams.lock.json`，升级也走仓库统一脚本

## 当前内容

- `godot/addons/godot_e2e/`
  vendored 的上游 Godot addon，来源于 `godot-e2e` `v1.1.0`，包含 `LICENSE` 与 `NOTICE`。
- `python/requirements-e2e.txt`
  已锁定可安装的 Python 依赖：`godot-e2e==1.1.0` 与 `pytest==8.4.1`。
- `examples/tests/`
  真实的 pytest smoke：启动 Godot、等待 `/root/Main`、断言节点存在，并读取 `name == "Main"`。
- `scripts/run_e2e_smoke.sh`
  pack-local 入口。负责创建 venv、安装依赖、做 Godot import preflight，并调用 `godot-e2e` 运行 smoke。Linux 无图形会话时，若系统存在 `xvfb-run`，会优先通过它启动。

## 手动运行

先显式组装 automation pack：

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/new-project --packs=automation
```

对已经具备 `AutomationServer` autoload 的 Godot 项目，可以独立运行：

```bash
bash ./packs/automation/scripts/run_e2e_smoke.sh /path/to/godot-project
```

默认会运行 pack 内置 smoke。这个内置 smoke 的项目契约是：

- `project.godot` 必须声明 `run/main_scene`
- 该主场景的根节点名称必须是 `Main`
- 也就是测试进程会等待并访问 `/root/Main`

脚本在使用内置 smoke 时会先做这组 preflight 检查；如果你的项目不满足这个契约，就不要用默认测试路径，而是显式传入自定义 pytest 文件：

```bash
bash ./packs/automation/scripts/run_e2e_smoke.sh /path/to/godot-project /path/to/your_test.py
```

常用环境变量：

- `GODOT_BIN`
  显式指定 Godot 可执行文件
- `E2E_VENV_DIR`
  指定 venv 目录；未指定时脚本会创建并清理一个隔离的临时 venv
- `E2E_TEST_PATH`
  指定要运行的 pytest 文件；默认是 pack 内置 smoke

## 仓库内验证

独立验证入口：

```bash
bash ./scripts/verify_automation_pack_poc.sh
```

这个脚本会：

- 先校验 `upstreams.lock.json`、`requirements-e2e.txt` 与 vendored addon 子树彼此一致
- 校验 `packs.manifest.json` 里的 `automation` pack 仍然是非默认 opt-in
- 先断言默认 bootstrap 输出中没有 `GodotE2E`、`godot_e2e` 插件或 `AutomationServer` autoload
- 再通过正式 `--packs=automation` bootstrap 路径生成临时项目
- 校验 addon、插件、autoload 与 `godot_toolbox/automation/enabled=true` 都来自 manifest 渲染
- 调用 pack-local smoke runner 验证最小闭环

它不会修改当前默认验证链，也不会把 automation 自动接入默认 bootstrap。

## Upstream / Upgrade

当前 vendored addon 的 upstream 已锁定为：

- repo: `https://github.com/RandallLiuXin/godot-e2e`
- version: `1.1.0`
- ref: `5bc097db714f1517cfa7b268ab919463d36f4c2c`

预演升级时，走仓库统一入口：

```bash
bash ./scripts/update_plugin_from_upstream.sh --id=godot_e2e --dry-run
```

真正升级或重导入后，仍然补跑这个 pack 的独立验证：

```bash
bash ./scripts/verify_automation_pack_poc.sh
```
