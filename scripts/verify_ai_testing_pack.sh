#!/usr/bin/env bash
# Verify the ai-testing pack structure and run smoke tests.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACK_DIR="$REPO_ROOT/packs/ai-testing"

echo "=== Verifying ai-testing pack ==="

# 1. Directory structure
echo "[1/6] Checking directory structure..."
for d in \
    "$PACK_DIR/python/ai_testing" \
    "$PACK_DIR/godot/addons/godot_toolbox_architecture/ai_testing" \
    "$PACK_DIR/scripts" \
    "$PACK_DIR/examples/tests" \
    "$PACK_DIR/examples/environments"; do
    if [ ! -d "$d" ]; then
        echo "FAIL: Missing directory: $d"
        exit 1
    fi
done
echo "  OK: All directories present"

# 2. Python files exist
echo "[2/6] Checking Python module files..."
for f in \
    "$PACK_DIR/python/ai_testing/__init__.py" \
    "$PACK_DIR/python/ai_testing/contracts.py" \
    "$PACK_DIR/python/ai_testing/policies.py" \
    "$PACK_DIR/python/ai_testing/runner.py" \
    "$PACK_DIR/python/ai_testing/summary_report.py" \
    "$PACK_DIR/python/ai_testing/artifacts.py" \
    "$PACK_DIR/python/ai_testing/coverage_tracker.py" \
    "$PACK_DIR/python/ai_testing/bug_discovery.py" \
    "$PACK_DIR/python/ai_testing/scenario_variant.py" \
    "$PACK_DIR/python/ai_testing/godot_e2e_env.py" \
    "$PACK_DIR/python/requirements.txt"; do
    if [ ! -f "$f" ]; then
        echo "FAIL: Missing file: $f"
        exit 1
    fi
done
echo "  OK: All Python files present"

# 3. GDScript files exist
echo "[3/6] Checking GDScript files..."
for f in \
    "$PACK_DIR/godot/addons/godot_toolbox_architecture/ai_testing/ai_testing.gd" \
    "$PACK_DIR/godot/addons/godot_toolbox_architecture/ai_testing/interaction_test_helper.gd"; do
    if [ ! -f "$f" ]; then
        echo "FAIL: Missing file: $f"
        exit 1
    fi
done
echo "  OK: All GDScript files present"

# 4. Python syntax check
echo "[4/6] Checking Python syntax..."
python3 -m py_compile "$PACK_DIR/python/ai_testing/contracts.py" || { echo "FAIL: contracts.py"; exit 1; }
python3 -m py_compile "$PACK_DIR/python/ai_testing/policies.py" || { echo "FAIL: policies.py"; exit 1; }
python3 -m py_compile "$PACK_DIR/python/ai_testing/summary_report.py" || { echo "FAIL: summary_report.py"; exit 1; }
python3 -m py_compile "$PACK_DIR/python/ai_testing/artifacts.py" || { echo "FAIL: artifacts.py"; exit 1; }
python3 -m py_compile "$PACK_DIR/python/ai_testing/coverage_tracker.py" || { echo "FAIL: coverage_tracker.py"; exit 1; }
python3 -m py_compile "$PACK_DIR/python/ai_testing/bug_discovery.py" || { echo "FAIL: bug_discovery.py"; exit 1; }
python3 -m py_compile "$PACK_DIR/python/ai_testing/scenario_variant.py" || { echo "FAIL: scenario_variant.py"; exit 1; }
python3 -m py_compile "$PACK_DIR/python/ai_testing/godot_e2e_env.py" || { echo "FAIL: godot_e2e_env.py"; exit 1; }
python3 -m py_compile "$PACK_DIR/python/ai_testing/runner.py" || { echo "FAIL: runner.py"; exit 1; }
python3 -m py_compile "$PACK_DIR/python/ai_testing/__init__.py" || { echo "FAIL: __init__.py"; exit 1; }
echo "  OK: All Python files pass syntax check"

# 5. GDScript lint/format (if gdtoolkit available)
echo "[5/6] Checking GDScript lint/format..."
if command -v gdlint &>/dev/null && command -v gdformat &>/dev/null; then
    lint_failed=0
    gdlint "$PACK_DIR/godot/addons/godot_toolbox_architecture/ai_testing/ai_testing.gd" || lint_failed=1
    gdlint "$PACK_DIR/godot/addons/godot_toolbox_architecture/ai_testing/interaction_test_helper.gd" || lint_failed=1
    if [ "$lint_failed" -ne 0 ]; then
        echo "FAIL: GDScript lint errors detected"
        exit 1
    fi
    fmt_failed=0
    gdformat --check "$PACK_DIR/godot/addons/godot_toolbox_architecture/ai_testing/ai_testing.gd" || fmt_failed=1
    gdformat --check "$PACK_DIR/godot/addons/godot_toolbox_architecture/ai_testing/interaction_test_helper.gd" || fmt_failed=1
    if [ "$fmt_failed" -ne 0 ]; then
        echo "FAIL: GDScript format errors detected"
        exit 1
    fi
    echo "  OK: GDScript lint/format checked"
else
    echo "  SKIP: gdtoolkit not available"
fi

# 6. Framework smoke test (Python-only)
echo "[6/6] Running framework smoke tests..."
PYTHONPATH="$PACK_DIR/python:${PYTHONPATH:-}" python3 -m pytest \
    "$PACK_DIR/examples/tests/test_ai_testing_framework_smoke.py" \
    -v --tb=short || { echo "FAIL: Smoke tests failed"; exit 1; }

echo ""
echo "=== ai-testing pack verification PASSED ==="
