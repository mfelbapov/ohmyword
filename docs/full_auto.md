# Parallel Agent Development Workflow

## What This Is

A workflow where you can launch 2-3 Claude Code sessions simultaneously, each building a separate feature on its own git branch in its own directory. No race conditions. Clean merge at the end.

---

## 1. Git Worktree Setup

### How Worktrees Work with Phoenix/Elixir

Git worktrees create **separate working directories** that share the same `.git` database. Each directory is checked out to a different branch.

**What's shared** (via the `.git` link):
- Git history, commits, branches, remotes

**What's NOT shared** (each worktree has its own copy):
- All source files (lib/, test/, config/, etc.)
- `_build/` directory (compiled BEAM files)
- `deps/` directory (Elixir dependencies)
- `node_modules/` or `assets/` build artifacts

**Key implication**: Each worktree needs its own `mix deps.get` and `mix compile`. This costs disk space (~200MB per worktree for deps + build) but ensures complete isolation. Tests in one worktree won't affect another.

### Database Consideration

All worktrees share the same Postgres database (`ohmyword_dev`). This is fine because:
- Schema migrations go forward only (no conflicts if features add different tables/columns)
- If two features add migrations, they get different timestamps (no conflict)
- The test database (`ohmyword_test`) uses SQL sandbox, so parallel test runs are safe

**One rule**: Don't run conflicting migrations simultaneously. Run `mix ecto.migrate` one worktree at a time, sequentially.

### Setup Commands

```bash
# From your main repo directory: ~/Projects/ohmyword

# 1. Make sure main is up to date
git checkout main
git pull

# 2. Create feature branches
git branch feature/inflection-fixes
git branch feature/dictionary-page

# 3. Create worktrees (sibling directories)
git worktree add ../ohmyword-inflection feature/inflection-fixes
git worktree add ../ohmyword-dictionary feature/dictionary-page

# 4. Set up each worktree
cd ../ohmyword-inflection && mix deps.get && mix compile
cd ../ohmyword-dictionary && mix deps.get && mix compile

# 5. Run migrations if needed (one at a time)
cd ../ohmyword-inflection && mix ecto.migrate
cd ../ohmyword-dictionary && mix ecto.migrate
```

Result:
```
~/Projects/
├── ohmyword/              # main branch (your orchestrator session)
├── ohmyword-inflection/   # feature/inflection-fixes branch
└── ohmyword-dictionary/   # feature/dictionary-page branch
```

### Cleanup When Done

```bash
# After merging, remove worktrees
git worktree remove ../ohmyword-inflection
git worktree remove ../ohmyword-dictionary
# Delete merged branches
git branch -d feature/inflection-fixes feature/dictionary-page
```

---

## 2. Writing Specs for Autonomous Agents

The existing spec pattern in `specs/features/` is good. Here's what makes a spec work well for autonomous agents vs. what causes them to get stuck.

### Good Spec Checklist

A spec that lets an agent work autonomously should have:

- [ ] **Clear acceptance criteria** (what "done" looks like, not how to get there)
- [ ] **File paths** to existing code that's relevant (agents don't know your codebase intuitively)
- [ ] **Test commands** to verify the work (`mix test path/to/test.exs`)
- [ ] **Explicitly out of scope** items (prevents over-engineering)
- [ ] **Example inputs/outputs** for any non-obvious behavior
- [ ] **Existing patterns to follow** ("look at FlashcardLive for the LiveView pattern")

### Bad Spec Patterns

| Bad | Why | Better |
|-----|-----|--------|
| "Make the dictionary page" | Too vague, agent will guess at design | "Create `/dictionary` route with live search, see `docs/search_words.md`" |
| Extremely long spec (500+ lines) | Agent gets confused by volume | Link to detailed docs, keep spec to key decisions |
| No test criteria | Agent has no way to verify success | "Run `mix test` - all must pass. Add tests for X, Y, Z" |
| "Make it look good" | Subjective, agent will pick random styles | "Use DaisyUI `card` component with `btn-primary` for actions" |

