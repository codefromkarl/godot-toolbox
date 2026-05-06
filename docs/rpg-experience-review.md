# RPG Experience Review

Status date: 2026-04-27.

This document is the review carrier for RPG Experience evidence. It does not replace the automated Interaction evidence in `docs/rpg-final-acceptance-receipt.md`, and it does not create `playable`, `release-ready`, or Release-layer claims.

## Claim Boundary

Allowed from the final automated receipt:

- `RPG-ready shell evidence exists` at Runtime layer.
- `complete RPG template evidence exists` at automated Interaction evidence layer.

Not allowed from automation alone:

- `playable`
- `release-ready`
- Experience-layer completion
- Release-layer completion

Experience review must add human or AI-assisted playtest notes that inspect clarity, usability, pacing, affordances, sample-content usefulness, and issue reproducibility. Screenshots or video may be attached when captured, but this initial record does not fabricate visual artifacts.

## Completion Language

Allowed completion language for this document:

- `Experience evidence carrier exists`
- `Experience session schema exists`
- `Experience review is not_claimed`
- `Experience review is partial`
- `human/AI-assisted Experience review remains required`

Forbidden completion language unless a later real session record includes reviewer notes and actual artifacts:

- `playable`
- `release-ready`
- `Experience-complete`
- `Release-ready`
- `ready to ship`

The current document may describe how to collect those claims, but it must not state that they have been achieved.

## Evidence Schema

Each review evidence record must include these fields:

```yaml
timestamp: "ISO-8601 timestamp for the review or playtest event"
session_id: "stable identifier for this review/playtest session"
phase: "review phase, for example battle_ui, party_equipment, save_reload, replay_audit"
actor: "human tester, AI-assisted observer, reviewer, or CI"
status: "pass, partial, blocked, needs_followup, or fail"
artifact_paths:
  - "relative/repository path to commands, logs, screenshots, UI tree notes, state dumps, or receipts"
notes: "short reviewer notes, including what was and was not observed"
```

Minimum Experience session fields are `timestamp`, `session_id`, `phase`, `actor`, `status`, `artifact_paths`, `notes`, and `claim_boundary`. A session is incomplete when any of those fields are missing or blank after the review is recorded.

`artifact_paths` must only contain repository-relative paths such as `docs/rpg-final-acceptance-receipt.md`, `docs/artifacts/rpg/session-001-ui-tree.json`, or `packs/rpg-test-kit/...`. Do not use local absolute paths, local URL references, home-directory paths, or temporary machine paths in repository documents. If an artifact cannot be committed, record a relative placeholder path and mark the session `blocked` or `needs_followup` instead of claiming completion.

## Playtest Issue Schema

Each issue found during human or AI-assisted playtest must include these fields:

```yaml
phase: "flow phase where the issue appears"
expected: "expected player-facing behavior or review outcome"
actual: "actual observed behavior"
evidence: "artifact path, screenshot/video path, log path, UI tree note, command output reference, or reviewer note"
severity: "blocker, major, minor, polish, or note"
repro: "steps or command sequence needed to reproduce"
source: "human playtest, AI-assisted review, automated evidence review, or CI"
```

## Review Template

Use this template for each human or AI-assisted RPG playtest session.

```yaml
evidence:
  timestamp: ""
  session_id: ""
  phase: ""
  actor: ""
  status: ""
  artifact_paths:
    - ""
  notes: ""
issues:
  - phase: ""
    expected: ""
    actual: ""
    evidence: ""
    severity: ""
    repro: ""
    source: ""
claim_boundary:
  automated_interaction_evidence: ""
  experience_claim: "not_claimed | partial | reviewed"
  playable_claim: "not_claimed | reviewed"
  release_ready_claim: "not_claimed"
```

Use `experience_claim: "not_claimed"` for a schema-only or artifact-only setup session. Use `experience_claim: "partial"` only when real reviewer notes or artifacts exist for at least one phase. Do not use `playable_claim: "reviewed"` without a specific session record explaining what was reviewed and which relative artifacts support it. `release_ready_claim` remains `not_claimed` in this evidence carrier.

