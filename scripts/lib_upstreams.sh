#!/usr/bin/env bash

die() {
  echo "[${SCRIPT_NAME}] ERROR: $*" >&2
  exit 1
}

log() {
  echo "[${SCRIPT_NAME}] $*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

ensure_cache_dir() {
  require_cmd python3
  local rel
  rel="$(
    python3 - "${REPO_ROOT}/upstreams.lock.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)
print(data.get("cache_dir", ".cache/upstreams"))
PY
  )"
  mkdir -p "${REPO_ROOT}/${rel}"
  printf '%s\n' "${REPO_ROOT}/${rel}"
}

sync_git_cache() {
  local repo_url="$1"
  local cache_path="$2"

  require_cmd git

  if [[ -d "${cache_path}/.git" ]]; then
    git -C "${cache_path}" remote set-url origin "${repo_url}"
    git -C "${cache_path}" fetch --tags --force origin
    return 0
  fi

  rm -rf "${cache_path}"
  git clone --filter=blob:none "${repo_url}" "${cache_path}"
}

checkout_git_ref() {
  local cache_path="$1"
  local ref="$2"

  if [[ -n "${ref}" ]]; then
    git -C "${cache_path}" checkout --detach "${ref}"
    return 0
  fi

  local default_ref=""
  default_ref="$(git -C "${cache_path}" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
  if [[ -z "${default_ref}" ]]; then
    default_ref="$(git -C "${cache_path}" remote show origin | sed -n '/HEAD branch/s/.*: //p' | head -n 1)"
  fi
  [[ -n "${default_ref}" ]] || die "unable to determine default branch for ${cache_path}"

  git -C "${cache_path}" checkout --detach "origin/${default_ref}"
}

resolve_checkout_ref() {
  local cache_path="$1"
  local explicit_ref="$2"
  local version="$3"

  if [[ -n "${explicit_ref}" ]]; then
    printf '%s\n' "${explicit_ref}"
    return 0
  fi

  if [[ -n "${version}" ]]; then
    if git -C "${cache_path}" rev-parse --verify --quiet "${version}^{commit}" >/dev/null; then
      printf '%s\n' "${version}"
      return 0
    fi

    if [[ "${version}" != v* ]]; then
      local prefixed="v${version}"
      if git -C "${cache_path}" rev-parse --verify --quiet "${prefixed}^{commit}" >/dev/null; then
        printf '%s\n' "${prefixed}"
        return 0
      fi
    fi
  fi

  printf '\n'
}

resolve_source_path() {
  local cache_path="$1"
  local source_subdir="$2"
  local target="$3"
  local entry_id="$4"

  if [[ -n "${source_subdir}" ]]; then
    local explicit_path="${cache_path}/${source_subdir}"
    [[ -d "${explicit_path}" ]] || die "source subdir does not exist: ${source_subdir}"
    printf '%s\n' "${explicit_path}"
    return 0
  fi

  if [[ -f "${cache_path}/plugin.cfg" ]]; then
    printf '%s\n' "${cache_path}"
    return 0
  fi

  local base_name
  base_name="$(basename "${target}")"
  if [[ -d "${cache_path}/${base_name}" ]]; then
    printf '%s\n' "${cache_path}/${base_name}"
    return 0
  fi
  if [[ -d "${cache_path}/addons/${base_name}" ]]; then
    printf '%s\n' "${cache_path}/addons/${base_name}"
    return 0
  fi
  if [[ -d "${cache_path}/addons/${entry_id}" ]]; then
    printf '%s\n' "${cache_path}/addons/${entry_id}"
    return 0
  fi

  die "unable to infer source path inside cache for id=${entry_id}; please pass --source-subdir"
}

copy_tree_overwrite() {
  local src="$1"
  local dest="$2"

  [[ -d "${src}" ]] || die "source directory does not exist: ${src}"
  rm -rf "${dest}"
  mkdir -p "$(dirname "${dest}")"
  cp -R "${src}" "${dest}"
}

