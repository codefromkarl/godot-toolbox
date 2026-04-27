#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '[verify-specialized-candidates] %s\n' "$*"; }
die() { printf '[verify-specialized-candidates] ERROR: %s\n' "$*" >&2; exit 1; }

log "checking specialized pack readiness metadata"
python3 - "${REPO_ROOT}/packs.manifest.json" <<'PY'
from pathlib import Path
import json
import sys

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
packs = {pack["id"]: pack for pack in manifest.get("packs", [])}

required_optional_packs = {
    "inventory": {
        "plugin": "gloot",
        "requires": {"base", "data-core", "save-core"},
    },
    "quest": {
        "plugin": "quest_system",
        "requires": {"base", "data-core", "save-core", "rules-events-core"},
    },
    "ai-behavior": {
        "plugin": "beehave",
        "requires": {"base"},
    },
    "save-state-lite": {
        "plugin": "savestate",
        "requires": {"base"},
    },
}
for pack_id, expected in required_optional_packs.items():
    pack = packs.get(pack_id)
    if pack is None:
        raise SystemExit(f"missing specialized optional pack: {pack_id}")
    if pack.get("default") is not False:
        raise SystemExit(f"specialized pack must be non-default: {pack_id}")
    if expected["plugin"] not in pack.get("plugins", []):
        raise SystemExit(f"specialized pack {pack_id} missing plugin {expected['plugin']}")
    missing_requires = expected["requires"].difference(pack.get("requires", []))
    if missing_requires:
        raise SystemExit(f"specialized pack {pack_id} missing requires: {sorted(missing_requires)}")
    if pack_id == "save-state-lite" and "save-core" not in pack.get("conflicts", []):
        raise SystemExit("save-state-lite must conflict with save-core because both expose SaveSlot")

references = {item.get("id"): item for item in manifest.get("open_source_references", [])}
required = {
    "quest_system": "quest",
    "dialogue_manager": "dialogue",
    "gloot": "inventory",
    "beehave": "ai",
    "limboai": "ai",
}
for ref_id, direction in required.items():
    item = references.get(ref_id)
    if item is None:
        raise SystemExit(f"missing candidate reference: {ref_id}")
    for field in ("url", "status", "absorption_mode"):
        if not item.get(field):
            raise SystemExit(f"candidate {ref_id} missing {field}")
    if item.get("pack_direction") != direction:
        raise SystemExit(f"candidate {ref_id} direction mismatch")

required_contracts = {"data-core", "save-core", "rules-events-core"}
missing_contracts = required_contracts.difference(packs)
if missing_contracts:
    raise SystemExit(f"candidate gating contracts missing active pack definitions: {sorted(missing_contracts)}")
PY

log "checking specialized pack files"
for path in \
  "packs/inventory/godot/addons/gloot/plugin.cfg" \
  "packs/quest/godot/addons/quest_system/plugin.cfg" \
  "packs/ai-behavior/godot/addons/beehave/plugin.cfg" \
  "packs/save-state-lite/godot/addons/savestate/plugin.cfg" \
  "packs/inventory/README.md" \
  "packs/quest/README.md" \
  "packs/ai-behavior/README.md" \
  "packs/save-state-lite/README.md" \
  "docs/rpg-template-absorption-plan.md"; do
  [[ -f "${REPO_ROOT}/${path}" ]] || die "missing specialized pack file: ${path}"
done

log "checking candidate docs mention readiness boundaries"
grep -Fq "Candidate Optional Packs" "${REPO_ROOT}/docs/open-source-architecture-links.md" \
  || die "open-source architecture links missing candidate section"
grep -Fq "rules-events-core" "${REPO_ROOT}/docs/open-source-architecture-links.md" \
  || die "open-source architecture links must mention rules-events-core gating"
grep -Fq "RPG Template Absorption Plan" "${REPO_ROOT}/docs/rpg-template-absorption-plan.md" \
  || die "RPG absorption plan missing title"

log "PASS"
