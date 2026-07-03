#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path


QUEST_REQUIRED_LOCALE_SUFFIXES = [
    "name",
    "description",
    "note",
    "startedMessageText",
    "successMessageText",
    "failMessageText",
    "acceptPlayerMessage",
    "declinePlayerMessage",
    "completePlayerMessage",
    "changeQuestMessageText",
]


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate quest locale files")
    parser.add_argument("--quest", required=True, help="Quest json file path")
    parser.add_argument("--locale", action="append", default=[], help="Locale file(s), repeat this flag")
    args = parser.parse_args()

    quest_data = load_json(Path(args.quest))
    locale_paths = [Path(p) for p in args.locale]
    locale_data = {p.name: load_json(p) for p in locale_paths if p.exists()}
    errors: list[str] = []

    for quest_id, quest in quest_data.items():
        for locale_name, data in locale_data.items():
            for suffix in QUEST_REQUIRED_LOCALE_SUFFIXES:
                key = f"{quest_id} {suffix}"
                if key not in data:
                    errors.append(f"{locale_name}: missing locale key '{key}'")

        for condition in (quest.get("conditions", {}).get("AvailableForFinish") or []):
            cid = condition.get("id")
            if cid and condition.get("conditionType") == "HandoverItem":
                for locale_name, data in locale_data.items():
                    if cid not in data:
                        errors.append(f"{locale_name}: missing handover condition key '{cid}'")

    if errors:
        print("VALIDATION FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print("VALIDATION OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
