#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${REPO_ROOT}/docs/rpg-content-authoring.md"
QUICKSTART="${REPO_ROOT}/docs/rpg-template-quickstart.md"
ART_DOC="${REPO_ROOT}/docs/rpg-art-asset-sources.md"
CONTENT="${REPO_ROOT}/packs/rpg-core/godot/content/rpg_example/rpg_example_content.json"

log() { printf '[verify-rpg-content-authoring] %s\n' "$*"; }
die() { printf '[verify-rpg-content-authoring] ERROR: %s\n' "$*" >&2; exit 1; }

require_file() {
  local path="$1"
  [[ -f "${path}" ]] || die "missing required file: ${path#${REPO_ROOT}/}"
}

require_text() {
  local file="$1"
  local text="$2"
  grep -Fq -- "${text}" "${file}" || die "${file#${REPO_ROOT}/} missing: ${text}"
}

require_no_local_absolute_paths() {
  local file="$1"
  if grep -Eq '(^|[^[:alnum:]_.-])(/home/|/tmp/|file://)' "${file}"; then
    die "${file#${REPO_ROOT}/} contains a local absolute path"
  fi
}

require_file "${DOC}"
require_file "${QUICKSTART}"
require_file "${ART_DOC}"
require_file "${CONTENT}"

log "checking example content JSON parses"
python3 - "${CONTENT}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
if not isinstance(data, dict):
    raise SystemExit("example content JSON must parse as an object")
PY

log "checking content authoring boundaries"
for text in \
  "teaching material, verifier fixture data, and sample data" \
  "not:" \
  "A balance standard for a production RPG." \
  "Release content for a shipped game." \
  "Content IDs and RPG state data shape" \
  "rpg-core" \
  "data-core" \
  "Art asset references" \
  "rpg-art-demo" \
  "Save schema and migrations" \
  "rpg-save-adapter" \
  "save-core" \
  "Battle formulas and combat rules" \
  "rpg-battle-core" \
  "Third-party plugin truth" \
  "The example content file must not contain:"; do
  require_text "${DOC}" "${text}"
done

log "checking linked docs mention governance boundary"
require_text "${QUICKSTART}" "docs/rpg-content-authoring.md"
require_text "${ART_DOC}" "docs/rpg-content-authoring.md"
require_text "${ART_DOC}" "must not define canonical RPG stats, item IDs, save schemas, or battle rules"

log "checking authored docs avoid local absolute paths"
for file in "${DOC}" "${QUICKSTART}" "${ART_DOC}"; do
  require_no_local_absolute_paths "${file}"
done

log "PASS"
