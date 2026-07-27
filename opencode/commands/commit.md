---
description: Stage changes interactively, split into logical commits, and create semantic commits
---

Analyze the current working tree and help the user commit changes — never blindly stage everything.

Steps:

1. **Assess scope** — Run `git status --short` and `git diff` (staged + unstaged). If no changes, stop.

2. **Group files logically** — Parse `git status --short` output and group files by directory/module:
   - Root-level files or config → "Config / Root"
   - `sms-backend/src/modules/*/` → the module name (e.g., "Academic", "Finance", "HR")
   - `sms-backend/src/database/` → "Database"
   - `sms-backend/src/common/` → "Common / Shared"
   - `sms-frontend/app/*/` → "Frontend: <section>"
   - Files with no clear group → "Misc"
   
   For each group, list the files with a brief description of the change (from `git diff`).

3. **Always ask the user** — Present the grouped summary and ask:
   > "I found <N> changed files across <M> areas. Shall I commit them all as one batch, or split by group?"
   
   If the user says "all" or "one" → single batch commit (continue to step 5).
   If the user says "split" or specifies groups → process each group individually (step 4).
   If the user rejects entirely → stop.

4. **Per-group commit loop** — For each group the user wants committed:
   a. List the files: "Committing group: **<Group Name>** — <file1>, <file2>"
   b. If the group has only 1 file, check if that file's diff contains changes across multiple logical concerns (e.g., both a bug fix and a refactor). If yes → ask:
      > "file.ts has mixed changes. Use `git add -p` to stage relevant hunks?"
   c. Stage files: `git add <file1> <file2> ...`
   d. Generate a semantic commit message scoped to this group
   e. **Show the proposed message** and ask the user to confirm or edit
   f. On confirmation → `git commit -m "<subject>" -m "<body>"`
   g. Show result: `git log --format="%h %s%n%b" -1`

5. **Single batch** (if user chose "all"):
   a. Show the full file list and ask:
      > "Commit all <N> files as one batch with this message? [y/N/edit]"
   b. Generate a broader semantic commit message covering all changes
   c. On confirmation → `git commit -m "<subject>" -m "<body>"`

6. **After all commits** — Run `git log --format="%h %s%n%b" -<N>` to show results.

**Key rules:**
- NEVER run `git add -A` or `git add .` — always stage specific files
- NEVER commit without explicit user confirmation
- If the user declines a group, skip it (do not commit it)
- If hunks are mixed, prefer `git add -p` over splitting the file manually
- Follow semantic commit conventions from AGENTS.md
