# Mars Python Scaffold

A reusable harness for authoring **Mars challenges** (Python) on Project Olympus.
Build the environment once, then reuse it for every challenge by editing one
config file and dropping in two patches.

## Layout

```
mars-python-scaffold/
├── challenge.env            # the ONLY file you edit per challenge
├── Dockerfile               # clones repo @ commit, bakes deps, runs offline
├── test.sh                  # base/new modes -> JUnit XML (what the platform calls)
├── problem.md               # the spec template (problem checks 1-7)
├── patches/
│   ├── test.patch           # generated: test changes only
│   └── solution.patch       # generated: implementation only (100+ LOC)
├── repo/                    # (gitignored) the cloned target repo
└── scripts/
    ├── make_patches.sh      # split working tree -> test.patch + solution.patch
    ├── self_review.sh       # build + verify the 4 gates offline
    └── in_container_check.sh# runs inside the offline container
```

## Per-challenge workflow

> Full step-by-step runbook with the 21-check audit and token discipline:
> **[PER_CHALLENGE.md](PER_CHALLENGE.md)**. Quick version below.

```bash
# 1. Pick repo + commit, edit challenge.env (REPO_URL, COMMIT, TEST_PATHS, NEW_TESTS).
# 2. Clone locally to author against:
git clone <REPO_URL> repo && git -C repo checkout <COMMIT>

# 3. Write problem.md, then make test + solution changes inside ./repo.
# 4. Generate the two patches:
scripts/make_patches.sh

# 5. Verify all four Mars gates, offline, the way the platform does:
scripts/self_review.sh            # or: scripts/self_review.sh --runs 3

# 6. When green: confirm solution adds 100+ real LOC, then run the platform's
#    agent checks and aim for the 10-50% pass band before submitting.
```

`self_review.sh` enforces the four gates: `base` passes pre-solution, `new`
fails pre-solution, `base` still passes post-solution (no regressions), `new`
passes post-solution. Run it `--runs 3` to prove determinism before spending
platform tokens.

## The three target repos (all eligible: 500+ stars, permissive, pytest, pure-Python, deterministic)

### 1. sqlglot — `tobymao/sqlglot` (MIT, ~8.9k stars, no runtime deps)
SQL parser/transpiler across ~31 dialects. **Best Mars fit.** Dialect quirks
and transpilation edge cases are naturally 100+ LOC, behavior-focused, and hard
for agents (lots of corner cases), with a clean pytest suite and zero network.
`INSTALL_CMD='pip install -e ".[dev]"'`, tests in `tests/`.
- Task ideas: add/extend a function or data-type translation between two
  dialects; correct generation of a clause (e.g. `QUALIFY`, `PIVOT`, interval
  literals) for a dialect that currently mishandles it; round-trip parse->generate
  fidelity for a construct one dialect supports and another drops.

### 2. Pygments — `pygments/pygments` (BSD-2, active, extensive test suite)
Generic syntax highlighter. Deterministic input->token output, self-contained,
no network. Adding/fixing a lexer's tokenization of a language feature is real
~100+ LOC work with precise, assertable output.
`INSTALL_CMD='pip install -e .'`, tests in `tests/`.
- Task ideas: lexer fails to tokenize a real language construct (string prefix,
  numeric literal form, nested comment, new keyword); add example-based token
  assertions that pin exact `Token` streams.

### 3. Rich — `Textualize/rich` (MIT, active)
Terminal text formatting/rendering. Render output is deterministic and exactly
assertable (capture console output, compare segments). Self-contained, offline.
`INSTALL_CMD='pip install -e ".[dev]"'`, tests in `tests/`.
- Task ideas: a renderable mishandles an edge case (zero-width / wide unicode,
  padding interaction, justify + overflow combo, markup escaping); assert exact
  rendered segments/strings.

> Pick ONE as your home repo for the first submission so you amortize learning
> its conventions. sqlglot is the recommended starting point.

## Mars gates this scaffold helps you hit
- **Difficulty 10-50% pass:** specify more edge cases in `problem.md` to push pass
  rate down; describe *what* not *how* so you don't give the solution away.
- **Scope 100+ LOC median:** real implementation, no filler/dead code (rejected).
- **Determinism:** `PYTHONHASHSEED=0`, `-p no:cacheprovider`, no time/random/network;
  prove it with `--runs 3`.
- **Offline repro:** all deps baked at build; verification runs `--network none`.

## Notes
- Patches are NOT baked into the image — the platform applies them at runtime,
  so the image must build and run without them.
- Editing any submission content after checks marks them stale; fix everything
  in one pass before rerunning (checks cost tokens).
