#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}"
WORKDIR=""
GODOT_BIN="${GODOT_BIN:-}"
PACKS="dialogue,base,data-core,save-core,rules-events-core"

log() { printf '[verify-dialogue-pack] %s\n' "$*"; }
die() { printf '[verify-dialogue-pack] ERROR: %s\n' "$*" >&2; exit 1; }

cleanup() {
  if [[ -n "${WORKDIR}" && -d "${WORKDIR}" ]]; then
    rm -rf "${WORKDIR}"
  fi
}
trap cleanup EXIT

resolve_godot_bin() {
  if [[ -n "${GODOT_BIN}" ]]; then
    [[ -x "${GODOT_BIN}" ]] || die "GODOT_BIN is not executable: ${GODOT_BIN}"
    printf '%s\n' "${GODOT_BIN}"
    return 0
  fi
  if command -v godot >/dev/null 2>&1; then
    command -v godot
    return 0
  fi
  if [[ -x "/usr/local/bin/godot" ]]; then
    printf '%s\n' "/usr/local/bin/godot"
    return 0
  fi
  return 1
}

# ── Phase 1: Validate manifest and dry-run report ───────────────────────
log "validating manifest and dry-run report"
python3 "${REPO_ROOT}/scripts/pack_manifest.py" validate >/dev/null
report="$(python3 "${REPO_ROOT}/scripts/pack_manifest.py" report --packs="${PACKS}")"
for expected in \
  "Selected packs:" \
  "dialogue_manager" \
  "dialogue/enabled=true" \
  "scripts/verify_dialogue_pack.sh"; do
  grep -Fq "${expected}" <<<"${report}" || die "dry-run report missing: ${expected}"
done

# ── Phase 2: Bootstrap temp project ─────────────────────────────────────
WORKDIR="$(mktemp -d "${TMP_ROOT%/}/godot-toolbox-dialogue.XXXXXX")"
log "bootstrapping ${PACKS} into ${WORKDIR}"
bash "${REPO_ROOT}/scripts/bootstrap_toolbox_project.sh" "${WORKDIR}" --packs="${PACKS}" >/dev/null

# ── Phase 3: Check required files ───────────────────────────────────────
required_files=(
  "godot/addons/dialogue_manager/plugin.cfg"
)
for path in "${required_files[@]}"; do
  [[ -f "${WORKDIR}/${path}" ]] || die "required file missing from bootstrap: ${path}"
done

# Check README exists in repo
[[ -f "${REPO_ROOT}/packs/dialogue/README.md" ]] || die "missing packs/dialogue/README.md"

# ── Phase 4: Verify project.godot settings ──────────────────────────────
PROJECT_GODOT="${WORKDIR}/godot/project.godot"
grep -Fq "dialogue/enabled=true" "${PROJECT_GODOT}" \
  || die "project.godot missing dialogue/enabled=true setting"

# ── Phase 5: Godot headless import ──────────────────────────────────────
if resolve_godot_bin >/dev/null 2>&1; then
  GODOT_BIN_RESOLVED="$(resolve_godot_bin)"
  log "running headless import"
  "${GODOT_BIN_RESOLVED}" --headless --editor --quit-after 1 --path "${WORKDIR}/godot" --import >/dev/null 2>&1 || true

  # ── Phase 6: Adapter smoke tests ────────────────────────────────────────
  log "running dialogue adapter smoke tests"
  "${GODOT_BIN_RESOLVED}" --headless --path "${WORKDIR}/godot" \
    --script res://addons/godot_toolbox_dialogue/tests/dialogue_adapter_smoke.gd
fi

log "PASS"
