# code-preference-skill

A Claude Code skill that distills a personal, per-language code-style guide from your own
GitHub repos, compared against industry baselines (standards, formatters, linters, exemplar
repos), with conflicts resolved against you directly. The result is written into
[claude-memories](https://github.com/sabilmakbar/claude-memories)
(`guidelines/code-style-<lang>.md`), versioned and wired to load automatically for matching
files.

## Getting started (new machine)

```bash
git clone https://github.com/sabilmakbar/code-preference-skill.git ~/code-preference-skill
```

Add it as a plugin marketplace in `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "code-preference-skill@code-preference-skill": true
  },
  "extraKnownMarketplaces": {
    "code-preference-skill": {
      "source": {
        "source": "github",
        "repo": "sabilmakbar/code-preference-skill",
        "ref": "v0.2.0"
      }
    }
  }
}
```

Then start a new Claude Code session and invoke the skill (`distill-code-style`), or just ask
to build or refresh a style guide for a language.

## Layout

| What | Where |
|---|---|
| The skill | `skills/distill-code-style/` |
| Rules sync: rebuilds `~/.claude/rules/code-style-<lang>.md` from each guide | `scripts/sync-rules.sh` (test: `tests/sync-rules.test.sh`) |
| Hooks that run the sync at session start and after Write or Edit | `hooks/hooks.json` |
| Evals (case/prompt/graders per scenario) | `evals/` |
| Full-provenance working drafts, research, baselines | kept locally per the skill's paths table, not in this repo |
| The guide itself, provenance-stripped, per language | `claude-memories` (`guidelines/code-style-<lang>.md`) |

## Notes

- This repo holds the skill, the rules sync and its hooks, and the evals. Drafting work (full-provenance research,
  baseline comparisons) stays local, per the skill's own "Paths" table.
- Bump `version` in `.claude-plugin/plugin.json` and tag a release to ship an update; machines
  pick it up by bumping the `ref` in their `extraKnownMarketplaces` entry.
