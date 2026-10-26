# Contributing

`main` is protected. Nothing lands on it except through a pull request — that includes the
owner, and it includes automated agents working in this repository.

## The flow

```sh
git checkout main && git pull
git checkout -b fix/short-description        # or feat/, docs/, chore/
# ... work, then run the checks ...
tools/test.sh
git commit -am "what changed and why"
git push -u origin fix/short-description
gh pr create --fill                          # then merge it when you are happy
```

A pull request needs:

- a branch that is up to date with `main` (no merge commits required, but no force-push),
- a green `tools/test.sh`,
- every review thread resolved.

Zero approving reviews are required, because GitHub does not let an author approve their own
pull request and this is a single-maintainer repository. The gate is the pull request itself:
nothing reaches `main` any other way. Force-pushes and branch deletion are refused.

## What the checks are

```sh
tools/test.sh      # luac -p over every file, then the headless suite
tools/build.sh     # game/ -> clickeragents.love -> port/ -> ClickerAgents.zip
```

The headless suite is the contract: it draws every screen at six sizes, asserts the formulas
and the pacing numbers, round-trips the save, and fails if the gptk and the game disagree
about a button. If a change moves a balance number, the acceptance assertions in
`tests/headless.lua` have to move with it — deliberately, in the same pull request.

## Releases

Tag and release only from a merged `main`, following the convention in
[`docs/PORTING.md`](docs/PORTING.md#releasing): tag `v<major>.<minor>.<patch>`, title
`Clicker Agents v<version>`, the zip attached as `ClickerAgents.zip`.

## Style

- One file per screen, one concern per module; nothing over ~300 lines if it can be helped.
- `sim/` never calls `love.*` — that is what keeps it testable without a window.
- Balance lives in `game/tuning.lua`. Content lives in `game/data/`. Code reads them, never
  the other way round.
- No comments that repeat the code. A comment earns its place by saying why.
