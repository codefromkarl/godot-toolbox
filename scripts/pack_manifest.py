#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from collections import OrderedDict, defaultdict
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = REPO_ROOT / "packs.manifest.json"


REQUIRED_PACK_FIELDS = (
    "id",
    "kind",
    "default",
    "plugins",
    "requires",
    "conflicts",
    "autoloads",
    "project_settings",
    "input_map",
    "verification",
    "godot_version",
    "selection_rationale",
)

REQUIRED_MANIFEST_FIELDS = (
    "schema_version",
    "toolbox_identity",
    "base_template",
    "pack_contract",
    "packs",
)

V2_CONTRACT_FIELDS = (
    "requires",
    "conflicts",
    "autoloads",
    "project_settings",
    "input_map",
    "verification",
    "godot_version",
)

LIST_OF_STRINGS_FIELDS = (
    "plugins",
    "tooling",
    "requires",
    "conflicts",
    "verification",
    "when_to_enable",
)


def load_manifest() -> dict[str, Any]:
    with MANIFEST_PATH.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def pack_index(manifest: dict[str, Any]) -> OrderedDict[str, dict[str, Any]]:
    packs: OrderedDict[str, dict[str, Any]] = OrderedDict()
    raw_packs = manifest.get("packs", [])
    if not isinstance(raw_packs, list):
        raise ValueError("packs must be an array")
    for index, pack in enumerate(raw_packs):
        if not isinstance(pack, dict):
            raise ValueError(f"pack entry at index {index} must be an object")
        pack_id = pack.get("id")
        if not isinstance(pack_id, str) or not pack_id:
            raise ValueError("every pack must declare a non-empty string id")
        if pack_id in packs:
            raise ValueError(f"duplicate pack id: {pack_id}")
        packs[pack_id] = pack
    return packs


def normalize_selected(raw_packs: str | None, packs: OrderedDict[str, dict[str, Any]]) -> list[str]:
    selected: list[str] = []
    seen: set[str] = set()
    if raw_packs:
        for raw_pack in raw_packs.split(","):
            pack_id = raw_pack.strip()
            if not pack_id:
                continue
            if pack_id not in packs:
                supported = ",".join(packs)
                raise ValueError(
                    f"pack '{pack_id}' is not defined in packs.manifest.json. Supported packs: {supported}"
                )
            if pack_id not in seen:
                selected.append(pack_id)
                seen.add(pack_id)
    return selected


