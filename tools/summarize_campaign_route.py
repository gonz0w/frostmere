#!/usr/bin/env python3
"""Summarize the connected campaign audit without representing simulation as playtime."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
data = json.loads((ROOT / "build/campaign-route-audit.json").read_text())
rows = data["rows"]
assert data["schema"] == 1 and len(rows) == 45
lines = [
    "# Connected campaign progression and resource audit", "",
    f"Generated UTC: {data['generated_utc']}. {data['checks']} checks; three fresh builds, 15 checkpoints each.", "",
    "Normal quest actions, prerequisite gates, loot, required crafting, finite purchases, damage handling, training and save validation run in the engine. No story completion flags or campaign rewards are inserted. Each character carries its earned inventory and progress from Oldwatch to the homecoming heirloom.", "",
    "This is an automated progression audit with a numerical combat model, **not a human playthrough or measured fight duration**. Interactions are reached by repositioning; attacks apply runtime damage directly. Enemy AI, retaliation, collision aiming, projectile flight, blocking, criticals, finishers, travel time and optional quests are excluded. Special bosses remain closed; Prismwing fracture still runs through damage handling. No health, death or healing-pressure conclusion can be drawn.", "",
    "Frostkin warrior/ranger/mage, starter armor, unspent attributes and perks, no tempering. At each chapter boundary, equip the owned eligible weapon with the highest listed damage (not a full DPS optimizer). Ranger uses bows; mage keeps Emberbolt, including after learning later spells. Ranged attacks miss every fourth attempt within each chapter; melee always hits. Stamina/magicka regenerate during modeled attack intervals and explicit waits, with no between-encounter travel regeneration. Owned magicka draughts are consumed only when needed to cast. Arrow shortages model a forge visit; missing wood/iron is bought from finite shop stock with earned gold, with no stock refresh. Travel feasibility/time for these resupply visits is not simulated.", "",
    "| Build | Attack attempts | Extra regeneration wait (model seconds) | Magicka draughts used | Fletching batches | Supply gold spent | Final arrows |",
    "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
]
for build in ("warrior", "ranger", "mage"):
    group = [r for r in rows if r["build"] == build]
    assert len(group) == 15 and "last_furnace" in group[-1]["story_completed"]
    total = lambda key: sum(r[key] for r in group)
    lines.append(f"| {build} | {total('attempts')} | {total('regen_wait_seconds'):.1f} | {total('magicka_draughts')} | {total('fletching_batches')} | {total('supply_gold')} | {group[-1]['arrows_end']} |")
lines += ["", "## Chapter ledger", "", "Attack-cycle seconds and regeneration wait are numerical demand estimates, not elapsed gameplay time. JSON also retains material, consumable, equipment and completion snapshots.", "",
          "| Build | Chapter | Weapon used at entry | Attempts | Extra regen wait | Draughts | Arrow balance | Supply gold |",
          "| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |"]
for r in rows:
    lines.append(f"| {r['build']} | {r['chapter']} | {r['weapon']} | {r['attempts']} | {r['regen_wait_seconds']:.1f} | {r['magicka_draughts']} | {r['arrows_start']} → {r['arrows_end']} | {r['supply_gold']} |")
lines += ["", "## Findings and follow-up", "",
          "- All three selected routes earn the finale and their chosen heirloom; every chapter save is accepted by the real loader. Required story components are affordable from carried rewards without emergency recovery.",
          "- The ranger first needs extra arrows in Woodland Roots, after Pinehall. Thirteen fletching batches cost 289 gold in missing ingredients across the route; finite merchant stock covers this case. The later chapter reserves leave 107 arrows at homecoming. Verify the inconvenience of resupply on foot before adding more free ammunition.",
          "- Starter-spell mage demand includes substantial regeneration waiting. This intentionally excludes later spell strategies, perk spending and travel regeneration. Next compare Clear Channel/Kindled Mind and actual Sunlance, chain and Starfall hits in live encounters; do not treat this baseline as evidence for a blanket mana buff.",
          "- Melee has no modeled stamina wait without sprinting or guarding. This says nothing about survival or shield pressure; those costs require live fights.",
          "- Fixed stale finale bow/staff base-damage labels by reading the item catalog. Repeated world initialization now preserves input actions/events without duplicate registration errors.", ""]
(ROOT / "build/campaign-route-audit.md").write_text("\n".join(lines))
print("CAMPAIGN_REPORT_COMPLETE rows=45")
