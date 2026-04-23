#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./lib_upstreams.sh
source "${REPO_ROOT}/scripts/lib_upstreams.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/update_plugin_from_upstream.sh \
    --id <entry_id> \
    [--ref=<git_ref>] \
    [--version=<display_version>] \
    [--dry-run] \
    [--skip-verify]

Notes:
  - 第一版支持 git upstream + vendor-subtree 升级。
  - 若 lock entry 是 tool-only，这一版仅允许更新 lock metadata，不自动改写目标文件。
EOF
}

ENTRY_ID=""
REF=""
VERSION=""
DRY_RUN="0"
SKIP_VERIFY="0"

for arg in "$@"; do
  case "${arg}" in
    --id=*) ENTRY_ID="${arg#--id=}" ;;
    --ref=*) REF="${arg#--ref=}" ;;
    --version=*) VERSION="${arg#--version=}" ;;
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

if ! mapfile -t fields < <(read_lock_entry_fields "${ENTRY_ID}"); then
  die "entry not found in upstreams.lock.json: ${ENTRY_ID}"
fi

[[ "${#fields[@]}" -ge 8 ]] || die "invalid lock entry payload for ${ENTRY_ID}"

lock_id="${fields[0]}"
kind="${fields[1]}"
source_type="${fields[2]}"
repo_url="${fields[3]}"
current_version="${fields[4]}"
current_ref="${fields[5]}"
mode="${fields[6]}"
target="${fields[7]}"
source_subdir="${fields[8]-}"
note="${fields[9]-}"
[[ -n "${lock_id}" ]] || die "failed to read lock entry for ${ENTRY_ID}"
[[ "${source_type}" == "git" ]] || die "only git upstreams are supported in this version"

new_version="${VERSION:-${current_version}}"

cache_root="$(ensure_cache_dir)"
cache_path="${cache_root}/${ENTRY_ID}"

log "syncing upstream cache: ${repo_url}"
sync_git_cache "${repo_url}" "${cache_path}"
new_ref="$(resolve_checkout_ref "${cache_path}" "${REF:-${current_ref}}" "${VERSION:-${current_version}}")"
checkout_git_ref "${cache_path}" "${new_ref}"

if [[ "${mode}" == "tool-only" ]]; then
  if [[ "${DRY_RUN}" == "1" ]]; then
    log "dry-run tool-only update summary"
    log "  id=${ENTRY_ID}"
    log "  version=${new_version:-<unchanged>}"
    log "  ref=${new_ref}"
    exit 0
  fi

  update_upstreams_lock_entry \
    "${ENTRY_ID}" \
    "${kind}" \
    "${source_type}" \
    "${repo_url}" \
    "${new_version}" \
    "${REF:-${current_ref}}" \
    "${mode}" \
    "${target}" \
    "${source_subdir}" \
    "${note}"

  log "updated tool-only lock metadata for ${ENTRY_ID}"
  exit 0
fi

[[ "${mode}" == "vendor-subtree" ]] || die "unsupported integration mode: ${mode}"
source_path="$(resolve_source_path "${cache_path}" "${source_subdir}" "${target}" "${ENTRY_ID}")"
dest_path="${REPO_ROOT}/${target}"

if [[ "${DRY_RUN}" == "1" ]]; then
  log "dry-run update summary"
  log "  id=${ENTRY_ID}"
  log "  source=${source_path}"
  log "  target=${dest_path}"
  log "  ref=${new_ref}"
  log "  version=${new_version:-<unchanged>}"
  exit 0
fi

copy_tree_overwrite "${source_path}" "${dest_path}"
verify_plugin_tree "${dest_path}"

update_upstreams_lock_entry \
  "${ENTRY_ID}" \
  "${kind}" \
  "${source_type}" \
  "${repo_url}" \
  "${new_version}" \
  "${REF:-${current_ref}}" \
  "${mode}" \
  "${target}" \
  "${source_subdir}" \
  "${note}"

if [[ "${SKIP_VERIFY}" != "1" ]]; then
  verify_toolbox_layout
fi

log "updated ${ENTRY_ID} -> ${target}"
log "review changes with: git status --short && git diff --stat"
