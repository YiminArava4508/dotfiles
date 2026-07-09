#!/usr/bin/env bash
# Sets a Claude Code work-status glyph on the containing tmux window.
# Called from Claude Code hooks (see ~/.claude/settings.json):
#   prompt | agent-start | agent-stop | stop | notify | end
#
# Window option @claude_status holds the styled glyph shown by
# window-status-format and the choose-tree bindings in tmux.conf.
# Pane options @claude_agents / @claude_stopped track state so the
# checkmark only appears once the main loop AND all subagents finished.
#
# Hooks run async and in parallel (many subagents can start at once), so
# the counter read-modify-write is serialized with a per-pane flock.

[ -n "$TMUX_PANE" ] || exit 0

WORKING="#[fg=yellow]✳"
DONE="#[fg=green]✔"
INPUT="#[fg=red]?"

pget() { tmux show-options -pv -t "$TMUX_PANE" "$1" 2>/dev/null; }

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/claude-tmux-status-${TMUX_PANE#%}.lock"
flock -w 2 9 || exit 0

case "$1" in
  prompt)
    tmux set-option -p -t "$TMUX_PANE" @claude_stopped 0 \; \
         set-option -w -t "$TMUX_PANE" @claude_status "$WORKING" 2>/dev/null
    ;;
  agent-start)
    n=$(pget @claude_agents)
    tmux set-option -p -t "$TMUX_PANE" @claude_agents $(( ${n:-0} + 1 )) \; \
         set-option -w -t "$TMUX_PANE" @claude_status "$WORKING" 2>/dev/null
    ;;
  agent-stop)
    n=$(pget @claude_agents)
    n=$(( ${n:-1} - 1 ))
    [ "$n" -lt 0 ] && n=0
    if [ "$n" -eq 0 ] && [ "$(pget @claude_stopped)" = "1" ]; then
      tmux set-option -p -t "$TMUX_PANE" @claude_agents 0 \; \
           set-option -w -t "$TMUX_PANE" @claude_status "$DONE" 2>/dev/null
    else
      tmux set-option -p -t "$TMUX_PANE" @claude_agents "$n" 2>/dev/null
    fi
    ;;
  stop)
    n=$(pget @claude_agents)
    if [ "${n:-0}" -gt 0 ]; then
      tmux set-option -p -t "$TMUX_PANE" @claude_stopped 1 \; \
           set-option -w -t "$TMUX_PANE" @claude_status "$WORKING" 2>/dev/null
    else
      tmux set-option -p -t "$TMUX_PANE" @claude_stopped 1 \; \
           set-option -w -t "$TMUX_PANE" @claude_status "$DONE" 2>/dev/null
    fi
    ;;
  notify)
    tmux set-option -w -t "$TMUX_PANE" @claude_status "$INPUT" 2>/dev/null
    ;;
  end)
    tmux set-option -w -t "$TMUX_PANE" -u @claude_status \; \
         set-option -p -t "$TMUX_PANE" -u @claude_agents \; \
         set-option -p -t "$TMUX_PANE" -u @claude_stopped 2>/dev/null
    rm -f "${XDG_RUNTIME_DIR:-/tmp}/claude-tmux-status-${TMUX_PANE#%}.lock"
    ;;
esac
exit 0
