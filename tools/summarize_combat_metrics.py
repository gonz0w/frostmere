"""Summarize local opt-in Godot combat records; never touches player saves."""
import argparse
import json
from pathlib import Path


def summarize(path):
    rows = []
    for number, line in enumerate(path.read_text().splitlines(), 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
            if row["schema"] != 1:
                raise ValueError("unsupported schema")
            rows.append(row)
        except (ValueError, KeyError, TypeError) as error:
            raise ValueError(f"Line {number}: {error}") from error
    print("# Combat playtest segments\n")
    print("Inactivity splits segments after 10 seconds; quiet tails and menu time are excluded. "
          "Disengagement is not victory. Shots without targets may be practice or misses. "
          "Gear and detailed restoration remain in the source JSON.\n")
    print("| Area | Build | End reason | Active seconds | Damage taken | Damage dealt | Kills | Healing draughts | Arrows | Rounds |")
    print("| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
    for row in rows:
        ammo = row["ammo"]
        values = [row["area"], row["start"]["archetype"], row["outcome"],
                  f'{row["active_seconds"]:.2f}', f'{row["damage_taken"]:.2f}',
                  f'{row["damage_dealt"]:.2f}', row["kills"],
                  row["consumables"].get("healing_draught", 0), ammo.get("arrow", 0),
                  ammo.get("station_round", 0) + ammo.get("hell_round", 0)]
        print("| " + " | ".join(str(value).replace("|", "\\|").replace("\n", " ") for value in values) + " |")
    print(f'\n{len(rows)} segments; {sum(row["outcome"] == "death" for row in rows)} deaths.')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=Path)
    args = parser.parse_args()
    try:
        summarize(args.log)
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.exit(1, f"Cannot summarize combat log: {error}\n")
