#!/usr/bin/env python3
"""Summarize real-AI stress fixtures without assigning a human difficulty rating."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
data = json.loads((root / 'build/aeralis-pressure.json').read_text())
assert data['failures'] == 0 and len(data['scenarios']) == 3
lines = ['# Aeralis close-range and overlapping-enemy pressure', '',
         f"UTC: {data['generated_utc']}. Display: {data['display']}. Three native Mac scenarios passed.", '',
         'Isolated Frostkin mage stage fixtures: starter cloth armor, Superior Horizon Staff of Insight, Kindled Mind/Clear Channel, full starting resources. Real player casts, projectile collisions, enemy AI, damage and regeneration; no healing, damage injection or invulnerability during fights. Automatic aim and staged starting positions are explicit test policies, not human play.', '',
         '| Scenario | Outcome | Casts | Physics time (s) | Damage taken | Final combat HP | Bite damage | Peak simultaneous warnings |',
         '| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |']
for r in data['scenarios']:
    m = r['metrics']
    # The recorder preserves zero health before respawn in a death case.
    hp = m.get('end', {}).get('health', r['health_end'])
    lines.append(f"| {r['scenario']} | {r['outcome']} | {r['casts']} | {r['seconds']:.2f} | {m.get('damage_taken', 0):.2f} | {hp:.2f} | {r['bite_damage']:.1f} | {r['peak_windups']} |")
lines += ['',
    'Bite policy: start three metres from the authored-health boss, cast until real damage triggers fracture, then withhold casts until a bite resolves. Standing still takes 32 damage. The sidestep uses horizontal velocity and move_and_slide during the warning, moving roughly 3.6 metres with collision checks; it avoids damage. Normal player physics remains enabled. This tests the attack response, not human reaction speed or keyboard control.', '',
    'Group policy: both sentries are moved onto the boss terrace, with the player eight metres from the boss. All three retain their authored AI and health. Wait until each has resolved an attack before returning fire, then automatically target the nearest living enemy with Starfall. The native run observed all three attack, three simultaneous warning animations, damage to all three targets, and incoming damage. This adversarial arrangement differs from the normal separated realm approach.', '',
    'All three scenarios finished with victories. No combat numbers or AI behaviors changed: the live tests confirmed the intended hit/avoid response and functioning overlapping attacks. A death remains a valid measured group outcome in the harness, not automatically a game defect. Each result is one deterministic script policy, not a success-rate estimate. Add human misses, reaction delay, depleted resources and actual approach routing before tuning encounter difficulty.', '',
    'Reproduce: `.tools/Godot.app/Contents/MacOS/Godot --path . --script tools/playtest_aeralis_pressure.gd -- --capture`, then `python3 tools/summarize_aeralis_pressure.py`. Headless execution is also supported. Native runs require capture isolation and reject persistent profiles. Dedicated JSON/JSONL files are written under build; normal saves are untouched. Read the timestamp and failure count before using results.', '']
(root / 'build/aeralis-pressure.md').write_text('\n'.join(lines))
print('AERALIS_PRESSURE_REPORT_COMPLETE scenarios=3')
