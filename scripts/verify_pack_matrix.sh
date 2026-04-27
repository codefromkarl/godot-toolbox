#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
GODOT_BIN="${GODOT_BIN:-}"
OUTPUT_DIR="${REPO_ROOT}/outputs/verification/pack-matrix"
RUN_ALL="0"
SELECTED_ROW=""

MATRIX_ROWS=(
  "base"
  "validation,debug,stateful,juice"
  "automation"
  "input"
  "flow-core,simulation-core,data-core,save-core,flow-test-kit"
  "rules-events-core"
  "ui-game-shell,flow-core"
  "automation,flow-core,flow-test-kit"
  "input,ui-game-shell"
  "inventory,data-core,save-core"
  "quest,data-core,save-core,rules-events-core"
  "ai-behavior"
  "save-state-lite"
)

log() { printf '[verify-pack-matrix] %s\n' "$*" >&2; }
die() { printf '[verify-pack-matrix] ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage:
  bash scripts/verify_pack_matrix.sh --all
  bash scripts/verify_pack_matrix.sh --row=<packs-csv-or-base>
EOF
}

for arg in "$@"; do
  case "$arg" in
    --all)
      RUN_ALL="1"
      ;;
    --row=*)
      SELECTED_ROW="${arg#--row=}"
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

if [[ "${RUN_ALL}" != "1" && -z "${SELECTED_ROW}" ]]; then
  usage
  exit 1
fi

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

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip("\n")))' <<<"$1"
}

pack_arg_for_row() {
  local row="$1"
  if [[ "${row}" == "base" ]]; then
    printf ''
  else
    printf '%s' "${row}"
  fi
}

run_row() {
  local row="$1"
  local packs
  local workdir
  local status="pass"
  local notes="ok"
  packs="$(pack_arg_for_row "${row}")"
  workdir="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-matrix.XXXXXX")"

  log "row ${row}: dry-run"
  if [[ -n "${packs}" ]]; then
    python3 "${REPO_ROOT}/scripts/pack_manifest.py" report --packs="${packs}" >/dev/null
  else
    python3 "${REPO_ROOT}/scripts/pack_manifest.py" report >/dev/null
  fi

  log "row ${row}: bootstrap"
  if [[ -n "${packs}" ]]; then
    bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${workdir}" --packs="${packs}" >/dev/null
  else
    bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${workdir}" >/dev/null
  fi

  log "row ${row}: import"
  "${GODOT_BIN}" --headless --editor --quit-after 1 --path "${workdir}/godot" --import >/dev/null

  case "${row}" in
    base|validation,debug,stateful,juice)
      GODOT_BIN="${GODOT_BIN}" bash "${workdir}/scripts/gdunit4_smoke.sh" >/dev/null
      ;;
    flow-core,simulation-core,data-core,save-core,flow-test-kit)
      "${GODOT_BIN}" --headless --path "${workdir}/godot" --script res://addons/godot_toolbox_architecture/flow_test_kit/architecture_spine_smoke.gd >/dev/null
      ;;
    rules-events-core)
      "${GODOT_BIN}" --headless --path "${workdir}/godot" --script res://addons/godot_toolbox_architecture/rules_events_core/tests/rules_events_core_smoke.gd >/dev/null
      ;;
    ui-game-shell,flow-core|input,ui-game-shell)
      "${GODOT_BIN}" --headless --path "${workdir}/godot" --script res://addons/godot_toolbox_architecture/ui_game_shell/tests/ui_game_shell_smoke.gd >/dev/null
      ;;
    automation|automation,flow-core,flow-test-kit|input|inventory,data-core,save-core|quest,data-core,save-core,rules-events-core|ai-behavior|save-state-lite)
      notes="import-only runtime smoke; pack-specific verifier covers deeper behavior"
      ;;
  esac

  rm -rf "${workdir}"
  printf '{"row":%s,"status":%s,"notes":%s}' "$(json_escape "${row}")" "$(json_escape "${status}")" "$(json_escape "${notes}")"
}

GODOT_BIN="$(resolve_godot_bin)"
python3 "${REPO_ROOT}/scripts/pack_manifest.py" validate >/dev/null
mkdir -p "${OUTPUT_DIR}"

rows_to_run=()
if [[ "${RUN_ALL}" == "1" ]]; then
  rows_to_run=("${MATRIX_ROWS[@]}")
else
  rows_to_run=("${SELECTED_ROW}")
fi

results=()
for row in "${rows_to_run[@]}"; do
  results+=("$(run_row "${row}")")
done

{
  printf '{\n  "status": "pass",\n  "rows": [\n'
  for i in "${!results[@]}"; do
    printf '    %s' "${results[$i]}"
    if [[ "${i}" -lt $((${#results[@]} - 1)) ]]; then
      printf ','
    fi
    printf '\n'
  done
  printf '  ]\n}\n'
} > "${OUTPUT_DIR}/latest.json"

python3 -m json.tool "${OUTPUT_DIR}/latest.json" >/dev/null

log "wrote ${OUTPUT_DIR}/latest.json"
log "PASS"
