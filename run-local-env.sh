#!/bin/bash
# run-local-env.sh - Spin up the local dev environment for a worktree.
#
# Extracted from new-session.sh / continue-session.sh so sessions no longer
# auto-launch servers (memory cost). It lays out the docker / Go / React /
# LangServe panes and is safe to re-run: if the env is already up it no-ops
# (guarding against the destructive `docker compose down -v`).
#
# Usage:
#   run-local-env.sh                 Interactive: split the CURRENT tmux window
#                                    (run this from inside a worktree, in tmux).
#   run-local-env.sh <session-name>  Headless: target that tmux session, laying
#                                    the stack in a new 'LocalDev' window. The
#                                    worktree is ~/Work/worktrees/<session-name>;
#                                    the session is created detached if absent.
#                                    Used by linear-helper on In-Review.
#   --force                          Start even if the env looks already up.

set -uo pipefail

log() { echo "[$(date '+%H:%M:%S')] $*"; }
die() {
  log "ERROR: $*"
  exit 1
}

# --- Parse args ---
FORCE=false
SESSION=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    -*) die "unknown option: $arg" ;;
    *) SESSION="$arg" ;;
  esac
done

# --- Resolve the worktree root ---
if [ -n "$SESSION" ]; then
  # Session name == worktree dir name by convention (setup-worktree.sh).
  WORKTREE="$HOME/Work/worktrees/$SESSION"
else
  # Interactive: we lay servers across panes of the current window.
  [ -n "${TMUX:-}" ] || die "Not inside a tmux session. Start/attach one, or pass a session name."
  WORKTREE=$(pwd)
  while [ "$WORKTREE" != "/" ] && [ ! -f "$WORKTREE/.env.worktree" ]; do
    WORKTREE=$(dirname "$WORKTREE")
  done
fi
[ -f "$WORKTREE/.env.worktree" ] ||
  die "No .env.worktree at $WORKTREE. Run this from inside a worktree, or pass a valid session name."

# --- Skip if the env is already up (unless --force) ---
# Treat the API or React port already LISTENING as "up" — re-running would wipe
# a live DB via `docker compose down -v`.
if ! $FORCE; then
  APP_PORT=$(grep -m1 '^APP_PORT=' "$WORKTREE/.env.worktree" | cut -d= -f2)
  REACT_UI_PORT=$(grep -m1 '^REACT_UI_PORT=' "$WORKTREE/.env.worktree" | cut -d= -f2)
  for port in "$APP_PORT" "$REACT_UI_PORT"; do
    [ -n "$port" ] || continue
    if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
      log "Local dev already up for $WORKTREE (port $port listening). Use --force to restart."
      exit 0
    fi
  done
fi

log "Starting local dev for worktree: $WORKTREE"

# --- Pick the target tmux window ---
# The window's initial/current pane is left as the spare shell; the 4 server
# panes are added to it, reproducing the 5-pane tiled layout.
if [ -n "$SESSION" ]; then
  tmux has-session -t "$SESSION" 2>/dev/null ||
    tmux new-session -d -s "$SESSION" -c "$WORKTREE" || die "failed to create session '$SESSION'"
  WIN=$(tmux new-window -d -t "$SESSION" -n LocalDev -c "$WORKTREE" -P -F '#{window_id}') ||
    die "failed to create LocalDev window in '$SESSION'"
else
  WIN=$(tmux display-message -p '#{window_id}')
fi

# Pane: docker compose (fresh start with volume wipe, scoped to this worktree's
# COMPOSE_PROJECT_NAME via .env.worktree). .env.local (LOCAL_ARTEMIS creds) is
# sourced only if present — not every worktree has it.
tmux split-window -h -t "$WIN"
tmux send-keys -t "$WIN" "cd $WORKTREE && set -a && source .env.worktree && [ -f service-api-go/.env.local ] && source service-api-go/.env.local; set +a && cd service-api-go && docker compose down -v --remove-orphans && docker compose up --build -d" C-m

# Pane: Go API via air (wait for docker)
tmux split-window -v -t "$WIN"
tmux send-keys -t "$WIN" "cd $WORKTREE && set -a && source .env.worktree && set +a && cd service-api-go && sleep 30s && task generate && air serve-graphql --pe" C-m

# Pane: React dev server
tmux split-window -v -t "$WIN"
tmux send-keys -t "$WIN" "cd $WORKTREE && set -a && source .env.worktree && set +a && cd react-ui && pnpm run dev" C-m

# Pane: LangServe API (Python via poetry). Pin the venv to Python 3.11 so the
# old langchain/httpx/psycopg pins resolve — the default python is too new.
# LANGSERVE_PORT/DATABASE_URL_APP come from .env.worktree (sourced in-pane).
tmux split-window -v -t "$WIN"
tmux send-keys -t "$WIN" "cd $WORKTREE/api-langserve && set -a && source ../.env.worktree && set +a && export GROQ_API_KEY= && export POSTGRESQL_URI=\$DATABASE_URL_APP && mise install python@3.11 && poetry env use \$(mise where python@3.11)/bin/python && (poetry install || { poetry lock && poetry install; }) && poetry run uvicorn app.server:app --host 0.0.0.0 --port \$LANGSERVE_PORT" C-m

# Even out the window now that it has all the server panes.
tmux select-layout -t "$WIN" tiled

log "Local dev panes started for $WORKTREE"
