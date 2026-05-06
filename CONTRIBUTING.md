# Contributing to godot-toolbox

Thank you for your interest in contributing! This guide covers the basics.

## Development Setup

```bash
git clone https://github.com/codefromkarl/godot-toolbox.git
cd godot-toolbox
```

Bootstrap a test project to verify your environment:

```bash
./scripts/bootstrap_toolbox_project.sh /tmp/test-project --packs=validation,debug
```

Run the full verification suite:

```bash
bash ./scripts/verify_toolbox_layout.sh
bash ./scripts/verify_game_architecture_packs.sh
bash ./scripts/verify_pack_matrix.sh --all
bash ./scripts/verify_bootstrap_flow.sh
```

## Pack Proposal Flow

1. Open an issue using the **Pack Request** template
2. Include upstream URL, license, and selection axis assessment
3. Discuss fit with maintainers
4. If accepted: add manifest entry, upstream lock, README, verification script
5. Submit a PR referencing the issue

## Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — new pack, plugin, or feature
- `fix:` — bug fix
- `docs:` — documentation changes
- `test:` — adding or updating tests
- `chore:` — maintenance, CI, tooling
- `refactor:` — code restructuring without behavior change

## Pull Request Checklist

Before submitting a PR, verify:

- [ ] `packs.manifest.json` and `upstreams.lock.json` are consistent (if changed)
- [ ] All verification scripts pass locally
- [ ] No vendored addon files modified without a corresponding lock update
- [ ] New packs include a README, manifest entry, and verification script
- [ ] Commit messages follow Conventional Commits

## Adding a New Pack

1. Create `packs/<pack-id>/` with `godot/addons/` structure
2. Add entry to `packs.manifest.json` with all required fields
3. Add upstream entry to `upstreams.lock.json` (if vendoring a plugin)
4. Create `packs/<pack-id>/README.md` following the standard template
5. Add a verification script at `scripts/verify_<pack-id>_pack.sh`
6. Run `bash ./scripts/verify_pack_matrix.sh --row=<pack-id>`

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](.github/CODE_OF_CONDUCT.md).

---

<details>
<summary><strong>中文贡献指南</strong></summary>

## 开发环境设置

```bash
git clone https://github.com/codefromkarl/godot-toolbox.git
cd godot-toolbox
```

引导一个测试项目来验证环境：

```bash
./scripts/bootstrap_toolbox_project.sh /tmp/test-project --packs=validation,debug
```

## Pack 提交流程

1. 使用 **Pack Request** 模板开一个 Issue
2. 包含上游 URL、License 和选型轴评估
3. 与维护者讨论是否适合
4. 如果被接受：添加 manifest 条目、upstream lock、README、验证脚本
5. 提交 PR 并引用该 Issue

## 提交规范

使用 [Conventional Commits](https://www.conventionalcommits.org/)：

- `feat:` — 新 pack、插件或功能
- `fix:` — Bug 修复
- `docs:` — 文档变更
- `test:` — 添加或更新测试
- `chore:` — 维护、CI、工具链
- `refactor:` — 不改变行为的代码重构

## PR 检查清单

- [ ] `packs.manifest.json` 和 `upstreams.lock.json` 一致（如有变更）
- [ ] 本地验证脚本全部通过
- [ ] 未修改 vendored addon 文件（除非同步更新 lock）
- [ ] 新 pack 包含 README、manifest 条目和验证脚本
- [ ] 提交信息遵循 Conventional Commits

</details>
