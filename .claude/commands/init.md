Session kickstart — get up to speed quickly.

1. Read `CLAUDE.md` for project context (already loaded automatically)
2. Read `.claude/file-index.md` for codebase map
3. Read `.claude/widgets.md` for reusable components
4. Run `git log --oneline -5` for recent changes
5. Run `git status --short` for uncommitted work
6. Run `flutter analyze` in a subagent — report summary only
7. Check if build_runner output is stale (compare model source vs generated file timestamps)

Output a concise session brief:
```
Project: Lifeboard (Flutter + Firebase + Riverpod)
Branch: {branch} | Uncommitted: {count} files
Recent: {last 3 commits}
Health: Analyze {ok/issues} | Codegen {fresh/stale}
Ready to work.
```
