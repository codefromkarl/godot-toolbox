#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""
GODOT_BIN="${GODOT_BIN:-}"

log() {
  printf '[verify-game-architecture] %s\n' "$*"
}

die() {
  printf '[verify-game-architecture] ERROR: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "${WORKDIR}" && -d "${WORKDIR}" ]]; then
    rm -rf "${WORKDIR}"
  fi
}

trap cleanup EXIT

PACKS="flow-core,simulation-core,data-core,save-core,flow-test-kit"

expect_failure_contains() {
  local expected="$1"
  shift
  local output=""
  local status=0

  set +e
  output="$("$@" 2>&1)"
  status=$?
  set -e

  if [[ "${status}" -eq 0 ]]; then
    die "expected command to fail: $*"
  fi
  grep -Fq "${expected}" <<<"${output}" || die "expected failure output to mention '${expected}', got: ${output}"
}

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

GODOT_BIN="$(resolve_godot_bin)"

log "validating pack manifest contract"
python3 "${REPO_ROOT}/scripts/pack_manifest.py" validate

log "checking dry-run injection report"
dry_run_dest="${TMP_ROOT%/}/godot-toolbox-arch-dry-run.$$"
rm -rf "${dry_run_dest}"
dry_run_report="$(bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${dry_run_dest}" --packs="${PACKS}" --dry-run-report)"
[[ ! -e "${dry_run_dest}" ]] || die "dry-run report created destination: ${dry_run_dest}"

for expected in \
  "Selected packs: ${PACKS}" \
  "Active packs: base,${PACKS}" \
  "Packs to overlay: ${PACKS}" \
  FlowCore \
  SimulationCore \
  DataCore \
  SaveCore \
  "godot_toolbox/flow_core/enabled=true" \
  "godot_toolbox/simulation_core/enabled=true" \
  "godot_toolbox/data_core/enabled=true" \
  "godot_toolbox/save_core/enabled=true" \
  "scripts/verify_game_architecture_packs.sh"
do
  grep -Fq "${expected}" <<<"${dry_run_report}" || die "dry-run report does not mention ${expected}"
done

log "checking negative pack selection paths"
expect_failure_contains "pack 'unknown-pack' is not defined" \
  bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${dry_run_dest}-unknown" --packs="unknown-pack" --dry-run-report
[[ ! -e "${dry_run_dest}-unknown" ]] || die "unknown-pack dry-run created destination"
expect_failure_contains "pack 'simulation-core' requires pack 'flow-core'" \
  bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${dry_run_dest}-missing-dep" --packs="simulation-core" --dry-run-report
[[ ! -e "${dry_run_dest}-missing-dep" ]] || die "missing dependency dry-run created destination"

real_failure_dest="${TMP_ROOT%/}/godot-toolbox-arch-real-failure.$$"
rm -rf "${real_failure_dest}"
expect_failure_contains "pack 'simulation-core' requires pack 'flow-core'" \
  bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${real_failure_dest}" --packs="simulation-core"
[[ ! -e "${real_failure_dest}" ]] || die "missing dependency real bootstrap created destination"

WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-architecture.XXXXXX")"

log "bootstrapping architecture packs into ${WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}" --packs="${PACKS}"

project_file="${WORKDIR}/godot/project.godot"
[[ -f "${project_file}" ]] || die "generated project.godot missing"

for expected in \
  'FlowCore="*res://addons/godot_toolbox_architecture/flow_core/flow_core.gd"' \
  'SimulationCore="*res://addons/godot_toolbox_architecture/simulation_core/simulation_core.gd"' \
  'DataCore="*res://addons/godot_toolbox_architecture/data_core/data_core.gd"' \
  'SaveCore="*res://addons/godot_toolbox_architecture/save_core/save_core.gd"' \
  'flow_core/enabled=true' \
  'simulation_core/enabled=true' \
  'data_core/enabled=true' \
  'save_core/enabled=true' \
  'flow_test_kit/enabled=true'
do
  grep -Fq "${expected}" "${project_file}" || die "generated project.godot missing: ${expected}"
done

required_files=(
  "godot/addons/godot_toolbox_architecture/flow_core/flow_core.gd"
  "godot/addons/godot_toolbox_architecture/flow_core/flow_request.gd"
  "godot/addons/godot_toolbox_architecture/flow_core/game_mode.gd"
  "godot/addons/godot_toolbox_architecture/simulation_core/simulation_core.gd"
  "godot/addons/godot_toolbox_architecture/data_core/data_core.gd"
  "godot/addons/godot_toolbox_architecture/data_core/tests/data_core_smoke.gd"
  "godot/addons/godot_toolbox_architecture/save_core/save_core.gd"
  "godot/addons/godot_toolbox_architecture/save_core/tests/save_core_smoke.gd"
  "godot/addons/godot_toolbox_architecture/flow_test_kit/flow_smoke_fixture.gd"
  "godot/test/gdunit/flow_core_smoke_test.gd"
)

for path in "${required_files[@]}"; do
  [[ -f "${WORKDIR}/${path}" ]] || die "required architecture scaffold missing: ${path}"
done

grep -Fq "${PACKS}" "${WORKDIR}/.toolbox-packs" || die ".toolbox-packs does not record selected architecture packs"

log "running Godot import for architecture packs"
"${GODOT_BIN}" --headless --editor --quit-after 1 --path "${WORKDIR}/godot" --import >/dev/null

log "running flow-core gdUnit smoke"
GODOT_BIN="${GODOT_BIN}" bash "${WORKDIR}/scripts/gdunit4_smoke.sh" res://test/gdunit/flow_core_smoke_test.gd

log "running data-core headless smoke"
"${GODOT_BIN}" --headless --path "${WORKDIR}/godot" \
  --script res://addons/godot_toolbox_architecture/data_core/tests/data_core_smoke.gd

log "running save-core headless smoke"
"${GODOT_BIN}" --headless --path "${WORKDIR}/godot" \
  --script res://addons/godot_toolbox_architecture/save_core/tests/save_core_smoke.gd

log "PASS"
