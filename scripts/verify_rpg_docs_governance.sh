#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '[verify-rpg-docs] %s\n' "$*"; }
die() { printf '[verify-rpg-docs] ERROR: %s\n' "$*" >&2; exit 1; }

log "checking required RPG docs"
for path in \
  "docs/rpg-pack-recipes.md" \
  "docs/rpg-adapter-boundaries.md" \
  "docs/rpg-vendor-upgrade-checklist.md" \
  "docs/rpg-acceptance-matrix.md" \
  "docs/rpg-implementation-execution-plan.md" \
  "docs/rpg-execution-verification-log.md"; do
  [[ -f "${REPO_ROOT}/${path}" ]] || die "missing RPG governance doc: ${path}"
done

log "checking README RPG links and claim boundaries"
for text in \
  "docs/rpg-template-absorption-plan.md" \
  "docs/rpg-pack-recipes.md" \
  "docs/rpg-adapter-boundaries.md" \
  "docs/rpg-vendor-upgrade-checklist.md" \
  "docs/rpg-acceptance-matrix.md" \
  "RPG-ready shell evidence exists" \
  "complete RPG template"; do
  grep -Fq "${text}" "${REPO_ROOT}/README.md" || die "README missing: ${text}"
done

log "checking RPG pack dry-run recipes"
for packs in \
  "rpg-battle-core,rpg-core,rpg-save-adapter,rpg-test-kit,flow-core,rules-events-core,data-core,save-core" \
  "inventory,data-core,save-core,rpg-core,rpg-save-adapter,rules-events-core" \
  "quest,data-core,save-core,rules-events-core,rpg-save-adapter,rpg-core" \
  "ai-behavior,rpg-battle-core,rpg-core,flow-core,rules-events-core,data-core,save-core"; do
  grep -Fq -- "--packs=${packs}" "${REPO_ROOT}/docs/rpg-pack-recipes.md" \
    || die "recipe doc missing pack set: ${packs}"
  python3 "${REPO_ROOT}/scripts/pack_manifest.py" report --packs="${packs}" >/dev/null
done

log "checking adapter boundary docs"
for text in \
  "GLoot" \
  "QuestSystem" \
  "Beehave" \
  "SaveState Lite" \
  "save-core" \
  "state ownership" \
  "save ownership" \
  "source boundary"; do
  grep -Fq "${text}" "${REPO_ROOT}/docs/rpg-adapter-boundaries.md" \
    || die "adapter boundary doc missing: ${text}"
done

log "checking vendor upgrade checklist"
for text in \
  "./scripts/update_plugin_from_upstream.sh --id=gloot --dry-run" \
  "./scripts/update_plugin_from_upstream.sh --id=quest_system --dry-run" \
  "./scripts/update_plugin_from_upstream.sh --id=beehave --dry-run" \
  "./scripts/update_plugin_from_upstream.sh --id=savestate_lite --dry-run" \
  "ResourceUID" \
  "license / NOTICE" \
  "verify_specialized_pack_candidates.sh"; do
  grep -Fq "${text}" "${REPO_ROOT}/docs/rpg-vendor-upgrade-checklist.md" \
    || die "upgrade checklist missing: ${text}"
done

log "PASS"
