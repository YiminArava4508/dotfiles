#!/usr/bin/env bash
# Sets a Claude Code work-status glyph on the containing tmux window.
# Called from Claude Code hooks (see ~/.claude/settings.json):
#   prompt | agent-start | agent-stop | stop | notify | end
#
# Window option @claude_status holds the styled glyph shown by
# window-status-format and the choose-tree bindings in tmux.conf.
# Pane options @claude_agents / @claude_stopped track state so the
# checkmark only appears once the main loop AND all subagents finished.

[ -n "$TMUX_PANE" ] || exit 0

WORKING="#[fg=yellow]✳"
DONE="#[fg=green]✔"
INPUT="#[fg=red]?"

glyph() { tmux set-option -w -t "$TMUX_PANE" @claude_status "$1" 2>/dev/null; }
pget()  { tmux show-options -pv -t "$TMUX_PANE" "$1" 2>/dev/null; }
pset()  { tmux set-option -p -t "$TMUX_PANE" "$1" "$2" 2>/dev/null; }

case "$1" in
  prompt)
    pset @claude_stopped 0
    glyph "$WORKING"
    ;;
  agent-start)
    n=$(pget @claude_agents)
    pset @claude_agents $(( ${n:-0} + 1 ))
    glyph "$WORKING"
    ;;
  agent-stop)
    n=$(( $(pget @claude_agents || echo 1) - 1 ))
    [ "$n" -lt 0 ] && n=0
    pset @claude_agents "$n"
    if [ "$n" -eq 0 ] && [ "$(pget @claude_stopped)" = "1" ]; then
      glyph "$DONE"
    fi
    ;;
  stop)
    pset @claude_stopped 1
    n=$(pget @claude_agents)
    if [ "${n:-0}" -gt 0 ]; then
      glyph "$WORKING"
    else
      glyph "$DONE"
    fi
    ;;
  notify)
    glyph "$INPUT"
    ;;
  end)
    tmux set-option -w -t "$TMUX_PANE" -u @claude_status 2>/dev/null
    tmux set-option -p -t "$TMUX_PANE" -u @claude_agents 2>/dev/null
    tmux set-option -p -t "$TMUX_PANE" -u @claude_stopped 2>/dev/null
    ;;
esac
exit 0
