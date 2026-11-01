# Guide template (one file per language)

Rule categories to cover. Skip a category the user's code has no evidence for, and say so in the guide rather
than inventing a rule.

```markdown
# Code style (<language>)

## When this guide applies

The scope rule is in the `feedback_code_style` memory.

## Rules

### Layout of a file        (header, imports or includes, constants, functions, entry point)
### Naming
### Functions and types      (signatures, type annotations, docstrings or doc comments)
### Comments
### Errors                   (what to catch, how to raise, where the top-level boundary is)
### Logging                  (levels, format, logger names; when plain printing is allowed)
### Paths and I/O
### Do not copy these older habits

## Linting and formatting    (tool, pinned version, full config block, how to run it, pre-commit)

## Examples
### 1. Single script
### 2. Several scripts in one folder
### 3. Package or library
```

Notes:

- Write each rule as an instruction ("Use `pathlib`"), with the reason when it is not obvious.
- Put the full config in the guide. A rule the linter enforces needs only a short line plus the rule code.
- Examples must run through the guide's own formatter and linter cleanly. Fix the example, not the config.
- Languages with no personal code yet (no High-tier evidence) get a short guide that points to the baseline
  file and says that personal rules come later.
