#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_tpl_set(index_path: Path) -> set[str]:
    suffix = index_path.suffix.lower()
    if suffix == ".jsonl":
        values: set[str] = set()
        with index_path.open("r", encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if not line:
                    continue
                obj = json.loads(line)
                tpl = obj.get("tpl")
                if tpl:
                    values.add(tpl)
        return values
    data = load_json(index_path)
    return set(data.keys())


def to_list(value):
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def is_probable_tpl(value) -> bool:
    return isinstance(value, str) and len(value) == 24 and all(c in "0123456789abcdefABCDEF" for c in value)


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate quest target/reward TPL references")
    parser.add_argument("--quest", required=True, help="Quest json file path")
    parser.add_argument("--item-index", required=True, help="item_tpl_index.jsonl or json path")
    args = parser.parse_args()

    quest_path = Path(args.quest)
    data = load_json(quest_path)
    tpl_set = load_tpl_set(Path(args.item_index))
    errors: list[str] = []

    for outer_id, quest in data.items():
        if not isinstance(quest, dict):
            continue
        conditions = quest.get("conditions") or {}
        for stage in ("Started", "AvailableForFinish", "AvailableForStart", "Success", "Fail"):
            for condition in conditions.get(stage) or []:
                if not isinstance(condition, dict):
                    continue
                for tpl in to_list(condition.get("target")):
                    if is_probable_tpl(tpl) and tpl not in tpl_set:
                        errors.append(f"{quest_path.name}: quest '{outer_id}' target tpl '{tpl}' not found in item index")

        rewards = quest.get("rewards") or {}
        for stage in ("Started", "Success", "Fail"):
            for reward in rewards.get(stage) or []:
                if not isinstance(reward, dict):
                    continue
                for item in reward.get("items") or []:
                    if not isinstance(item, dict):
                        continue
                    tpl = item.get("_tpl")
                    if tpl and tpl not in tpl_set:
                        errors.append(f"{quest_path.name}: quest '{outer_id}' reward tpl '{tpl}' not found in item index")

    if errors:
        print("VALIDATION FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print("VALIDATION OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
