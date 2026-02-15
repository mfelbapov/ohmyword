#!/usr/bin/env bash
#
# run_parallel.sh — Orchestrate parallel Claude Code agents on isolated worktrees
#
# Each agent gets its own git worktree, branch, and PostgreSQL database.
# After all agents finish, results are validated, committed, pushed, and PRs created.
#
# Usage:
#   scripts/run_parallel.sh --prompts "prompt1" "prompt2" ...
#   scripts/run_parallel.sh --prompt-file prompts.txt [--merge] [--max-turns 120]
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP=$(date +%s)
LOG_DIR="/tmp/parallel-agents-${TIMESTAMP}"
MAX_TURNS=120
DO_MERGE=false
PROMPTS=()

# ─── Colors ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${BLUE}[parallel]${NC} $*"; }
ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; }

usage() {
  cat <<'EOF'
Usage: scripts/run_parallel.sh [OPTIONS] --prompts "prompt1" "prompt2" ...

Orchestrates parallel Claude Code agents on isolated git worktrees.
Number of agents = number of prompts provided.

OPTIONS:
  --prompts "p1" "p2" ...   Prompts for each agent (one per agent)
  --prompt-file FILE         Read prompts from file (one per line, blank lines ignored)
  --max-turns N              Max agentic turns per agent (default: 120)
  --merge                    Auto-merge PRs sequentially after validation
  -h, --help                 Show this help

EXAMPLES:
  scripts/run_parallel.sh --prompts \
    "/adding_new_word Add these words: kuvar, pekmez, džem" \
    "/add_sentences Add 5 sentences using nouns in accusative case"

  scripts/run_parallel.sh --prompt-file my_prompts.txt --max-turns 80
EOF
  exit 0
}

# ─── Parse arguments ───────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompts)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
        PROMPTS+=("$1")
        shift
      done
      ;;
    --prompt-file)
      shift
      if [[ ! -f "$1" ]]; then
        err "Prompt file not found: $1"
        exit 1
      fi
      while IFS= read -r line; do
        line="${line%%#*}"        # strip comments
        line="${line#"${line%%[![:space:]]*}"}"  # trim leading whitespace
        line="${line%"${line##*[![:space:]]}"}"  # trim trailing whitespace
        [[ -n "$line" ]] && PROMPTS+=("$line")
      done < "$1"
      shift
      ;;
    --max-turns)
      shift
      MAX_TURNS="$1"
      shift
      ;;
    --merge)
      DO_MERGE=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      err "Unknown option: $1"
      exit 1
      ;;
  esac
done

