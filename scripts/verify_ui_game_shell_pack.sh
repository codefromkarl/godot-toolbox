#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""
GODOT_BIN="${GODOT_BIN:-}"
PACKS="ui-game-shell,flow-core"

log() { printf '[verify-ui-game-shell] %s\n' "$*"; }
die() { printf '[verify-ui-game-shell] ERROR: %s\n' "$*" >&2; exit 1; }

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

GODOT_BIN="$(resolve_godot_bin)"

log "validating manifest and dry-run report"
python3 "${REPO_ROOT}/scripts/pack_manifest.py" validate >/dev/null
report="$(python3 "${REPO_ROOT}/scripts/pack_manifest.py" report --packs="${PACKS}")"
for expected in \
  "Selected packs: ${PACKS}" \
  "godot_toolbox/ui_game_shell/enabled=true" \
  "scripts/verify_ui_game_shell_pack.sh"
do
  grep -Fq "${expected}" <<<"${report}" || die "dry-run report missing: ${expected}"
done
if grep -Fq "maaacks_game_template" <<<"${report}"; then
  die "ui-game-shell must not enable Maaack shell candidate"
fi

WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-ui-shell.XXXXXX")"
log "bootstrapping ${PACKS} into ${WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}" --packs="${PACKS}" >/dev/null

required_files=(
  "godot/addons/godot_toolbox_architecture/ui_game_shell/shell_root.gd"
  "godot/addons/godot_toolbox_architecture/ui_game_shell/modal_layer.gd"
  "godot/addons/godot_toolbox_architecture/ui_game_shell/tests/ui_game_shell_smoke.gd"
)
for path in "${required_files[@]}"; do
  [[ -f "${WORKDIR}/${path}" ]] || die "required file missing from bootstrap: ${path}"
done

if [[ -d "${WORKDIR}/godot/addons/maaacks_game_template" ]]; then
  die "ui-game-shell bootstrap must not copy Maaack shell candidate"
fi

log "running headless import"
"${GODOT_BIN}" --headless --editor --quit-after 1 --path "${WORKDIR}/godot" --import >/dev/null

log "running ui-game-shell smoke"
"${GODOT_BIN}" --headless --path "${WORKDIR}/godot" \
  --script res://addons/godot_toolbox_architecture/ui_game_shell/tests/ui_game_shell_smoke.gd

log "PASS"
