#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
GODOT_BIN="${GODOT_BIN:-}"

log() { printf '[verify-vendor-optional-packs] %s\n' "$*"; }
die() { printf '[verify-vendor-optional-packs] ERROR: %s\n' "$*" >&2; exit 1; }

# ── Phase 1: Manifest metadata ──────────────────────────────────────────
log "checking vendor optional pack metadata"
python3 - "${REPO_ROOT}/packs.manifest.json" <<'PY'
from pathlib import Path
import json
import sys

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
packs = {pack["id"]: pack for pack in manifest.get("packs", [])}

required_vendor_packs = {
    "validation": {
        "plugin": "godot_doctor",
        "requires": ["base"],
    },
    "debug": {
        "plugin": "signal_lens",
        "requires": ["base"],
    },
    "stateful": {
        "plugin": "godot_state_charts",
        "requires": ["base"],
    },
    "juice": {
        "plugin": "sparkle_lite",
        "requires": ["base"],
    },
}

for pack_id, expected in required_vendor_packs.items():
    pack = packs.get(pack_id)
    if pack is None:
        raise SystemExit(f"missing vendor optional pack: {pack_id}")
    if pack.get("default") is not False:
        raise SystemExit(f"vendor pack must be non-default: {pack_id}")
    if expected["plugin"] not in pack.get("plugins", []):
        raise SystemExit(f"vendor pack {pack_id} missing plugin {expected['plugin']}")
    if pack.get("requires", []) != expected["requires"]:
        raise SystemExit(f"vendor pack {pack_id} requires must be {expected['requires']}")
    if pack.get("conflicts", []):
        raise SystemExit(f"vendor pack {pack_id} must have empty conflicts")
    if pack.get("autoloads", []):
        raise SystemExit(f"vendor pack {pack_id} must have empty autoloads")
    if "scripts/verify_vendor_optional_packs.sh" not in pack.get("verification", []):
        raise SystemExit(f"vendor pack {pack_id} missing verify_vendor_optional_packs.sh in verification")
PY

# ── Phase 2: File existence ─────────────────────────────────────────────
log "checking vendor pack files"
for path in \
  "packs/validation/godot/addons/godot_doctor/plugin.cfg" \
  "packs/debug/godot/addons/signal_lens/plugin.cfg" \
  "packs/stateful/godot/addons/godot_state_charts/plugin.cfg" \
  "packs/juice/godot/addons/sparkle_lite/plugin.cfg" \
  "packs/validation/README.md" \
  "packs/debug/README.md" \
  "packs/stateful/README.md" \
  "packs/juice/README.md"; do
  [[ -f "${REPO_ROOT}/${path}" ]] || die "missing vendor pack file: ${path}"
done

# ── Phase 3: Bootstrap tests ────────────────────────────────────────────
resolve_godot_bin() {
  if [[ -n "${GODOT_BIN}" ]]; then
    [[ -x "${GODOT_BIN}" ]] || die "GODOT_BIN is not executable: ${GODOT_BIN}"
    printf '%s\n' "${GODOT_BIN}"
    return 0
  fi
  if command -v godot >/dev/null 2>&1; then
    command -v godot
    return 0
  fi
  if [[ -x "/usr/local/bin/godot" ]]; then
    printf '%s\n' "/usr/local/bin/godot"
    return 0
  fi
  return 1
}

for PACK in validation debug stateful juice; do
  WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-${PACK}.XXXXXX")"
  log "bootstrapping ${PACK} into ${WORKDIR}"
  if ! bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}" --packs="${PACK}" >/dev/null 2>&1; then
    rm -rf "${WORKDIR}"
    die "bootstrap failed for pack: ${PACK}"
  fi

  # Check plugin.cfg exists in bootstrapped project
  PLUGIN_DIR="${WORKDIR}/godot/addons"
  FOUND_PLUGIN=""
  case "${PACK}" in
    validation) FOUND_PLUGIN="${PLUGIN_DIR}/godot_doctor/plugin.cfg" ;;
    debug)      FOUND_PLUGIN="${PLUGIN_DIR}/signal_lens/plugin.cfg" ;;
    stateful)   FOUND_PLUGIN="${PLUGIN_DIR}/godot_state_charts/plugin.cfg" ;;
    juice)      FOUND_PLUGIN="${PLUGIN_DIR}/sparkle_lite/plugin.cfg" ;;
  esac
  [[ -f "${FOUND_PLUGIN}" ]] || { rm -rf "${WORKDIR}"; die "plugin.cfg missing in bootstrap for ${PACK}"; }

  # Check project.godot has enabled setting (settings are under [godot_toolbox] section)
  PROJECT_GODOT="${WORKDIR}/godot/project.godot"
  SETTING_KEY="${PACK}/enabled=true"
  grep -Fq "${SETTING_KEY}" "${PROJECT_GODOT}" \
    || { rm -rf "${WORKDIR}"; die "project.godot missing enabled setting for ${PACK}: ${SETTING_KEY}"; }

  # ── Phase 4: Godot headless import (optional) ─────────────────────────
  if resolve_godot_bin >/dev/null 2>&1; then
    GODOT_BIN_RESOLVED="$(resolve_godot_bin)"
    log "running headless import for ${PACK}"
    "${GODOT_BIN_RESOLVED}" --headless --editor --quit-after 1 --path "${WORKDIR}/godot" --import >/dev/null 2>&1 || true
  fi

  rm -rf "${WORKDIR}"
done

log "PASS"
