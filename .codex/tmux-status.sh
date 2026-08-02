#!/usr/bin/env bash
# Sets a Codex work-status glyph on the containing tmux window.
# Called from Codex lifecycle hooks (see ~/.codex/hooks.json):
#   prompt | agent-start | agent-stop | stop | notify | end
#
# Window option @codex_status holds the styled glyph shown by
# window-status-format and the choose-tree bindings in tmux.conf.
# Pane options @codex_agents / @codex_stopped track state so the
# checkmark only appears once the main loop and all subagents finish.

[ -n "${TMUX_PANE:-}" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

WORKING="#[fg=yellow]✳"
DONE="#[fg=green]✔"
INPUT="#[fg=red]?"

pget() { tmux show-options -pv -t "$TMUX_PANE" "$1" 2>/dev/null; }

# mkdir is an atomic, portable lock on both macOS and Linux. Codex may launch
# hooks concurrently when several subagents change state at the same time.
RUNTIME_DIR="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
LOCK_DIR="${RUNTIME_DIR%/}/codex-tmux-status-${TMUX_PANE#%}.lock"
attempt=0
until mkdir "$LOCK_DIR" 2>/dev/null; do
  attempt=$((attempt + 1))
  [ "$attempt" -lt 40 ] || exit 0
  sleep 0.05
done
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT HUP INT TERM

case "${1:-}" in
  prompt)
    tmux set-option -p -t "$TMUX_PANE" @codex_stopped 0 \; \
         set-option -w -t "$TMUX_PANE" @codex_status "$WORKING" 2>/dev/null
    ;;
  agent-start)
    n=$(pget @codex_agents)
    tmux set-option -p -t "$TMUX_PANE" @codex_agents $(( ${n:-0} + 1 )) \; \
         set-option -w -t "$TMUX_PANE" @codex_status "$WORKING" 2>/dev/null
    ;;
  agent-stop)
    n=$(pget @codex_agents)
    n=$(( ${n:-1} - 1 ))
    [ "$n" -lt 0 ] && n=0
    if [ "$n" -eq 0 ] && [ "$(pget @codex_stopped)" = "1" ]; then
      tmux set-option -p -t "$TMUX_PANE" @codex_agents 0 \; \
           set-option -w -t "$TMUX_PANE" @codex_status "$DONE" 2>/dev/null
    else
      tmux set-option -p -t "$TMUX_PANE" @codex_agents "$n" 2>/dev/null
    fi
    ;;
  stop)
    n=$(pget @codex_agents)
    if [ "${n:-0}" -gt 0 ]; then
      tmux set-option -p -t "$TMUX_PANE" @codex_stopped 1 \; \
           set-option -w -t "$TMUX_PANE" @codex_status "$WORKING" 2>/dev/null
    else
      tmux set-option -p -t "$TMUX_PANE" @codex_stopped 1 \; \
           set-option -w -t "$TMUX_PANE" @codex_status "$DONE" 2>/dev/null
    fi
    ;;
  notify)
    tmux set-option -w -t "$TMUX_PANE" @codex_status "$INPUT" 2>/dev/null
    ;;
  end)
    tmux set-option -w -t "$TMUX_PANE" -u @codex_status \; \
         set-option -p -t "$TMUX_PANE" -u @codex_agents \; \
         set-option -p -t "$TMUX_PANE" -u @codex_stopped 2>/dev/null
    ;;
esac
exit 0
