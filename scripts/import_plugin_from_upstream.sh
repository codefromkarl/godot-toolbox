#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./lib_upstreams.sh
source "${REPO_ROOT}/scripts/lib_upstreams.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/import_plugin_from_upstream.sh \
    --id <plugin_id> \
    --repo <git_url> \
    --target <repo_relative_target_dir> \
    [--pack=<base|validation|debug|stateful|juice>] \
    [--ref=<git_ref>] \
    [--version=<display_version>] \
    [--source-subdir=<path_inside_upstream>] \
    [--note=<text>] \
    [--dry-run] \
    [--skip-verify]

Notes:
  - 第一版仅支持 git upstream + vendor-subtree 导入。
  - 若无法自动推断插件目录，请显式传入 --source-subdir。
EOF
}

ENTRY_ID=""
REPO_URL=""
TARGET=""
PACK_ID=""
REF=""
VERSION=""
SOURCE_SUBDIR=""
NOTE=""
DRY_RUN="0"
SKIP_VERIFY="0"

for arg in "$@"; do
  case "${arg}" in
    --id=*) ENTRY_ID="${arg#--id=}" ;;
    --repo=*) REPO_URL="${arg#--repo=}" ;;
    --target=*) TARGET="${arg#--target=}" ;;
    --pack=*) PACK_ID="${arg#--pack=}" ;;
    --ref=*) REF="${arg#--ref=}" ;;
    --version=*) VERSION="${arg#--version=}" ;;
    --source-subdir=*) SOURCE_SUBDIR="${arg#--source-subdir=}" ;;
    --note=*) NOTE="${arg#--note=}" ;;
    --dry-run) DRY_RUN="1" ;;
    --skip-verify) SKIP_VERIFY="1" ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unexpected argument: ${arg}"
      ;;
  esac
done

[[ -n "${ENTRY_ID}" ]] || die "--id is required"
[[ -n "${REPO_URL}" ]] || die "--repo is required"
[[ -n "${TARGET}" ]] || die "--target is required"
[[ -n "${REF}" || -n "${VERSION}" ]] || die "either --ref or --version is required"

if [[ "${DRY_RUN}" == "1" ]]; then
  cache_root="$(cache_dir_path)"
else
  cache_root="$(ensure_cache_dir)"
fi
cache_path="${cache_root}/${ENTRY_ID}"
workspace_path=""
trap 'cleanup_git_workspace "${workspace_path}" "${cache_path}"' EXIT

log "preparing upstream workspace: ${REPO_URL}"
workspace_path="$(prepare_git_workspace "${REPO_URL}" "${cache_path}" "${DRY_RUN}")"
checkout_ref="$(resolve_checkout_ref "${workspace_path}" "${REF}" "${VERSION}")"
checkout_git_ref "${workspace_path}" "${checkout_ref}"

source_path="$(resolve_source_path "${workspace_path}" "${SOURCE_SUBDIR}" "${TARGET}" "${ENTRY_ID}")"
dest_path="${REPO_ROOT}/${TARGET}"

if [[ "${DRY_RUN}" == "1" ]]; then
  log "dry-run import summary"
  log "  id=${ENTRY_ID}"
  log "  workspace=${workspace_path}"
  log "  source=${source_path}"
  log "  target=${dest_path}"
  log "  pack=${PACK_ID:-<none>}"
  log "  version=${VERSION:-<unchanged>}"
  log "  ref=${checkout_ref}"
  exit 0
fi

copy_tree_overwrite "${source_path}" "${dest_path}"
verify_plugin_tree "${dest_path}"

update_upstreams_lock_entry \
  "${ENTRY_ID}" \
  "plugin" \
  "git" \
  "${REPO_URL}" \
  "${VERSION}" \
  "${checkout_ref}" \
  "vendor-subtree" \
  "${TARGET}" \
  "${SOURCE_SUBDIR}" \
  "${NOTE}"

append_plugin_to_pack_manifest "${PACK_ID}" "${ENTRY_ID}"

if [[ "${SKIP_VERIFY}" != "1" ]]; then
  verify_toolbox_layout
fi

log "imported ${ENTRY_ID} -> ${TARGET}"
log "review changes with: git status --short && git diff --stat"
