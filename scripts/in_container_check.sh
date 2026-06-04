#!/usr/bin/env bash
# ==========================================================================
# Runs INSIDE the container (mounted at /work) with --network none.
# Verifies the four Mars gate conditions against the baked repo at /app/repo.
# Invoked by scripts/self_review.sh — you normally don't run this by hand.
# ==========================================================================
set -uo pipefail

REPO=/app/repo
PATCHES=/work/patches
TESTSH=/app/test.sh

cd "$REPO"
git checkout -q -- . 2>/dev/null || true
git clean -fdq 2>/dev/null || true

run() { "$TESTSH" --output_path "$1" "$2" >/tmp/log 2>&1; return $?; }

echo "== apply test.patch =="
git apply --check "$PATCHES/test.patch" 2>/tmp/log \
  && git apply "$PATCHES/test.patch" \
  || { echo "FAIL: test.patch does not apply cleanly"; cat /tmp/log; exit 1; }

run /tmp/base.xml base;      BASE_RC=$?        # expect 0  (existing tests pass)
run /tmp/new_before.xml new; NEW_BEFORE_RC=$?  # expect !0 (new tests fail pre-solution)

echo "== apply solution.patch =="
git apply --check "$PATCHES/solution.patch" 2>/tmp/log \
  && git apply "$PATCHES/solution.patch" \
  || { echo "FAIL: solution.patch does not apply (conflicts with test.patch?)"; cat /tmp/log; exit 1; }

run /tmp/base2.xml base;     BASE2_RC=$?       # expect 0  (no regressions)
run /tmp/new_after.xml new;  NEW_AFTER_RC=$?   # expect 0  (new tests pass)

echo
echo "================ Mars gate check ================"
ok() { [[ "$1" == "$2" ]] && echo "PASS" || echo "FAIL"; }
neq() { [[ "$1" != "0" ]] && echo "PASS" || echo "FAIL"; }

printf "  base passes pre-solution .......... %s (rc=%s)\n"  "$(ok "$BASE_RC" 0)"       "$BASE_RC"
printf "  new FAILS pre-solution ............ %s (rc=%s)\n"  "$(neq "$NEW_BEFORE_RC")"  "$NEW_BEFORE_RC"
printf "  base passes post-solution ......... %s (rc=%s)\n"  "$(ok "$BASE2_RC" 0)"      "$BASE2_RC"
printf "  new passes post-solution .......... %s (rc=%s)\n"  "$(ok "$NEW_AFTER_RC" 0)"  "$NEW_AFTER_RC"
echo "================================================="

if [[ "$BASE_RC" == 0 && "$NEW_BEFORE_RC" != 0 && "$BASE2_RC" == 0 && "$NEW_AFTER_RC" == 0 ]]; then
  echo "ALL GATES PASS"
  exit 0
fi
echo "ONE OR MORE GATES FAILED — see logs above"
exit 1
