#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path


NODE_RE = re.compile(r"^<([A-Za-z0-9_.\-]+)")
ARROW_RE = re.compile(r"\s->\s([^\s|]+)")


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate VisitAPI .dlg node jumps")
    parser.add_argument("--dlg", required=True, help="Dialogue .dlg path")
    args = parser.parse_args()

    path = Path(args.dlg)
    lines = path.read_text(encoding="utf-8").splitlines()
    nodes: set[str] = set()
    targets: list[tuple[int, str]] = []
    errors: list[str] = []

    for line_no, raw in enumerate(lines, start=1):
        line = raw.strip()
        if not line or line.startswith("#") or line.startswith("//"):
            continue
        node = NODE_RE.match(line)
        if node:
            nodes.add(node.group(1))
            continue
        if line.startswith("- "):
            match = ARROW_RE.search(line)
            if match:
                targets.append((line_no, match.group(1).strip()))
        elif line.startswith("->"):
            targets.append((line_no, line[2:].strip()))

    for line_no, target in targets:
        if target in {"@trade", "@tasks", "@services", "@start", "@close", "@leave"}:
            continue
        if target not in nodes:
            errors.append(f"{path.name}:{line_no}: target node '{target}' does not exist")

    if errors:
        print("VALIDATION FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print("VALIDATION OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
