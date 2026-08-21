# CLAUDE.md - Global instructions

Personal instructions for Claude Code, applied at the start of every session in
every directory. Project-specific rules belong in a `CLAUDE.md` inside that repo.

## Working style
Never use em dashes in any output, including prose, code comments, and commit messages.
Format chat responses for scanning, not reading: lean on bullet points, bolded
lead phrases, and numbered steps. Cap paragraphs at 1-2 sentences. Never emit a
wall of prose; if an explanation has more than two parts, it's a list.
For non-trivial or multi-step work, brainstorm and write a spec/plan before
coding. Keep specs and plans under docs/superpowers/.

## Code
Don't add verbose comments when coding, don't bloat the files with comments, only add comments when the logic is obscure
Match existing convention as much as possible, always reuse existing components if possible
Write tests first (TDD): a failing test, then the implementation, then green.
Never nest ternaries. One level is fine; a ternary whose branch is another
ternary is not. Use early returns in a small named function, or if/else
assigning to a variable. This applies to JSX branches too.
For CSS and design work, never use inline styles; use the project's styling system (Tailwind, theme tokens, stylesheets).

## Workflow
When creating commits, never mention Claude, Claude Code, or AI, and never add
"Generated with" or "Co-Authored-By: Claude" trailers.
Before creating a PR, run a code review once and fix all medium and higher
findings. Fix small findings only when the fix is not a big change.
Before claiming a task done or committing, run the project's tests and typecheck
and confirm they pass.
When opening a PR, always create a new PR; never reopen a previously closed PR,
even one referenced by the branch, commit, or ticket.
Keep PR descriptions extremely concise: a 1-2 sentence summary of what changed,
plus a short "Why" line only when the justification isn't obvious. No test
plans, no file-by-file walkthroughs, no headers/sections, no bullet lists
restating the diff. Aim for under 10 lines total.
Do ticket work in a dedicated git worktree + tmux session (new-session.sh), one
ticket at a time.

## Environment
Projects live under ~/Work and ~/git/matthewsreis. This machine runs Arch Linux
with Hyprland (omarchy).
For Node/TypeScript projects use pnpm (pnpm test, pnpm typecheck, pnpm start).
Tickets come from Linear (eng-* slugs) and Shortcut (sc-* slugs).