def validate_manifest(manifest: dict[str, Any]) -> OrderedDict[str, dict[str, Any]]:
    errors: list[str] = []
    for field in REQUIRED_MANIFEST_FIELDS:
        if field not in manifest:
            errors.append(f"manifest missing required field '{field}'")

    if manifest.get("schema_version") != 2:
        errors.append("schema_version must be 2")

    if "toolbox_identity" in manifest and not isinstance(manifest["toolbox_identity"], dict):
        errors.append("toolbox_identity must be an object")

    base_template = manifest.get("base_template")
    if not isinstance(base_template, dict):
        errors.append("base_template must be an object")
    else:
        default_plugins = base_template.get("default_enabled_plugins", [])
        if not isinstance(default_plugins, list) or not all(isinstance(item, str) for item in default_plugins):
            errors.append("base_template.default_enabled_plugins must be an array of strings")
        if "verification" in base_template and (
            not isinstance(base_template["verification"], list)
            or not all(isinstance(item, str) for item in base_template["verification"])
        ):
            errors.append("base_template.verification must be an array of strings")

    pack_contract = manifest.get("pack_contract")
    if not isinstance(pack_contract, dict):
        errors.append("pack_contract must be an object")
    else:
        required_fields = pack_contract.get("required_fields")
        if not isinstance(required_fields, list) or not all(isinstance(item, str) for item in required_fields):
            errors.append("pack_contract.required_fields must be an array of strings")
        else:
            missing_contract_fields = [field for field in V2_CONTRACT_FIELDS if field not in required_fields]
            for field in missing_contract_fields:
                errors.append(f"pack_contract.required_fields missing v2 field '{field}'")

    if not isinstance(manifest.get("packs"), list) or not manifest.get("packs"):
        errors.append("packs must be a non-empty array")

    packs = OrderedDict()
    try:
        packs = pack_index(manifest)
    except ValueError as exc:
        errors.append(str(exc))

    if "base" not in packs:
        errors.append("manifest must define the implicit base pack")

    for pack_id, pack in packs.items():
        for field in REQUIRED_PACK_FIELDS:
            if field not in pack:
                errors.append(f"pack '{pack_id}' missing required field '{field}'")

        for field in ("id", "kind", "selection_rationale"):
            if field in pack and (not isinstance(pack[field], str) or not pack[field].strip()):
                errors.append(f"pack '{pack_id}' field '{field}' must be a non-empty string")

        if "default" in pack and not isinstance(pack["default"], bool):
            errors.append(f"pack '{pack_id}' field 'default' must be a boolean")

        for field in ("autoloads", "project_settings", "input_map"):
            if field in pack and not isinstance(pack[field], list):
                errors.append(f"pack '{pack_id}' field '{field}' must be an array")

        for field in LIST_OF_STRINGS_FIELDS:
            if field in pack:
                if not isinstance(pack[field], list):
                    errors.append(f"pack '{pack_id}' field '{field}' must be an array")
                elif not all(isinstance(item, str) and item.strip() for item in pack[field]):
                    errors.append(f"pack '{pack_id}' field '{field}' must be an array of non-empty strings")

        if pack_id != "base" and "requires" in pack and "base" not in pack.get("requires", []):
            errors.append(f"pack '{pack_id}' must explicitly require 'base'")

        godot_version = pack.get("godot_version")
        if not isinstance(godot_version, dict):
            errors.append(f"pack '{pack_id}' field 'godot_version' must be an object")
        elif "min" not in godot_version or not isinstance(godot_version["min"], str) or not godot_version["min"].strip():
            errors.append(f"pack '{pack_id}' godot_version.min must be a non-empty string")

        seen_autoload_names: set[str] = set()
        for autoload in pack.get("autoloads", []):
            if not isinstance(autoload, dict):
                errors.append(f"pack '{pack_id}' autoload entries must be objects")
                continue
            name = autoload.get("name")
            path = autoload.get("path")
            if not isinstance(name, str) or not name.strip() or not isinstance(path, str) or not path.strip():
                errors.append(f"pack '{pack_id}' autoload entries require name and path")
                continue
            if name in seen_autoload_names:
                errors.append(f"pack '{pack_id}' declares duplicate autoload '{name}'")
            seen_autoload_names.add(name)
            if not path.startswith("res://"):
                errors.append(f"pack '{pack_id}' autoload '{name}' path must start with res://")
            if "singleton" in autoload and not isinstance(autoload["singleton"], bool):
                errors.append(f"pack '{pack_id}' autoload '{name}' singleton must be a boolean")

        seen_setting_paths: set[str] = set()
        for setting in pack.get("project_settings", []):
            if not isinstance(setting, dict):
                errors.append(f"pack '{pack_id}' project_settings entries must be objects")
                continue
            path = setting.get("path")
            if not isinstance(path, str) or "/" not in path:
                errors.append(f"pack '{pack_id}' project setting path must be section/key: {setting}")
            else:
                section, key = path.split("/", 1)
                if not section or not key:
                    errors.append(f"pack '{pack_id}' project setting path must be section/key: {setting}")
                if path in seen_setting_paths:
                    errors.append(f"pack '{pack_id}' declares duplicate project setting '{path}'")
                seen_setting_paths.add(path)
            if "value" not in setting:
                errors.append(f"pack '{pack_id}' project setting missing value: {setting}")

        seen_actions: set[str] = set()
        for action in pack.get("input_map", []):
            if not isinstance(action, dict):
                errors.append(f"pack '{pack_id}' input_map entries must be objects")
                continue
            action_name = action.get("action")
            if not isinstance(action_name, str) or not action_name.strip():
                errors.append(f"pack '{pack_id}' input_map entries require a non-empty action")
                continue
            if action_name in seen_actions:
                errors.append(f"pack '{pack_id}' declares duplicate input action '{action_name}'")
            seen_actions.add(action_name)
            if "deadzone" in action and not isinstance(action["deadzone"], (int, float)):
                errors.append(f"pack '{pack_id}' input action '{action_name}' deadzone must be a number")

    for pack_id, pack in packs.items():
        for required in pack.get("requires", []):
            if required == pack_id:
                errors.append(f"pack '{pack_id}' cannot require itself")
            if required != "base" and required not in packs:
                errors.append(f"pack '{pack_id}' requires unknown pack '{required}'")
        for conflict in pack.get("conflicts", []):
            if conflict == pack_id:
                errors.append(f"pack '{pack_id}' cannot conflict with itself")
            if conflict not in packs:
                errors.append(f"pack '{pack_id}' conflicts with unknown pack '{conflict}'")

    if errors:
        raise ValueError("\n".join(errors))
    return packs