N=${#PROMPTS[@]}
if [[ $N -eq 0 ]]; then
  err "No prompts provided. Use --prompts or --prompt-file."
  exit 1
fi

log "${BOLD}Starting $N parallel agent(s)${NC}"
mkdir -p "$LOG_DIR"

# ─── Track resources for cleanup ──────────────────────────────────
WORKTREE_DIRS=()
DB_NAMES=()
BRANCH_NAMES=()

cleanup() {
  echo ""
  log "Cleaning up..."
  for dir in "${WORKTREE_DIRS[@]:-}"; do
    if [[ -n "$dir" && -d "$dir" ]]; then
      log "  Removing worktree: $(basename "$dir")"
      git -C "$REPO_DIR" worktree remove --force "$dir" 2>/dev/null || true
    fi
  done
  for db in "${DB_NAMES[@]:-}"; do
    if [[ -n "$db" ]]; then
      log "  Dropping databases: $db, ${db}_test"
      dropdb -U postgres --if-exists "$db" 2>/dev/null || true
      dropdb -U postgres --if-exists "${db}_test" 2>/dev/null || true
    fi
  done
  # Clean up local-only branches (ignore errors if already deleted or pushed)
  for branch in "${BRANCH_NAMES[@]:-}"; do
    [[ -n "$branch" ]] && git -C "$REPO_DIR" branch -D "$branch" 2>/dev/null || true
  done
  log "Cleanup complete. Logs preserved at ${LOG_DIR}/"
}
trap cleanup EXIT

# ─── 1. SETUP ──────────────────────────────────────────────────────
log "${BOLD}Phase 1: Setting up worktrees and databases${NC}"

for i in $(seq 1 "$N"); do
  BRANCH="parallel-${i}-${TIMESTAMP}"
  WT_DIR="${REPO_DIR}/../ohmyword-wt-${i}-${TIMESTAMP}"
  DB_DEV="ohmyword_wt_${i}_${TIMESTAMP}"
  DB_TEST="${DB_DEV}_test"

  BRANCH_NAMES+=("$BRANCH")
  WORKTREE_DIRS+=("$WT_DIR")
  DB_NAMES+=("$DB_DEV")

  log "  Agent $i: branch=${BRANCH} db=${DB_DEV}"

  # Create worktree from current HEAD
  git -C "$REPO_DIR" worktree add "$WT_DIR" -b "$BRANCH"

  # Point worktree at isolated databases (sed edits are local to worktree)
  sed -i '' "s/database: \"ohmyword_dev\"/database: \"${DB_DEV}\"/" "$WT_DIR/config/dev.exs"
  sed -i '' "s/database: \"ohmyword_test/database: \"${DB_TEST}/" "$WT_DIR/config/test.exs"

  # Install deps and set up both dev and test databases
  log "  Agent $i: installing deps and setting up databases..."
  (
    cd "$WT_DIR"
    mix deps.get --quiet
    MIX_ENV=dev mix ecto.setup
    MIX_ENV=test mix ecto.create --quiet
    MIX_ENV=test mix ecto.migrate --quiet
  )

  ok "Agent $i ready"
done

# ─── 2. LAUNCH ─────────────────────────────────────────────────────
log "${BOLD}Phase 2: Launching agents${NC}"
PIDS=()

for i in $(seq 1 "$N"); do
  WT_DIR="${WORKTREE_DIRS[$((i-1))]}"
  PROMPT="${PROMPTS[$((i-1))]}"
  AGENT_LOG="${LOG_DIR}/agent-${i}.log"

  log "  Agent $i: launching (log: ${AGENT_LOG})"
  (
    cd "$WT_DIR"
    claude -p "$PROMPT" \
      --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
      --max-turns "$MAX_TURNS" \
      --dangerously-skip-permissions \
      > "$AGENT_LOG" 2>&1
  ) &
  PIDS+=($!)
done

log "All agents launched. Tail logs with:"
log "  tail -f ${LOG_DIR}/agent-*.log"
echo ""

# Wait for all agents and record exit status
AGENT_EXIT=()
for i in $(seq 1 "$N"); do
  pid="${PIDS[$((i-1))]}"
  if wait "$pid"; then
    ok "Agent $i finished successfully (PID $pid)"
    AGENT_EXIT+=(0)
  else
    err "Agent $i exited with error (PID $pid)"
    AGENT_EXIT+=(1)
  fi
done

# ─── 3. VALIDATE ───────────────────────────────────────────────────
log "${BOLD}Phase 3: Validating agent work${NC}"
VALID_AGENTS=()

for i in $(seq 1 "$N"); do
  if [[ "${AGENT_EXIT[$((i-1))]}" -ne 0 ]]; then
    warn "Agent $i: skipping (agent exited with error)"
    continue
  fi

  WT_DIR="${WORKTREE_DIRS[$((i-1))]}"

  # Check if agent made any changes
  if (cd "$WT_DIR" && git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]); then
    warn "Agent $i: no changes detected, skipping"
    continue
  fi

  log "  Agent $i: running mix precommit..."
  if (cd "$WT_DIR" && mix precommit); then
    ok "Agent $i: validation passed"
    VALID_AGENTS+=("$i")
  else
    err "Agent $i: validation failed (see log for details)"
  fi
done

