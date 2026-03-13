Dump minimal project context for a new session. Do NOT explore files — just output this from memory/CLAUDE.md:

1. Read `CLAUDE.md` (already loaded)
2. Read `.claude/file-index.md` for file layout
3. Read `.claude/widgets.md` for reusable components
4. Run `git log --oneline -10` for recent changes
5. Run `git status --short` for uncommitted work

Output a concise session brief:
- What the project is (1 line)
- Current branch + uncommitted changes summary
- Recent commits (last 5, one line each)
- Any known blockers from memory
