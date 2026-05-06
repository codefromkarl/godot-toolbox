#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${REPO_ROOT}/docs/rpg-playable-sample-recipe.md"
QUICKSTART="${REPO_ROOT}/docs/rpg-template-quickstart.md"
RECIPES="${REPO_ROOT}/docs/rpg-pack-recipes.md"
MANIFEST="${REPO_ROOT}/packs.manifest.json"

MINIMAL_PACKS="rpg-core,rpg-battle-core,rpg-save-adapter,rpg-test-kit,flow-core,rules-events-core,data-core,save-core"

log() { printf '[verify-rpg-playable-sample-recipe] %s\n' "$*"; }
die() { printf '[verify-rpg-playable-sample-recipe] ERROR: %s\n' "$*" >&2; exit 1; }

require_file() {
  local path="$1"
  [[ -f "${path}" ]] || die "missing required file: ${path#${REPO_ROOT}/}"
}

require_text() {
  local file="$1"
  local text="$2"
  grep -Fq -- "${text}" "${file}" || die "${file#${REPO_ROOT}/} missing: ${text}"
}

require_absent_regex() {
  local file="$1"
  local pattern="$2"
  if grep -Ein -- "${pattern}" "${file}" >/tmp/rpg_playable_sample_forbidden.$$; then
    cat /tmp/rpg_playable_sample_forbidden.$$ >&2
    rm -f /tmp/rpg_playable_sample_forbidden.$$
    die "${file#${REPO_ROOT}/} contains forbidden overclaim pattern: ${pattern}"
  fi
  rm -f /tmp/rpg_playable_sample_forbidden.$$
}

require_file "${DOC}"
require_file "${QUICKSTART}"
require_file "${RECIPES}"
require_file "${MANIFEST}"

log "checking required route sections and claim boundaries"
for text in \
  "# RPG Playable Sample Recipe" \
  "Current Automated Interaction Sample" \
  "Future Experience/Playable Sample" \
  "Release Claim Boundary" \
  "Current minimal RPG pack set" \
  "rpg-art-demo" \
  "not part of the current required command" \
  "automated Interaction" \
  "Experience/playable" \
  "Release claims are prohibited"; do
  require_text "${DOC}" "${text}"
done

log "checking current minimal recipe command"
require_text "${DOC}" "python3 scripts/pack_manifest.py report --packs=${MINIMAL_PACKS}"
python3 "${REPO_ROOT}/scripts/pack_manifest.py" report --packs="${MINIMAL_PACKS}" >/dev/null

log "checking rpg-art-demo remains optional and non-promotional"
python3 "${REPO_ROOT}/scripts/pack_manifest.py" report --packs="rpg-art-demo" >/dev/null
bash "${REPO_ROOT}/scripts/verify_rpg_art_demo_pack.sh" >/dev/null
require_text "${DOC}" '`rpg-art-demo` is an existing non-default placeholder overlay'
require_text "${DOC}" 'It is not part of the current required command'
require_text "${DOC}" 'must not upgrade the current automated route into an Experience/playable claim'
require_text "${DOC}" 'keeps `rpg-art-demo` optional and non-promotional'
require_absent_regex "${DOC}" 'absent from the manifest'
if grep -Eq -- "--packs=[^\n]*rpg-art-demo" "${DOC}"; then
  die "docs/rpg-playable-sample-recipe.md must not include rpg-art-demo in current --packs commands"
fi

log "checking repository-relative documentation paths"
require_absent_regex "${DOC}" '(^|[^A-Za-z0-9_./-])/(home|tmp)/'
require_absent_regex "${DOC}" 'file://'

log "checking overclaim guardrails"
require_absent_regex "${DOC}" '\bis playable\b'
require_absent_regex "${DOC}" '\brelease-ready\b'
require_absent_regex "${DOC}" '\bready to ship\b'
require_absent_regex "${DOC}" '\bproduction-ready\b'

log "checking entrypoint links"
require_text "${QUICKSTART}" "docs/rpg-playable-sample-recipe.md"
require_text "${RECIPES}" "docs/rpg-playable-sample-recipe.md"

log "PASS"