def collect_plan(manifest: dict[str, Any], raw_packs: str | None) -> dict[str, Any]:
    packs = validate_manifest(manifest)
    selected = normalize_selected(raw_packs, packs)
    active_ids = ["base"] + [pack_id for pack_id in selected if pack_id != "base"]
    active_set = set(active_ids)

    for pack_id in active_ids:
        pack = packs[pack_id]
        for required in pack.get("requires", []):
            if required not in active_set:
                raise ValueError(f"pack '{pack_id}' requires pack '{required}'")
        for conflict in pack.get("conflicts", []):
            if conflict in active_set:
                raise ValueError(f"pack '{pack_id}' conflicts with selected pack '{conflict}'")

    plugins: list[str] = []
    seen_plugins: set[str] = set()

    def add_plugin(plugin_id: str) -> None:
        if not plugin_id:
            return
        plugin_cfg = f"res://addons/{plugin_id}/plugin.cfg"
        if plugin_cfg not in seen_plugins:
            plugins.append(plugin_cfg)
            seen_plugins.add(plugin_cfg)

    for plugin_id in manifest.get("base_template", {}).get("default_enabled_plugins", []):
        add_plugin(plugin_id)

    autoloads: list[dict[str, Any]] = []
    project_settings: list[dict[str, Any]] = []
    input_map: list[dict[str, Any]] = []
    verification: list[str] = []
    seen_verification: set[str] = set()
    seen_autoloads: dict[str, str] = {}
    seen_project_settings: set[str] = set()
    seen_input_actions: set[str] = set()

    for pack_id in active_ids:
        pack = packs[pack_id]
        for plugin_id in pack.get("plugins", []):
            add_plugin(plugin_id)
        for autoload in pack.get("autoloads", []):
            name = autoload["name"]
            path = autoload["path"]
            if name in seen_autoloads and seen_autoloads[name] != path:
                raise ValueError(
                    f"pack '{pack_id}' autoload '{name}' conflicts with existing autoload path '{seen_autoloads[name]}'"
                )
            if name not in seen_autoloads:
                autoloads.append(autoload)
                seen_autoloads[name] = path
        for setting in pack.get("project_settings", []):
            path = setting["path"]
            if path in seen_project_settings:
                raise ValueError(f"pack '{pack_id}' duplicates project setting '{path}'")
            project_settings.append(setting)
            seen_project_settings.add(path)
        for action in pack.get("input_map", []):
            action_name = action["action"]
            if action_name in seen_input_actions:
                raise ValueError(f"pack '{pack_id}' duplicates input action '{action_name}'")
            input_map.append(action)
            seen_input_actions.add(action_name)
        for verification_entry in pack.get("verification", []):
            if verification_entry not in seen_verification:
                verification.append(verification_entry)
                seen_verification.add(verification_entry)

    copy_packs = [pack_id for pack_id in selected if pack_id != "base"]
    return {
        "selected_packs": selected,
        "active_packs": active_ids,
        "copy_packs": copy_packs,
        "plugins": plugins,
        "autoloads": autoloads,
        "project_settings": project_settings,
        "input_map": input_map,
        "verification": verification,
    }


