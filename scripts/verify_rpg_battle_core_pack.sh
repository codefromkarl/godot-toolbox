#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""
PACKS="rpg-battle-core,rpg-core,flow-core,rules-events-core,data-core,save-core"

log() { printf '[verify-rpg-battle-core] %s\n' "$*"; }
die() { printf '[verify-rpg-battle-core] ERROR: %s\n' "$*" >&2; exit 1; }

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

log "PASS"
