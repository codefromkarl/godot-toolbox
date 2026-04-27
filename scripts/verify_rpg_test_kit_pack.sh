#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""
PACKS="rpg-test-kit,rpg-battle-core,rpg-core,flow-core,rules-events-core,data-core,save-core"

log() { printf '[verify-rpg-test-kit] %s\n' "$*"; }
die() { printf '[verify-rpg-test-kit] ERROR: %s\n' "$*" >&2; exit 1; }

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
  "godot_toolbox/rpg_test_kit/enabled=true" \
  "scripts/verify_rpg_test_kit_pack.sh" \
  "scripts/verify_rpg_battle_core_pack.sh" \
  "scripts/verify_rpg_core_pack.sh"
do
  grep -Fq "${expected}" <<<"${report}" || die "dry-run report missing: ${expected}"
done

WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-rpg-test-kit.XXXXXX")"
log "bootstrapping ${PACKS} into ${WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}" --packs="${PACKS}" >/dev/null

required_files=(
  "godot/addons/godot_toolbox_architecture/rpg_test_kit/rpg_readiness_smoke.gd"
  "godot/addons/godot_toolbox_architecture/rpg_battle_core/rpg_battle_core.gd"
  "godot/addons/godot_toolbox_architecture/rpg_core/rpg_core.gd"
)
for path in "${required_files[@]}"; do
  [[ -f "${WORKDIR}/${path}" ]] || die "required file missing from bootstrap: ${path}"
done

grep -Fq 'rpg_test_kit/enabled=true' \
  "${WORKDIR}/godot/project.godot" || die "project.godot missing rpg-test-kit setting"

log "PASS"
