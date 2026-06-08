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

- view_components: version-bump commits are titled **`Release tracking`**
- octicons: titled **`Version Packages`**

```bash
git fetch upstream
GREP="Release tracking"   # octicons: "Version Packages"
for vp in $(git log upstream/main --grep="$GREP" --not main --reverse --format=%H); do
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

After resolving, re-stage, run setup, and commit:

```bash
git add -A
script/setup             # regenerates lockfiles + docs from the merged sources
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

## Quick Reference

```bash
git fetch upstream
# TARGET = parent of the OLDEST unmerged version-bump whose parent isn't in main:
for vp in $(git log upstream/main --grep="Release tracking" --not main --reverse --format=%H); do
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
- **Merging a version-bump commit itself** (e.g. `Release tracking`) instead of
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
- **Inventing a PR/release flow.** The job ends at the local merge commit on
  `bump/primer-upstream`; release is a separate changeset-driven process.

## Keeping the two forks aligned

This skill and `script/merge-upstream` are mirrored between view_components and
octicons. When you change one, port the change to the other. The repo
differences to account for:

- **Commit-title grep term:** `Release tracking` (view_components) vs
  `Version Packages` (octicons).
- **Package managers / lockfiles:** view_components uses Ruby Bundler
  (`Gemfile.lock`, `demo/Gemfile.lock`) plus npm (`package-lock.json`,
  `demo/package-lock.json`), driven by `script/setup`; octicons uses yarn at the root
  plus npm for `octicons_angular`.
- **npm scope:** `@primer/view-components` → `@openproject/primer-view-components`
  (octicons: `@primer/octicons` → `@openproject/octicons`).