## Initial Review Record

```yaml
evidence:
  timestamp: "2026-04-27T00:00:00+08:00"
  session_id: "rpg-experience-initial-2026-04-27-worker-a"
  phase: "automated_interaction_evidence_review"
  actor: "Worker A AI-assisted reviewer"
  status: "partial"
  artifact_paths:
    - "docs/rpg-final-acceptance-receipt.md"
    - "docs/rpg-execution-verification-log.md"
    - "docs/rpg-acceptance-matrix.md"
    - "scripts/verify_rpg_ui_content.sh"
    - "scripts/verify_rpg_observability.sh"
    - "scripts/verify_rpg_test_kit_pack.sh"
    - "scripts/verify_rpg_final_acceptance.sh"
    - "packs/rpg-test-kit/godot/addons/godot_toolbox_architecture/rpg_test_kit/replay/fixed_battle_replay.json"
    - "packs/rpg-test-kit/godot/addons/godot_toolbox_architecture/rpg_test_kit/replay/battle_replay_runner.gd"
    - "packs/rpg-test-kit/godot/addons/godot_toolbox_architecture/rpg_test_kit/dump/rpg_state_dump.gd"
    - "packs/rpg-test-kit/godot/addons/godot_toolbox_architecture/rpg_test_kit/tests/rpg_battle_replay_smoke.gd"
    - "packs/rpg-test-kit/godot/addons/godot_toolbox_architecture/rpg_test_kit/tests/rpg_state_dump_smoke.gd"
  notes: "Initial review is based on existing automated Interaction evidence only. The receipt and verification log cite passing UI/content smoke, deterministic replay, combat event stream serialization, state dump JSON serialization, and final acceptance checks. No live human playtest, screenshot, or video artifact was produced in this record."
issues:
  - phase: "experience_review"
    expected: "A human or AI-assisted tester records battle UI clarity, menu affordance clarity, sample content usefulness, and any confusion from normal play."
    actual: "Only automated Interaction evidence has been reviewed so far; no live playtest notes, screenshots, or video are attached."
    evidence: "docs/rpg-final-acceptance-receipt.md; docs/rpg-execution-verification-log.md; docs/rpg-acceptance-matrix.md"
    severity: "major"
    repro: "Run the automated commands listed below, then conduct a separate human or AI-assisted playtest and attach notes/artifacts to this document."
    source: "automated evidence review"
claim_boundary:
  automated_interaction_evidence: "complete RPG template evidence exists"
  experience_claim: "partial"
  playable_claim: "not_claimed"
  release_ready_claim: "not_claimed"
```

## Existing Automated Evidence Reviewed

The initial record references these existing verification commands as automated evidence:

```bash
bash scripts/verify_rpg_ui_content.sh
bash scripts/verify_rpg_observability.sh
bash scripts/verify_rpg_test_kit_pack.sh
bash scripts/verify_rpg_final_acceptance.sh
python3 scripts/check_rpg_readiness.py
```

These commands support automated Runtime and Interaction evidence. They do not, by themselves, prove that the template is playable, release-ready, or Experience-complete.

## Next Human/AI-Assisted Review Checklist

- Battle UI clarity: verify the player can understand party/enemy status, current turn, available actions, disabled actions, and action feedback without reading code.
- Menu affordance clarity: verify skill, item, party, and equipment flows expose expected choices and explain unavailable options.
- Sample content usefulness: verify example heroes, enemies, skills, items, and equipment are enough to teach reuse of the template.
- Save/replay interpretability: verify state dump, replay, and event stream artifacts let a reviewer explain a failure without a debugger.
- Evidence capture: attach reviewer notes and any real screenshots, video, UI tree notes, or command logs that were actually produced.

## Current Review Outcome

The current outcome is `partial`: automated Interaction evidence is inspectable and linked, but human/AI-assisted Experience review remains required before any `playable` or `release-ready` language is allowed.
