#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_PROJECT_DIR="${REPO_ROOT}/godot"
GODOT_BIN="${GODOT_BIN:-}"
TEST_PATH="${1:-res://test/gdunit/tooling_smoke_test.gd}"
IMPORT_PREFLIGHT="${GDUNIT_IMPORT_PREFLIGHT:-1}"

if [[ -z "${GODOT_BIN}" ]]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot)"
  elif [[ -x "/usr/local/bin/godot" ]]; then
    GODOT_BIN="/usr/local/bin/godot"
  else
    echo "[gdunit4-smoke] ERROR: Godot binary not found. Set GODOT_BIN." >&2
    exit 1
  fi
fi

if [[ ! -f "${GODOT_PROJECT_DIR}/test/gdunit/tooling_smoke_test.gd" ]]; then
  echo "[gdunit4-smoke] ERROR: smoke test not found at ${TEST_PATH}" >&2
  exit 1
fi

if [[ "${IMPORT_PREFLIGHT}" == "1" ]]; then
  echo "[gdunit4-smoke] Running import preflight"
  "${GODOT_BIN}" --headless --editor --quit-after 1 --path "${GODOT_PROJECT_DIR}" --import >/dev/null
fi

echo "[gdunit4-smoke] Running ${TEST_PATH}"
(
  cd "${GODOT_PROJECT_DIR}"
  bash addons/gdUnit4/runtest.sh --godot_binary "${GODOT_BIN}" --add "${TEST_PATH}" --continue
)
