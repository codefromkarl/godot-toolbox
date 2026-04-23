#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_paths=(
  "README.md"
  "docs/plugin-catalog.md"
  "docs/plugin-integration-standard.md"
  "docs/selection-framework.md"
  "scripts/bootstrap_toolbox_project.sh"
  "packs.manifest.json"
  "upstreams.lock.json"
  "templates/base/godot/project.godot.in"
  "templates/base/godot/test/gdunit/tooling_smoke_test.gd"
  "templates/base/scripts/gdunit4_smoke.sh"
  "templates/base/godot/addons/gdUnit4/plugin.cfg"
  "packs/validation/godot/addons/godot_doctor/plugin.cfg"
  "packs/debug/godot/addons/signal_lens/plugin.cfg"
  "packs/stateful/godot/addons/godot_state_charts/plugin.cfg"
  "packs/juice/godot/addons/sparkle_lite/plugin.cfg"
)

missing=0
for path in "${required_paths[@]}"; do
  if [[ ! -e "${REPO_ROOT}/${path}" ]]; then
    echo "[verify] MISSING ${path}" >&2
    missing=1
  fi
done

if [[ "${missing}" != "0" ]]; then
  echo "[verify] FAIL" >&2
  exit 1
fi

echo "[verify] PASS"
