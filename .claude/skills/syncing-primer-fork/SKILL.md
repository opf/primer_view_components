---
name: syncing-primer-fork
description: Use when syncing this OpenProject fork with its upstream Primer repo (primer/view_components or primer/octicons) — pulling new components, merging upstream changes, resolving dependency/lockfile conflicts, or running script/merge-upstream.
---

# Syncing a Primer Fork from Upstream

## Overview

The `@openproject/*` repos (view_components, octicons) are forks of `primer/*`.
Syncing means merging upstream changes onto a `bump/primer-upstream` branch via
`script/merge-upstream`, **one upstream release batch at a time**, stopping just
before each version-bump commit, then resolving dependency conflicts per package
manager.

**Core principle:** Sync the *oldest* unmerged release batch first. Merge the
*parent* of the oldest unmerged version-bump commit whose parent isn't already
in `main` — never a version-bump commit itself, and never skip ahead to the
latest one.

**Why the oldest, not the latest:** a version-bump commit (changesets bot)
*deletes* the `.changeset/*.md` files it consumes. If you jump to the parent of
the *latest* version-bump, every intervening version-bump in that range has
already deleted its changesets — so the fork loses them and can't regenerate
those changelog entries with its own `changeset:version`. Stopping before the
*oldest* unmerged version-bump keeps that batch's changesets intact. Repeat per
batch.

## One-time prerequisite: register the `ours` merge driver

`.gitattributes` marks `CHANGELOG.md`, `Gemfile.lock`, `demo/Gemfile.lock`, and
`lib/primer/view_components/version.rb` with `merge=ours`, but that driver is
**inert unless registered in git config**. Without it those files conflict like
any other. Run once per clone (or set `--global`):

```bash
git config merge.ours.driver true
```

Verify: `git config merge.ours.driver` prints `true`.

## Procedure

### 1. Pick the SHA — parent of the *oldest* unmerged version-bump commit

Walk the unmerged version-bump commits oldest-first and merge the parent of the
first one whose parent isn't already in `main`. (`main` usually sits exactly at
the previous batch's boundary, i.e. the parent of the *oldest* unmerged
version-bump — that's a no-op, so skip it and take the next.)

- view_components: version-bump commits are titled **`Release Tracking`**
- octicons: titled **`Version Packages`**

The `--grep` below is case-insensitive (`-i`): upstream has used both
`Release Tracking` and `Release tracking` casings over time.

```bash
git fetch upstream
GREP="Release Tracking"   # octicons: "Version Packages"
for vp in $(git log upstream/main -i --grep="$GREP" --not main --reverse --format=%H); do
  parent=$(git rev-parse "$vp^")
  git merge-base --is-ancestor "$parent" main && continue   # parent already merged → skip
  echo "TARGET: $parent  ($(git log -1 --format='%h %s' "$vp")'s parent)"
  break
done
```

That `TARGET` SHA is what you pass to the script. Each run advances one batch;
re-run after the fork has versioned/released the previous batch.

### 2. Run the merge script

```bash
script/merge-upstream <TARGET> gsed   # the SHA from step 1
```

On macOS pass `gsed` as the 2nd arg (the script auto-detects, but be explicit).
The script: fetches upstream, builds `bump/primer-upstream-ref` (reset to the
SHA) and `bump/primer-upstream` (from `origin/main`), merges with `--no-commit`,
rescopes `@primer/view-components` → `@openproject/primer-view-components` in
`.changeset/*.md`, then runs `script/setup`, stages, and stops at an interactive
`git commit`.

**The merge step is conflict-tolerant (`|| true`), but the later `script/setup` is
not.** `script/setup` runs `bundle install` and `npm install`; when a `Gemfile`,
`*.gemspec`, or `package.json` conflicts (almost always — fork scope/version vs
upstream), the conflict markers make those installs fail → `set -e` aborts the
script *before* stage/commit. That's expected: the changeset rescope has already
run, and you're left mid-merge. **Resolve conflicts (step 3) first, then run
`script/setup` yourself**, then stage and commit.

### 3. Resolve conflicts by package manager

