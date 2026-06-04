# Per-Challenge Runbook

Do these steps in order for every Mars challenge. Order matters: the cheap,
reversible work (picking, writing, local verification) comes before the
expensive, token-costing platform checks. Fix everything in one pass before you
rerun platform checks — editing after a check marks it stale and costs tokens again.

---

## Phase 0 — Pick the task (cheapest to get wrong, do it carefully)

1. Choose your home repo + an **immutable commit hash** (not a branch/tag).
   Put both in `challenge.env` (`REPO_URL`, `COMMIT`).
2. Pick a task that is:
   - **Unbuilt** — not already done in any open or merged PR. Verify:
     `git log --oneline | grep -i <keyword>` and search the repo's PRs/issues.
   - **In-scope** — a realistic issue that fits the project's design philosophy.
   - **100+ LOC of real work** — its natural solution touches enough surface.
     Rename/comment/one-liner tasks do not qualify.
   - **Behavior-testable offline** — no network, time, or randomness needed.
3. Write a one-paragraph hypothesis of *why agents will fail it 10-50% of the
   time* (ambiguity-free but genuinely hard). If you can't, pick a harder variant.

## Phase 1 — Set up the working copy

```bash
git clone <REPO_URL> repo && git -C repo checkout <COMMIT>
```

Confirm the existing suite runs at all:
`TEST_REPO_DIR=repo ./test.sh --output_path /tmp/x.xml base` (should pass).

## Phase 2 — Write the problem (problem.md → checks 1-7)

Fill `problem.md`. Then self-audit against the 7 problem checks:
- [ ] 1. Self-contained — solvable from description + repo alone.
- [ ] 2. No ambiguity — exactly one correct interpretation.
- [ ] 3. Describes **what, not how** — don't name the algorithm or the fix site.
- [ ] 4. Matches real repo scope.
- [ ] 5. Aligns with repo design philosophy.
- [ ] 6. No irrelevant background narrative.
- [ ] 7. Structured: Goal / Expected Behavior / Constraints.

> Difficulty dial: each edge case you specify in Expected Behavior lowers the
> agent pass rate. Add cases to push out of the "too easy" zone, but keep every
> one unambiguous.

## Phase 3 — Write the tests FIRST (→ checks 8-15)

Write tests in the repo that **fail on the base commit**. Put them under the
path you set in `TEST_PATHS` / `NEW_TESTS`.
- [ ] 8. Fail on base, pass after correct solution.
- [ ] 9. Deterministic — no timing, randomness, ordering, or network.
- [ ] 10. Assert **precise** expected output, not `len > 0`.
- [ ] 11. Validate behavior via public APIs / observable output, not internals.
- [ ] 12. Follow repo conventions — naming, folder, framework.
- [ ] 13. Cover success **and** failure/edge paths.
- [ ] 14. Concise — focused, non-redundant.
- [ ] 15. Only test behavior the problem spec describes.

## Phase 4 — Write the reference solution (→ checks 16-21)

Implement until `NEW_TESTS` pass and the existing suite stays green.
- [ ] 16. Every specified behavior implemented.
- [ ] 17. No regressions; idiomatic, consistent with the codebase.
- [ ] 18. No speculative guards / unnecessary error handling.
- [ ] 19. Diff contains only task-related changes (no drive-by refactors/formatting).
- [ ] 20. Public APIs unchanged unless the spec requires it.
- [ ] 21. No AI slop — clean, intentional, not over-commented boilerplate.
- [ ] **Scope:** adds **100+ real LOC** (no blank-line/dead-code padding).

## Phase 5 — Generate patches

```bash
scripts/make_patches.sh
```
Produces `patches/test.patch` (tests only) and `patches/solution.patch`
(implementation only). They must not conflict and each must apply to base.

## Phase 6 — Local self-review (offline, free, repeat until clean)

```bash
scripts/self_review.sh --runs 3
```
This builds the image and verifies the four gates with `--network none`, three
times to prove determinism:
- base passes pre-solution
- new **fails** pre-solution
- base passes post-solution (no regressions)
- new passes post-solution

Do **not** proceed until all gates pass on all 3 runs. A test that passes 9/10
times will be rejected.

## Phase 7 — Platform checks (this costs tokens — go in clean)

1. Run the platform's agent checks (10 runs).
2. Read the **pass rate**:
   - `> 50%` → too easy. Add an edge case to the spec + a test, re-solve, redo
     Phases 5-6, then rerun. (Batch all edits first — don't drip-feed.)
   - `< 10%` / unsolvable → usually missing context or hidden ambiguity, not
     genuine hardness. Clarify the spec; only tighten difficulty if it's real.
   - `10-50%` → in band. Proceed.
3. Confirm the other Mars criteria: cheat rate below threshold, no environment
   blockers, no fairness flag, and successful runs meet scope (1+ file, 1+ agent
   message, 100+ LOC median).

## Phase 8 — Submit

- [ ] No existing PR solves this issue.
- [ ] Inspect both diffs one last time in source control.
- [ ] At least one agent solved it (solvability cannot be bypassed).
- [ ] Submit. Only bypass a failing check with a written reason if you genuinely
      believe it is unfair — legitimate failures come back in review.

Target: quality score **5+/7** across the three rubric groups
(Problem 1-7, Tests 8-15, Solution 16-21). Review ETA ~12h, pays $50-100.

---

## Token discipline (don't burn your balance)
- All of Phases 0-6 are free and offline. Get the challenge fully green locally
  before spending a single platform check.
- Editing **any** submission content after a check marks results stale.
  Make every fix in one pass, then rerun once.
