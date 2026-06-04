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
tmux new-session -d -s "$NAME" ||
  die "Failed to create tmux session '$NAME'"
log "Tmux session created"

# Pane 1: docker compose (fresh start with volume wipe)
# Source .env.worktree explicitly to ensure unique COMPOSE_PROJECT_NAME and ports
# are set regardless of whether direnv is active in the tmux pane
tmux send-keys -t "$NAME" "cd $WORKTREE && set -a && source .env.worktree && source service-api-go/.env.local && set +a && cd service-api-go && docker rm -f \$(docker ps -aq) 2>/dev/null || true && docker system prune -af --volumes && docker volume rm \$(docker volume ls -q) 2>/dev/null || true && docker compose down -v && docker compose up --build -d" C-m

# Pane 2: Go API via air (wait for docker)
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

log "All windows set up. Switching to session '$NAME'"

tmux select-window -t "$NAME:0"

# Switch if already in tmux, otherwise attach
if [ -n "$TMUX" ]; then
  tmux switch-client -t "$NAME" || die "Failed to switch to session '$NAME'"
else
  tmux attach -t "$NAME" || die "Failed to attach to session '$NAME'"
fi
