#!/usr/bin/env bash
# List an account's repos with the signals needed to weight them by AI involvement.
# Usage: repo-inventory.sh <owner> [repo ...]   (reads through the GitHub API; clones nothing)
# Output: TSV on stdout. Tiering is a judgement call; see references/ai-signature-tiers.md.
set -euo pipefail

owner=${1:?usage: repo-inventory.sh <owner> [repo ...]}
shift
marked='Co-Authored-By: *(Claude|Copilot|Cursor|Codex|Gemini)|\[bot\]@|Generated with \[?Claude Code|🤖 Generated'

if [ $# -gt 0 ]; then
  repos=("$@")
else
  me=$(gh api user --jq .login)
  if [ "$me" = "$owner" ]; then path="user/repos?affiliation=owner&per_page=100"; else path="users/$owner/repos?per_page=100"; fi
  repos=()
  while IFS= read -r r; do repos+=("$r"); done < <(gh api "$path" --paginate --jq '.[].name')
fi

printf 'repo\tfork\tprivate\tlanguage\town_commits\tfirst\tlast\tmax_per_day\tai_marked_commits\tai_marked_prs\tagent_files\n'
for r in "${repos[@]}"; do
  meta=$(gh api "repos/$owner/$r" --jq '[.fork, .private, (.language // "-")] | @tsv')
  commits=$(gh api "repos/$owner/$r/commits?author=$owner&per_page=100" --paginate \
    --jq '.[] | [.commit.author.date[:10], (.commit.message | gsub("[\n\t]"; " "))] | @tsv' 2>/dev/null || true)
  if [ -n "$commits" ]; then
    n=$(printf '%s\n' "$commits" | wc -l | tr -d ' ')
    first=$(printf '%s\n' "$commits" | cut -f1 | sort | head -1)
    last=$(printf '%s\n' "$commits" | cut -f1 | sort | tail -1)
    burst=$(printf '%s\n' "$commits" | cut -f1 | sort | uniq -c | sort -rn | awk 'NR==1{print $1}')
    ai_c=$(printf '%s\n' "$commits" | grep -ciE "$marked" || true)
  else
    n=0 first=- last=- burst=0 ai_c=0
  fi
  ai_p=$(gh api "repos/$owner/$r/pulls?state=all&per_page=100" --paginate --jq '.[] | (.body // "") | gsub("\n"; " ")' 2>/dev/null \
    | grep -ciE "$marked" || true)
  files=$(gh api "repos/$owner/$r/contents" --jq '.[].name' 2>/dev/null \
    | grep -E '^(AGENTS\.md|CLAUDE\.md|\.cursorrules|\.claude|\.github)$' | paste -sd, - || true)
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$r" "$meta" "$n" "$first" "$last" "$burst" "$ai_c" "${ai_p:-0}" "${files:--}"
done
