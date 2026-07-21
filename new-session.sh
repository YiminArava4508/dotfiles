#!/bin/bash

NAME=$1
SETUP_SCRIPT=~/setup-worktree.sh

log() { echo "[$(date '+%H:%M:%S')] $*"; }
die() {
  log "ERROR: $*"
  exit 1
}

if [ -z "$NAME" ]; then
  echo "Usage: $0 <name>"
  exit 1
fi

# Match setup-worktree.sh's sanitization so the path is consistent
WORKTREE_DIR=$(echo "$NAME" | sed 's/[^a-zA-Z0-9-]/-/g' | cut -c1-50)
WORKTREE=~/Work/worktrees/$WORKTREE_DIR

# --- Run setup-worktree.sh for worktree/env setup ---
log "Running setup-worktree.sh for '$NAME'..."
bash "$SETUP_SCRIPT" "$NAME" || die "setup-worktree.sh failed"
log "Worktree setup complete"

# --- Create service-api-go/.env.local with local dev credentials ---
cat > "$WORKTREE/service-api-go/.env.local" <<'EOF'
LOCAL_ARTEMIS_USER_EMAIL=yimin.arava@matthews.com
LOCAL_ARTEMIS_USER_SF_ID=005Pm000002BUODIA4
EOF
log "service-api-go/.env.local created"

# --- Tmux session ---
if tmux has-session -t "$NAME" 2>/dev/null; then
  log "Session '$NAME' already exists, switching to it..."
  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$NAME" || die "Failed to switch to session '$NAME'"
  elif [ -t 0 ]; then
    tmux attach -t "$NAME" || die "Failed to attach to session '$NAME'"
  else
    log "No TTY; session '$NAME' already running, leaving detached"
  fi
  exit 0
fi
# Capture the first window/pane IDs so the script is independent of
# base-index / pane-base-index (omarchy's tmux.conf sets both to 1)
FIRST_INFO=$(tmux new-session -d -s "$NAME" -P -F '#{window_id} #{pane_id}') ||
  die "Failed to create tmux session '$NAME'"
read -r FIRST_WINDOW FIRST_PANE <<<"$FIRST_INFO"
log "Tmux session created"

# Window 0: a single shell in the worktree. Servers are NOT auto-started (memory
# cost) — instead we stage ~/run-local-env.sh in shell history so Up-arrow +
# Enter spins up the full docker/Go/React/LangServe layout when you need it.
tmux send-keys -t "$NAME" "cd $WORKTREE" C-m
tmux send-keys -t "$NAME" "echo 'Local dev not started. Press Up then Enter to run ~/run-local-env.sh'" C-m
tmux send-keys -t "$NAME" "history -s '~/run-local-env.sh'" C-m

# Frontend window
tmux new-window -t "$NAME" -n Frontend
tmux send-keys -t "$NAME:Frontend" "cd $WORKTREE/react-ui" C-m
tmux send-keys -t "$NAME:Frontend" "nvim" C-m

# Backend window
tmux new-window -t "$NAME" -n Backend
tmux send-keys -t "$NAME:Backend" "cd $WORKTREE/service-api-go" C-m
tmux send-keys -t "$NAME:Backend" "nvim" C-m

# Claude window
tmux new-window -t "$NAME" -n Claude
tmux send-keys -t "$NAME:Claude" "cd $WORKTREE" C-m

# If launched from shortcut-helper (name is sc-<storyId>-<slug>), seed the
# Claude session with a prompt that asks it to look up the ticket via the
# Shortcut MCP and draft an implementation plan before any code is written.
if [[ "$NAME" =~ ^sc-([0-9]+)- ]]; then
  STORY_ID="${BASH_REMATCH[1]}"
  CLAUDE_PROMPT="Fetch Shortcut story ${STORY_ID} via the Shortcut MCP (mcp__shortcut__stories-get-by-id) and read its description, acceptance criteria, and comments. Then invoke the superpowers:writing-plans skill and use it to produce the implementation plan for this ticket. Do not write code — stop after the plan is written."
  tmux send-keys -t "$NAME:Claude" "claude \"$CLAUDE_PROMPT\"" C-m
elif [[ "$NAME" =~ ^eng-([0-9]+)- ]]; then
  ISSUE_ID="ENG-${BASH_REMATCH[1]}"
  CLAUDE_PROMPT="Fetch Linear issue ${ISSUE_ID} via the Linear MCP (mcp__linear-server__get_issue) and read its description and comments. Then invoke the superpowers:writing-plans skill and use it to produce the implementation plan for this ticket. Do not write code — stop after the plan is written."
  tmux send-keys -t "$NAME:Claude" "claude \"$CLAUDE_PROMPT\"" C-m
else
  tmux send-keys -t "$NAME:Claude" "claude" C-m
fi

log "All windows set up. Switching to session '$NAME'"

tmux select-window -t "$FIRST_WINDOW"

# Switch if already in tmux, attach if on a terminal; when launched headless
# (e.g. by linear-helper/shortcut-helper) leave the session detached and exit 0
if [ -n "$TMUX" ]; then
  tmux switch-client -t "$NAME" || die "Failed to switch to session '$NAME'"
elif [ -t 0 ]; then
  tmux attach -t "$NAME" || die "Failed to attach to session '$NAME'"
else
  log "No TTY; session '$NAME' left detached"
fi