With the `ours` driver registered (see prerequisite), `.gitattributes` resolves
`CHANGELOG.md`, `Gemfile.lock`, `demo/Gemfile.lock`, and the gem `version.rb`
automatically (fork wins). For the rest:

| Conflict in | Manager | Fix |
|---|---|---|
| `Gemfile` / `*.gemspec` | **bundler** | Resolve the manifest, then `bundle install` (root and in `demo/`) to bring the `Gemfile.lock`s in sync. `bundle install` does **not** resolve conflict markers in a `Gemfile.lock` itself — those are handled by `merge=ours`; if any ever appear (driver not registered), `git checkout --ours <Gemfile.lock>` first, then `bundle install`. |
| `package.json` (root or `demo/`) | **npm** | Resolve `package.json`, then `npm install` in that dir to regenerate `package-lock.json` |
| component source, `.changeset/*.md`, `previews/`, docs | — | Resolve normally; keep upstream's new components |

`script/setup` does both (`bundle install` + `npm install`, root and `demo/`, then
`rake docs:build`), so once conflicts are resolved a single `script/setup` refreshes
every lockfile and the generated docs. The mirror repo (octicons) instead uses
yarn at the root plus npm for `octicons_angular`.

After resolving, re-stage and run setup:

```bash
git add -A
script/setup             # regenerates lockfiles + docs from the merged sources
```

Then regenerate generated files **from a clean tree** and fold in the fork's
own fixes *before* committing (see 3a), so the sync lands as one
self-contained merge commit — not a merge followed by `cherry-pick` /
CI-autocommit cleanup commits.

### 3a. Regenerate static/generated files from a *clean* tree

`script/export-css-selectors` (invoked by `script/setup` → `npm install` →
the `prepare` build) scans the **compiled** `app/components/**/*.css` —
gitignored build artifacts, not the `.pcss` sources. Stale compiled CSS left
in the working tree from an *earlier branch* — a component not in this batch,
e.g. a fork-only `Primer::OpenProject::DataTable` — is picked up and injected
into `static/classes.json` and `static/classnames.{js,cjs,d.ts}`. Wipe
artifacts before regenerating:

```bash
git clean -fdx -- app/          # remove stale compiled .css/.js/.d.ts/.map
script/build-assets             # recompile CSS/JS from the merged sources
bundle exec rake utilities:build docs:build static:dump
```

Then confirm nothing phantom leaked — for a batch that does **not** add
DataTable, this must be empty:

```bash
git grep -i "OpenProject::DataTable" -- static/ && echo "POLLUTED — reclean and rebuild"
```

The `static-files` CI job only regenerates and commits `static/*.json` (plus
`utilities.yml`) — **not** `static/classnames.{js,cjs,d.ts}`. Those must be
correct *in the merge commit itself*; a dirty-tree pollution there is never
auto-corrected downstream. Finally stage and finish the merge:

```bash
git add -A
git commit          # finishes the deferred merge commit
```

### 4. Audit dependency bumps dropped by `merge=ours`

Because `Gemfile.lock` is `merge=ours`, any upstream bump made by `bundle update
<gem>` **alone** — no `Gemfile` change, the common shape for Dependabot patch and
transitive bumps like `nokogiri` or `rubocop` — is discarded on merge. The fork
silently stays on the old locked version. `package-lock.json` is *not* `merge=ours`
(it 3-way merges), but `npm install` re-resolving to the fork's manifest ranges can
still lock a **lower** version than upstream had — the same "missing bump" failure.

The fork's own weekly Dependabot (`.github/dependabot.yml`) re-applies most of these
eventually, but it's cooldown-gated and its grouping/ignore rules don't mirror
upstream's — so security bumps shouldn't wait for it. After the merge, before you
commit, list what upstream locked that the fork didn't pick up:

```bash
# gems: '+' side is upstream's TARGET, '-' is the fork's merged result
git diff bump/primer-upstream..<TARGET> -- Gemfile.lock demo/Gemfile.lock
# npm (noisier — scan the "version" lines for shared packages)
git diff bump/primer-upstream..<TARGET> -- package-lock.json demo/package-lock.json
```

