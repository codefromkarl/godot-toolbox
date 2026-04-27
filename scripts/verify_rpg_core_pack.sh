#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""
PACKS="rpg-core,data-core,save-core"

log() { printf '[verify-rpg-core] %s\n' "$*"; }
die() { printf '[verify-rpg-core] ERROR: %s\n' "$*" >&2; exit 1; }

cleanup() {
  if [[ -n "${WORKDIR}" && -d "${WORKDIR}" ]]; then
    rm -rf "${WORKDIR}"
  fi
}
trap cleanup EXIT

log "validating manifest and dry-run report"
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

log "PASS"
