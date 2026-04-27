#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""
UPSTREAM_WORKDIR=""
GUIDE_ENTRY_ID="guide"
GUIDE_TARGET="packs/input/godot/addons/guide"
GUIDE_PLUGIN_CFG_PATH="res://addons/guide/plugin.cfg"
GUIDE_AUTOLOAD_ENTRY='GUIDE="*res://addons/guide/guide.gd"'
GUIDE_REPO_URL=""
GUIDE_REF=""
GUIDE_SOURCE_SUBDIR=""
GODOT_BIN="${GODOT_BIN:-}"

log() {
  printf '[verify-input-pack] %s\n' "$*"
}

die() {
  printf '[verify-input-pack] ERROR: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "${WORKDIR}" && -d "${WORKDIR}" ]]; then
    rm -rf "${WORKDIR}"
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

load_guide_lock_metadata() {
  local parsed=""

  if ! parsed="$(python3 - \
    "${REPO_ROOT}/upstreams.lock.json" \
    "${GUIDE_ENTRY_ID}" \
    "${GUIDE_TARGET}" <<'PY'
from pathlib import Path
import json
import sys

lock_path = Path(sys.argv[1])
entry_id = sys.argv[2]
expected_target = sys.argv[3]

data = json.loads(lock_path.read_text(encoding="utf-8"))
entry = next((item for item in data.get("entries", []) if item.get("id") == entry_id), None)
if entry is None:
    raise SystemExit(f"missing upstream lock entry: {entry_id}")

source = entry.get("source", {})
integration = entry.get("integration", {})

if entry.get("kind") != "plugin":
    raise SystemExit(f"{entry_id} must be locked as plugin")
if source.get("type") != "git":
    raise SystemExit(f"{entry_id} must use git source type")
if not source.get("url"):
    raise SystemExit(f"{entry_id} must declare source.url")
if source.get("version") != "0.12.0":
    raise SystemExit(f"{entry_id} must be pinned to version 0.12.0")
if source.get("ref") != "v0.12.0":
    raise SystemExit(f"{entry_id} must be pinned to ref v0.12.0")
if integration.get("mode") != "vendor-subtree":
    raise SystemExit(f"{entry_id} must use vendor-subtree integration mode")
if integration.get("target") != expected_target:
    raise SystemExit(f"{entry_id} integration target mismatch")
if integration.get("source_subdir") != "addons/guide":
    raise SystemExit(f"{entry_id} must declare source_subdir=addons/guide")

print(source["url"])
print(source["ref"])
print(integration["source_subdir"])
PY
  )"; then
    die "guide upstream lock metadata is missing or inconsistent"
  fi

  mapfile -t lock_fields <<<"${parsed}"
  [[ "${#lock_fields[@]}" -eq 3 ]] || die "unexpected guide upstream lock metadata payload"
  GUIDE_REPO_URL="${lock_fields[0]}"
  GUIDE_REF="${lock_fields[1]}"
  GUIDE_SOURCE_SUBDIR="${lock_fields[2]}"
}

assert_vendored_tree_matches_locked_ref() {
  local vendored_dir="${REPO_ROOT}/${GUIDE_TARGET}"
  local source_dir=""
  local diff_output=""

  command -v git >/dev/null 2>&1 || die "required command not found: git"
  [[ -d "${vendored_dir}" ]] || die "vendored guide tree missing: ${vendored_dir}"

  UPSTREAM_WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-guide-upstream.XXXXXX")"

  git clone --filter=blob:none "${GUIDE_REPO_URL}" "${UPSTREAM_WORKDIR}" >/dev/null 2>&1 \
    || die "failed to clone locked guide upstream: ${GUIDE_REPO_URL}"
  git -C "${UPSTREAM_WORKDIR}" checkout --detach "${GUIDE_REF}" >/dev/null 2>&1 \
    || die "failed to checkout locked guide ref: ${GUIDE_REF}"

  source_dir="${UPSTREAM_WORKDIR}/${GUIDE_SOURCE_SUBDIR}"
  [[ -d "${source_dir}" ]] || die "locked guide source subtree missing: ${GUIDE_SOURCE_SUBDIR}"

  if ! diff_output="$(diff -qr "${vendored_dir}" "${source_dir}" 2>&1)"; then
    diff_output="$(printf '%s\n' "${diff_output}" | head -n 20)"
    die "vendored guide tree does not match locked upstream ref ${GUIDE_REF}: ${diff_output}"
  fi
}

assert_manifest_defines_optional_input() {
  python3 - "${REPO_ROOT}/packs.manifest.json" <<'PY'
from pathlib import Path
import json
import sys

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
packs = {pack.get("id"): pack for pack in manifest.get("packs", [])}
pack = packs.get("input")

if pack is None:
    raise SystemExit("input pack missing from packs.manifest.json")
if pack.get("default") is not False:
    raise SystemExit("input pack must remain non-default")
if "base" not in pack.get("requires", []):
    raise SystemExit("input pack must require base")
if "guide" not in pack.get("plugins", []):
    raise SystemExit("input pack must enable guide plugin")
if not any(
    item.get("name") == "GUIDE" and item.get("path") == "res://addons/guide/guide.gd"
    for item in pack.get("autoloads", [])
):
    raise SystemExit("input pack must declare GUIDE autoload")
if not any(
    item.get("path") == "godot_toolbox/input/enabled" and item.get("value") is True
    for item in pack.get("project_settings", [])
):
    raise SystemExit("input pack must declare godot_toolbox/input/enabled=true")
PY
}

require_file "${REPO_ROOT}/packs/input/README.md"
require_file "${REPO_ROOT}/packs/input/godot/addons/guide/plugin.cfg"
require_file "${REPO_ROOT}/packs/input/godot/addons/guide/guide.gd"
require_file "${REPO_ROOT}/upstreams.lock.json"
load_guide_lock_metadata
assert_vendored_tree_matches_locked_ref
assert_manifest_defines_optional_input

GODOT_BIN="$(resolve_godot_bin)"
WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-input-pack.XXXXXX")"

log "checking default bootstrap excludes input"
default_report="$(bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}-default" --dry-run-report)"
[[ ! -e "${WORKDIR}-default" ]] || die "default dry-run unexpectedly created destination"
if grep -Fq "${GUIDE_PLUGIN_CFG_PATH}" <<<"${default_report}"; then
  die "default dry-run unexpectedly enables ${GUIDE_PLUGIN_CFG_PATH}"
fi
if grep -Fq "GUIDE:" <<<"${default_report}"; then
  die "default dry-run unexpectedly includes GUIDE autoload"
fi

log "bootstrapping input optional pack at ${WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}" --packs=input

grep -Fxq "input" "${WORKDIR}/.toolbox-packs" || die ".toolbox-packs does not record input"
[[ -d "${WORKDIR}/godot/addons/guide" ]] || die "input bootstrap did not copy guide addon"

if ! grep -Fq "${GUIDE_PLUGIN_CFG_PATH}" "${WORKDIR}/godot/project.godot"; then
  die "input bootstrap did not enable ${GUIDE_PLUGIN_CFG_PATH}"
fi
if ! grep -Fq "${GUIDE_AUTOLOAD_ENTRY}" "${WORKDIR}/godot/project.godot"; then
  die "input bootstrap did not include GUIDE autoload"
fi
if ! grep -Fq "input/enabled=true" "${WORKDIR}/godot/project.godot"; then
  die "input bootstrap did not set godot_toolbox/input/enabled=true"
fi

log "running Godot import for input pack"
"${GODOT_BIN}" --headless --editor --quit-after 1 --path "${WORKDIR}/godot" --import >/dev/null

log "PASS"
