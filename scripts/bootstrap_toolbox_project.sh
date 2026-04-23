#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_TEMPLATE="${REPO_ROOT}/templates/base"
MANIFEST_PATH="${REPO_ROOT}/packs.manifest.json"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/bootstrap_toolbox_project.sh <destination> [--packs=pack_a,pack_b] [--force]
EOF
}

DEST=""
PACKS_CSV=""
FORCE="0"

for arg in "$@"; do
  case "$arg" in
    --packs=*)
      PACKS_CSV="${arg#--packs=}"
      ;;
    --force)
      FORCE="1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${DEST}" ]]; then
        DEST="$arg"
      else
        echo "[bootstrap] ERROR: unexpected argument: ${arg}" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${DEST}" ]]; then
  echo "[bootstrap] ERROR: destination is required." >&2
  usage
  exit 1
fi

mkdir -p "${DEST}"

if [[ "${FORCE}" != "1" ]] && [[ -n "$(find "${DEST}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
  echo "[bootstrap] ERROR: destination is not empty. Use --force to overlay." >&2
  exit 1
fi

copy_overlay() {
  local src="$1"
  cp -R "${src}/." "${DEST}/"
}

copy_overlay "${BASE_TEMPLATE}"

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "${value}"
}

manifest_has_pack() {
  local pack_id="$1"
  jq -e --arg pack_id "${pack_id}" \
    '.packs[] | select(.id == $pack_id)' \
    "${MANIFEST_PATH}" > /dev/null
}

manifest_pack_plugins() {
  local pack_id="$1"
  jq -r --arg pack_id "${pack_id}" \
    '.packs[] | select(.id == $pack_id) | .plugins[]?' \
    "${MANIFEST_PATH}"
}

manifest_supported_packs_csv() {
  jq -r '[.packs[].id] | join(",")' "${MANIFEST_PATH}"
}

declare -a enabled_plugins=()
declare -A seen_plugins=()
declare -a normalized_packs=()
declare -A seen_packs=()

add_plugin_id() {
  local plugin_id="$1"
  local plugin_cfg=""

  [[ -n "${plugin_id}" ]] || return 0

  plugin_cfg="res://addons/${plugin_id}/plugin.cfg"
  if [[ -z "${seen_plugins[${plugin_cfg}]+x}" ]]; then
    enabled_plugins+=("${plugin_cfg}")
    seen_plugins["${plugin_cfg}"]=1
  fi
}

while IFS= read -r plugin_id; do
  add_plugin_id "${plugin_id}"
done < <(jq -r '.base_template.default_enabled_plugins[]?' "${MANIFEST_PATH}")

while IFS= read -r plugin_id; do
  add_plugin_id "${plugin_id}"
done < <(manifest_pack_plugins "base")

if [[ -n "${PACKS_CSV}" ]]; then
  IFS=',' read -r -a requested_packs <<< "${PACKS_CSV}"
  for raw_pack in "${requested_packs[@]}"; do
    pack="$(trim "${raw_pack}")"
    [[ -n "${pack}" ]] || continue

    if ! manifest_has_pack "${pack}"; then
      echo "[bootstrap] ERROR: pack '${pack}' is not defined in packs.manifest.json. Supported packs: $(manifest_supported_packs_csv)" >&2
      exit 1
    fi

    if [[ -z "${seen_packs[${pack}]+x}" ]]; then
      normalized_packs+=("${pack}")
      seen_packs["${pack}"]=1
    fi

    if [[ "${pack}" != "base" ]]; then
      pack_dir="${REPO_ROOT}/packs/${pack}"
      if [[ ! -d "${pack_dir}" ]]; then
        echo "[bootstrap] ERROR: pack '${pack}' is defined in packs.manifest.json but '${pack_dir}' does not exist." >&2
        exit 1
      fi
      copy_overlay "${pack_dir}"
    fi

    while IFS= read -r plugin_id; do
      add_plugin_id "${plugin_id}"
    done < <(manifest_pack_plugins "${pack}")
  done
fi

plugin_list=""
for plugin in "${enabled_plugins[@]}"; do
  if [[ -n "${plugin_list}" ]]; then
    plugin_list+=", "
  fi
  plugin_list+="\"${plugin}\""
done

sed "s|__EDITOR_PLUGIN_LIST__|${plugin_list}|g" \
  "${DEST}/godot/project.godot.in" > "${DEST}/godot/project.godot"
rm -f "${DEST}/godot/project.godot.in"

if [[ "${#normalized_packs[@]}" -gt 0 ]]; then
  normalized_packs_csv="$(IFS=','; printf '%s' "${normalized_packs[*]}")"
  printf '%s\n' "${normalized_packs_csv}" > "${DEST}/.toolbox-packs"
fi

echo "[bootstrap] Project created at ${DEST}"
echo "[bootstrap] Enabled plugins: ${plugin_list}"
