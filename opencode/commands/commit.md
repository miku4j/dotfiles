---
description: Stage all changes and create a semantic commit with description
---

Create a semantic commit for the current changes.

Steps:
1. Run `git status` and `git diff` (staged + unstaged) to understand what changed
2. If no changes, stop and tell the user
3. Stage all relevant changes with `git add -A`
4. Generate a semantic commit message with BOTH subject AND body:
   - Subject line: `<type>: <imperative summary>` under 72 chars
     - Types: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `style`, `perf`, `ci`, `build`, `revert`
   - Blank line
   - Body explaining WHAT changed and WHY (wrapped at 72 chars)
     - Reference root cause if fixing a bug
     - List key changes as bullet points if helpful
     - Mention file paths when relevant
5. Commit: `git commit -m "<subject>" -m "<body>"`
6. Show the result with `git log --format="%h %s%n%b" -1`

Follow git conventions from AGENTS.md.