For each bump worth replaying now — **security first** — re-apply it within the
fork's constraints, then re-stage:

```bash
bundle update <gem> --conservative       # root; add BUNDLE_GEMFILE=demo/Gemfile for demo
npm install <pkg>@<version>              # run in the dir that owns the lockfile
```

`--conservative` limits the change to that one gem instead of dragging in unrelated
transitive bumps. If the fork's `Gemfile` constraint *forbids* upstream's version,
that's a manifest bump (resolve in step 3), not a lockfile-only replay — leave it to
the fork's Dependabot. Leave everything non-urgent to the weekly Dependabot cycle.
These are dependency bumps, so no changeset (matches the `skip changeset` label the
fork's Dependabot uses).

### 5. Push and open a PR — reference the released upstream *version*, not a PR number

The merge commit's identity is the upstream *release* it lands on, not any single
upstream PR merged along the way (a batch often bundles several). Title and
body must key off that version — never an upstream PR/issue number standing in
for "which sync this is."

Read the version off **`CHANGELOG.md` at `<TARGET>`** (its top `## X.Y.Z`
heading — the changeset-driven changelog upstream commits alongside the code,
so it's already sitting at the version TARGET belongs to, no separate version
file path to know per-repo):

```bash
git show <TARGET>:CHANGELOG.md | head -5   # top heading = the version this batch releases as
```

Push and open the PR:

```bash
git push -u origin bump/primer-upstream
gh pr create --title "Sync Primer view_components upstream through vX.Y.Z" --body "..."
```

(octicons: same shape, `Sync Primer octicons upstream through vX.Y.Z`.)

Body: prefix with 🤖 (posting under the user's identity — see global git
posting rules), state the merge target SHA, list the upstream PRs *folded
into* this version bump (that's where individual `#NNNN` references belong —
describing what changed, not naming the sync), and call out anything
hand-folded into the merge commit (tsconfig widen, dependency replays, etc.)
per step 4 and the Common Mistakes below.

## Quick Reference

```bash
git fetch upstream
# TARGET = parent of the OLDEST unmerged version-bump whose parent isn't in main:
for vp in $(git log upstream/main -i --grep="Release Tracking" --not main --reverse --format=%H); do
  p=$(git rev-parse "$vp^"); git merge-base --is-ancestor "$p" main && continue; echo "$p"; break
done
script/merge-upstream <TARGET> gsed
# resolve conflicts: Gemfile→bundle install, package.json→npm install, others normal
# audit dropped bumps (merge=ours discards upstream Gemfile.lock-only bumps):
git diff bump/primer-upstream..<TARGET> -- Gemfile.lock demo/Gemfile.lock
script/setup && git add -A && git commit
```

## Common Mistakes

- **Jumping to the parent of the *latest* version-bump.** That drags in every
  intervening version-bump, which already deleted its changesets — the fork loses
  them. Sync the *oldest* unmerged batch first (see Core principle).
- **Merging a version-bump commit itself** (e.g. `Release Tracking`) instead of
  its parent — pulls upstream's bump and conflicts with the fork's `changeset:version`.
- **Assuming the changeset rename worked.** Upstream changesets use *single*
  quotes (`'@primer/view-components'`); a double-quote-only sed silently no-ops.
  The script matches either quote (and a trailing `[^-]` guards any
  `@primer/view-components-*` sibling). Verify after: no `@primer/view-components'`
  or `@primer/view-components"` remains in `.changeset/`.
- **Forgetting `gsed` on macOS.** BSD `sed -i` needs a backup-suffix arg; the
  changeset rename silently misbehaves without a GNU-compatible sed.
- **Trusting hand-merged / rerere-resolved YAML by eye.** Merges in `.github/*.yml`
  (workflows, `dependabot.yml`) easily produce subtly broken YAML — wrong list-item
  indentation, a key dropped to the wrong level, duplicate keys, a mapping/sequence
  mismatch. `rerere` can also replay a resolution from a *different* merge context
  and reintroduce upstream's quirks (e.g. list items flush with their key). Always
  re-validate after resolving: `ruby -ryaml -e 'YAML.load_file(ARGV[0])' <file>`
  (or `yq` / `python3 -c`), and confirm the *structure* parsed as intended — that a
  list is a list and sibling keys sit at the right depth, not just that it loads.
- **Assuming rerere makes the sync reproducible.** `rerere.enabled` is usually set
  *globally* (`~/.gitconfig`), and `.git/rr-cache` is **per-clone and never
  committed** — so the same upstream batch resolves *differently* for different
  people, and every replay lands silently in the working tree (all files, not just
  YAML; with `rerere.autoupdate` it's even auto-staged). Diff every rerere-touched
  hunk before staging; if a replayed resolution looks stale, `git rerere forget
  <path>` and resolve it by hand.
- **Losing the fork's widened `tsconfig.json` `include`.** Upstream's
  `tsconfig.json` matches only *top-level* component TS
  (`app/components/primer/*.ts`); the fork widens it to `**/*.ts` (recursive,
  plus `**/*.d.ts` in `exclude`) so nested components (`alpha/`, `beta/`,
  `open_project/`) are covered. A sync that takes upstream's `tsconfig.json`
  silently reverts this. Under Vite 8/rolldown the demo build then transforms
  the un-matched nested TS **without** `experimentalDecorators`, so Catalyst
  `@controller(...)` reaches terser un-downleveled →
  `RolldownError: Unexpected character '@'` → demo build dies → **every** chrome
  system test fails (no JS assets, nothing renders). It's a silent revert, not a
  conflict, so nothing flags it. After each sync, verify:
  ```bash
  grep -A3 '"include"' tsconfig.json   # must list app/components/primer/**/*.ts (recursive); exclude must list **/*.d.ts
  ```
  If reverted, re-apply the widen (from `ba86b76eb`, PR #409 / WP 590) **in the
  working tree before finishing the merge commit** — edit `tsconfig.json` and
  `git add` it into the deferred merge, don't `cherry-pick` it as a *trailing*
  commit. The sync should be one self-contained merge commit.
- **Polluting `static/` by regenerating on a dirty tree.**
  `script/export-css-selectors` reads the *compiled* `app/components/**/*.css`
  (gitignored build artifacts), so stale CSS from a previous branch — a
  component not in this batch, e.g. a fork-only `DataTable` — leaks phantom
  classes into `static/classes.json` and `static/classnames.{js,cjs,d.ts}`.
  Symptom: the merge adds class entries for components absent from `main`, and
  the `static-files` CI job auto-commits their removal from `static/*.json`
  afterwards (but never fixes `classnames.*`, which CI doesn't regenerate).
  Always `git clean -fdx -- app/` before rebuilding (see 3a), and grep
  `static/` for any component name that isn't in this batch.
- **Inventing a release flow, or titling the PR after an upstream PR number.**
  The job ends at pushing `bump/primer-upstream` and opening one PR against
  `main` (step 5) — actually cutting the fork's own release afterward is a
  separate changeset-driven process, not part of this skill. And when opening
  that PR: title/reference the released upstream *version* (`CHANGELOG.md` at
  `<TARGET>`), never a `#NNNN` upstream PR/issue number — a batch usually
  bundles several upstream PRs, so no single one identifies "this sync."

## Keeping the two forks aligned

This skill and `script/merge-upstream` are mirrored between view_components and
octicons. When you change one, port the change to the other. The repo
differences to account for:

- **Commit-title grep term:** `Release Tracking` (view_components) vs
  `Version Packages` (octicons).
- **Package managers / lockfiles:** view_components uses Ruby Bundler
  (`Gemfile.lock`, `demo/Gemfile.lock`) plus npm (`package-lock.json`,
  `demo/package-lock.json`), driven by `script/setup`; octicons uses yarn at the root
  plus npm for `octicons_angular`.
- **npm scope:** `@primer/view-components` → `@openproject/primer-view-components`
  (octicons: `@primer/octicons` → `@openproject/octicons`).
