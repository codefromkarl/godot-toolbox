#!/usr/bin/env python3
"""Autoload 命名冲突检测 — 确保 autoload 注册名与 class_name 不重名。

Godot 4.6 headless/CLI 模式下，autoload 注册名与 class_name 同名会产生
硬性 Parse Error（"Class X hides an autoload singleton"），阻塞 gdUnit4 测试。

规范：autoload 注册名（业务用途）≠ class_name（类型定义 + Service 后缀）。
例如：autoload "ContentBridge" → class_name "ContentBridgeService"

用法:
    python3 scripts/autoload_name_check.py [godot_root]
    # 默认 godot_root = 当前目录下的 godot/

退出码:
    0 — 无冲突
    1 — 存在冲突（阻塞 CI）
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# autoload 注册行: Key="*res://path/to/script.gd"
_AUTOLOAD_RE = re.compile(r'^(\w+)="\*res://.*\.gd"$')
# class_name 声明
_CLASS_NAME_RE = re.compile(r'^class_name\s+(\w+)')


def parse_autoloads(project_godot: Path) -> dict[str, str]:
    """解析 project.godot 中 [autoload] 段，返回 {autoload_name: script_path}。"""
    autoloads: dict[str, str] = {}
    in_autoload_section = False

    for line in project_godot.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped == "[autoload]":
            in_autoload_section = True
            continue
        if in_autoload_section:
            if stripped.startswith("["):
                break
            m = _AUTOLOAD_RE.match(stripped)
            if m:
                autoloads[m.group(1)] = stripped.split('"*')[1].rstrip('"')

    return autoloads


def extract_class_name(script_path: Path) -> str | None:
    """从 .gd 文件中提取 class_name，无则返回 None。"""
    try:
        text = script_path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return None
    for line in text.splitlines():
        m = _CLASS_NAME_RE.match(line.strip())
        if m:
            return m.group(1)
    return None


def check_conflicts(godot_root: Path) -> list[dict[str, str]]:
    """检测 autoload 注册名与 class_name 的同名冲突。

    返回冲突列表 [{autoload, class_name, script}]。
    """
    project_godot = godot_root / "project.godot"
    if not project_godot.exists():
        print(f"ERROR: {project_godot} not found", file=sys.stderr)
        sys.exit(2)

    autoloads = parse_autoloads(project_godot)
    conflicts: list[dict[str, str]] = []

    for autoload_name, script_rel in autoloads.items():
        script_path = godot_root / script_rel.replace("res://", "")
        if not script_path.exists():
            continue
        cn = extract_class_name(script_path)
        if cn is not None and cn == autoload_name:
            conflicts.append({
                "autoload": autoload_name,
                "class_name": cn,
                "script": script_rel,
            })

    return conflicts


def main() -> None:
    godot_root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("godot")
    if not godot_root.is_absolute():
        godot_root = Path.cwd() / godot_root

    conflicts = check_conflicts(godot_root)

    if not conflicts:
        print("✅ autoload 命名冲突检查通过 — 无冲突")
        sys.exit(0)

    print(f"❌ 发现 {len(conflicts)} 个 autoload/class_name 命名冲突:\n")
    print(f"  {'Autoload名':<20} {'class_name':<25} {'脚本路径'}")
    print(f"  {'-'*20} {'-'*25} {'-'*40}")
    for c in conflicts:
        print(f"  {c['autoload']:<20} {c['class_name']:<25} {c['script']}")
    print()
    print("修复方案: 将 class_name 改为 autoload名 + Service 后缀")
    print("  例如: class_name ContentBridge → class_name ContentBridgeService")
    print("  autoload 注册名保持不变（业务代码无需改动）")
    sys.exit(1)


if __name__ == "__main__":
    main()
