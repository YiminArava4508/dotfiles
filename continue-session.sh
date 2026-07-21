#!/bin/bash

# continue-session.sh - Recreate tmux sessions for all existing worktrees

log() { echo "[$(date '+%H:%M:%S')] $*"; }

WORKTREES_BASE=~/Work/worktrees

# Find all worktree roots (identified by .env.worktree)
while IFS= read -r env_file; do
  WORKTREE=$(dirname "$env_file")
  # Derive session name from path relative to worktrees base (slashes -> dashes)
  NAME=$(basename "$WORKTREE")

  # Skip if tmux session already exists
  if tmux has-session -t "$NAME" 2>/dev/null; then
    log "Session '$NAME' already exists, skipping"
    continue
  fi

  log "Creating session '$NAME' for $WORKTREE (servers staged, not started)"

  # Capture first window/pane IDs to stay independent of base-index/pane-base-index
  FIRST_INFO=$(tmux new-session -d -s "$NAME" -P -F '#{window_id} #{pane_id}') || { log "ERROR: Failed to create session '$NAME'"; continue; }
  read -r FIRST_WINDOW FIRST_PANE <<<"$FIRST_INFO"

  # Window 0: a single shell in the worktree. Servers are NOT auto-started
  # (memory cost) — ~/run-local-env.sh is staged in history so Up-arrow + Enter
  # spins up the full docker/Go/React/LangServe layout when you need it.
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
  tmux send-keys -t "$NAME:Claude" "claude" C-m

  tmux select-window -t "$FIRST_WINDOW"

  log "Session '$NAME' created"

done < <(find "$WORKTREES_BASE" -maxdepth 3 -name ".env.worktree" 2>/dev/null)

log "Done. Sessions:"
tmux list-sessions 2>/dev/null || log "No tmux sessions running"
