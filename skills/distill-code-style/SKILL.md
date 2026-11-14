---
name: distill-code-style
description: Build or update a personal code-style guide for one or more programming languages by distilling the user's own repositories (weighting out AI-generated code), comparing it with industry baselines (standards, formatters, linters, exemplar repos, from web research or sources the user points to), resolving each conflict with the user, and wiring the result into Claude's memory so it loads when Claude touches matching files. Use this whenever the user wants Claude to "write code like me", wants coding preferences, conventions or lint config learned from their GitHub or local repos, asks to add a new language (C++, SQL, Go, TypeScript...) to their style guide, or wants to refresh an existing guide against newer code or standards, even if they never say "style guide". Not for prose, writing or documentation style, and not for formatting a single file.
---

# Distill a personal code-style guide

The goal is a guide Claude follows when writing code for this user: rules drawn from the code they wrote
themselves, checked against what the industry does, with every disagreement settled by the user rather than by
Claude. Most of the value comes from three habits that are easy to skip: weighting out AI-written code (it shows
the model's habits, not the user's), citing every industry claim, and asking the user one conflict at a time.

A run can cover several languages. Keep one guide per language so each loads only for its own files.

## Paths

| What | Where | In git? |
|---|---|---|
| Working folder: full-provenance drafts, research, baselines | `~/Documents/coding-style-preference/` (ask if the user wants another) | No |
| Per-language guide, provenance stripped | `~/.claude/memory/guidelines/code-style-<lang>.md` | Yes, claude-memories |
| Scope rule, one memory for all languages | `~/.claude/memory/feedback_code_style.md` | Yes |
| Loader, one per language, generated from the guide by `scripts/sync-rules.sh` | `~/.claude/rules/code-style-<lang>.md` | No |
| Tool config (ruff, clang-format, sqlfluff...) | the tool's user-level config path | Depends |

An older guide may exist as `guidelines/code-style.md`. Read it first and treat it as the current state; propose
renaming it to the per-language form instead of creating a duplicate.

## Steps

Each step ends with a check. Do not start the next step until its check passes, because later steps build on
earlier output and a wrong inventory poisons every rule drawn from it.

1. **Scope.** Ask: which languages, which sources (personal and work GitHub accounts, forks with real
   contributions, local folders), and where baselines come from (web research, repos or style guides the user
   names, or both). Check: the user confirms the source list and the language list.

2. **Access.** Ask approval for each scope separately, for example "read private repos of account X through the
   API". Read through `gh api` or the local filesystem; do not clone unless the user agrees. If a `gh auth switch`
   is needed, switch back to the original account at the end and say so. Never write a token to a file or
   pass one on a command line. Check: `gh auth status` shows the original account active.

3. **Inventory and weight.** Run `scripts/repo-inventory.sh <owner> [repo...]` for each account. It lists repos,
   the user's own commit counts and dates, AI signatures in commits and PR bodies, agent instruction files, and
   commit bursts. Assign tiers with `references/ai-signature-tiers.md`. Check: show the tier table to the user
   and get it confirmed before drawing any rule from it.

4. **Extract.** Personal rules come only from code the user wrote. Teammates' code, AI-written code and copied
   examples show someone else's habits, so they never become a "your style" rule. Read High-tier repos first,
   then the user's own commits in forks. When a file was started from a template (a Hugging Face loader, a
   project template, a fork's upstream), fetch that template and diff the user's file against it: only what the
   user changed or added is evidence. Lower tiers count only where they agree with High-tier code. Group the
   rules by the categories in `references/guide-template.md`, and list old habits not to copy. Check: every rule
   names at least one High-tier example in the working draft.

5. **Baseline.** Research it fresh on every run, because tools, versions and standards move. For each language,
   collect the standard (PEPs, ISO and committee papers, vendor reference), the main formatter and linter with
   their current versions, the docstring or comment convention, and the conventions of two or three popular,
   well-maintained repos in that language. Add any sources the user names. A baseline file from an earlier run is
   a list of things to re-check, not a source. Cite each claim beside it. Check: no uncited claim, and every tool
   version was checked on this run.

6. **Resolve conflicts.** Build the table in `references/conflict-table.md`: the user's habit, industry practice,
   the team convention when one exists, and a recommendation. A team convention is extra input, not a source of
   personal rules: it shows where work code will differ, and the user can tune single choices against it
   (parentheses, indentation, comment style). Present the rows a few at a time and let the user decide each. A
   decision the user reverses later replaces the old one; record the date. Check: every row is marked Decided.

7. **Write the guide.** One file per language from `references/guide-template.md`: scope pointer, rules, tool
   config, three examples (single script, several scripts in one folder, package or library). Run the examples
   through the language's formatter and linter and a syntax check. Check: the examples pass with the guide's
   own config.

8. **Check overlap.** Compare the guide with `~/.claude/memory/AGENTS.md`, the `feedback_*` memories and any
   CLAUDE.md. List duplicates and conflicts and let the user pick one home for each. Check: the list is empty or
   every item has a decision.

9. **Wire it in.** Follow `references/wiring.md`: strip provenance with `scripts/strip-provenance.py`, update the
   scope memory through the `memory-kit:save-memory` skill, add the language's globs to `scripts/sync-rules.sh`
   and run it, install tool config.
   Check: the strip script exits 0 (it also fails on links and `~/` paths that do not resolve from the guide's
   new folder), and the headless-session check in `references/wiring.md` passes.

10. **Commit.** Ask separately to track new files, to commit, and to push to claude-memories. Never push without
    a yes for that push.

## Working with the user

- Questions that need a decision go one topic at a time, with your recommendation first and the reason.
- When the user's habit conflicts with a standard, say which one you would pick and why, then let them choose.
  Do not silently prefer the standard: the guide is theirs.
- The guide combines two things only: the user's own code and current best practice. Everything else (team
  code, earlier guides, examples) is context for questions, not a source of rules.
- Keep private repo names, work repo names and evidence tables out of anything that leaves the working folder.
