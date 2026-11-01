#!/usr/bin/env python3
"""Copy a code-style guide without its provenance, and fail if a forbidden name survives.

Drops paragraphs that start with "Source:" or "Evidence:" and any section titled "Evidence weighting".
Writes the output only when no forbidden name is left, so a leak never reaches the memory repo, and only
when every relative link and `~/` path resolves from the output folder, since the guide moves folders.
"""

import argparse
import re
import sys
from pathlib import Path


def strip(text: str) -> str:
    """Remove provenance paragraphs and the evidence-weighting section."""
    text = re.sub(r"^#{2,6} Evidence weighting\n.*?(?=^#{1,2} |\Z)", "", text, flags=re.M | re.S)
    text = re.sub(r"^(Source|Evidence):.*?(?:\n\n|\Z)", "", text, flags=re.M | re.S)
    return re.sub(r"\n{3,}", "\n\n", text)


def broken_paths(text: str, base: Path) -> list[str]:
    """List relative links and `~/` paths that do not exist, skipping placeholders like `<lang>`."""
    found = []
    for i, line in enumerate(text.splitlines(), 1):
        links = [base / t for t in re.findall(r"\]\(([^)#\s]+)\)", line) if "://" not in t]
        homes = [Path(t).expanduser() for t in re.findall(r"`(~/[^`\s]+)`", line)]
        found += [
            f"{i}: {p}" for p in links + homes if not re.search(r"[<*{]", str(p)) and not p.exists()
        ]
    return found


def main() -> None:
    """Strip the input guide, check it, and write the output."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("src", type=Path)
    parser.add_argument("dst", type=Path)
    parser.add_argument(
        "--forbid", nargs="*", default=[], help="names that must not appear in the output"
    )
    args = parser.parse_args()

    text = strip(args.src.read_text())
    leaks = [
        f"{i}: {name}: {line.strip()}"
        for i, line in enumerate(text.splitlines(), 1)
        for name in args.forbid
        if name in line
    ]
    if leaks:
        sys.exit("forbidden names left (fix the draft, then rerun):\n" + "\n".join(leaks))
    broken = broken_paths(text, args.dst.parent)
    if broken:
        sys.exit("paths that do not resolve from the output folder:\n" + "\n".join(broken))
    args.dst.parent.mkdir(parents=True, exist_ok=True)
    args.dst.write_text(text)
    print(f"wrote {args.dst} ({len(text)} chars)")  # noqa: T201 - final output


if __name__ == "__main__":
    main()
