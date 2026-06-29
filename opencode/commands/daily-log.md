---
description: Generate session log and copy to clipboard (xsel)
---

Generate a concise daily log of what was accomplished in this session.

Format requirements:
- Nested markdown bullet points
- Use 4-space indentation per level (Obsidian format)
- No nesting depth limit — nest as deep as needed (5+ levels fine) when it clarifies cause → fix → detail
- Group by task/feature; sub-bullets for root cause, key changes, decisions
- Include commit hashes if any commits were made
- Skip preamble/postamble — just the bullet list

Example:
- Fixed <task name>
    - Root cause: <brief>
    - <key change>
        - <deeper detail if needed>
            - <even deeper if it adds clarity>
    - Commit: <hash>

After generating the log:
1. Print the full log to stdout so the user can review it
2. Copy it to the clipboard by piping to `xsel -b` via a bash heredoc
3. Confirm it was copied
