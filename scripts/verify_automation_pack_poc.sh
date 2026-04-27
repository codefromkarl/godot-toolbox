#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEEP_TEMP="0"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""
UPSTREAM_WORKDIR=""
AUTOLOAD_NAME=""
AUTOLOAD_PATH=""
AUTOLOAD_ENTRY=""
AUTOMATION_ENTRY_ID="godot_e2e"
AUTOMATION_TARGET="packs/automation/godot/addons/godot_e2e"
AUTOMATION_PLUGIN_CFG_PATH="res://addons/godot_e2e/plugin.cfg"
AUTOMATION_REPO_URL=""
AUTOMATION_LOCK_VERSION=""
AUTOMATION_REF=""
AUTOMATION_SOURCE_SUBDIR=""

usage() {
  cat <<'EOF'
Usage:
  bash ./scripts/verify_automation_pack_poc.sh [--keep-temp]

What it does:
  - verifies automation is a non-default optional pack in packs.manifest.json
  - asserts default bootstrap output does not include GodotE2E or AutomationServer
  - bootstraps with --packs=automation and validates addon, plugin, autoload, and settings injection
  - runs the pack-local GodotE2E smoke entry against the generated project
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

  if [[ -n "${UPSTREAM_WORKDIR}" && -d "${UPSTREAM_WORKDIR}" ]]; then
    rm -rf "${UPSTREAM_WORKDIR}"
  fi
}

trap cleanup EXIT

require_file() {
  local path="$1"
  [[ -f "${path}" ]] || die "required file missing: ${path}"
}

load_automation_lock_metadata() {
  local parsed=""

  if ! parsed="$(python3 - \
    "${REPO_ROOT}/upstreams.lock.json" \
    "${REPO_ROOT}/packs/automation/python/requirements-e2e.txt" \
    "${AUTOMATION_ENTRY_ID}" \
    "${AUTOMATION_TARGET}" <<'PY'
from pathlib import Path
import json
import re
import sys

lock_path = Path(sys.argv[1])
requirements_path = Path(sys.argv[2])
entry_id = sys.argv[3]
expected_target = sys.argv[4]

with lock_path.open("r", encoding="utf-8") as fh:
    data = json.load(fh)

entry = next((item for item in data.get("entries", []) if item.get("id") == entry_id), None)
if entry is None:
    raise SystemExit(f"missing upstream lock entry: {entry_id}")

source = entry.get("source", {})
integration = entry.get("integration", {})
repo_url = source.get("url", "")
version = source.get("version", "")
ref = source.get("ref", "")
source_subdir = integration.get("source_subdir", "")

if source.get("type") != "git":
    raise SystemExit(f"{entry_id} must use git source type")
if not repo_url:
    raise SystemExit(f"{entry_id} must declare source.url")
if not version:
    raise SystemExit(f"{entry_id} must declare source.version")
if not ref:
    raise SystemExit(f"{entry_id} must declare source.ref")
if integration.get("mode") != "vendor-subtree":
    raise SystemExit(f"{entry_id} must use vendor-subtree integration mode")
if integration.get("target") != expected_target:
    raise SystemExit(
        f"{entry_id} integration target mismatch: {integration.get('target')} != {expected_target}"
    )
if not source_subdir:
    raise SystemExit(f"{entry_id} must declare integration.source_subdir for reproducible subtree checks")

requirements = requirements_path.read_text(encoding="utf-8").splitlines()
req_version = ""
for line in requirements:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        continue
    match = re.fullmatch(r"godot-e2e==([^\s]+)", stripped)
    if match:
        req_version = match.group(1)
        break

if not req_version:
    raise SystemExit("requirements-e2e.txt must pin godot-e2e==<version>")
if req_version != version:
    raise SystemExit(
        f"godot-e2e version mismatch between upstream lock ({version}) and requirements ({req_version})"
    )

print(repo_url)
print(version)
print(ref)
print(source_subdir)
PY
  )"; then
    die "automation upstream lock metadata is missing or inconsistent"
  fi

  mapfile -t lock_fields <<<"${parsed}"
  [[ "${#lock_fields[@]}" -eq 4 ]] || die "unexpected automation upstream lock metadata payload"
  AUTOMATION_REPO_URL="${lock_fields[0]}"
  AUTOMATION_LOCK_VERSION="${lock_fields[1]}"
  AUTOMATION_REF="${lock_fields[2]}"
  AUTOMATION_SOURCE_SUBDIR="${lock_fields[3]}"
}

