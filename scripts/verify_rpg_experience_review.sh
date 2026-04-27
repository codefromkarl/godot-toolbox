#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REVIEW="${REPO_ROOT}/docs/rpg-experience-review.md"
README="${REPO_ROOT}/README.md"
RECEIPT="${REPO_ROOT}/docs/rpg-final-acceptance-receipt.md"

log() { printf '[verify-rpg-experience-review] %s\n' "$*"; }
die() { printf '[verify-rpg-experience-review] ERROR: %s\n' "$*" >&2; exit 1; }

require_text() {
  local file="$1"
  local text="$2"
  grep -Fq "${text}" "${file}" || die "${file#${REPO_ROOT}/} missing: ${text}"
}

log "checking required files"
[[ -f "${REVIEW}" ]] || die "missing review doc: docs/rpg-experience-review.md"
[[ -f "${README}" ]] || die "missing README.md"
[[ -f "${RECEIPT}" ]] || die "missing final receipt"

log "checking claim boundary language"
for text in \
  "automated Interaction evidence" \
  "playable" \
  "release-ready" \
  "Experience-layer completion" \
  "Release-layer completion" \
  "not_claimed" \
  "No live human playtest, screenshot, or video artifact was produced"; do
  require_text "${REVIEW}" "${text}"
done

log "checking evidence schema fields"
for field in \
  "timestamp:" \
  "session_id:" \
  "phase:" \
  "actor:" \
  "status:" \
  "artifact_paths:" \
  "notes:"; do
  require_text "${REVIEW}" "${field}"
done

log "checking playtest issue schema fields"
for field in \
  "phase:" \
  "expected:" \
  "actual:" \
  "evidence:" \
  "severity:" \
  "repro:" \
  "source:"; do
  require_text "${REVIEW}" "${field}"
done

log "checking initial review references automated commands and artifacts"
for text in \
  "bash scripts/verify_rpg_ui_content.sh" \
  "bash scripts/verify_rpg_observability.sh" \
  "bash scripts/verify_rpg_test_kit_pack.sh" \
  "bash scripts/verify_rpg_final_acceptance.sh" \
  "python3 scripts/check_rpg_readiness.py" \
  "packs/rpg-test-kit/godot/addons/godot_toolbox_architecture/rpg_test_kit/replay/fixed_battle_replay.json" \
  "packs/rpg-test-kit/godot/addons/godot_toolbox_architecture/rpg_test_kit/dump/rpg_state_dump.gd"; do
  require_text "${REVIEW}" "${text}"
done

log "checking README and final receipt links"
require_text "${README}" "docs/rpg-experience-review.md"
require_text "${RECEIPT}" "docs/rpg-experience-review.md"
require_text "${RECEIPT}" "Experience Review Boundary"

log "PASS"
