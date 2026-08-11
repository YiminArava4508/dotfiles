#!/usr/bin/env bash
# PreToolUse hook: block em dashes (U+2014) and en dashes (U+2013) in outgoing
# PR / issue comment text, so review replies always match the no-dash rule in
# CLAUDE.md regardless of which session or subagent posts them.
#
# Covers:
#   - Bash `gh` commands (gh pr comment, gh api graphql reply bodies,
#     gh pr review --body, gh pr edit --body, etc.)
#   - Linear MCP comment tools (save_comment, save_diff_comment)
#   - Shortcut MCP comment tools (stories/epics create-comment)
#
# On a match it denies the tool call and tells the model to rewrite without the
# dash. Any non-match exits 0 and lets the call through.

input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // ""')"

case "$tool" in
  Bash)
    text="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"
    ;;
  *save_comment|*save_diff_comment|*create-comment|*create_comment)
    text="$(printf '%s' "$input" | jq -r '[.tool_input.body, .tool_input.text, .tool_input.comment] | map(select(. != null)) | join("\n")')"
    ;;
  *)
    exit 0
    ;;
esac

if printf '%s' "$text" | grep -q $'—\|–'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "This text contains an em dash (—) or en dash (–). Per CLAUDE.md, never use them in any output. Rewrite the comment/body with commas, colons, parentheses, or separate sentences, then retry."
    }
  }'
  exit 0
fi

exit 0
