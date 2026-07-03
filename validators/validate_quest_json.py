#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path


QUEST_TOP_LEVEL_ALLOWED = {
    "QuestName",
    "_id",
    "canShowNotificationsInGame",
    "conditions",
    "description",
    "failMessageText",
    "name",
    "note",
    "traderId",
    "location",
    "image",
    "type",
    "isKey",
    "restartable",
    "instantComplete",
    "secretQuest",
    "startedMessageText",
    "successMessageText",
    "acceptPlayerMessage",
    "acceptanceAndFinishingSource",
    "declinePlayerMessage",
    "completePlayerMessage",
    "templateId",
    "rewards",
    "status",
    "KeyQuest",
    "changeQuestMessageText",
    "side",
    "progressSource",
    "rankingModes",
    "gameModes",
    "arenaLocations",
    "dialogueId",
    "sptStatus",
}

CONDITION_ALLOWED = {
    "id",
    "index",
    "compareMethod",
    "dynamicLocale",
    "globalQuestCounterId",
    "visibilityConditions",
    "parentId",
    "target",
    "value",
    "type",
    "status",
    "availableAfter",
    "dispersion",
    "onlyFoundInRaid",
    "oneSessionOnly",
    "isResetOnConditionFailed",
    "isNecessary",
    "doNotResetIfCounterCompleted",
    "dogtagLevel",
    "traderId",
    "maxDurability",
    "minDurability",
    "counter",
    "plantTime",
    "zoneId",
    "countInRaid",
    "completeInSeconds",
    "isEncoded",
    "conditionType",
    "areaType",
    "baseAccuracy",
    "containsItems",
    "durability",
    "effectiveDistance",
    "emptyTacticalSlot",
    "ergonomics",
    "height",
    "hasItemFromCategory",
    "magazineCapacity",
    "muzzleVelocity",
    "recoil",
    "weight",
    "width",
}

REWARD_ALLOWED = {
    "value",
    "id",
    "type",
    "index",
    "target",
    "items",
    "loyaltyLevel",
    "traderId",
    "isEncoded",
    "unknown",
    "findInRaid",
    "gameMode",
    "availableInGameEditions",
    "notAvailableInGameEditions",
    "illustrationConfig",
    "isHidden",
    "message",
}


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate VisitAPI/SPT quest JSON structure against the known 4.0.13 model boundary")
    parser.add_argument("--quest", required=True, help="Quest json file path")
    args = parser.parse_args()

    path = Path(args.quest)
    data = load_json(path)
    errors: list[str] = []

    if not isinstance(data, dict):
        print("VALIDATION FAILED")
        print(f"- {path.name}: top-level is not an object")
        return 1

    for outer_id, quest in data.items():
        if not isinstance(quest, dict):
            errors.append(f"{path.name}: quest '{outer_id}' is not an object")
            continue

        unknown_top = sorted(set(quest.keys()) - QUEST_TOP_LEVEL_ALLOWED)
        if unknown_top:
            errors.append(f"{path.name}: quest '{outer_id}' has unknown top-level fields: {', '.join(unknown_top)}")

        if quest.get("_id") != outer_id:
            errors.append(f"{path.name}: outer quest id '{outer_id}' does not match _id '{quest.get('_id')}'")

        template_id = quest.get("templateId")
        if template_id is not None and template_id != outer_id:
            errors.append(f"{path.name}: quest '{outer_id}' templateId '{template_id}' does not match _id")

        conditions = quest.get("conditions") or {}
        for stage in ("Started", "AvailableForFinish", "AvailableForStart", "Success", "Fail"):
            for condition in conditions.get(stage) or []:
                if not isinstance(condition, dict):
                    errors.append(f"{path.name}: quest '{outer_id}' has non-object condition in {stage}")
                    continue
                unknown_condition = sorted(set(condition.keys()) - CONDITION_ALLOWED)
                if unknown_condition:
                    errors.append(
                        f"{path.name}: quest '{outer_id}' condition '{condition.get('id')}' has unknown fields: {', '.join(unknown_condition)}"
                    )
                if condition.get("conditionType") == "HandoverItem" and "items" in condition:
                    errors.append(f"{path.name}: quest '{outer_id}' handover condition uses invalid 'items' field")

        rewards = quest.get("rewards") or {}
        for stage in ("Started", "Success", "Fail"):
            for reward in rewards.get(stage) or []:
                if not isinstance(reward, dict):
                    errors.append(f"{path.name}: quest '{outer_id}' has non-object reward in {stage}")
                    continue
                unknown_reward = sorted(set(reward.keys()) - REWARD_ALLOWED)
                if unknown_reward:
                    errors.append(
                        f"{path.name}: quest '{outer_id}' reward '{reward.get('id')}' has unknown fields: {', '.join(unknown_reward)}"
                    )

    if errors:
        print("VALIDATION FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print("VALIDATION OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