### Spec Template

```markdown
# Feature: [Name]

## Context
Read these files first:
- `docs/relevant_doc.md` (background)
- `lib/ohmyword_web/live/similar_feature.ex` (pattern to follow)

## What to Build
[2-3 sentences describing the feature]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Files to Create/Modify
- Create: `lib/ohmyword_web/live/new_thing.ex`
- Modify: `lib/ohmyword_web/router.ex` (add route)

## Out of Scope
- Don't add X
- Don't refactor Y

## Verification
1. `mix compile --warnings-as-errors`
2. `mix test` (all pass)
3. `mix test test/specific_test.exs` (new tests pass)
4. Manual: visit `/route` and verify [behavior]
```

### Existing Specs

The `specs/features/po/` directory has product-owner-level specs and `specs/features/dev/` has technical implementation specs. This two-level pattern is good. The dev specs should be what you point agents at.

---

## 3. Agent Instructions - What to Tell Each Claude Session

### Starting a Session

When you open a new terminal and run `claude` in a worktree directory, the agent starts fresh. It reads your `CLAUDE.md` but knows nothing about your intent. You need to give it a clear, complete first message.

### Template First Message

```
Read `docs/search_words.md` for the full spec.

Build the Dictionary page feature:
1. Create the DictionaryLive module at lib/ohmyword_web/live/dictionary_live.ex
2. Add the /dictionary route to router.ex
3. Add a Dictionary link to the navigation in root.html.heex
4. Write tests in test/ohmyword_web/live/dictionary_live_test.exs

Follow the pattern from lib/ohmyword_web/live/flashcard_live.ex for the LiveView structure.

When done, run:
- mix compile --warnings-as-errors
- mix format --check-formatted
- mix test

Commit with a descriptive message on this branch.
```

### Key Principles

1. **Reference existing files** - "follow the pattern from X" is the single most effective instruction
2. **List concrete deliverables** - files to create, files to modify
3. **Include verification steps** - the agent will run them and fix issues
4. **One feature per session** - don't ask for unrelated work
5. **Tell it to commit** - so you can review the diff later

### What NOT to Do

- Don't paste the entire spec into the chat (tell it to read the file)
- Don't micromanage implementation details (let the agent make technical decisions within your constraints)
- Don't ask it to "figure out what to build" (that's your job as orchestrator)

### Checking on Progress

If an agent is running and you want to see what it's doing, you can read its output in the terminal. If you want to redirect it, just type your correction. The agent will adjust.

---

## 4. Merge Workflow

### After Agents Complete Their Work

```bash
# 1. Go to your main repo
cd ~/Projects/ohmyword

# 2. Review each branch's changes
git log main..feature/inflection-fixes --oneline
git diff main..feature/inflection-fixes --stat

git log main..feature/dictionary-page --oneline
git diff main..feature/dictionary-page --stat

# 3. Run tests on each branch before merging
cd ../ohmyword-inflection && mix test
cd ../ohmyword-dictionary && mix test

# 4. Merge one at a time into main
cd ~/Projects/ohmyword
git checkout main
git merge feature/inflection-fixes    # should be clean (no overlap)
mix test                               # verify after first merge

git merge feature/dictionary-page      # might have small conflicts in router.ex
# resolve any conflicts, then:
mix test                               # verify after second merge
```

### Common Conflict Points (This Project)

| File | Conflict Likelihood | Resolution |
|------|-------------------|------------|
| `lib/ohmyword_web/router.ex` | HIGH if both features add routes | Keep both route additions |
| `lib/ohmyword_web/components/layouts/root.html.heex` | MEDIUM if both add nav links | Keep both nav links in desired order |
| `lib/ohmyword_web/components/core_components.ex` | LOW unless both modify buttons | Review carefully |
| `priv/repo/migrations/*` | NONE (timestamps differ) | No conflict possible |
| `lib/ohmyword/linguistics/*.ex` | NONE (only inflection branch touches these) | No conflict |

