# Multibranch Agentic Flow Guide

Run multiple Claude Code agents in parallel on isolated branches to scale content work (vocabulary, sentences, features) without conflicts.

## Concept

```
main
 ├── worktree-a/  (branch: add-words-batch-1)     ← Agent A: adding words
 ├── worktree-b/  (branch: add-words-batch-2)     ← Agent B: adding words
 ├── worktree-c/  (branch: add-sentences-batch-1) ← Agent C: adding sentences
 └── (original)   (branch: main)                  ← you, orchestrating
```

**Git worktrees** let you check out multiple branches of the same repo in separate directories — each with its own working tree but sharing `.git` history. **Claude Code headless mode** (`-p`) lets you run agents non-interactively from the shell. Combine the two to run N agents in parallel, each on its own branch, each producing a PR.

## Setup

### 1. Create worktrees

From the main repo directory:

```bash
# Create worktrees for parallel work
git worktree add ../ohmyword-wt-a -b add-words-batch-1
git worktree add ../ohmyword-wt-b -b add-words-batch-2
git worktree add ../ohmyword-wt-c -b add-sentences-batch-1
```

Each worktree is a full checkout. You can `cd` into it and run `mix`, `git`, etc. independently.

### 2. Set up each worktree's database

Each worktree needs its own compiled app and database:

```bash
cd ../ohmyword-wt-a
mix deps.get
mix ecto.setup    # creates DB, runs migrations, seeds
```

Repeat for each worktree. The test database is created automatically by `mix test`.

> **Tip:** If you're only doing seed-file edits (JSON changes, no DB queries), you can skip `ecto.setup` — but the agent won't be able to run the validator or import words without it.

### 3. Verify Claude Code skills are available

Skills (`.claude/skills/`) and commands (`.claude/commands/`) live in the repo, so they're available in every worktree automatically.

## Running Agents

### CLI flags reference

| Flag | Purpose |
|------|---------|
| `--print` / `-p` | Headless mode — reads prompt from stdin/arg, prints output, exits |
| `--allowedTools` | Comma-separated list of tools the agent can use without asking |
| `--max-turns` | Cap on agentic turns (default unlimited) |
| `--output-format` | `text` (default), `json`, or `stream-json` |
| `--dangerously-skip-permissions` | Skip all permission prompts (use only in trusted automation) |

### Basic invocation

```bash
cd ../ohmyword-wt-a
claude -p "Add these 20 words to the vocabulary: ..." \
  --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
  --max-turns 100
```

### Using skills in headless mode

Skills are invoked with the `/skill` syntax in the prompt:

```bash
claude -p "/adding_new_word Add the following words: kuvar, kuvati, kuhinja" \
  --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
  --max-turns 80
```

## Practical Recipes

### Recipe 1: Parallel vocabulary addition

Split a word list across agents, each on its own branch/worktree.

**prepare-words.sh:**

```bash
#!/bin/bash
# Split a word list file and run agents in parallel

WORD_FILE="docs/words_to_add.md"
WORDS_PER_AGENT=25

# Create worktrees
git worktree add ../ohmyword-wt-words-1 -b add-words-batch-1
git worktree add ../ohmyword-wt-words-2 -b add-words-batch-2

# Split the word file (assumes one word per line or comma-separated)
head -n $WORDS_PER_AGENT "$WORD_FILE" > /tmp/batch1.txt
tail -n +$((WORDS_PER_AGENT + 1)) "$WORD_FILE" | head -n $WORDS_PER_AGENT > /tmp/batch2.txt

# Launch agents in parallel
(
  cd ../ohmyword-wt-words-1
  mix deps.get && mix ecto.setup
  claude -p "/adding_new_word Add these words to the vocabulary seed. After adding all words, run mix precommit to verify everything passes. Words: $(cat /tmp/batch1.txt)" \
    --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
    --max-turns 120 \
    --dangerously-skip-permissions \
    > /tmp/agent1.log 2>&1
) &

(
  cd ../ohmyword-wt-words-2
  mix deps.get && mix ecto.setup
  claude -p "/adding_new_word Add these words to the vocabulary seed. After adding all words, run mix precommit to verify everything passes. Words: $(cat /tmp/batch2.txt)" \
    --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
    --max-turns 120 \
    --dangerously-skip-permissions \
    > /tmp/agent2.log 2>&1
) &

echo "Agents launched. Tail logs:"
echo "  tail -f /tmp/agent1.log"
echo "  tail -f /tmp/agent2.log"
wait
echo "All agents finished."
```

### Recipe 2: Batch word addition with the script

If you already have a JSON file of word entries, use `batch_add_words.exs` instead of the skill:

```bash
cd ../ohmyword-wt-words-1
mix run scripts/batch_add_words.exs /tmp/batch1.json
```

The script validates each entry against the engine, merges passing words into `vocabulary_seed.json`, and logs failures to `docs/new_words_to_check.md`.

### Recipe 3: Parallel sentence addition