def godot_value(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        if value.startswith(("PackedStringArray(", "Vector2", "Vector3", "Color(", "NodePath(")):
            return value
        return json.dumps(value)
    if isinstance(value, list):
        return json.dumps(value)
    if value is None:
        return "null"
    return json.dumps(value, ensure_ascii=False)


def render_project(plan: dict[str, Any], template: Path) -> str:
    plugin_list = ", ".join(json.dumps(plugin) for plugin in plan["plugins"])
    text = template.read_text(encoding="utf-8")
    text = text.replace("__EDITOR_PLUGIN_LIST__", plugin_list)

    sections: list[str] = []
    if plan["autoloads"]:
        lines = ["[autoload]", ""]
        for autoload in plan["autoloads"]:
            singleton_prefix = "*" if autoload.get("singleton", True) else ""
            lines.append(f'{autoload["name"]}="{singleton_prefix}{autoload["path"]}"')
        sections.append("\n".join(lines))

    grouped_settings: dict[str, list[tuple[str, Any]]] = defaultdict(list)
    for setting in plan["project_settings"]:
        section, key = str(setting["path"]).split("/", 1)
        grouped_settings[section].append((key, setting["value"]))
    for section, values in grouped_settings.items():
        lines = [f"[{section}]", ""]
        for key, value in values:
            lines.append(f"{key}={godot_value(value)}")
        sections.append("\n".join(lines))

    if plan["input_map"]:
        lines = ["[input]", ""]
        for action in plan["input_map"]:
            name = action["action"]
            deadzone = action.get("deadzone", 0.5)
            lines.append(f'{name}={{"deadzone": {deadzone}, "events": []}}')
        sections.append("\n".join(lines))

    rendered = text.rstrip() + "\n"
    if sections:
        rendered += "\n" + "\n\n".join(sections).rstrip() + "\n"
    return rendered


def render_report(plan: dict[str, Any]) -> str:
    lines = [
        "[bootstrap] Dry-run injection report",
        f"[bootstrap] Selected packs: {','.join(plan['selected_packs']) or '(none)'}",
        f"[bootstrap] Active packs: {','.join(plan['active_packs'])}",
        f"[bootstrap] Packs to overlay: {','.join(plan['copy_packs']) or '(none)'}",
        f"[bootstrap] Enabled plugins: {', '.join(plan['plugins']) or '(none)'}",
    ]
    lines.append("[bootstrap] Autoloads:")
    if plan["autoloads"]:
        for autoload in plan["autoloads"]:
            lines.append(f"  - {autoload['name']}: {autoload['path']}")
    else:
        lines.append("  - (none)")
    lines.append("[bootstrap] Project settings:")
    if plan["project_settings"]:
        for setting in plan["project_settings"]:
            lines.append(f"  - {setting['path']}={godot_value(setting['value'])}")
    else:
        lines.append("  - (none)")
    lines.append("[bootstrap] Verification:")
    if plan["verification"]:
        for item in plan["verification"]:
            lines.append(f"  - {item}")
    else:
        lines.append("  - (none)")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate and render godot-toolbox pack manifest data.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("validate")

    report_parser = subparsers.add_parser("report")
    report_parser.add_argument("--packs", default="")

    plugins_parser = subparsers.add_parser("plugins")
    plugins_parser.add_argument("--packs", default="")

    render_parser = subparsers.add_parser("render-project")
    render_parser.add_argument("--packs", default="")
    render_parser.add_argument("--template", required=True)

    args = parser.parse_args()
    manifest = load_manifest()

    try:
        if args.command == "validate":
            validate_manifest(manifest)
            print("[pack-manifest] PASS")
            return 0

        plan = collect_plan(manifest, getattr(args, "packs", ""))
        if args.command == "report":
            sys.stdout.write(render_report(plan))
            return 0
        if args.command == "plugins":
            print(", ".join(json.dumps(plugin) for plugin in plan["plugins"]))
            return 0
        if args.command == "render-project":
            sys.stdout.write(render_project(plan, Path(args.template)))
            return 0
    except ValueError as exc:
        print(f"[pack-manifest] ERROR: {exc}", file=sys.stderr)
        return 1

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
