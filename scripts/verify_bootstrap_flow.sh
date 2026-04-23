#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKS_CSV="validation,debug,stateful,juice"
KEEP_TEMP="0"
TMP_ROOT="${TMPDIR:-/tmp}"
GODOT_BIN="${GODOT_BIN:-}"
WORKDIR=""

usage() {
  cat <<'EOF'
Usage:
  bash ./scripts/verify_bootstrap_flow.sh [--packs=pack_a,pack_b] [--keep-temp]

Environment:
  GODOT_BIN   Explicit Godot binary path. Defaults to `godot` in PATH.
  TMPDIR      Parent directory for the temporary bootstrap project.
EOF
}

log() {
  printf '[verify-bootstrap] %s\n' "$*"
}

die() {
  printf '[verify-bootstrap] ERROR: %s\n' "$*" >&2
  exit 1
}

for arg in "$@"; do
  case "$arg" in
    --packs=*)
      PACKS_CSV="${arg#--packs=}"
      ;;
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

GODOT_BIN="$(resolve_godot_bin)"
WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-bootstrap.XXXXXX")"

log "bootstrapping temporary project at ${WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}" --packs="${PACKS_CSV}"

[[ -f "${WORKDIR}/godot/project.godot" ]] || die "generated project.godot not found"
[[ -f "${WORKDIR}/scripts/gdunit4_smoke.sh" ]] || die "generated gdunit4 smoke script not found"
[[ -f "${WORKDIR}/godot/test/gdunit/tooling_smoke_test.gd" ]] || die "generated smoke test not found"

log "running headless import with ${GODOT_BIN}"
"${GODOT_BIN}" --headless --editor --quit-after 1 --path "${WORKDIR}/godot" --import >/dev/null

log "running gdUnit4 smoke"
GODOT_BIN="${GODOT_BIN}" bash "${WORKDIR}/scripts/gdunit4_smoke.sh"

log "PASS"