assert_vendored_tree_matches_locked_ref() {
  local vendored_dir="${REPO_ROOT}/${AUTOMATION_TARGET}"
  local source_dir=""
  local diff_output=""

  command -v git >/dev/null 2>&1 || die "required command not found: git"
  [[ -d "${vendored_dir}" ]] || die "vendored automation tree missing: ${vendored_dir}"
  [[ -n "${AUTOMATION_REPO_URL}" ]] || die "automation upstream repo url not loaded"
  [[ -n "${AUTOMATION_REF}" ]] || die "automation upstream ref not loaded"
  [[ -n "${AUTOMATION_SOURCE_SUBDIR}" ]] || die "automation upstream source_subdir not loaded"

  UPSTREAM_WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-automation-upstream.XXXXXX")"

  git clone --filter=blob:none "${AUTOMATION_REPO_URL}" "${UPSTREAM_WORKDIR}" >/dev/null 2>&1 \
    || die "failed to clone locked automation upstream: ${AUTOMATION_REPO_URL}"
  git -C "${UPSTREAM_WORKDIR}" checkout --detach "${AUTOMATION_REF}" >/dev/null 2>&1 \
    || die "failed to checkout locked automation ref: ${AUTOMATION_REF}"

  source_dir="${UPSTREAM_WORKDIR}/${AUTOMATION_SOURCE_SUBDIR}"
  [[ -d "${source_dir}" ]] || die "locked automation source subtree missing: ${AUTOMATION_SOURCE_SUBDIR}"

  if ! diff_output="$(diff -qr -x LICENSE -x NOTICE "${vendored_dir}" "${source_dir}" 2>&1)"; then
    diff_output="$(printf '%s\n' "${diff_output}" | head -n 20)"
    die "vendored automation tree does not match locked upstream ref ${AUTOMATION_REF}: ${diff_output}"
  fi
}

load_vendored_autoload_truth() {
  local plugin_script="$1"
  local parsed=""

  if ! parsed="$(python3 - "${plugin_script}" <<'PY'
from pathlib import Path
import re
import sys

plugin_script = Path(sys.argv[1])
text = plugin_script.read_text(encoding="utf-8")
name_match = re.search(r'const\s+AUTOLOAD_NAME\s*:=\s*"([^"]+)"', text)
path_match = re.search(r'const\s+AUTOLOAD_PATH\s*:=\s*"([^"]+)"', text)
if not name_match or not path_match:
    raise SystemExit("failed to parse AUTOLOAD_NAME/AUTOLOAD_PATH from vendored plugin.gd")

name = name_match.group(1)
path = path_match.group(1)
print(name)
print(path)
print(f'{name}="*{path}"')
PY
)"; then
    die "failed to parse vendored autoload truth from ${plugin_script}"
  fi

  mapfile -t autoload_truth <<<"${parsed}"
  [[ "${#autoload_truth[@]}" -eq 3 ]] || die "unexpected vendored autoload parse result"
  AUTOLOAD_NAME="${autoload_truth[0]}"
  AUTOLOAD_PATH="${autoload_truth[1]}"
  AUTOLOAD_ENTRY="${autoload_truth[2]}"
}

