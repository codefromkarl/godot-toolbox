#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""
QUEST_WORKDIR=""
PACKS="rpg-save-adapter,rpg-core,save-core,rules-events-core,data-core"
QUEST_PACKS="quest,rpg-save-adapter,rpg-core,save-core,rules-events-core,data-core"
GODOT_BIN="${GODOT_BIN:-}"

log() { printf '[verify-rpg-save-adapter] %s\n' "$*"; }
die() { printf '[verify-rpg-save-adapter] ERROR: %s\n' "$*" >&2; exit 1; }

cleanup() {
  if [[ -n "${WORKDIR}" && -d "${WORKDIR}" ]]; then
    rm -rf "${WORKDIR}"
  fi
  if [[ -n "${QUEST_WORKDIR}" && -d "${QUEST_WORKDIR}" ]]; then
    rm -rf "${QUEST_WORKDIR}"
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

run_godot_allow_quest_teardown_noise() {
  local log_path
  log_path="$(mktemp "${TMP_ROOT%/}/godot-toolbox-quest.XXXXXX.log")"
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
    if "ObjectDB instances leaked at exit" not in line
    and "resources still in use at exit" not in line
    and "at: cleanup (core/object/object.cpp" not in line
    and "at: clear (core/io/resource.cpp" not in line
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
  "RPGSaveAdapter: res://addons/godot_toolbox_architecture/rpg_save_adapter/rpg_save_adapter.gd" \
  "RPGCore: res://addons/godot_toolbox_architecture/rpg_core/rpg_core.gd" \
  "SaveCore: res://addons/godot_toolbox_architecture/save_core/save_core.gd" \
  "godot_toolbox/rpg_save_adapter/enabled=true" \
  "scripts/verify_rpg_save_adapter_pack.sh"
do
  grep -Fq "${expected}" <<<"${report}" || die "dry-run report missing: ${expected}"
done

WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-rpg-save-adapter.XXXXXX")"
log "bootstrapping ${PACKS} into ${WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}" --packs="${PACKS}" >/dev/null
"${GODOT_BIN}" --headless --editor --quit-after 1 --path "${WORKDIR}/godot" --import >/dev/null
log "running rpg-save-adapter roundtrip smoke"
"${GODOT_BIN}" --headless --path "${WORKDIR}/godot" \
  --script res://addons/godot_toolbox_architecture/rpg_save_adapter/tests/rpg_save_adapter_smoke.gd >/dev/null

QUEST_WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-rpg-save-quest.XXXXXX")"
log "bootstrapping ${QUEST_PACKS} into ${QUEST_WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${QUEST_WORKDIR}" --packs="${QUEST_PACKS}" >/dev/null
run_godot_allow_quest_teardown_noise \
  "${GODOT_BIN}" --headless --editor --quit-after 1 --path "${QUEST_WORKDIR}/godot" --import >/dev/null
log "running rpg-save-adapter quest smoke"
run_godot_allow_quest_teardown_noise \
  "${GODOT_BIN}" --headless --path "${QUEST_WORKDIR}/godot" \
  --script res://addons/godot_toolbox_architecture/rpg_save_adapter/tests/rpg_quest_save_adapter_smoke.gd >/dev/null

log "PASS"
