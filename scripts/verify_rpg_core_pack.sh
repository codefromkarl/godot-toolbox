#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""
ADAPTER_WORKDIR=""
PACKS="rpg-core,data-core,save-core"
ADAPTER_PACKS="inventory,data-core,save-core,rpg-core"
GODOT_BIN="${GODOT_BIN:-}"

log() { printf '[verify-rpg-core] %s\n' "$*"; }
die() { printf '[verify-rpg-core] ERROR: %s\n' "$*" >&2; exit 1; }

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

log "validating manifest and dry-run report"
GODOT_BIN="$(resolve_godot_bin)"
python3 "${REPO_ROOT}/scripts/pack_manifest.py" validate >/dev/null
report="$(python3 "${REPO_ROOT}/scripts/pack_manifest.py" report --packs="${PACKS}")"
for expected in \
  "Selected packs: ${PACKS}" \
  "RPGCore: res://addons/godot_toolbox_architecture/rpg_core/rpg_core.gd" \
  "godot_toolbox/rpg_core/enabled=true" \
  "scripts/verify_rpg_core_pack.sh"
do
  grep -Fq "${expected}" <<<"${report}" || die "dry-run report missing: ${expected}"
done

WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-rpg-core.XXXXXX")"
log "bootstrapping ${PACKS} into ${WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}" --packs="${PACKS}" >/dev/null

required_files=(
  "godot/addons/godot_toolbox_architecture/rpg_core/rpg_core.gd"
  "godot/addons/godot_toolbox_architecture/data_core/data_core.gd"
  "godot/addons/godot_toolbox_architecture/save_core/save_core.gd"
)
for path in "${required_files[@]}"; do
  [[ -f "${WORKDIR}/${path}" ]] || die "required file missing from bootstrap: ${path}"
done

grep -Fq 'RPGCore="*res://addons/godot_toolbox_architecture/rpg_core/rpg_core.gd"' \
  "${WORKDIR}/godot/project.godot" || die "project.godot missing RPGCore autoload"

"${GODOT_BIN}" --headless --editor --quit-after 1 --path "${WORKDIR}/godot" --import >/dev/null
log "running rpg-core domain smoke"
"${GODOT_BIN}" --headless --path "${WORKDIR}/godot" \
  --script res://addons/godot_toolbox_architecture/rpg_core/tests/rpg_core_domain_smoke.gd >/dev/null

log "running rpg-core GLoot adapter smoke"
ADAPTER_WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-rpg-core-adapter.XXXXXX")"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${ADAPTER_WORKDIR}" --packs="${ADAPTER_PACKS}" >/dev/null
"${GODOT_BIN}" --headless --editor --quit-after 1 --path "${ADAPTER_WORKDIR}/godot" --import >/dev/null
"${GODOT_BIN}" --headless --path "${ADAPTER_WORKDIR}/godot" \
  --script res://addons/godot_toolbox_architecture/rpg_core/tests/rpg_core_gloot_adapter_smoke.gd >/dev/null
rm -rf "${ADAPTER_WORKDIR}"
ADAPTER_WORKDIR=""

log "PASS"
