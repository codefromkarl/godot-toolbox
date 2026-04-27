#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_paths=(
  ".github/workflows/ci.yml"
  "README.md"
  "docs/plugin-catalog.md"
  "docs/plugin-integration-standard.md"
  "docs/maintenance-workflow.md"
  "docs/selection-framework.md"
  "docs/research/godot-plugin-scout-agent.md"
  "docs/research/hot-plugin-scan-2026-04.md"
  "scripts/bootstrap_toolbox_project.sh"
  "scripts/import_plugin_from_upstream.sh"
  "scripts/update_plugin_from_upstream.sh"
  "scripts/pack_manifest.py"
  "scripts/verify_bootstrap_flow.sh"
  "scripts/verify_game_architecture_packs.sh"
  "packs.manifest.json"
  "upstreams.lock.json"
  "docs/open-source-architecture-links.md"
  "templates/base/godot/project.godot.in"
  "templates/base/godot/test/gdunit/tooling_smoke_test.gd"
  "templates/base/scripts/gdunit4_smoke.sh"
  "templates/base/godot/addons/gdUnit4/plugin.cfg"
  "packs/automation/godot/addons/godot_e2e/plugin.cfg"
  "packs/automation/scripts/run_e2e_smoke.sh"
  "packs/input/godot/addons/guide/plugin.cfg"
  "scripts/verify_input_pack_poc.sh"
  "packs/validation/godot/addons/godot_doctor/plugin.cfg"
  "packs/debug/godot/addons/signal_lens/plugin.cfg"
  "packs/stateful/godot/addons/godot_state_charts/plugin.cfg"
  "packs/juice/godot/addons/sparkle_lite/plugin.cfg"
  "packs/shell/README.md"
  "packs/shell/godot/addons/maaacks_game_template/plugin.cfg"
  "packs/flow-core/godot/addons/godot_toolbox_architecture/flow_core/flow_core.gd"
  "packs/simulation-core/godot/addons/godot_toolbox_architecture/simulation_core/simulation_core.gd"
  "packs/data-core/godot/addons/godot_toolbox_architecture/data_core/data_core.gd"
  "packs/save-core/godot/addons/godot_toolbox_architecture/save_core/save_core.gd"
  "packs/flow-test-kit/godot/addons/godot_toolbox_architecture/flow_test_kit/flow_smoke_fixture.gd"
  "packs/flow-test-kit/godot/addons/godot_toolbox_architecture/flow_test_kit/architecture_spine_smoke.gd"
  "packs/rules-events-core/godot/addons/godot_toolbox_architecture/rules_events_core/rules_events_core.gd"
  "packs/ui-game-shell/godot/addons/godot_toolbox_architecture/ui_game_shell/shell_root.gd"
  "packs/inventory/README.md"
  "packs/inventory/godot/addons/gloot/plugin.cfg"
  "packs/quest/README.md"
  "packs/quest/godot/addons/quest_system/plugin.cfg"
  "packs/ai-behavior/README.md"
  "packs/ai-behavior/godot/addons/beehave/plugin.cfg"
  "packs/save-state-lite/README.md"
  "packs/save-state-lite/godot/addons/savestate/plugin.cfg"
  "docs/rpg-template-absorption-plan.md"
  "scripts/verify_rules_events_core_pack.sh"
  "scripts/verify_ui_game_shell_pack.sh"
  "scripts/verify_pack_matrix.sh"
  "scripts/verify_specialized_pack_candidates.sh"
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

python3 "${REPO_ROOT}/scripts/pack_manifest.py" validate >/dev/null

echo "[verify] PASS"
