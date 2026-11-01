# Wiring the guide into Claude

Why this layout: `~/.claude/memory/AGENTS.md` holds only external guidance sets, so a personal guide belongs on
the memory side. The guide is too large for one memory file, so a short memory carries the scope rule and points
to the guide, and a path-scoped rules file loads the guide only when Claude touches that language's files.

## 1. Strip provenance into the memory repo

```bash
python3 "${CLAUDE_PLUGIN_ROOT:-~/.claude/skills/distill-code-style}/scripts/strip-provenance.py" \
  ~/Documents/coding-style-preference/code-style-<lang>.md \
  ~/.claude/memory/guidelines/code-style-<lang>.md \
  --forbid <every repo name from the inventory, space separated>
```

It drops `Source:` and `Evidence:` paragraphs and any section titled "Evidence weighting", then fails if a
forbidden name is still there, or if a relative link or a `~/` path does not resolve from the output folder. Fix the remaining lines in the working draft, not in the output, and rerun.
Use the script rather than the Write tool: memory-kit's write guard treats every `.md` under
`~/.claude/memory/` as a memory file and refuses one without memory frontmatter.

Relative links to the working folder break after the move. Replace them with the full path.

## 2. Scope memory

One memory, `feedback_code_style`, for all languages. Create or amend it through `memory-kit:save-memory`.
It states:

- new project: follow the guide;
- existing repo with good standards: follow the repo, also for new files, modules and features;
- existing repo with poor standards: warn first and name the problems, then use the guide for new and changed
  code;
- throwaway files in `/tmp` or the scratchpad: exempt;
- the list of guides, by language.

## 3. Rules loader

`~/.claude/rules/code-style-<lang>.md`:

```markdown
---
paths:
  - "**/*.<ext>"
  - "**/<build or project file>"
---

Follow the personal code-style guide and its scope rule (memory `feedback_code_style`):
@~/.claude/memory/guidelines/code-style-<lang>.md
```

Use an import, not a symlink: the docs say a symlinked rules file that points outside the working folder can lose
its `paths:` behaviour.

## 4. Tool config

Install the user-level config the guide defines (for example `~/.config/ruff/ruff.toml`, `~/.clang-format`,
`~/.sqlfluff`) as a symlink to the working-folder copy. Ask first: a user-level config affects every project
without its own config.

## Manual check for the next session

1. Start a session in a repo with a `.<ext>` file and have Claude read it.
2. Ask whether the code-style guide for <language> is loaded. Expected: yes.
3. In a session that never touches such a file, the guide should not appear.