verify_plugin_tree() {
  local target_dir="$1"
  [[ -f "${target_dir}/plugin.cfg" ]] || die "plugin.cfg not found in ${target_dir}"
}

update_upstreams_lock_entry() {
  local id="$1"
  local kind="$2"
  local source_type="$3"
  local repo_url="$4"
  local version="$5"
  local ref="$6"
  local mode="$7"
  local target="$8"
  local source_subdir="$9"
  local note="${10}"

  python3 - "${REPO_ROOT}/upstreams.lock.json" "${id}" "${kind}" "${source_type}" "${repo_url}" "${version}" "${ref}" "${mode}" "${target}" "${source_subdir}" "${note}" <<'PY'
import json
import sys
from pathlib import Path

lock_path = Path(sys.argv[1])
entry_id, kind, source_type, repo_url, version, ref, mode, target, source_subdir, note = sys.argv[2:]

with lock_path.open("r", encoding="utf-8") as fh:
    data = json.load(fh)

entry = {
    "id": entry_id,
    "kind": kind,
    "source": {
        "type": source_type,
        "url": repo_url,
    },
    "integration": {
        "mode": mode,
        "target": target,
    },
    "patches": [],
}

if version:
    entry["source"]["version"] = version
if ref:
    entry["source"]["ref"] = ref
if source_subdir:
    entry["integration"]["source_subdir"] = source_subdir
if note:
    entry["integration"]["note"] = note

entries = data.setdefault("entries", [])
for index, existing in enumerate(entries):
    if existing.get("id") == entry_id:
      entry["patches"] = existing.get("patches", [])
      entries[index] = entry
      break
else:
    entries.append(entry)

with lock_path.open("w", encoding="utf-8") as fh:
    json.dump(data, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY
}

append_plugin_to_pack_manifest() {
  local pack_id="$1"
  local plugin_id="$2"

  [[ -n "${pack_id}" ]] || return 0

  python3 - "${REPO_ROOT}/packs.manifest.json" "${pack_id}" "${plugin_id}" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
pack_id = sys.argv[2]
plugin_id = sys.argv[3]

with manifest_path.open("r", encoding="utf-8") as fh:
    data = json.load(fh)

if pack_id == "base":
    defaults = data.setdefault("base_template", {}).setdefault("default_enabled_plugins", [])
    if plugin_id not in defaults:
        defaults.append(plugin_id)
    for pack in data.get("packs", []):
        if pack.get("id") == "base":
            plugins = pack.setdefault("plugins", [])
            if plugin_id not in plugins:
                plugins.append(plugin_id)
            break
    else:
        raise SystemExit("pack 'base' not found in packs.manifest.json")
else:
    for pack in data.get("packs", []):
        if pack.get("id") == pack_id:
            plugins = pack.setdefault("plugins", [])
            if plugin_id not in plugins:
                plugins.append(plugin_id)
            break
    else:
        raise SystemExit(f"pack '{pack_id}' not found in packs.manifest.json")

with manifest_path.open("w", encoding="utf-8") as fh:
    json.dump(data, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY
}

read_lock_entry_fields() {
  local entry_id="$1"

  python3 - "${REPO_ROOT}/upstreams.lock.json" "${entry_id}" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)

entry_id = sys.argv[2]
for entry in data.get("entries", []):
    if entry.get("id") == entry_id:
        source = entry.get("source", {})
        integration = entry.get("integration", {})
        fields = [
            entry.get("id", ""),
            entry.get("kind", ""),
            source.get("type", ""),
            source.get("url", ""),
            source.get("version", ""),
            source.get("ref", ""),
            integration.get("mode", ""),
            integration.get("target", ""),
            integration.get("source_subdir", ""),
            integration.get("note", ""),
        ]
        for field in fields:
            print(field)
        break
else:
    raise SystemExit(1)
PY
}

verify_toolbox_layout() {
  "${REPO_ROOT}/scripts/verify_toolbox_layout.sh"
}