```bash
git worktree add ../ohmyword-wt-sent-1 -b add-sentences-batch-1
git worktree add ../ohmyword-wt-sent-2 -b add-sentences-batch-2

# Agent 1: sentences for nouns
(
  cd ../ohmyword-wt-sent-1
  mix deps.get && mix ecto.setup
  claude -p "/add_sentences Add 15 new sentences focusing on noun declensions (accusative, genitive, instrumental cases). Use words already in the vocabulary seed. Run mix precommit when done." \
    --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
    --max-turns 100 \
    --dangerously-skip-permissions \
    > /tmp/sent-agent1.log 2>&1
) &

# Agent 2: sentences for verbs
(
  cd ../ohmyword-wt-sent-2
  mix deps.get && mix ecto.setup
  claude -p "/add_sentences Add 15 new sentences focusing on verb conjugations (present tense, past tense, imperatives). Use words already in the vocabulary seed. Run mix precommit when done." \
    --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
    --max-turns 100 \
    --dangerously-skip-permissions \
    > /tmp/sent-agent2.log 2>&1
) &

wait
```

### Recipe 4: Mixed parallel work

Run different types of work simultaneously:

```bash
# Agent A: add vocabulary
(cd ../ohmyword-wt-a && claude -p "/adding_new_word ..." --dangerously-skip-permissions) &

# Agent B: add sentences
(cd ../ohmyword-wt-b && claude -p "/add_sentences ..." --dangerously-skip-permissions) &

# Agent C: feature work
(cd ../ohmyword-wt-c && claude -p "Add a progress bar to the flashcard view..." --dangerously-skip-permissions) &

wait
```

## Merge & Deploy

### 1. Review and commit in each worktree

After an agent finishes, inspect its work:

```bash
cd ../ohmyword-wt-words-1
git diff                    # review changes
mix precommit               # verify everything passes
git add priv/repo/vocabulary_seed.json docs/new_words_to_check.md
git commit -m "Add vocabulary batch 1: 25 new words"
```

### 2. Push and create PRs

```bash
git push -u origin add-words-batch-1
gh pr create --fill
```

Or let Claude do it with the push_to_dev command (note: this merges to main **and** deploys):

```bash
claude -p "/push_to_dev"
```

> If you want to just push a branch + open a PR **without** deploying, do it manually with `git push` + `gh pr create`.

### 3. Merge order for seed file changes

When multiple PRs touch the same seed file (`vocabulary_seed.json` or `sentences_seed.json`), merge them **one at a time**:

1. Merge PR #1 (squash)
2. In worktree #2: `git fetch origin && git rebase origin/main` — resolve any JSON merge conflicts
3. Push the rebased branch, let CI pass
4. Merge PR #2
5. Repeat

### 4. Deploy

After all PRs are merged, follow the normal tag-based deploy:

```bash
git checkout main && git pull
git tag v0.1.XX && git push origin v0.1.XX   # triggers CD
fly ssh console -C "/app/bin/ohmyword eval 'Ohmyword.Release.seed()'"
```

**Reminder:** Never push tags without explicit intent. See CLAUDE.md deployment rules.

## Cleanup

Remove worktrees when done:

```bash
git worktree remove ../ohmyword-wt-words-1
git worktree remove ../ohmyword-wt-words-2
git worktree remove ../ohmyword-wt-sent-1

# Delete remote branches that were already merged
git branch -d add-words-batch-1 add-words-batch-2
```

List active worktrees:

```bash
git worktree list
```

## Gotchas

### Database per worktree
Each worktree is a separate Elixir project checkout. If an agent needs to run the validator, import words, or run tests, it needs `mix ecto.setup` first. All worktrees share the same Postgres server but use the same database name by default — so either:
- Run agents that don't need DB (JSON-only edits), or
- Override `DATABASE_URL` per worktree to use separate databases:
  ```bash
  DATABASE_URL=ecto://localhost/ohmyword_wt1 mix ecto.setup
  ```

### Seed file merge conflicts
`vocabulary_seed.json` and `sentences_seed.json` are large JSON arrays. When two branches both append to the same array, Git will produce a merge conflict. The fix is straightforward: keep both additions and ensure the JSON array is valid (watch for missing/extra commas at the splice point). Merging PRs sequentially (as described above) avoids this.

### Agent turn limits
Complex word additions (verbs with 24 forms, adjectives with 84+ forms) consume many turns per word. Set `--max-turns` generously — 5-8 turns per word is typical. For 25 words, use `--max-turns 120` or higher.

### Skill context
Skills rely on reading files (`vocabulary_seed.json`, `sentences_seed.json`). In large prompts, ensure the agent has enough context window to hold the seed file contents. If the seed files grow very large, consider telling the agent to work with a subset or to use `Grep` to search rather than reading the entire file.

### CI runs on PR
CI (`.github/workflows/ci.yml`) runs on every PR to `main`: formatting check, compile with warnings-as-errors, full test suite. Make sure `mix precommit` passes in the worktree before pushing.

### Deployment rules
From CLAUDE.md:
- Never push directly to `main` — always use a feature branch + PR
- Never create version tags unless explicitly asked
- Never `git push` without asking first (in interactive mode)

In headless mode with `--dangerously-skip-permissions`, the agent can push freely — so keep your prompts scoped to content work and explicitly tell the agent **not** to push or deploy.
