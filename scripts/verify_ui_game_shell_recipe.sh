#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${REPO_ROOT}/docs/ui-game-shell-recipe.md"
UI_README="${REPO_ROOT}/packs/ui-game-shell/README.md"
SHELL_README="${REPO_ROOT}/packs/shell/README.md"
CATALOG="${REPO_ROOT}/docs/plugin-catalog.md"

log() { printf '[verify-ui-game-shell-recipe] %s\n' "$*"; }
die() { printf '[verify-ui-game-shell-recipe] ERROR: %s\n' "$*" >&2; exit 1; }

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
  local matches
  matches="$(grep -Ein -- "${pattern}" "${file}" || true)"
  if [[ -n "${matches}" ]]; then
    printf '%s\n' "${matches}" >&2
    die "${file#${REPO_ROOT}/} contains forbidden pattern: ${pattern}"
  fi
}

require_file "${DOC}"
require_file "${UI_README}"
require_file "${SHELL_README}"
require_file "${CATALOG}"

log "checking recipe boundary language"
for text in \
  '# UI Game Shell Recipe' \
  'ui-game-shell is the default governed extension route' \
  "shell/Maaack's Game Template is a candidate/reference" \
  'must not take over `run/main_scene`' \
  'must not add or replace project autoloads' \
  'must not become the save truth' \
  'must not replace the FlowCore stack' \
  'Menus, pause, settings, and loading ideas may be absorbed selectively'; do
  require_text "${DOC}" "${text}"
done

log "checking executable verification commands"
require_text "${DOC}" "python3 scripts/pack_manifest.py report --packs=ui-game-shell"
require_text "${DOC}" "bash scripts/verify_ui_game_shell_recipe.sh"
require_text "${DOC}" "bash scripts/verify_ui_game_shell_pack.sh"

log "checking ui-game-shell manifest report"
report="$(python3 "${REPO_ROOT}/scripts/pack_manifest.py" report --packs=ui-game-shell)"
for expected in \
  "Selected packs: ui-game-shell" \
  "godot_toolbox/ui_game_shell/enabled=true" \
  "scripts/verify_ui_game_shell_pack.sh"; do
  grep -Fq "${expected}" <<<"${report}" || die "pack report missing: ${expected}"
done
if grep -Fq "maaacks_game_template" <<<"${report}"; then
  die "ui-game-shell report must not enable Maaack shell candidate"
fi

log "checking README and catalog links"
require_text "${UI_README}" "docs/ui-game-shell-recipe.md"
require_text "${SHELL_README}" "docs/ui-game-shell-recipe.md"
require_text "${CATALOG}" "docs/ui-game-shell-recipe.md"

log "checking repository-portable documentation paths"
for file in "${DOC}" "${UI_README}" "${SHELL_README}" "${CATALOG}"; do
  require_absent_regex "${file}" '(^|[^A-Za-z0-9_./:-])/(home|tmp)/'
  require_absent_regex "${file}" 'file://'
done

log "PASS"
