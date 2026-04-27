#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""
ADAPTER_WORKDIR=""
PACKS="rpg-battle-core,rpg-core,flow-core,rules-events-core,data-core,save-core"
ADAPTER_PACKS="ai-behavior,rpg-battle-core,rpg-core,flow-core,rules-events-core,data-core,save-core"
GODOT_BIN="${GODOT_BIN:-}"

log() { printf '[verify-rpg-battle-core] %s\n' "$*"; }
die() { printf '[verify-rpg-battle-core] ERROR: %s\n' "$*" >&2; exit 1; }

cleanup() {
  if [[ -n "${WORKDIR}" && -d "${WORKDIR}" ]]; then
    rm -rf "${WORKDIR}"
  fi
  if [[ -n "${ADAPTER_WORKDIR}" && -d "${ADAPTER_WORKDIR}" ]]; then
    rm -rf "${ADAPTER_WORKDIR}"
  fi
}
trap cleanup EXIT

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
  die "Godot binary not found. Install Godot 4.6.x and expose it as 'godot', or set GODOT_BIN."
}

run_godot_allow_beehave_teardown_noise() {
  local log_path
  log_path="$(mktemp "${TMP_ROOT%/}/godot-toolbox-beehave.XXXXXX.log")"
  set +e
  "$@" >"${log_path}" 2>&1
  local status=$?
  set -e
  python3 - "${log_path}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
filtered = [
    line for line in lines
    if "Capture not registered: 'beehave'" not in line
    and "unregister_message_capture" not in line
]
text = "\n".join(filtered)
if text:
    print(text)
if "SCRIPT ERROR" in text or "ERROR:" in text:
    raise SystemExit(2)
PY
  local filter_status=$?
  rm -f "${log_path}"
  if [[ "${status}" -ne 0 ]]; then
    return "${status}"
  fi
  return "${filter_status}"
}

log "validating manifest and dry-run report"
GODOT_BIN="$(resolve_godot_bin)"
python3 "${REPO_ROOT}/scripts/pack_manifest.py" validate >/dev/null
report="$(python3 "${REPO_ROOT}/scripts/pack_manifest.py" report --packs="${PACKS}")"
for expected in \
  "Selected packs: ${PACKS}" \
  "RPGBattleCore: res://addons/godot_toolbox_architecture/rpg_battle_core/rpg_battle_core.gd" \
  "RPGCore: res://addons/godot_toolbox_architecture/rpg_core/rpg_core.gd" \
  "FlowCore: res://addons/godot_toolbox_architecture/flow_core/flow_core.gd" \
  "RulesEventsCore: res://addons/godot_toolbox_architecture/rules_events_core/rules_events_core.gd" \
  "godot_toolbox/rpg_battle_core/enabled=true" \
  "scripts/verify_rpg_battle_core_pack.sh"
do
  grep -Fq "${expected}" <<<"${report}" || die "dry-run report missing: ${expected}"
done

WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-rpg-battle-core.XXXXXX")"
log "bootstrapping ${PACKS} into ${WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}" --packs="${PACKS}" >/dev/null

required_files=(
  "godot/addons/godot_toolbox_architecture/rpg_battle_core/rpg_battle_core.gd"
  "godot/addons/godot_toolbox_architecture/rpg_core/rpg_core.gd"
  "godot/addons/godot_toolbox_architecture/flow_core/flow_core.gd"
  "godot/addons/godot_toolbox_architecture/rules_events_core/rules_events_core.gd"
)
for path in "${required_files[@]}"; do
  [[ -f "${WORKDIR}/${path}" ]] || die "required file missing from bootstrap: ${path}"
done

grep -Fq 'RPGBattleCore="*res://addons/godot_toolbox_architecture/rpg_battle_core/rpg_battle_core.gd"' \
  "${WORKDIR}/godot/project.godot" || die "project.godot missing RPGBattleCore autoload"

"${GODOT_BIN}" --headless --editor --quit-after 1 --path "${WORKDIR}/godot" --import >/dev/null
log "running rpg-battle-core domain smoke"
"${GODOT_BIN}" --headless --path "${WORKDIR}/godot" \
  --script res://addons/godot_toolbox_architecture/rpg_battle_core/tests/rpg_battle_core_smoke.gd >/dev/null

log "running optional Beehave adapter smoke"
ADAPTER_WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-rpg-battle-adapter.XXXXXX")"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${ADAPTER_WORKDIR}" --packs="${ADAPTER_PACKS}" >/dev/null
run_godot_allow_beehave_teardown_noise \
  "${GODOT_BIN}" --headless --editor --quit-after 1 --path "${ADAPTER_WORKDIR}/godot" --import >/dev/null
run_godot_allow_beehave_teardown_noise \
  "${GODOT_BIN}" --headless --path "${ADAPTER_WORKDIR}/godot" \
  --script res://addons/godot_toolbox_architecture/rpg_battle_core/tests/rpg_battle_beehave_adapter_smoke.gd >/dev/null
rm -rf "${ADAPTER_WORKDIR}"
ADAPTER_WORKDIR=""

log "PASS"
