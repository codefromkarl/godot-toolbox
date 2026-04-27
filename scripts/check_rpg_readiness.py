#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def read_text(path: str) -> str:
    target = REPO_ROOT / path
    if not target.exists():
        return ""
    return target.read_text(encoding="utf-8", errors="ignore")


def has_all(blob: str, needles: list[str]) -> bool:
    return all(needle in blob for needle in needles)


def pack_exists(pack_id: str) -> bool:
    return (REPO_ROOT / "packs" / pack_id / "README.md").is_file()


def main() -> int:
    docs_blob = "\n".join(
        path.read_text(encoding="utf-8", errors="ignore")
        for root in ("README.md", "docs")
        for path in (
            [REPO_ROOT / root]
            if (REPO_ROOT / root).is_file()
            else sorted((REPO_ROOT / root).rglob("*.md"))
        )
    )
    manifest = read_text("packs.manifest.json")
    scripts_blob = "\n".join(
        path.read_text(encoding="utf-8", errors="ignore")
        for path in sorted((REPO_ROOT / "scripts").glob("*.sh"))
    )
    combined = "\n".join([docs_blob, manifest, scripts_blob])

    checks = {
        "RPG-I01": has_all(
            combined,
            [
                "--packs=inventory,data-core,save-core",
                "--packs=quest,data-core,save-core,rules-events-core",
                "--packs=ai-behavior",
                "--packs=save-state-lite",
            ],
        ),
        "RPG-I02": has_all(combined, ["save-state-lite,save-core", "conflict"]),
        "RPG-I03": has_all(combined, ["License", "NOTICE", "GLoot", "QuestSystem", "Beehave", "SaveState Lite"]),
        "RPG-I04": has_all(combined, ["ResourceUID", "upstream", "local"]),
        "RPG-I05": has_all(combined, ["verify_pack_matrix.sh --all", "local-only"]),
        "RPG-C01": pack_exists("rpg-core") and has_all(manifest, ['"id": "rpg-core"', '"data-core"', '"save-core"']),
        "RPG-B01": pack_exists("rpg-battle-core")
        and has_all(manifest, ['"id": "rpg-battle-core"', '"rpg-core"', '"flow-core"', '"rules-events-core"']),
        "RPG-T01": pack_exists("rpg-test-kit") and has_all(manifest, ['"id": "rpg-test-kit"', '"rpg-core"', '"rpg-battle-core"']),
        "RPG-T05": has_all(combined, ["RPG-ready shell", "complete RPG template", "acceptance matrix"]),
    }

    missing = [task_id for task_id, passed in checks.items() if not passed]
    print(len(missing))
    print(json.dumps({"missing": missing, "passed": [k for k, v in checks.items() if v]}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
