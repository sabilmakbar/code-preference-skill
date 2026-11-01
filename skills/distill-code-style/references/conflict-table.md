# Conflict table

Keep it in the working folder's baseline file, one table per language.

| # | Topic | User's habit (tier, example) | Industry practice (cited) | Team convention (if any) | Recommendation and why | Decision (date) |
|---|---|---|---|---|---|---|
| 1 | Line length | 150+ chars (High, `wiki_gen.py`) | 79/88/100; ruff default 88 ([ruff docs](https://docs.astral.sh/ruff/settings/#line-length)) | - | 100: fits the user's long names, still reviewable side by side | Decided 2026-10-29: 100 |

The team column is context, never evidence of the user's habit. Use it to show where work code will differ and
to let the user tune single choices against it.

How to run it:

- Present two to four rows at a time. Put the recommendation first, with the reason in one sentence.
- Mark a row Decided only on an explicit answer. "Keep it" is an answer; silence is not.
- If the user reverses a decision, edit the row and update the date. The guide follows the table, not the chat.
- Rows where habit and practice agree do not belong here; they go straight into the guide.
