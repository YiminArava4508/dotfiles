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

## Word choice
Write in plain, direct language. Strip filler adverbs and adjectives; keep a
modifier only when removing it changes the meaning.
Banned adverbs: simply, easily, seamlessly, effortlessly, significantly,
essentially, basically, actually, definitely, certainly, truly, really,
carefully, gracefully, elegantly, quickly, robustly, dramatically, notably,
importantly, crucially.
Banned adjectives: powerful, robust, seamless, comprehensive, elegant,
sophisticated, cutting-edge, state-of-the-art, world-class, best-in-class,
game-changing, innovative, streamlined, holistic, scalable (unless describing
actual scaling behavior), crucial, vital, key, essential, perfect, amazing,
great, excellent.
Banned AI jargon and stock phrases: "delve", "leverage", "utilize" (say "use"),
"dive into", "in the realm of", "it's worth noting", "it's important to note",
"as an AI", "harness the power", "unlock", "elevate", "empower", "supercharge",
"a testament to", "landscape", "ecosystem" (unless literal), "journey",
"tapestry", "furthermore", "moreover", "additionally" as sentence openers.
Prefer verbs and nouns over modifiers: say what a thing does, not how great it
is. State facts without praise or hype.
Never use the "not X, but Y" contrast pattern ("it's not just a bug, it's a
design flaw", "this isn't about speed, it's about correctness"). Just state Y
directly.
Write like you'd talk: casual, spoken-sounding phrasing. Say "this breaks
because", "turns out", "the catch is", "heads up" instead of formal connectors
like "however", "therefore", "consequently", "thus".

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
