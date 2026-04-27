# RPG Acceptance Matrix

This matrix defines which RPG claims are allowed by evidence. It prevents scaffold-only or readiness-sentinel-only completion claims.

| Claim | Required layer | Required automated evidence | Required human / AI-assisted evidence | Completion language allowed |
| --- | --- | --- | --- | --- |
| `RPG optional pack absorption` | Shell | Manifest validation, optional pack dry-run reports, conflict checks, license / NOTICE policy. | Maintainer review of source boundaries. | "RPG optional pack absorption is verified." |
| `RPG runtime contracts` | Runtime | `verify_rpg_core_pack.sh`, `verify_rpg_battle_core_pack.sh`, `verify_rpg_save_adapter_pack.sh`. | Reviewer checks API boundaries do not hand project truth to third-party plugins. | "RPG runtime contracts pass targeted checks." |
| `RPG-ready shell` | Runtime | Deterministic battle replay, combat event stream, state dump, save roundtrip, and UI/content smoke all pass. | AI/manual reviewer can inspect JSON state dump and event stream without debugger. | "RPG-ready shell evidence exists." |
| `complete RPG template` | Interaction | `RPG-ready shell` evidence plus battle HUD, skill menu, item menu, party/equipment UI, and example content smoke. | Human or AI-assisted review records UI clarity, sample content usefulness, screenshots or UI tree notes, and remaining issues. | "complete RPG template evidence exists." |

## Evidence Actors

- CI decides whether commands pass.
- AI observer decides whether replay, event stream, state dump, and UI tree evidence can explain failures.
- Human reviewer decides whether battle UI, party UI, and example content are understandable as a reusable template.
- Maintainer decides whether release language in README matches the weakest evidence layer.

## Completion Language Allowed

- Before replay/event/state dump checks pass: do not claim `RPG-ready shell`.
- Before UI/content and interaction review pass: do not claim `complete RPG template`.
- A readiness sentinel or scaffold-only pack check can only support a shell/scaffold claim.

## Required Observability Signals

- `Runtime`: deterministic replay output, battle outcome, reward output, save payload, and state dump.
- `Interaction`: UI scene import, visible controls, disabled skill state, item consumption feedback, equipment stat feedback.
- `Experience`: reviewer notes or screenshots/UI tree notes for clarity and usability.