assert_manifest_defines_optional_automation() {
  python3 - "${REPO_ROOT}/packs.manifest.json" "${AUTOLOAD_NAME}" "${AUTOLOAD_PATH}" <<'PY'
from pathlib import Path
import json
import sys

manifest_path = Path(sys.argv[1])
autoload_name = sys.argv[2]
autoload_path = sys.argv[3]
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
packs = {pack.get("id"): pack for pack in manifest.get("packs", [])}
pack = packs.get("automation")

if pack is None:
    raise SystemExit("automation pack missing from packs.manifest.json")
if pack.get("default") is not False:
    raise SystemExit("automation pack must remain non-default")
if "base" not in pack.get("requires", []):
    raise SystemExit("automation pack must require base")
if "godot_e2e" not in pack.get("plugins", []):
    raise SystemExit("automation pack must enable godot_e2e plugin")

autoloads = pack.get("autoloads", [])
if not any(
    item.get("name") == autoload_name and item.get("path") == autoload_path
    for item in autoloads
):
    raise SystemExit("automation pack autoload does not match vendored plugin.gd truth")

settings = pack.get("project_settings", [])
if not any(
    item.get("path") == "godot_toolbox/automation/enabled" and item.get("value") is True
    for item in settings
):
    raise SystemExit("automation pack must declare godot_toolbox/automation/enabled=true")
PY
}

require_file "${REPO_ROOT}/packs/automation/README.md"
require_file "${REPO_ROOT}/packs/automation/python/requirements-e2e.txt"
require_file "${REPO_ROOT}/packs/automation/examples/tests/conftest.py"
require_file "${REPO_ROOT}/packs/automation/examples/tests/test_ui_smoke.py"
require_file "${REPO_ROOT}/packs/automation/scripts/run_e2e_smoke.sh"
require_file "${REPO_ROOT}/packs/automation/godot/addons/godot_e2e/automation_server.gd"
require_file "${REPO_ROOT}/packs/automation/godot/addons/godot_e2e/plugin.cfg"
require_file "${REPO_ROOT}/packs/automation/godot/addons/godot_e2e/LICENSE"
require_file "${REPO_ROOT}/upstreams.lock.json"
load_automation_lock_metadata
assert_vendored_tree_matches_locked_ref
load_vendored_autoload_truth "${REPO_ROOT}/packs/automation/godot/addons/godot_e2e/plugin.gd"
assert_manifest_defines_optional_automation

WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-automation-poc.XXXXXX")"

log "checking default bootstrap excludes automation"
default_report="$(bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}-default" --dry-run-report)"
[[ ! -e "${WORKDIR}-default" ]] || die "default dry-run unexpectedly created destination"
grep -Fq "Active packs: base" <<<"${default_report}" || die "default dry-run does not report only base"
if grep -Fq "${AUTOMATION_PLUGIN_CFG_PATH}" <<<"${default_report}"; then
  die "default dry-run unexpectedly enables ${AUTOMATION_PLUGIN_CFG_PATH}"
fi
if grep -Fq "${AUTOLOAD_NAME}" <<<"${default_report}"; then
  die "default dry-run unexpectedly includes ${AUTOLOAD_NAME} autoload"
fi

log "bootstrapping automation optional pack at ${WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}" --packs=automation

require_file "${WORKDIR}/godot/project.godot"
require_file "${WORKDIR}/scripts/gdunit4_smoke.sh"

grep -Fxq "automation" "${WORKDIR}/.toolbox-packs" || die ".toolbox-packs does not record automation"
[[ -d "${WORKDIR}/godot/addons/godot_e2e" ]] || die "automation bootstrap did not copy godot_e2e addon"

if ! grep -Fq "${AUTOMATION_PLUGIN_CFG_PATH}" "${WORKDIR}/godot/project.godot"; then
  die "automation bootstrap did not enable ${AUTOMATION_PLUGIN_CFG_PATH}"
fi

if ! grep -Fq "${AUTOLOAD_ENTRY}" "${WORKDIR}/godot/project.godot"; then
  die "automation bootstrap did not include ${AUTOLOAD_NAME} autoload"
fi

if ! grep -Fq "automation/enabled=true" "${WORKDIR}/godot/project.godot"; then
  die "automation bootstrap did not set godot_toolbox/automation/enabled=true"
fi

log "running pack-local GodotE2E smoke"
E2E_VENV_DIR="${WORKDIR}/.venv-e2e" \
  bash "${REPO_ROOT}/packs/automation/scripts/run_e2e_smoke.sh" "${WORKDIR}/godot"

log "automation pack remains non-default and opt-in"
log "PASS"
