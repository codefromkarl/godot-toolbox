#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACK_ID="rpg-art-demo"
PACK_DIR="${REPO_ROOT}/packs/${PACK_ID}"

fail() {
  echo "[rpg-art-demo] ERROR: $*" >&2
  exit 1
}

require_file() {
  local path="$1"
  [[ -f "${path}" ]] || fail "missing required file: ${path#${REPO_ROOT}/}"
}

cd "${REPO_ROOT}"

python3 scripts/pack_manifest.py validate >/dev/null
python3 scripts/pack_manifest.py report --packs="${PACK_ID}" >/dev/null

[[ -d "${PACK_DIR}" ]] || fail "missing pack directory: packs/${PACK_ID}"
require_file "${PACK_DIR}/README.md"
require_file "${PACK_DIR}/NOTICE.md"
require_file "${PACK_DIR}/import-policy.md"
require_file "${PACK_DIR}/art/placeholders/placeholder_assets.json"
require_file "${PACK_DIR}/audio/placeholders/placeholder_audio_assets.json"

python3 - <<'PY'
import json
from pathlib import Path

manifest = json.loads(Path("packs.manifest.json").read_text(encoding="utf-8"))
pack = next((item for item in manifest["packs"] if item.get("id") == "rpg-art-demo"), None)
if pack is None:
    raise SystemExit("manifest missing rpg-art-demo")
if pack.get("kind") != "optional-pack":
    raise SystemExit("rpg-art-demo kind must be optional-pack")
if pack.get("default") is not False:
    raise SystemExit("rpg-art-demo default must be false")
if "base" not in pack.get("requires", []):
    raise SystemExit("rpg-art-demo must require base")
if pack.get("plugins"):
    raise SystemExit("rpg-art-demo must not enable third-party plugins")
if pack.get("autoloads"):
    raise SystemExit("rpg-art-demo must not define autoloads")
if pack.get("input_map"):
    raise SystemExit("rpg-art-demo must not define input actions")

for path in (
    Path("packs/rpg-art-demo/art/placeholders/placeholder_assets.json"),
    Path("packs/rpg-art-demo/audio/placeholders/placeholder_audio_assets.json"),
):
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("status") != "first-party-placeholder-only":
        raise SystemExit(f"{path} must declare first-party placeholder status")
    if not isinstance(data.get("categories"), list) or not data["categories"]:
        raise SystemExit(f"{path} must declare placeholder categories")
PY

grep -qi "CC0" "${PACK_DIR}/README.md" || fail "README must mention CC0 import policy"
grep -qi "NOTICE" "${PACK_DIR}/README.md" || fail "README must mention NOTICE requirements"
grep -qi "placeholder" "${PACK_DIR}/README.md" || fail "README must describe placeholder status"
grep -qi "source URL" "${PACK_DIR}/NOTICE.md" || fail "NOTICE must require source URL records"

if find "${PACK_DIR}" -type f \( \
  -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' -o -name '*.aseprite' -o \
  -name '*.ogg' -o -name '*.wav' -o -name '*.mp3' -o -name '*.flac' -o \
  -name '*.zip' -o -name '*.7z' -o -name '*.rar' -o \
  -name '*.blend' -o -name '*.glb' -o -name '*.gltf' -o -name '*.fbx' -o -name '*.res' \
  \) -print -quit | grep -q .; then
  fail "pack must stay text-placeholder-only until binary art/audio imports are explicitly reviewed"
fi

if find "${PACK_DIR}" -type f -size +128k -print -quit | grep -q .; then
  fail "pack contains an unexpectedly large file"
fi

if find "${PACK_DIR}" -type f \( -name '*.gd' -o -name '*.tscn' -o -name '*.tres' -o -name '*.import' \) -print -quit | grep -q .; then
  fail "pack must not add runtime scripts, scenes, resources, or Godot import files"
fi

echo "[rpg-art-demo] PASS"
