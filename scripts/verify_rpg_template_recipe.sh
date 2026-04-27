#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUICKSTART="${REPO_ROOT}/docs/rpg-template-quickstart.md"
RECIPES="${REPO_ROOT}/docs/rpg-pack-recipes.md"
README="${REPO_ROOT}/README.md"
LOG="${REPO_ROOT}/docs/rpg-execution-verification-log.md"
TMP_ROOT="${TMPDIR:-/tmp}"
CONFLICT_LOG=""

log() { printf '[verify-rpg-template-recipe] %s\n' "$*"; }
die() { printf '[verify-rpg-template-recipe] ERROR: %s\n' "$*" >&2; exit 1; }

cleanup() {
  if [[ -n "${CONFLICT_LOG}" && -f "${CONFLICT_LOG}" ]]; then
    rm -f "${CONFLICT_LOG}"
  fi
}
trap cleanup EXIT

require_file() {
  local path="$1"
  [[ -f "${path}" ]] || die "missing required file: ${path#${REPO_ROOT}/}"
}

require_text() {
  local file="$1"
  local text="$2"
  grep -Fq -- "${text}" "${file}" || die "${file#${REPO_ROOT}/} missing: ${text}"
}

require_absent_text() {
  local file="$1"
  local text="$2"
  if grep -Fq -- "${text}" "${file}"; then
    die "${file#${REPO_ROOT}/} contains forbidden text: ${text}"
  fi
}

require_file "${QUICKSTART}"
require_file "${RECIPES}"
require_file "${README}"
require_file "${LOG}"

MINIMAL_PACKS="rpg-core,rpg-battle-core,rpg-save-adapter,rpg-test-kit,flow-core,rules-events-core,data-core,save-core"

log "checking quickstart pack ids and install order"
for text in \
  "Minimal RPG Template Recipe" \
  "Required packs" \
  "Optional packs" \
  "Install order" \
  "Verification commands" \
  "Conflict boundaries" \
  "Completion-language boundary" \
  "docs/rpg-final-acceptance-receipt.md" \
  "docs/rpg-execution-verification-log.md" \
  "rpg-core" \
  "rpg-battle-core" \
  "rpg-save-adapter" \
  "rpg-test-kit" \
  "flow-core" \
  "rules-events-core" \
  "data-core" \
  "save-core" \
  "inventory" \
  "quest" \
  "ai-behavior" \
  "save-state-lite"; do
  require_text "${QUICKSTART}" "${text}"
done

log "checking documented executable commands"
for text in \
  "python3 scripts/pack_manifest.py validate" \
  "python3 scripts/pack_manifest.py report --packs=${MINIMAL_PACKS}" \
  "bash scripts/verify_pack_matrix.sh --row=${MINIMAL_PACKS}" \
  "bash scripts/verify_rpg_final_acceptance.sh" \
  "bash scripts/verify_rpg_template_recipe.sh"; do
  require_text "${QUICKSTART}" "${text}"
done

log "checking dry-run recipe can be resolved by manifest"
python3 "${REPO_ROOT}/scripts/pack_manifest.py" report --packs="${MINIMAL_PACKS}" >/dev/null

log "checking save-core and save-state-lite conflict boundary"
for text in \
  "save-state-lite conflicts with save-core" \
  "both expose a global SaveSlot" \
  "do not enable both"; do
  require_text "${QUICKSTART}" "${text}"
done

CONFLICT_LOG="$(mktemp "${TMP_ROOT%/}/godot-toolbox-template-conflict.XXXXXX.log")"
if python3 "${REPO_ROOT}/scripts/pack_manifest.py" report --packs="save-state-lite,save-core" >"${CONFLICT_LOG}" 2>&1; then
  cat "${CONFLICT_LOG}" >&2
  die "save-state-lite,save-core unexpectedly resolved"
fi
require_text "${CONFLICT_LOG}" "conflicts with selected pack 'save-core'"

log "checking recipe docs and README entrypoints"
require_text "${RECIPES}" "docs/rpg-template-quickstart.md"
require_text "${README}" "docs/rpg-template-quickstart.md"

log "checking completion-language boundary"
for text in \
  "RPG-ready shell evidence exists" \
  "complete RPG template evidence exists" \
  "automated Interaction" \
  "Experience" \
  "docs/rpg-experience-review.md"; do
  require_text "${QUICKSTART}" "${text}"
done

for file in "${QUICKSTART}" "${RECIPES}" "${README}"; do
  require_absent_text "${file}" "is playable"
  require_absent_text "${file}" "is release-ready"
  require_absent_text "${file}" "playable template"
  require_absent_text "${file}" "release-ready template"
  require_absent_text "${file}" "ready to ship"
done

log "checking verification log entry"
require_text "${LOG}" "Follow-up Template Productization"
require_text "${LOG}" "scripts/verify_rpg_template_recipe.sh"

log "PASS"