if [[ ${#VALID_AGENTS[@]} -eq 0 ]]; then
  err "No agents passed validation. Exiting."
  exit 1
fi

ok "${#VALID_AGENTS[@]}/${N} agent(s) passed validation"

# ─── 4. COMMIT & PUSH ──────────────────────────────────────────────
log "${BOLD}Phase 4: Committing and pushing${NC}"
PUSHED_AGENTS=()

for i in "${VALID_AGENTS[@]}"; do
  WT_DIR="${WORKTREE_DIRS[$((i-1))]}"
  BRANCH="${BRANCH_NAMES[$((i-1))]}"

  # Revert config changes (DB overrides) before committing
  (cd "$WT_DIR" && git checkout -- config/dev.exs config/test.exs)

  # Check again after reverting config — agent may have only changed config
  if (cd "$WT_DIR" && git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]); then
    warn "Agent $i: only config changes detected (reverted), skipping"
    continue
  fi

  # Stage and commit
  (cd "$WT_DIR" && git add -A && git commit -m "$(cat <<EOF
Parallel agent ${i}: automated changes

Co-Authored-By: Claude Code <noreply@anthropic.com>
EOF
  )")

  # Push branch
  (cd "$WT_DIR" && git push -u origin "$BRANCH")
  ok "Agent $i: pushed ${BRANCH}"
  PUSHED_AGENTS+=("$i")
done

if [[ ${#PUSHED_AGENTS[@]} -eq 0 ]]; then
  err "No agents had changes to push. Exiting."
  exit 1
fi

# ─── 5. CREATE PRs ─────────────────────────────────────────────────
log "${BOLD}Phase 5: Creating pull requests${NC}"
PR_URLS=()

for i in "${PUSHED_AGENTS[@]}"; do
  WT_DIR="${WORKTREE_DIRS[$((i-1))]}"
  BRANCH="${BRANCH_NAMES[$((i-1))]}"

  PR_URL=$(cd "$WT_DIR" && gh pr create \
    --title "Parallel agent ${i}: ${BRANCH}" \
    --body "$(cat <<EOF
## Summary
Automated changes from parallel agent ${i}.

**Prompt:** ${PROMPTS[$((i-1))]:0:200}

## Agent log
\`${LOG_DIR}/agent-${i}.log\`

---
🤖 Generated with parallel Claude Code agents
EOF
  )" 2>&1) || true

  if [[ -n "$PR_URL" && "$PR_URL" == http* ]]; then
    ok "Agent $i: $PR_URL"
    PR_URLS+=("$PR_URL")
  else
    warn "Agent $i: PR creation issue — $PR_URL"
  fi
done

# ─── 6. MERGE (optional, sequential) ──────────────────────────────
if [[ "$DO_MERGE" == true && ${#PR_URLS[@]} -gt 0 ]]; then
  log "${BOLD}Phase 6: Merging PRs sequentially${NC}"

  for idx in "${!PR_URLS[@]}"; do
    url="${PR_URLS[$idx]}"
    log "  Merging: $url"
    if gh pr merge "$url" --squash --delete-branch; then
      ok "Merged: $url"
      # Rebase remaining worktrees onto updated main
      for j in "${PUSHED_AGENTS[@]}"; do
        remaining_wt="${WORKTREE_DIRS[$((j-1))]}"
        if [[ -d "$remaining_wt" ]]; then
          (cd "$remaining_wt" && git fetch origin && git rebase origin/main 2>/dev/null) || true
        fi
      done
    else
      err "Failed to merge: $url (may need manual conflict resolution)"
    fi
  done
else
  if [[ ${#PR_URLS[@]} -gt 0 ]]; then
    log "Phase 6: Skipping merge (use --merge to auto-merge)"
  fi
fi

# ─── SUMMARY ───────────────────────────────────────────────────────
echo ""
log "═══════════════════════════════════════════════"
log "${BOLD}Summary${NC}"
log "  Agents:    $N launched, ${#VALID_AGENTS[@]} validated, ${#PUSHED_AGENTS[@]} pushed"
log "  Logs:      $LOG_DIR/"
for url in "${PR_URLS[@]}"; do
  log "  PR:        $url"
done
if [[ "$DO_MERGE" == true ]]; then
  log "  Merge:     completed"
else
  log "  Merge:     skipped (PRs ready for review)"
fi
log "═══════════════════════════════════════════════"
log "Done!"
