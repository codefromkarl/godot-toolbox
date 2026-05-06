#!/usr/bin/env bash
# Run AI testing framework smoke tests (Python-only, no Godot required).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(dirname "$SCRIPT_DIR")"
PYTHON_DIR="$PACK_ROOT/python"

echo "[ai-testing] Running framework smoke tests..."

# Ensure the package is importable
PYTHONPATH="$PYTHON_DIR:$PYTHONPATH" python3 -m pytest \
    "$PACK_ROOT/examples/tests/test_ai_testing_framework_smoke.py" \
    -v \
    --tb=short \
    "$@"

echo "[ai-testing] Smoke tests passed."
