#!/usr/bin/env python3
"""Report controlled real-AI exchanges; do not interpret them as human difficulty."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
data = json.loads((root / "build/prismwing-live-playtest.json").read_text())
assert data["failures"] == 0 and len(data["scenarios"]) == 3, "Only summarize a successful complete run"
lines = [
    "# Prismwing active-AI mage follow-up", "",
    f"UTC: {data['generated_utc']}. Engine: {data['engine']}. Display: {data['display']}; renderer: {data['renderer']}.", "",
    "Three isolated fresh stage fixtures. Frostkin mage, starter cloth armor, Superior Horizon Staff of Insight; unspent attributes. The perked fixtures learn Kindled Mind/Clear Channel through eligibility checks after configuring level-five training. Aeralis prerequisites are staged; normal entry and attunement unlock Starfall. This is not campaign-earned progression.", "",
    "Prismwing retains its authored 240 HP, movement, attacks, cooldowns, fracture behavior and collision. Player physics, casts, projectiles, damage, regeneration and cooldowns all run normally. The other realm enemies are disabled. The player starts 16 metres away, stands still, aims automatically at the monster and waits for a real incoming hit before attacking on cooldown. No potions, invulnerability, direct damage injection, finishers or health resets during a fight. Attack windows below are physics-time measurements from the first cast decision to observed defeat, not human completion times.", "",
    "| Spell | Perks | Casts | Attack window (s) | Mana stall (s) | Damage taken | HP remaining | Magicka remaining | Hostile projectiles |",
    "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
]
for r in data["scenarios"]:
    assert r["outcome"] == "defeated"
    m = r["metrics"]
    lines.append(f"| {r['spell']} | {'Both' if r['perks'] else 'None'} | {r['casts']} | {r['seconds']-r['attack_started']:.2f} | {r['mana_wait_seconds']:.2f} | {m['damage_taken']:.1f} | {r['health_end']:.1f} | {r['magicka_end']:.1f} | {r['hostile_projectiles']} |")
lines += ["", "All three cases verify real incoming fan damage, more than two metres of AI movement, the wing-fracture transition, victory within the bounded run and recorded damage in both directions. Each case has a separate `build/prismwing-<spell>-<perks>.jsonl` combat log.", "",
          "The configured mage can sustain these single-boss exchanges from a full magicka pool. Perks and Starfall improve resource use, and earlier fracture/defeat can interrupt a subsequent attack. These observations do not establish that the boss is easy: aim is automated, only one enemy is active, no approach resources have been spent and the policy stays outside bite range. Misses, evasive movement, multi-enemy encounters and the close-range second phase remain separate playtests. No combat stats changed from this run.", "",
          "Regenerate with `.tools/Godot.app/Contents/MacOS/Godot --path . --script tools/playtest_prismwing.gd -- --capture`, then `python3 tools/summarize_prismwing_playtest.py`. Headless mode is also supported. Native mode requires capture isolation; the tool refuses persistent character/atlas state. Only dedicated build reports/logs are written. A failed run must not be mistaken for a successful prior report; inspect the JSON failure count and timestamp.", ""]
(root / "build/prismwing-live-playtest.md").write_text("\n".join(lines))
print("PRISMWING_REPORT_COMPLETE scenarios=3")
