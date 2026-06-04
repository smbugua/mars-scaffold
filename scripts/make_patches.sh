#!/usr/bin/env bash
# ==========================================================================
# Generate test.patch and solution.patch from your working changes in ./repo.
#
# Workflow:
#   1. git clone the target repo into ./repo and `git checkout <COMMIT>`.
#   2. Make BOTH your test changes and your solution changes in ./repo.
#   3. Run this script. It splits the working tree by TEST_PATHS:
#         test.patch     = changes under TEST_PATHS  (tests only)
#         solution.patch = everything else           (implementation only)
# ==========================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/challenge.env"

cd "$ROOT/repo"

# Intent-to-add untracked files so new test files appear in `git diff`.
git add -N . >/dev/null 2>&1 || true

read -ra TP <<< "$TEST_PATHS"
EXCLUDES=()
for p in "${TP[@]}"; do EXCLUDES+=(":(exclude)$p"); done

mkdir -p "$ROOT/patches"
git diff --binary -- "${TP[@]}"            > "$ROOT/patches/test.patch"
git diff --binary -- . "${EXCLUDES[@]}"    > "$ROOT/patches/solution.patch"

echo "Wrote:"
echo "  patches/test.patch     ($(wc -l < "$ROOT/patches/test.patch") lines)"
echo "  patches/solution.patch ($(wc -l < "$ROOT/patches/solution.patch") lines)"
echo
echo "Reminder: solution.patch should add 100+ real LOC (Mars scope floor)."
echo "Next: run scripts/self_review.sh to verify both patches in Docker."
