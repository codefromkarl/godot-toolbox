#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEEP_TEMP="0"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""

usage() {
  cat <<'EOF'
Usage:
  bash ./scripts/verify_automation_pack_poc.sh [--keep-temp]

What it does:
  - bootstraps a minimal project without the candidate automation pack
  - checks that the candidate PoC scaffold exists
  - runs a minimal placeholder validation when Python is available
  - prints the current gaps before this PoC can graduate into a real pack
EOF
}

log() {
  printf '[verify-automation-poc] %s\n' "$*"
}

die() {
  printf '[verify-automation-poc] ERROR: %s\n' "$*" >&2
  exit 1
}

for arg in "$@"; do
  case "$arg" in
    --keep-temp)
      KEEP_TEMP="1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unexpected argument: ${arg}"
      ;;
  esac
done

cleanup() {
  if [[ -n "${WORKDIR}" && -d "${WORKDIR}" ]]; then
    if [[ "${KEEP_TEMP}" == "1" ]]; then
      log "kept temporary project at ${WORKDIR}"
    else
      rm -rf "${WORKDIR}"
    fi
  fi
}

trap cleanup EXIT

require_file() {
  local path="$1"
  [[ -f "${path}" ]] || die "required file missing: ${path}"
}

assert_manifest_lacks_automation() {
  if command -v jq >/dev/null 2>&1; then
    if jq -e '.packs[] | select(.id == "automation")' "${REPO_ROOT}/packs.manifest.json" >/dev/null; then
      die "candidate automation pack unexpectedly appears in packs.manifest.json"
    fi
    return 0
  fi

  if grep -q '"id"[[:space:]]*:[[:space:]]*"automation"' "${REPO_ROOT}/packs.manifest.json"; then
    die "candidate automation pack unexpectedly appears in packs.manifest.json"
  fi
}

require_file "${REPO_ROOT}/packs/automation/README.md"
require_file "${REPO_ROOT}/packs/automation/python/requirements-e2e.txt"
require_file "${REPO_ROOT}/packs/automation/examples/tests/test_ui_smoke_placeholder.py"
assert_manifest_lacks_automation

WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-automation-poc.XXXXXX")"

log "bootstrapping minimal temporary project at ${WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}"

require_file "${WORKDIR}/godot/project.godot"
require_file "${WORKDIR}/scripts/gdunit4_smoke.sh"

if [[ -f "${WORKDIR}/.toolbox-packs" ]]; then
  if [[ -n "$(tr -d '[:space:]' < "${WORKDIR}/.toolbox-packs")" ]]; then
    die "expected no packs in minimal bootstrap, found: $(cat "${WORKDIR}/.toolbox-packs")"
  fi
fi

if command -v python3 >/dev/null 2>&1; then
  log "running placeholder Python validation"
  PLACEHOLDER_PYC="${TMP_ROOT%/}/godot-toolbox-automation-placeholder.pyc"
  rm -f "${PLACEHOLDER_PYC}"
  python3 - <<PY
import py_compile
py_compile.compile(
    r"${REPO_ROOT}/packs/automation/examples/tests/test_ui_smoke_placeholder.py",
    cfile=r"${PLACEHOLDER_PYC}",
    doraise=True,
)
PY
  rm -f "${PLACEHOLDER_PYC}"
else
  log "python3 not found; skipped placeholder Python validation"
fi

log "candidate pack remains intentionally outside packs.manifest.json and default bootstrap"
log "current gaps:"
log "1. lock the real GodotE2E Python package name and version strategy"
log "2. decide whether a Godot-side addon must be vendored for this pack"
log "3. define the minimal runnable E2E smoke contract for CI"
log "4. set promotion criteria before adding automation to packs.manifest.json"
log "PASS"
