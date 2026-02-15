# Push to Dev

Deploy the current branch to stasta.world (dev/production on Fly.io). Execute all steps sequentially, stopping immediately if any step fails.

## Steps

### 1. Run precommit checks

Run `mix precommit` (compile, deps.unlock --unused, format, test). If it fails, fix the issues and re-run until it passes. Do NOT proceed until precommit is green.

### 2. Commit all changes

- Run `git status` to see what changed
- Stage all modified and untracked files (but skip `.env`, credentials, or secrets)
- Commit with a descriptive message summarizing the changes
- If there are no changes to commit, skip this step

### 3. Push branch to remote

```
git push -u origin <current-branch-name>
```

### 4. Create and merge PR

- Check if a PR already exists for this branch: `gh pr view --json state 2>/dev/null`
- If no PR exists, create one: `gh pr create --fill`
- Merge with squash: `gh pr merge --squash --delete-branch`
- If merge fails due to checks, wait for them: `gh pr checks --watch` then retry the merge

### 5. Switch to main and pull

```
git checkout main && git pull origin main
```

### 6. Determine next tag version

- Get the latest tag: `git tag --sort=-v:refname | head -1`
- Parse the patch number from `v0.1.N` and increment by 1
- The new tag will be `v0.1.(N+1)`

### 7. Create and push the tag

```
git tag v0.1.<next> && git push origin v0.1.<next>
```

This triggers the CD workflow (`.github/workflows/cd.yml`): test -> deploy to Fly.io.

### 8. Wait for deploy

Watch the triggered workflow run in real-time:

```
gh run watch
```

Select the run triggered by the tag push. Stream logs until it completes. If the deploy fails, stop and report the error — do NOT retry automatically.

### 9. Reseed the database

After successful deploy, reseed vocabulary, sentences, and admin user on the remote:

```
fly ssh console -C "/app/bin/ohmyword eval 'Ohmyword.Release.seed()'"
```

This clears and reloads: search_terms, vocabulary_words, sentence_words, sentences.

### 10. Clean up

Delete the old feature branch locally if it still exists:

```
git branch -d <feature-branch-name>
```

### Done

Report: tag version deployed, reseed result, and any warnings encountered.
