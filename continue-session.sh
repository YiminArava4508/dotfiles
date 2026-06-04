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

  log "Creating session '$NAME' for $WORKTREE"

  tmux new-session -d -s "$NAME" || { log "ERROR: Failed to create session '$NAME'"; continue; }

  # Pane 1: docker compose
  tmux send-keys -t "$NAME" "cd $WORKTREE && set -a && source .env.worktree && source service-api-go/.env.local && set +a && cd service-api-go && docker compose down -v && docker compose up --build -d" C-m

  # Pane 2: Go API via air
  tmux split-window -h -t "$NAME"
  tmux send-keys -t "$NAME" "cd $WORKTREE && set -a && source .env.worktree && set +a && cd service-api-go && sleep 30s && task generate && air serve-graphql --pe" C-m

  # Pane 3: React dev server
  tmux split-window -v -t "$NAME"
  tmux send-keys -t "$NAME" "cd $WORKTREE && set -a && source .env.worktree && set +a && cd react-ui && pnpm run dev" C-m

  # Pane 4: Empty shell for general use
  tmux split-window -v -t "$NAME:0.0"
  tmux send-keys -t "$NAME" "cd $WORKTREE" C-m

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

  tmux select-window -t "$NAME:0"

  log "Session '$NAME' created"

done < <(find "$WORKTREES_BASE" -maxdepth 3 -name ".env.worktree" 2>/dev/null)

log "Done. Sessions:"
tmux list-sessions 2>/dev/null || log "No tmux sessions running"
