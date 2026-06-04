#!/usr/bin/env bash
# ==========================================================================
# test.sh — the harness the Mars platform invokes.
#
#   ./test.sh --output_path results.xml base   # existing tests, MUST pass
#   ./test.sh --output_path results.xml new    # new tests, MUST fail w/o solution
#
# Writes JUnit XML to the path given by --output_path. No network needed.
# ==========================================================================
set -euo pipefail

SELF="$(cd "$(dirname "$0")" && pwd)"
# Load per-challenge config if it sits next to this script (it does in the image).
[[ -f "$SELF/challenge.env" ]] && source "$SELF/challenge.env"

REPO_DIR="${TEST_REPO_DIR:-$SELF/repo}"   # /app/repo in the container
NEW_TESTS="${NEW_TESTS:-tests/}"
BASE_TESTS="${BASE_TESTS:-tests/}"
PYTEST_ARGS="${PYTEST_ARGS:-}"

OUTPUT_PATH=""
MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output_path) OUTPUT_PATH="$2"; shift 2 ;;
    --output_path=*) OUTPUT_PATH="${1#*=}"; shift ;;
    base|new) MODE="$1"; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -z "$MODE" ]] && { echo "Usage: test.sh --output_path <path> <base|new>" >&2; exit 2; }
[[ -z "$OUTPUT_PATH" ]] && { echo "Error: --output_path is required" >&2; exit 2; }

# Determinism guards: fixed hash seed, no .pyc churn, stable locale.
export PYTHONHASHSEED="${PYTHONHASHSEED:-0}"
export PYTHONDONTWRITEBYTECODE=1
export LC_ALL="${LC_ALL:-C.UTF-8}"

cd "$REPO_DIR"

case "$MODE" in
  base) SELECTION="$BASE_TESTS" ;;
  new)  SELECTION="$NEW_TESTS"  ;;
esac

# shellcheck disable=SC2086
exec python -m pytest $PYTEST_ARGS --junitxml="$OUTPUT_PATH" $SELECTION
