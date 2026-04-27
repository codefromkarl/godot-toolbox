#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECEIPT="${REPO_ROOT}/docs/rpg-final-acceptance-receipt.md"

log() { printf '[verify-rpg-final] %s\n' "$*"; }
die() { printf '[verify-rpg-final] ERROR: %s\n' "$*" >&2; exit 1; }

[[ -f "${RECEIPT}" ]] || die "missing final receipt: docs/rpg-final-acceptance-receipt.md"

log "checking final receipt task coverage"
python3 - "${RECEIPT}" <<'PY'
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")
ids = []
for prefix, end in [('I', 5), ('C', 7), ('B', 10), ('S', 4), ('U', 6), ('T', 5), ('D', 4)]:
    ids.extend(f'RPG-{prefix}{i:02d}' for i in range(1, end + 1))
missing = [task_id for task_id in ids if task_id not in text]
not_verified = [task_id for task_id in ids if f"| `{task_id}` | `verified` |" not in text]
if missing or not_verified:
    raise SystemExit({
        "missing": missing,
        "not_verified": not_verified,
    })
PY

log "checking final receipt sections"
for text in \
  "Task Status Matrix" \
  "Implementation Evidence" \
  "Verification Commands" \
  "Cleanup Receipt" \
  "RPG-ready shell evidence exists" \
  "complete RPG template evidence exists"; do
  grep -Fq "${text}" "${RECEIPT}" || die "final receipt missing: ${text}"
done

log "checking no RPG temp dirs remain"
if compgen -G "/tmp/godot-toolbox-rpg-*" >/dev/null; then
  compgen -G "/tmp/godot-toolbox-rpg-*" >&2
  die "RPG temp dirs remain"
fi

log "PASS"
