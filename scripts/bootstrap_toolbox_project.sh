#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_TEMPLATE="${REPO_ROOT}/templates/base"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/bootstrap_toolbox_project.sh <destination> [--packs=validation,debug,stateful,juice] [--force]
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

declare -a enabled_plugins=(
  "res://addons/gdUnit4/plugin.cfg"
)

normalize_pack() {
  case "$1" in
    validation|debug|stateful|juice)
      printf '%s\n' "$1"
      ;;
    "")
      ;;
    *)
      echo "[bootstrap] ERROR: unsupported pack '$1'." >&2
      exit 1
      ;;
  esac
}

if [[ -n "${PACKS_CSV}" ]]; then
  IFS=',' read -r -a requested_packs <<< "${PACKS_CSV}"
  for raw_pack in "${requested_packs[@]}"; do
    pack="$(normalize_pack "${raw_pack}")"
    [[ -n "${pack}" ]] || continue
    copy_overlay "${REPO_ROOT}/packs/${pack}"
    case "${pack}" in
      validation)
        enabled_plugins+=("res://addons/godot_doctor/plugin.cfg")
        ;;
      debug)
        enabled_plugins+=("res://addons/signal_lens/plugin.cfg")
        ;;
      stateful)
        enabled_plugins+=("res://addons/godot_state_charts/plugin.cfg")
        ;;
      juice)
        enabled_plugins+=("res://addons/sparkle_lite/plugin.cfg")
        ;;
    esac
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

if [[ -n "${PACKS_CSV}" ]]; then
  printf '%s\n' "${PACKS_CSV}" > "${DEST}/.toolbox-packs"
fi

echo "[bootstrap] Project created at ${DEST}"
echo "[bootstrap] Enabled plugins: ${plugin_list}"
