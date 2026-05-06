#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REVIEW="${REPO_ROOT}/docs/rpg-experience-review.md"
SESSION_TEMPLATE="${REPO_ROOT}/docs/rpg-experience-session-template.md"
PLAYTEST_CHECKLIST="${REPO_ROOT}/docs/rpg-experience-playtest-checklist.md"

log() { printf '[verify-rpg-experience-review] %s\n' "$*"; }
die() { printf '[verify-rpg-experience-review] ERROR: %s\n' "$*" >&2; exit 1; }

require_text() {
  local file="$1"
  local text="$2"
  grep -Fq "${text}" "${file}" || die "${file#${REPO_ROOT}/} missing: ${text}"
}

log "checking required files"
[[ -f "${REVIEW}" ]] || die "missing review doc: docs/rpg-experience-review.md"

log "checking claim boundary language"
for text in \
  "## Claim Boundary" \
  "automated Interaction evidence" \
  "playable" \
  "release-ready" \
  "Experience-layer completion" \
  "Release-layer completion" \
  "Completion Language" \
  "Allowed completion language" \
  "Forbidden completion language" \
  "not_claimed" \
  "release_ready_claim: \"not_claimed\"" \
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

log "checking claim boundary schema fields"
for field in \
  "claim_boundary:" \
  "automated_interaction_evidence:" \
  "experience_claim:" \
  "playable_claim:" \
  "release_ready_claim:"; do
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

log "checking relative artifact guidance"
for text in \
  "Minimum Experience session fields" \
  "repository-relative paths" \
  "Do not use local absolute paths" \
  "blocked" \
  "needs_followup"; do
  require_text "${REVIEW}" "${text}"
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

log "checking next-step checklist"
for text in \
  "## Next Human/AI-Assisted Review Checklist" \
  "Battle UI clarity" \
  "Menu affordance clarity" \
  "Sample content usefulness" \
  "Save/replay interpretability" \
  "Evidence capture"; do
  require_text "${REVIEW}" "${text}"
done

log "checking optional template documents"
if [[ -f "${SESSION_TEMPLATE}" ]]; then
  require_text "${REVIEW}" "docs/rpg-experience-session-template.md"
  for field in \
    "timestamp:" \
    "session_id:" \
    "phase:" \
    "actor:" \
    "status:" \
    "artifact_paths:" \
    "claim_boundary:" \
    "not_claimed"; do
    require_text "${SESSION_TEMPLATE}" "${field}"
  done
fi

if [[ -f "${PLAYTEST_CHECKLIST}" ]]; then
  require_text "${REVIEW}" "docs/rpg-experience-playtest-checklist.md"
  for text in \
    "Battle UI clarity" \
    "Menu affordance clarity" \
    "Sample content usefulness" \
    "Evidence capture"; do
    require_text "${PLAYTEST_CHECKLIST}" "${text}"
  done
fi

log "checking repository docs do not contain local absolute artifact paths"
experience_docs=("${REVIEW}")
[[ -f "${SESSION_TEMPLATE}" ]] && experience_docs+=("${SESSION_TEMPLATE}")
[[ -f "${PLAYTEST_CHECKLIST}" ]] && experience_docs+=("${PLAYTEST_CHECKLIST}")
if grep -Eq '(/home/|/tmp/|file://)' "${experience_docs[@]}"; then
  die "Experience docs must not contain local absolute paths or file:// URLs"
fi

log "PASS"
