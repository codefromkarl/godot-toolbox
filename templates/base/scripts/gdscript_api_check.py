#!/usr/bin/env python3
"""GDScript API semantic checker — prevents Node/Dictionary API confusion bugs.

Exit codes:
    0 = no violations
    1 = one or more violations found

Usage:
    python3 scripts/gdscript_api_check.py [file1.gd file2.gd ...]
    python3 scripts/gdscript_api_check.py --json [files...]
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import List, Dict, Any


# Detection patterns: (rule_id, regex, level, message_template)
PATTERNS = [
    (
        "untyped_member_var",
        r"^\s*var\s+\w+\s*$",
        "ERROR",
        "Untyped member variable: {match}",
    ),
    (
        "untyped_func_param",
        r"func\s+\w+\s*\([^)]*\w+(?!\s*:)\s*(?:[,\)]|$)",
        "WARNING",
        "Potentially untyped function parameter in signature",
    ),
    (
        "unguarded_get_no_default",
        r'\.get\(["\'][^"\']+["\']\)(?!\s*,)',
        "WARNING",
        "Unguarded .get() without default value — ambiguous Node.get() vs Dictionary.get()",
    ),
    (
        "private_field_access",
        r'\.get\(["\']_[^"\']+["\']\)',
        "ERROR",
        "Accessing private field via .get() — violates encapsulation",
    ),
    (
        "variant_non_bridge",
        r"(?::|->)\s*Variant\b",
        "ERROR",
        "Untyped Variant bypasses type safety — use concrete type",
    ),
    (
        "unchecked_set",
        r'\.set\(["\'][^"\']+["\']\s*,',
        "WARNING",
        "Unchecked .set() — bypasses type safety, prefer direct property assignment",
    ),
]

# File path patterns to exclude (third-party, generated)
EXCLUDE_PATH_PATTERNS = [
    re.compile(r"addons/(?:gdUnit4|gdterm|godot_doctor|godot_state_charts|signal_lens)/"),
    re.compile(r"/\.godot(?:-mcp|-mcp-src)?/"),
]


SUPPRESS_RE = re.compile(r"#\s*gdscript-api-check:\s*suppress=(\S+)")


def _has_suppression(lines: List[str], line_no: int, rule_id: str) -> bool:
    """Check current and previous line for suppression comments."""
    for idx in range(min(2, len(lines))):
        m = SUPPRESS_RE.search(lines[idx])
        if m:
            suppressed = m.group(1).split(",")
            if rule_id in suppressed or "*" in suppressed:
                return True

    for idx in range(max(0, line_no - 5), line_no):
        m = SUPPRESS_RE.search(lines[idx])
        if m:
            suppressed = m.group(1).split(",")
            if rule_id in suppressed or "*" in suppressed:
                return True
    return False


def _is_inside_string(line: str, pos: int) -> bool:
    """Heuristic: check if position is inside a string literal."""
    prefix = line[:pos]
    dquotes = prefix.count('"') - prefix.count('\\"')
    squotes = prefix.count("'") - prefix.count("\\'")
    return (dquotes % 2 == 1) or (squotes % 2 == 1)


def _has_type_guard(lines: List[str], center_line_no: int) -> bool:
    """Check if adjacent 5 lines contain a type guard for .has() or .get()."""
    start = max(0, center_line_no - 3)
    end = min(len(lines), center_line_no + 2)
    context = "\n".join(lines[start:end])
    return (
        "is Dictionary" in context
        or "is Node" in context
        or "TYPE_DICTIONARY" in context
        or "TYPE_ARRAY" in context
        or "is Array" in context
    )


def _is_typed_as_dict(lines: List[str], receiver: str, up_to_line: int) -> bool:
    """Heuristic: check if receiver variable was declared with : Dictionary type."""
    for i in range(up_to_line - 1, -1, -1):
        line = lines[i]
        pattern = rf"\b{re.escape(receiver)}\s*:\s*Dictionary\b"
        if re.search(pattern, line):
            return True
        if re.search(rf"\b{re.escape(receiver)}\s*(:=|=)\s*\{{", line):
            return True
    return False


def _is_typed_as_node(lines: List[str], receiver: str, up_to_line: int) -> bool:
    """Heuristic: check if receiver variable was declared as Node or subclass."""
    for i in range(up_to_line - 1, -1, -1):
        line = lines[i]
        pattern = rf"\b{re.escape(receiver)}\s*:\s*(?:Node|Node2D|Node3D|Control|CanvasItem|CanvasLayer)\b"
        if re.search(pattern, line):
            return True
    return False


def _is_typed_as_array(lines: List[str], receiver: str, up_to_line: int) -> bool:
    """Heuristic: check if receiver variable was declared as Array."""
    for i in range(up_to_line - 1, -1, -1):
        line = lines[i]
        pattern = rf"\b{re.escape(receiver)}\s*:\s*Array\b"
        if re.search(pattern, line):
            return True
        if re.search(rf"\b{re.escape(receiver)}\s*(:=|=)\s*\[", line):
            return True
    return False


def _extract_receiver(line: str, match_start: int) -> str:
    """Extract the receiver object name before .get( or .has(."""
    prefix = line[:match_start]
    m = re.search(r'(\w+)\s*$', prefix)
    if m:
        return m.group(1)
    return ""


def _has_typed_params_in_signature(lines: List[str], line_no: int) -> bool:
    """Check if the function signature on this line has at least one typed param."""
    line = lines[line_no - 1]
    paren_start = line.find('(')
    paren_end = line.rfind(')')
    if paren_start == -1 or paren_end == -1 or paren_end <= paren_start:
        return False
    sig = line[paren_start + 1:paren_end]
    return ': ' in sig or ':' in sig


def check_file(filepath: Path) -> List[Dict[str, Any]]:
    """Scan a single GDScript file for API confusion vulnerabilities."""
    violations: List[Dict[str, Any]] = []
    content = filepath.read_text(encoding="utf-8")
    lines = content.splitlines()

    is_bridge = "bridge" in str(filepath)

    for line_no, line in enumerate(lines, start=1):
        stripped = line.strip()
        if stripped.startswith("#"):
            continue

        for rule_id, pattern, level, msg_template in PATTERNS:
            if rule_id == "variant_non_bridge" and is_bridge:
                continue
            if rule_id == "unchecked_set" and is_bridge:
                continue

            for match in re.finditer(pattern, line):
                if _is_inside_string(line, match.start()):
                    continue
                if _has_suppression(lines, line_no, rule_id):
                    continue

                if rule_id == "untyped_func_param":
                    if _has_typed_params_in_signature(lines, line_no):
                        continue

                if rule_id == "unguarded_get_no_default":
                    receiver = _extract_receiver(line, match.start())
                    if receiver and _is_typed_as_dict(lines, receiver, line_no):
                        continue
                    if receiver and _is_typed_as_node(lines, receiver, line_no):
                        continue
                    if _has_type_guard(lines, line_no):
                        continue

                if rule_id == "unchecked_set":
                    receiver = _extract_receiver(line, match.start())
                    if receiver and _is_typed_as_dict(lines, receiver, line_no):
                        continue
                    if receiver and _is_typed_as_node(lines, receiver, line_no):
                        continue
                    if _has_type_guard(lines, line_no):
                        continue

                violations.append(
                    {
                        "file": str(filepath),
                        "line": line_no,
                        "level": level,
                        "rule": rule_id,
                        "message": msg_template.format(match=match.group()),
                        "code": stripped,
                    }
                )

        # Separate check for .has() without type guard
        for match in re.finditer(r'\.has\(["\'][^"\']+["\']\)', line):
            if _is_inside_string(line, match.start()):
                continue
            receiver = _extract_receiver(line, match.start())
            if receiver and _is_typed_as_dict(lines, receiver, line_no):
                continue
            if receiver and _is_typed_as_node(lines, receiver, line_no):
                continue
            if receiver and _is_typed_as_array(lines, receiver, line_no):
                continue
            if _has_type_guard(lines, line_no):
                continue
            if _has_suppression(lines, line_no, "unguarded_has"):
                continue
            violations.append(
                {
                    "file": str(filepath),
                    "line": line_no,
                    "level": "WARNING",
                    "rule": "unguarded_has",
                    "message": "Unguarded .has() without type guard — ambiguous Node.has() vs Dictionary.has()",
                    "code": stripped,
                }
            )

        # Separate check for .call() / .callv() / call_deferred() without type guard
        if is_bridge:
            continue
        for match in re.finditer(r'\.(?:call|callv|call_deferred)\(["\'][^"\']+["\']', line):
            if _is_inside_string(line, match.start()):
                continue
            receiver = _extract_receiver(line, match.start())
            if receiver and _is_typed_as_dict(lines, receiver, line_no):
                continue
            if receiver and _is_typed_as_node(lines, receiver, line_no):
                continue
            if _has_type_guard(lines, line_no):
                continue
            if _has_suppression(lines, line_no, "unguarded_reflective_call"):
                continue
            method_match = re.search(r'\.(?:call|callv|call_deferred)\(["\']([^"\']+)["\']', match.group())
            method_name = method_match.group(1) if method_match else ""
            level = "ERROR" if method_name.startswith("_") else "WARNING"
            msg = (
                f"Reflective .{match.group().split('(')[0].split('.')[-1]}() to private method — bypasses type safety"
                if method_name.startswith("_")
                else f"Reflective .{match.group().split('(')[0].split('.')[-1]}() without type guard — prefer direct method call or interface cast"
            )
            violations.append(
                {
                    "file": str(filepath),
                    "line": line_no,
                    "level": level,
                    "rule": "unguarded_reflective_call",
                    "message": msg,
                    "code": stripped,
                }
            )

    return violations


def should_check(path: Path) -> bool:
    """Return True if the file should be scanned (not excluded)."""
    path_str = str(path)
    for pat in EXCLUDE_PATH_PATTERNS:
        if pat.search(path_str):
            return False
    return True


def _load_baseline(baseline_path: Path) -> set:
    """Load baseline violations as a set of (file, line, rule) tuples."""
    if not baseline_path.exists():
        return set()
    try:
        data = json.loads(baseline_path.read_text(encoding="utf-8"))
        return {
            (v.get("file", ""), v.get("line", 0), v.get("rule", ""))
            for v in data
        }
    except (json.JSONDecodeError, OSError):
        return set()


def _filter_new_violations(violations: List[Dict[str, Any]], baseline: set) -> List[Dict[str, Any]]:
    """Return only violations not present in the baseline."""
    return [
        v for v in violations
        if (v.get("file", ""), v.get("line", 0), v.get("rule", "")) not in baseline
    ]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="GDScript API semantic checker",
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="GDScript files to check (default: all tracked godot/*.gd)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output violations as JSON",
    )
    parser.add_argument(
        "--max-warnings",
        type=int,
        default=-1,
        help="Maximum allowed warnings before exit 1 (-1 = unlimited, 0 = zero tolerance)",
    )
    parser.add_argument(
        "--baseline",
        type=Path,
        default=None,
        help="Baseline JSON file; only report violations not in baseline",
    )
    args = parser.parse_args()

    if args.files:
        targets = [Path(f) for f in args.files]
    else:
        import subprocess

        result = subprocess.run(
            ["git", "ls-files", "godot/*.gd", "godot/**/*.gd"],
            capture_output=True,
            text=True,
            check=True,
        )
        targets = [Path(line) for line in result.stdout.strip().split("\n") if line]

    all_violations: List[Dict[str, Any]] = []
    for target in targets:
        if not target.exists():
            continue
        if not should_check(target):
            continue
        violations = check_file(target)
        all_violations.extend(violations)

    if args.baseline:
        baseline = _load_baseline(args.baseline)
        all_violations = _filter_new_violations(all_violations, baseline)

    if args.json:
        print(json.dumps(all_violations, indent=2, ensure_ascii=False))
    else:
        errors = [v for v in all_violations if v["level"] == "ERROR"]
        warnings = [v for v in all_violations if v["level"] == "WARNING"]

        if errors:
            print(f"❌ {len(errors)} ERROR(s) found:")
            for v in errors:
                print(f"  {v['file']}:{v['line']}  {v['message']}")
                print(f"    → {v['code']}")
        if warnings:
            print(f"⚠️  {len(warnings)} WARNING(s) found:")
            for v in warnings:
                print(f"  {v['file']}:{v['line']}  {v['message']}")
                print(f"    → {v['code']}")

        if not errors and not warnings:
            print("✅ GDScript API check passed — no violations found.")

    error_count = len([v for v in all_violations if v["level"] == "ERROR"])
    warning_count = len([v for v in all_violations if v["level"] == "WARNING"])

    if error_count > 0:
        return 1
    if args.max_warnings >= 0 and warning_count > args.max_warnings:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
