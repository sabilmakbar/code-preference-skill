#!/usr/bin/env bash
# Tests for scripts/sync-rules.sh, run against temporary guide and rules folders.
# Usage: tests/sync-rules.test.sh
set -euo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/sync-rules.sh"

# global, not local: the EXIT trap runs after the script body, when locals are gone
tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "${tmp_dir}"' EXIT
export CODE_STYLE_GUIDE_DIR="${tmp_dir}/guidelines" CODE_STYLE_RULES_DIR="${tmp_dir}/rules"
mkdir -p "${CODE_STYLE_GUIDE_DIR}"

fails=0
check() {
    local name="${1}"
    shift
    if "$@"; then
        echo "ok   ${name}"
    else
        echo "FAIL ${name}" >&2
        fails=$((fails + 1))
    fi
}

no_import() {
    ! grep -q '^@' "${1}"
}

echo "# Code style (Bash) v1" >"${CODE_STYLE_GUIDE_DIR}/code-style-bash.md"
echo "# Code style (Python)" >"${CODE_STYLE_GUIDE_DIR}/code-style-python.md"
out="$("${SCRIPT}")"
bash_rule="${CODE_STYLE_RULES_DIR}/code-style-bash.md"
check "builds both rules files" test -f "${bash_rule}" -a -f "${CODE_STYLE_RULES_DIR}/code-style-python.md"
check "bash rule has its paths" grep -q -F '  - "**/*.sh"' "${bash_rule}"
check "bash rule has the guide text" grep -q -F '# Code style (Bash) v1' "${bash_rule}"
check "bash rule has no import" no_import "${bash_rule}"
check "reports each refresh" test "$(grep -c refreshed <<<"${out}")" -eq 2

out="$("${SCRIPT}")"
check "second run is silent" test -z "${out}"

echo "# Code style (Bash) v2" >"${CODE_STYLE_GUIDE_DIR}/code-style-bash.md"
"${SCRIPT}" >/dev/null
check "guide edit reaches the rule" grep -q -F 'v2' "${bash_rule}"

echo "hand-written" >"${CODE_STYLE_RULES_DIR}/code-style-go.md"
rm "${CODE_STYLE_GUIDE_DIR}/code-style-python.md"
"${SCRIPT}" >/dev/null
check "orphan generated copy removed" test ! -e "${CODE_STYLE_RULES_DIR}/code-style-python.md"
check "hand-written file kept" test -f "${CODE_STYLE_RULES_DIR}/code-style-go.md"

echo "# Code style (Rust)" >"${CODE_STYLE_GUIDE_DIR}/code-style-rust.md"
echo "# Code style (Bash) v3" >"${CODE_STYLE_GUIDE_DIR}/code-style-bash.md"
status=0
"${SCRIPT}" >/dev/null 2>&1 || status=$?
check "unknown language exits 1" test "${status}" -eq 1
check "other guides still sync" grep -q -F 'v3' "${bash_rule}"

rm "${CODE_STYLE_GUIDE_DIR}"/*.md
check "no guides is fine" "${SCRIPT}"

if ((fails > 0)); then
    echo "${fails} test(s) failed" >&2
    exit 1
fi
echo "all passed"
