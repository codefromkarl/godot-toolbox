#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""
PACKS="rpg-test-kit,rpg-battle-core,rpg-core,rpg-save-adapter,flow-core,rules-events-core,data-core,save-core"
GODOT_BIN="${GODOT_BIN:-}"

log() { printf '[verify-rpg-edge] %s\n' "$*"; }
die() { printf '[verify-rpg-edge] ERROR: %s\n' "$*" >&2; exit 1; }

cleanup() {
  if [[ -n "${WORKDIR}" && -d "${WORKDIR}" ]]; then
    rm -rf "${WORKDIR}"
    log "cleanup removed ${WORKDIR}"
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
  die "Godot binary not found after static edge assertions. Runtime edge smoke is not available; install Godot 4.6.x as 'godot' or set GODOT_BIN."
}

run_static_assertions() {
  log "running static edge assertions"
  python3 - "${REPO_ROOT}" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
required_files = [
    "packs/rpg-battle-core/godot/addons/godot_toolbox_architecture/rpg_battle_core/tests/rpg_battle_edge_cases.gd",
    "packs/rpg-battle-core/godot/addons/godot_toolbox_architecture/rpg_battle_core/tests/rpg_example_content_edge_cases.gd",
    "packs/rpg-save-adapter/godot/addons/godot_toolbox_architecture/rpg_save_adapter/tests/rpg_save_edge_cases.gd",
    "packs/rpg-test-kit/godot/addons/godot_toolbox_architecture/rpg_test_kit/tests/rpg_test_kit_edge_cases.gd",
]
for rel in required_files:
    if not (root / rel).is_file():
        raise SystemExit(f"missing edge test file: {rel}")

content_path = root / "packs/rpg-core/godot/content/rpg_example/rpg_example_content.json"
content = json.loads(content_path.read_text(encoding="utf-8"))
expected_counts = {
    "heroes": 2,
    "enemies": 3,
    "skills": 5,
    "items": 5,
    "equipment": 3,
}
for key, minimum in expected_counts.items():
    rows = content.get(key)
    if not isinstance(rows, list) or len(rows) < minimum:
        raise SystemExit(f"content {key} has insufficient rows: {len(rows) if isinstance(rows, list) else 'missing'}")

ids = []
for key in expected_counts:
    for row in content[key]:
        row_id = row.get("id")
        if not isinstance(row_id, str) or "/" not in row_id:
            raise SystemExit(f"invalid {key} id: {row_id!r}")
        ids.append(row_id)
if len(ids) != len(set(ids)):
    raise SystemExit("example content ids must be unique")

for row in content["heroes"] + content["enemies"]:
    stats = row.get("stats", {})
    missing = {"max_hp", "max_mp", "speed", "attack", "defense"} - set(stats)
    if missing:
        raise SystemExit(f"{row.get('id')} missing stats: {sorted(missing)}")
print("RPG_EDGE_STATIC_OK files=4 content_ids=%s" % len(ids))
PY
}

run_godot_script() {
  local script_path="$1"
  local expected_pattern="$2"
  local log_path
  local observed
  log_path="$(mktemp "${TMP_ROOT%/}/godot-toolbox-rpg-edge.XXXXXX.log")"
  set +e
  "${GODOT_BIN}" --headless --path "${WORKDIR}/godot" --script "${script_path}" >"${log_path}" 2>&1
  local status=$?
  set -e
  if [[ "${status}" -ne 0 ]]; then
    sed -n '1,220p' "${log_path}" >&2
    rm -f "${log_path}"
    die "Godot edge smoke failed: ${script_path}"
  fi
  if grep -Eq 'SCRIPT ERROR|ERROR:' "${log_path}"; then
    sed -n '1,220p' "${log_path}" >&2
    rm -f "${log_path}"
    die "Godot edge smoke emitted errors: ${script_path}"
  fi
  observed="$(grep -E "${expected_pattern}" "${log_path}" | head -n 1 || true)"
  if [[ -z "${observed}" ]]; then
    sed -n '1,220p' "${log_path}" >&2
    rm -f "${log_path}"
    die "Godot edge smoke missing expected output pattern: ${expected_pattern}"
  fi
  log "observed ${observed}"
  rm -f "${log_path}"
}

run_static_assertions
log "validating manifest and dry-run report"
python3 "${REPO_ROOT}/scripts/pack_manifest.py" validate >/dev/null
report="$(python3 "${REPO_ROOT}/scripts/pack_manifest.py" report --packs="${PACKS}")"
for expected in \
  "Selected packs: ${PACKS}" \
  "godot_toolbox/rpg_test_kit/enabled=true" \
  "godot_toolbox/rpg_battle_core/enabled=true" \
  "godot_toolbox/rpg_core/enabled=true" \
  "godot_toolbox/rpg_save_adapter/enabled=true" \
  "scripts/verify_rpg_test_kit_pack.sh" \
  "scripts/verify_rpg_battle_core_pack.sh" \
  "scripts/verify_rpg_save_adapter_pack.sh"
do
  grep -Fq "${expected}" <<<"${report}" || die "dry-run report missing: ${expected}"
done

GODOT_BIN="$(resolve_godot_bin)"
WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-rpg-edge.XXXXXX")"
log "bootstrapping ${PACKS} into ${WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}" --packs="${PACKS}" >/dev/null

for path in \
  "godot/addons/godot_toolbox_architecture/rpg_battle_core/tests/rpg_battle_edge_cases.gd" \
  "godot/addons/godot_toolbox_architecture/rpg_battle_core/tests/rpg_example_content_edge_cases.gd" \
  "godot/addons/godot_toolbox_architecture/rpg_save_adapter/tests/rpg_save_edge_cases.gd" \
  "godot/addons/godot_toolbox_architecture/rpg_test_kit/tests/rpg_test_kit_edge_cases.gd" \
  "godot/content/rpg_example/rpg_example_content.json"
do
  [[ -f "${WORKDIR}/${path}" ]] || die "required bootstrapped file missing: ${path}"
done

"${GODOT_BIN}" --headless --editor --quit-after 1 --path "${WORKDIR}/godot" --import >/dev/null

run_godot_script \
  "res://addons/godot_toolbox_architecture/rpg_battle_core/tests/rpg_battle_edge_cases.gd" \
  "^RPG_EDGE_BATTLE_OK formula_min=1 heal_negative=0 queue=alpha,beta,slow ai_empty=0$"
run_godot_script \
  "res://addons/godot_toolbox_architecture/rpg_save_adapter/tests/rpg_save_edge_cases.gd" \
  "^RPG_EDGE_SAVE_OK migrated_schema=[0-9]+ malformed_errors=[0-9]+ unsupported_schema=-1$"
run_godot_script \
  "res://addons/godot_toolbox_architecture/rpg_battle_core/tests/rpg_example_content_edge_cases.gd" \
  "^RPG_EDGE_CONTENT_OK heroes=[0-9]+ enemies=[0-9]+ skills=[0-9]+ items=[0-9]+ equipment=[0-9]+$"
run_godot_script \
  "res://addons/godot_toolbox_architecture/rpg_test_kit/tests/rpg_test_kit_edge_cases.gd" \
  "^RPG_EDGE_TEST_KIT_OK replay_events=[0-9]+ dump_inventory=[0-9]+ dump_events=[0-9]+$"

log "PASS"
