# Automation Candidate Pack

这是 `GodotE2E` 方向的候选 pack / PoC 骨架，不是已经纳入的正式 pack。

当前约束：

- **不在** `packs.manifest.json` 中
- **不参与** 默认 `bootstrap` 行为
- **不接入** 当前默认 CI / 默认验证链

这个目录的目标是先把 E2E 自动化方向的最小骨架和评估入口固定下来，等上游安装方式、Python 包名、Godot 侧接入面都验证清楚后，再决定是否晋升成正式 pack。

## 当前内容

- `python/requirements-e2e.txt`
  Python 侧依赖占位。当前故意不锁定真实包名，避免把未经确认的安装名写进仓库。
- `examples/tests/test_ui_smoke_placeholder.py`
  一个最小占位测试骨架，只表达未来 E2E 测试的大致入口，不代表已可执行。

## 当前缺口

1. 锁定真实的 `GodotE2E` Python 包名、安装方式和版本策略
2. 确认是否需要 vendoring Godot 侧 addon，以及应落在哪个目录
3. 定义最小可接受的 PoC 成功标准
4. 决定通过什么条件把它晋升为正式 `pack`

## 本地验证

独立验证入口：

```bash
bash ./scripts/verify_automation_pack_poc.sh
```

这个脚本会：

- bootstrap 一个**不叠加 automation** 的最小临时项目
- 校验候选骨架文件是否齐全
- 在条件满足时执行最小占位验证
- 输出当前 PoC 还缺什么

它不会修改当前默认验证链。
