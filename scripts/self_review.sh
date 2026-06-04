#!/usr/bin/env bash
# ==========================================================================
# Full local self-review: build the image, then verify the patches with the
# container offline (--network none) — exactly how the platform evaluates.
#
#   scripts/self_review.sh           # build + verify once
#   scripts/self_review.sh --runs 3  # verify 3x to confirm determinism
# ==========================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/challenge.env"

RUNS=1
[[ "${1:-}" == "--runs" ]] && RUNS="$2"

for f in patches/test.patch patches/solution.patch; do
  [[ -s "$ROOT/$f" ]] || { echo "Missing/empty $f — run scripts/make_patches.sh first"; exit 1; }
done
[[ "$COMMIT" == REPLACE_* ]] && { echo "Set COMMIT in challenge.env first"; exit 1; }

echo ">> Building image $IMAGE (network on, build phase only)"
docker build -t "$IMAGE" \
  --build-arg REPO_URL="$REPO_URL" \
  --build-arg COMMIT="$COMMIT" \
  --build-arg INSTALL_CMD="$INSTALL_CMD" \
  "$ROOT"

FAILED=0
for i in $(seq 1 "$RUNS"); do
  echo
  echo ">> Verification run $i/$RUNS (--network none)"
  docker run --rm --network none \
    -v "$ROOT:/work:ro" \
    "$IMAGE" bash /work/scripts/in_container_check.sh || FAILED=1
done

echo
if [[ "$FAILED" == 0 ]]; then
  echo "SELF-REVIEW PASSED across $RUNS run(s)."
  echo "Next: confirm solution scope (100+ LOC), then run the platform's agent checks."
else
  echo "SELF-REVIEW FAILED — fix issues in ONE pass before rerunning (checks cost tokens)."
  exit 1
fi
