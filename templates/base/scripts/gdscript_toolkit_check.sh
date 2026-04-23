#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GDTOOLKIT_SPEC="${GDTOOLKIT_SPEC:-gdtoolkit==4.5.0}"
export RUST_LOG="${RUST_LOG:-error}"
THIRD_PARTY_ADDON_REGEX='^godot/addons/(gdUnit4|godot_doctor|godot_state_charts|signal_lens|sparkle_lite)/'

declare -a UV_CMD=()

resolve_uv() {
  if command -v uv >/dev/null 2>&1; then
    UV_CMD=(uv)
    return 0
  fi
  if command -v python3 >/dev/null 2>&1 && python3 -m uv --version >/dev/null 2>&1; then
    UV_CMD=(python3 -m uv)
    return 0
  fi

  echo "[gdscript-toolkit-check] ERROR: uv is required." >&2
  exit 1
}

collect_default_targets() {
  (
    cd "${REPO_ROOT}"
    rg --files godot -g '*.gd' \
      | grep -E -v "^godot/(\\.godot/|\\.godot-mcp/|\\.godot-mcp-src/)|${THIRD_PARTY_ADDON_REGEX}" || true
  )
}

normalize_targets() {
  local file_path
  declare -A seen=()
  for file_path in "$@"; do
    [[ -n "${file_path}" ]] || continue
    [[ "${file_path}" == godot/* ]] || continue
    [[ "${file_path##*.}" == "gd" ]] || continue
    [[ "${file_path}" != godot/.godot/* ]] || continue
    [[ "${file_path}" != godot/.godot-mcp/* ]] || continue
    [[ "${file_path}" != godot/.godot-mcp-src/* ]] || continue
    [[ ! "${file_path}" =~ ${THIRD_PARTY_ADDON_REGEX} ]] || continue
    [[ -f "${REPO_ROOT}/${file_path}" ]] || continue
    if [[ -z "${seen["${file_path}"]+x}" ]]; then
      seen["${file_path}"]=1
      printf '%s\n' "${file_path}"
    fi
  done
}

run_gdtool() {
  "${UV_CMD[@]}" tool run --from "${GDTOOLKIT_SPEC}" "$@"
}

resolve_uv

declare -a requested_targets=()
if [[ "$#" -gt 0 ]]; then
  requested_targets=("$@")
else
  mapfile -t requested_targets < <(collect_default_targets)
fi

mapfile -t targets < <(normalize_targets "${requested_targets[@]}")

if [[ "${#targets[@]}" -eq 0 ]]; then
  echo "[gdscript-toolkit-check] No GDScript targets to check. Skipped."
  exit 0
fi

echo "[gdscript-toolkit-check] Running gdlint on ${#targets[@]} file(s)"
run_gdtool gdlint "${targets[@]}"

echo "[gdscript-toolkit-check] Running gdformat --check on ${#targets[@]} file(s)"
run_gdtool gdformat --check "${targets[@]}"

echo "[gdscript-toolkit-check] PASS"
