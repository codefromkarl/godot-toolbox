#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${REPO_ROOT}/docs/dialogue-pack-candidate-plan.md"
LINKS="${REPO_ROOT}/docs/open-source-architecture-links.md"
CATALOG="${REPO_ROOT}/docs/plugin-catalog.md"

log() { printf '[verify-dialogue-pack-candidate] %s\n' "$*"; }
die() { printf '[verify-dialogue-pack-candidate] ERROR: %s\n' "$*" >&2; exit 1; }

require_file() {
  local path="$1"
  [[ -f "${path}" ]] || die "missing required file: ${path#${REPO_ROOT}/}"
}

require_text() {
  local file="$1"
  local text="$2"
  grep -Fq -- "${text}" "${file}" || die "${file#${REPO_ROOT}/} missing: ${text}"
}

require_regex() {
  local file="$1"
  local pattern="$2"
  grep -Eq -- "${pattern}" "${file}" || die "${file#${REPO_ROOT}/} missing pattern: ${pattern}"
}

require_absent_regex() {
  local file="$1"
  local pattern="$2"
  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/dialogue-candidate-forbidden.XXXXXX")"
  if grep -Ein -- "${pattern}" "${file}" >"${tmp}"; then
    cat "${tmp}" >&2
    rm -f "${tmp}"
    die "${file#${REPO_ROOT}/} contains forbidden pattern: ${pattern}"
  fi
  rm -f "${tmp}"
}

require_no_positive_dialogue_claims() {
  local file="$1"
  local matches
  # Dialogue Manager has been promoted to optional pack; only check Dialogic for forbidden claims.
  # Broad "dialogue" keyword checks are relaxed since the dialogue pack now exists legitimately.
  matches="$(
    grep -Ein -- '\b(Dialogic)\b.*(default pack|default-enabled|default enabled|enabled by default|promoted pack|approved pack|shipped pack|vendored pack|runtime truth|promoted|approved|shipped|vendored)' "${file}" \
      | grep -Eiv -- '(not (a )?(default pack|default-enabled|default enabled|enabled by default|promoted pack|approved pack|shipped pack|vendored pack|runtime truth|promoted|approved|shipped|vendored)|do not (vendor|bootstrap|enable)|must not|cannot own|must fail if|fail if)' \
      || true
  )"
  if [[ -n "${matches}" ]]; then
    printf '%s\n' "${matches}" >&2
    die "${file#${REPO_ROOT}/} contains a positive Dialogic promotion/default claim"
  fi
}

require_file "${DOC}"
require_file "${LINKS}"
require_file "${CATALOG}"

log "checking candidate links and reference-only status"
for text in \
  "# Dialogue Pack Candidate Plan" \
  "Dialogue Manager" \
  "https://github.com/nathanhoad/godot_dialogue_manager" \
  "Dialogic" \
  "https://github.com/dialogic-godot/dialogic" \
  "Candidate/reference only" \
  "Do not vendor, bootstrap, or enable by default"; do
  # Dialogue Manager is now promoted to optional pack; skip its candidate-only checks
  case "${text}" in
    "Candidate/reference only"|"Do not vendor, bootstrap, or enable by default")
      # These must still exist in the doc for Dialogic (still candidate)
      require_text "${DOC}" "${text}"
      ;;
    *)
      require_text "${DOC}" "${text}"
      ;;
  esac
done

log "checking ownership and adapter boundaries"
for text in \
  "It must not own campaign truth" \
  "save schema" \
  "event history" \
  "rules-events-core" \
  "data-core" \
  "save-core" \
  "rpg-save-adapter" \
  "must not define the canonical campaign save schema"; do
  require_text "${DOC}" "${text}"
done

log "checking promotion gate requirements"
for text in \
  "Promotion Gate" \
  "Godot 4.6 compatibility" \
  "upstream maturity" \
  "License and NOTICE" \
  "dry-run pack contract" \
  "Adapter tests" \
  "No default bootstrap takeover"; do
  require_text "${DOC}" "${text}"
done

log "checking entrypoint links"
require_text "${LINKS}" "docs/dialogue-pack-candidate-plan.md"
require_text "${LINKS}" "campaign truth, save schema, event truth, vendoring, or default bootstrap authority"
require_text "${CATALOG}" "docs/dialogue-pack-candidate-plan.md"
# Catalog now lists dialogue as an optional pack; "not vendored, not default-enabled" applies to Dialogic only
require_text "${CATALOG}" "not vendored, not default-enabled"

log "checking no local absolute paths"
for file in "${DOC}" "${LINKS}" "${CATALOG}"; do
  require_absent_regex "${file}" '(^|[^A-Za-z0-9_./-])/(home|tmp)/'
  require_absent_regex "${file}" 'file://'
done

log "checking forbidden promotion/default claims"
for file in "${DOC}" "${LINKS}" "${CATALOG}"; do
  require_no_positive_dialogue_claims "${file}"
done

log "checking positive reference-only wording for Dialogic candidate"
# Dialogue Manager is now promoted to optional pack; only Dialogic must remain candidate/reference only
require_regex "${DOC}" 'Dialogic.*Candidate/reference only'
require_regex "${LINKS}" 'Dialogic.*(Reference candidate|reference/candidate only)'

log "PASS"
