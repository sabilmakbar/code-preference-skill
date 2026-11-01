# Weighting repos by AI involvement

AI-written code shows the model's habits, not the user's. Weight it down so the guide describes the person.

## Signs

| Strength | Sign | Where to look |
|---|---|---|
| Marked | `Co-Authored-By: Claude` (or Copilot, Cursor, Codex, Gemini, a `[bot]` author) trailer | commit messages |
| Marked | "Generated with Claude Code", "🤖 Generated with" | commit messages, PR bodies |
| Suspected | `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md` in the repo | repo root |
| Suspected | spec, story or decision docs written for an agent; phase-tagged commits (`P10:`) | docs folder, commit subjects |
| Suspected | many commits in one day (a burst), long uniform commit bodies | commit dates and messages |
| Suspected | em-dashes and `# ====` banner blocks in comments, when the user's older code has neither | source files |

A sign is evidence, not proof. Show the user the signs per repo and let them correct the tier.

## Tiers

| Tier | Rule | Use |
|---|---|---|
| High | no signs, hand-written commit messages | rules come from here |
| High (fork or template) | the user's own commits in a fork, or a file started from a template, with no signs | diff against the upstream template; only what the user changed or added counts |
| Low | suspected signs only | counts only where it agrees with High-tier code |
| Lowest | marked signs | does not count, except to confirm a High-tier rule |
| Excluded | too little of the user's own code (one-line fork fixes, no own commits) | ignore |

Date matters: code from before the user started using AI tools is the strongest evidence. Ask when that was.
