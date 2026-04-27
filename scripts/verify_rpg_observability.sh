#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""
PACKS="rpg-test-kit,rpg-battle-core,rpg-core,rpg-save-adapter,flow-core,rules-events-core,data-core,save-core"
GODOT_BIN="${GODOT_BIN:-}"

log() { printf '[verify-rpg-observability] %s\n' "$*"; }
die() { printf '[verify-rpg-observability] ERROR: %s\n' "$*" >&2; exit 1; }

cleanup() {
  if [[ -n "${WORKDIR}" && -d "${WORKDIR}" ]]; then
    rm -rf "${WORKDIR}"
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

log "validating manifest and observability docs"
GODOT_BIN="$(resolve_godot_bin)"
python3 "${REPO_ROOT}/scripts/pack_manifest.py" validate >/dev/null
for required in \
  "RPG-ready shell" \
  "complete RPG template" \
  "Completion language allowed" \
  "Runtime" \
  "Interaction"
do
  grep -Fq "${required}" "${REPO_ROOT}/docs/rpg-acceptance-matrix.md" \
    || die "acceptance matrix missing: ${required}"
done

report="$(python3 "${REPO_ROOT}/scripts/pack_manifest.py" report --packs="${PACKS}")"
for expected in \
  "Selected packs: ${PACKS}" \
  "scripts/verify_rpg_observability.sh" \
  "scripts/verify_rpg_ui_content.sh" \
  "scripts/verify_rpg_test_kit_pack.sh"
do
  grep -Fq "${expected}" <<<"${report}" || die "dry-run report missing: ${expected}"
done

WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-rpg-observability.XXXXXX")"
log "bootstrapping ${PACKS} into ${WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}" --packs="${PACKS}" >/dev/null
"${GODOT_BIN}" --headless --editor --quit-after 1 --path "${WORKDIR}/godot" --import >/dev/null

log "running deterministic replay smoke"
"${GODOT_BIN}" --headless --path "${WORKDIR}/godot" \
  --script res://addons/godot_toolbox_architecture/rpg_test_kit/tests/rpg_battle_replay_smoke.gd >/dev/null

log "running state dump smoke"
"${GODOT_BIN}" --headless --path "${WORKDIR}/godot" \
  --script res://addons/godot_toolbox_architecture/rpg_test_kit/tests/rpg_state_dump_smoke.gd >/dev/null

log "PASS"
