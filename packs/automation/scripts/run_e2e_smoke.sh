#!/usr/bin/env bash
set -euo pipefail

PACK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${PACK_ROOT}/../.." && pwd)"
REQUIREMENTS_PATH="${PACK_ROOT}/python/requirements-e2e.txt"
DEFAULT_TEST_PATH="${PACK_ROOT}/examples/tests/test_ui_smoke.py"
TMP_ROOT="${TMPDIR:-/tmp}"
PROJECT_DIR="${1:-${GODOT_E2E_PROJECT_PATH:-}}"
TEST_PATH="${2:-${E2E_TEST_PATH:-${DEFAULT_TEST_PATH}}}"
E2E_VENV_DIR="${E2E_VENV_DIR:-}"
IMPORT_PREFLIGHT="${E2E_IMPORT_PREFLIGHT:-1}"
GODOT_BIN="${GODOT_BIN:-}"
CREATED_VENV_DIR="0"
declare -a TEST_LAUNCH_PREFIX=()

usage() {
  cat <<'EOF'
Usage:
  bash ./packs/automation/scripts/run_e2e_smoke.sh <godot-project-dir> [pytest-test-path]

Environment:
  GODOT_BIN           Explicit Godot binary path. Defaults to `godot` in PATH.
  E2E_VENV_DIR        Virtualenv directory for E2E dependencies.
                     If unset, the script creates and cleans up a temp venv.
  E2E_TEST_PATH       Override the pytest test path.
  E2E_IMPORT_PREFLIGHT  Set to 0 to skip Godot import preflight.
EOF
}

log() {
  printf '[automation-smoke] %s\n' "$*"
}

die() {
  printf '[automation-smoke] ERROR: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ "${CREATED_VENV_DIR}" == "1" && -n "${E2E_VENV_DIR}" && -d "${E2E_VENV_DIR}" ]]; then
    rm -rf "${E2E_VENV_DIR}"
  fi
}

trap cleanup EXIT

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

  die "Godot binary not found. Install Godot 4.x and expose it as 'godot', or set GODOT_BIN."
}

canonical_path() {
  python3 - "$1" <<'PY'
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
}

check_builtin_smoke_contract() {
  python3 - "${PROJECT_DIR}" <<'PY'
from pathlib import Path
import re
import sys

project_dir = Path(sys.argv[1]).resolve()
project_file = project_dir / "project.godot"
text = project_file.read_text(encoding="utf-8")
main_scene_match = re.search(r'^run/main_scene="([^"]+)"$', text, re.MULTILINE)
if not main_scene_match:
    raise SystemExit(
        "[automation-smoke] ERROR: built-in smoke requires project.godot to declare "
        'run/main_scene, and that scene must expose /root/Main. Pass a custom pytest '
        "test path for projects with a different contract."
    )

main_scene = main_scene_match.group(1)
if not main_scene.startswith("res://"):
    raise SystemExit(
        f"[automation-smoke] ERROR: built-in smoke only supports res:// main scenes; got {main_scene}. "
        "Pass a custom pytest test path for projects with a different contract."
    )

scene_path = project_dir / main_scene.removeprefix("res://")
if not scene_path.is_file():
    raise SystemExit(
        f"[automation-smoke] ERROR: built-in smoke expects the configured main scene to exist: {main_scene}. "
        "Pass a custom pytest test path for projects with a different contract."
    )

scene_text = scene_path.read_text(encoding="utf-8")
root_match = re.search(r'^\[node name="([^"]+)"[^\]]*\]$', scene_text, re.MULTILINE)
if not root_match:
    raise SystemExit(
        f"[automation-smoke] ERROR: built-in smoke could not find a root node declaration in {main_scene}. "
        "Pass a custom pytest test path for projects with a different contract."
    )

root_name = root_match.group(1)
if root_name != "Main":
    raise SystemExit(
        f"[automation-smoke] ERROR: built-in smoke expects the main scene root node to be named Main so it is reachable as /root/Main; "
        f"got {root_name!r} from {main_scene}. Pass a custom pytest test path for projects with a different contract."
    )
PY
}

if [[ "${PROJECT_DIR}" == "-h" || "${PROJECT_DIR}" == "--help" ]]; then
  usage
  exit 0
fi

[[ -n "${PROJECT_DIR}" ]] || die "godot project directory is required"
[[ -f "${PROJECT_DIR}/project.godot" ]] || die "project.godot not found under ${PROJECT_DIR}"
[[ -f "${REQUIREMENTS_PATH}" ]] || die "requirements file missing: ${REQUIREMENTS_PATH}"
[[ -f "${TEST_PATH}" ]] || die "pytest test file missing: ${TEST_PATH}"

if [[ "$(canonical_path "${TEST_PATH}")" == "$(canonical_path "${DEFAULT_TEST_PATH}")" ]]; then
  log "validating built-in smoke contract (/root/Main)"
  check_builtin_smoke_contract
fi

GODOT_BIN="$(resolve_godot_bin)"

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" && "$(uname -s)" == "Linux" ]]; then
  if command -v xvfb-run >/dev/null 2>&1; then
    TEST_LAUNCH_PREFIX=(xvfb-run -a)
    log "using xvfb-run for display-bound Godot process"
  else
    log "DISPLAY is absent and xvfb-run is unavailable; attempting direct launch"
  fi
fi

if [[ -z "${E2E_VENV_DIR}" ]]; then
  E2E_VENV_DIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-e2e-venv.XXXXXX")"
  CREATED_VENV_DIR="1"
fi

if [[ ! -d "${E2E_VENV_DIR}" ]]; then
  log "creating venv at ${E2E_VENV_DIR}"
  python3 -m venv "${E2E_VENV_DIR}"
fi

log "installing pinned Python dependencies"
"${E2E_VENV_DIR}/bin/python" -m pip install --upgrade pip >/dev/null
"${E2E_VENV_DIR}/bin/python" -m pip install -r "${REQUIREMENTS_PATH}" >/dev/null

if [[ "${IMPORT_PREFLIGHT}" == "1" ]]; then
  log "running Godot import preflight"
  "${GODOT_BIN}" --headless --editor --quit-after 1 --path "${PROJECT_DIR}" --import >/dev/null
fi

log "running pytest smoke via godot-e2e"
(
  cd "${REPO_ROOT}"
  export GODOT_E2E_PROJECT_PATH="${PROJECT_DIR}"
  export GODOT_PATH="${GODOT_BIN}"
  "${TEST_LAUNCH_PREFIX[@]}" \
    "${E2E_VENV_DIR}/bin/godot-e2e" \
    --godot-path "${GODOT_BIN}" \
    "${TEST_PATH}" \
    -q
)