### Best Practice: Merge Order

Merge the feature with **fewer shared-file changes** first. For this project:
1. First: inflection fixes (touches only linguistics files - no shared files)
2. Second: dictionary page (touches router.ex, layouts - potential conflict after #1 if that also touched these)

---

## 5. Feature Pairings for Parallel Work

Based on file overlap analysis:

### Safe to Run in Parallel
| Feature A | Feature B | Overlap |
|-----------|-----------|---------|
| Inflection engine fixes | Dictionary page | NONE |
| Inflection engine fixes | Spaced repetition | NONE |
| Inflection engine fixes | DaisyUI buttons | NONE |

### Avoid Running in Parallel
| Feature A | Feature B | Overlap |
|-----------|-----------|---------|
| Dictionary page | DaisyUI buttons | Both modify layouts, router |
| Dictionary page | Spaced repetition | Both add routes, nav links |

### Recommended First Parallel Pair
**Inflection engine fixes** + **Dictionary page**
- Zero file overlap
- Both have clear, complete specs already written
- Both have clear verification methods (inflection has validation tests, dictionary has manual + automated tests)

---

## 6. Example: First Parallel Run

### Step 1: Create feature branches and worktrees
```bash
git checkout main
git branch feature/inflection-fixes
git branch feature/dictionary-page
git worktree add ../ohmyword-inflection feature/inflection-fixes
git worktree add ../ohmyword-dictionary feature/dictionary-page
```

### Step 2: Install deps in each worktree
```bash
cd ../ohmyword-inflection && mix deps.get && mix compile
cd ../ohmyword-dictionary && mix deps.get && mix compile
```

### Step 3: Launch agents
Open two separate terminal windows:

**Terminal 1 - Inflection Agent:**
```bash
cd ~/Projects/ohmyword-inflection
claude
```
First message:
```
Read docs/missing_engine_logic.md for the full list of inflection engine issues.

Fix the noun inflection issues first (Section 1), then verbs (Section 2).
Focus on the "Quick Wins" and "Medium Effort" items listed in the Summary section.

After each fix, run:
  mix test --include inflector_validation test/ohmyword/linguistics/inflector_validation_test.exs

When all fixes are done, run:
  mix compile --warnings-as-errors
  mix test

Commit your changes with descriptive messages.
```

**Terminal 2 - Dictionary Agent:**
```bash
cd ~/Projects/ohmyword-dictionary
claude
```
First message:
```
Read docs/search_words.md for the full spec.

Build the Dictionary page:
1. Create lib/ohmyword_web/live/dictionary_live.ex with live search
2. Add route to router.ex
3. Add Dictionary nav link to root.html.heex
4. Write tests

Follow the LiveView pattern from lib/ohmyword_web/live/flashcard_live.ex.
Use the existing Ohmyword.Search.lookup/1 function for search.

When done, run:
  mix compile --warnings-as-errors
  mix format --check-formatted
  mix test

Commit your changes.
```

### Step 4: Monitor and merge
- Let agents work
- Review their commits: `git log` in each worktree
- Merge into main when both are done (inflection first, then dictionary)
- Run `mix test` after each merge

### Step 5: Clean up
```bash
cd ~/Projects/ohmyword
git worktree remove ../ohmyword-inflection
git worktree remove ../ohmyword-dictionary
git branch -d feature/inflection-fixes feature/dictionary-page
```

---

## Verification After Full Merge

1. `mix compile --warnings-as-errors` - no warnings
2. `mix format --check-formatted` - code formatted
3. `mix test` - all tests pass (including new ones from both features)
4. `mix test --include inflector_validation` - inflection improvements verified
5. `mix phx.server` - start app and manually verify dictionary page at `/dictionary`