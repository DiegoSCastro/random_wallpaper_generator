# PR Workflow

> Effective 2026-06-11 — features and fixes go through PRs to preserve a clean history.

## Rule of thumb

> **No direct push to `main`.** Every change — feature, fix, refactor, or docs — lands via a
> pull request that gets merged into `main`.

## Why

- **Traceability** — every change has a title, description, and reviewer trail.
- **Bisectability** — when something breaks, `git log` and `git bisect` stay meaningful.
- **Review surface** — even solo, the diff-on-PR habit catches things you miss in your editor.
- **CI hooks** — once we add status checks, PRs are the natural place to gate them.

## Day-to-day flow

```bash
# 1. Branch off main
git checkout main
git pull --ff-only
git checkout -b feat/short-descriptive-name

# 2. Work in small commits (Conventional Commits preferred)
#    feat: …, fix: …, refactor: …, chore: …, docs: …, test: …

# 3. Push the branch
git push -u origin feat/short-descriptive-name

# 4. Open the PR
gh pr create --base main \
  --title "feat(home): short imperative summary" \
  --body "## Why\n…\n\n## What\n…\n\n## Test plan\n- [ ] flutter analyze
- [ ] flutter test"

# 5. Self-review the diff on GitHub, then merge (squash is fine for solo work)
gh pr merge --squash --delete-branch
```

## Kanban workers

`hermes kanban` workers **may still push to their own branch** to land their work — that's
fine. The **merge into `main` must still go through a PR**:

1. Worker pushes its branch: `kanban/<task-id>-<slug>`.
2. Assistant opens a PR from that branch into `main` with a summary of the diff and the
   verification commands the worker ran.
3. Review the diff, then merge (squash for solo, or `--merge` if you want to keep the
   worker's commit history).

## Conventions

- **One concern per PR.** Don't bundle unrelated fixes.
- **Title in imperative mood** — `feat(home): add palette picker`, not `added palette picker`.
- **Body answers three questions**: Why, What, Test plan.
- **Keep PRs mergeable.** If `main` moves ahead, rebase or merge `main` into the branch.
- **Delete the branch after merge** (GitHub does this automatically when you tick the box).

## Local safety net

A local `pre-push` git hook blocks any push that would update `refs/heads/main` directly.
The hook refuses the push and prints a reminder to open a PR instead.

The hook is at `.git/hooks/pre-push` (local only — not committed) and is per-clone. On a
fresh clone you'll need to re-create it. The current contents:

```bash
#!/usr/bin/env bash
# Block direct pushes to main — workflow requires PRs.
protected='refs/heads/main'
while read local_ref local_sha remote_ref remote_sha; do
  if [ "$remote_ref" = "$protected" ]; then
    echo "❌ Direct push to main is disabled. Open a PR instead." >&2
    echo "   git push origin <your-branch>" >&2
    echo "   gh pr create --base main --head <your-branch>" >&2
    exit 1
  fi
done
exit 0
```

To re-install on a new clone:

```bash
mkdir -p .git/hooks
cat > .git/hooks/pre-push <<'EOF'
… (same as above)
EOF
chmod +x .git/hooks/pre-push
```

## Exceptions

Force-pushes to **feature branches** are fine (after a rebase, for example).
Force-pushes to `main` are **never** fine — protect history.
