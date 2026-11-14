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

The plugin generates `~/.claude/rules/code-style-<lang>.md` from each guide with `scripts/sync-rules.sh`: a
`paths:` header, then the full guide text. Its hooks run the script at session start and after every Write or
Edit, so a guide change reaches the rules file without a manual step. Never edit the rules file; edit the guide.

For a new language, add its globs to the `case` in `lang_paths()` in `scripts/sync-rules.sh` (the source files
plus the build or project file), then run the script once. A guide with no entry there makes the script exit 1
and name the language.

Why a copy: in a rules file, `paths:` scopes only the text written in that file. Tested 2026-11-14 with headless
sessions:

- an `@import` in a path-scoped rules file loads at session start, whatever files the session touches;
- a rules file that is a symlink to a file outside the rules folder did not load at all.

Do not write the loader by hand with an `@import` or a symlink.

## 4. Tool config

Put the user-level config the guide defines in `~/.claude/memory/guidelines/` (for example `ruff.toml`,
`shellcheckrc`), so it syncs with the guide, and symlink the tool's user-level path to it (for example
`~/.config/ruff/ruff.toml`, `~/.shellcheckrc`). Ask first: a user-level config affects every project without its
own config.

## Check with headless sessions

Run three `claude -p` sessions in an empty temp folder and ask each which rules from the guide it has (pick one
rule only that guide states):

1. no file read: the guide must not be in context;
2. after reading a matching file: the guide must be in context;
3. after reading another language's file: only that language's guide.

Log the files each session reads (`--output-format stream-json --verbose`), so a yes cannot come from the session
opening the guide itself.
