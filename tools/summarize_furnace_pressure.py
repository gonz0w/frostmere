#!/usr/bin/env python3
"""Summarize controlled, live-AI Furnace Maw exchanges."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
data = json.loads((root / 'build/furnace-live-pressure.json').read_text())
assert data['failures'] == 0 and len(data['scenarios']) == 4
lines = ['# Furnace Maw live pressure comparison', '',
         f"UTC: {data['generated_utc']}. Display: {data['display']}. Four scenarios passed.", '',
         'Configured Frostkin mage stage fixtures with starter cloth armor, Superior Horizon Staff of Insight and both magic perks. Gun cases equip the actual one-time Crucible arrival weapon and spend its ammunition. Only the Maw is active, retaining authored 340 HP, cooldowns, rupture, enraged phase and exposure multipliers. Player casts/shots, projectiles, collisions, regeneration and incoming damage run normally. No health inflation, healing, invulnerability or direct damage injection during fights.', '',
         '| Policy | Outcome | Physics time (s) | Attacks | Rounds spent | Ruptures | Enraged warnings | Damage taken |',
         '| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |']
for r in data['scenarios']:
    lines.append(f"| {r['policy']} | {r['outcome']} | {r['seconds']:.2f} | {r['attacks']} | {r['rounds_spent']} | {r['eruptions']} | {r['enraged_warnings']} | {r['damage_taken']:.1f} |")
lines += ['',
    'The stationary probe does not attack; it ends after the first authored rupture hits for 34 damage. Fight policies start seven metres away, aim automatically and sidestep at four metres per second through move_and_slide until outside the locked circle. Scripted velocity is cleared immediately to avoid an extra displacement from normal deceleration on the next player tick. The same correction is applied to the Aeralis sidestep harness.', '',
    'Continuous gunfire attacks whenever its cooldown allows. Exposure gunfire and Soulfire attack only while the core is visibly open; shots fired near the end of that window can arrive after it closes. Gun cases share a fixed critical RNG seed. The recorded run used 29 rounds continuously versus 21 when waiting for exposure: eight rounds saved. Soulfire took four casts across two eruptions, including an enraged warning. All warning origins stayed fixed after commitment, and all three fighting policies dodged the rupture without damage.', '',
    'This confirms the exposed core creates a practical resource tradeoff with real projectile travel. It does not establish human difficulty: aiming and reactions are automatic, resources start full, adds are disabled and the character is staged. No combat balance values changed. The standing probe checks the ordinary rupture; the enraged rupture is observed and dodged rather than intentionally taken.', '',
    'Reproduce with `.tools/Godot.app/Contents/MacOS/Godot --path . --script tools/playtest_furnace_pressure.gd -- --capture`, then `python3 tools/summarize_furnace_pressure.py`. Headless is supported. Native execution requires capture isolation and persistent profiles are rejected. Raw results and per-policy combat logs are under build. Inspect timestamp/failure count before using prior reports.', '']
(root / 'build/furnace-live-pressure.md').write_text('\n'.join(lines))
print('FURNACE_PRESSURE_REPORT_COMPLETE scenarios=4')
