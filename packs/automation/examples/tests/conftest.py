from __future__ import annotations

import os

import pytest


def _require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"required environment variable is missing: {name}")
    return value


@pytest.fixture(scope="module")
def game():
    from godot_e2e import GodotE2E

    project_path = _require_env("GODOT_E2E_PROJECT_PATH")
    godot_path = os.environ.get("GODOT_PATH", "").strip() or None

    with GodotE2E.launch(project_path, godot_path=godot_path, timeout=30.0) as client:
        client.wait_for_node("/root/Main", timeout=10.0)
        yield client
