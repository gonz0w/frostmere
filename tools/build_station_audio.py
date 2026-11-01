"""Original orbital-station loops, using the project's deterministic chip synth."""
from pathlib import Path
import ast, json
source=Path(__file__).with_name('build_audio.py')
module=ast.parse(source.read_text())
# Load only imports, definitions and initial constants; do not regenerate existing assets.
body=[]
for node in module.body:
    if isinstance(node, ast.For): break
    body.append(node)
ns={'__file__':str(source)}
exec(compile(ast.Module(body=body,type_ignores=[]),str(source),'exec'),ns)
np,SR=ns['np'],ns['SR']
for name,bpm,battle in [('station',88,False),('station_battle',136,True)]:
    beat=60/bpm; buf=np.zeros((round(32*4*beat*SR),2))
    roots=[45,48,41,43,45,52,48,43]
    for bar in range(32):
        root=roots[bar%8]; start=bar*4*beat
        for step in range(8):
            at=start+step*.5*beat
            ns['add'](buf,ns['note'](root-12,beat*.4,'pulse',.13),at)
            motif=[12,19,24,22,15,19,10,22]
            if battle or step%2==0: ns['add'](buf,ns['note'](root+motif[(step+bar)%8],beat*.38,'bell',.11 if battle else .065),at,(-.5 if step%2 else .5))
            ns['add'](buf,ns['drum']('hat')*(.75 if battle else .18),at,.3)
            if step in [0,4]: ns['add'](buf,ns['drum']('kick')*(1 if battle else .35),at)
            if battle and step in [2,6]: ns['add'](buf,ns['drum']('snare'),at,-.2)
        for interval in [0,7,14]: ns['add'](buf,ns['note'](root+interval,beat*4.1,'tri',.045),start)
    dry=buf.copy()
    for delay,gain in [(1,.22),(2,.11)]: buf+=np.roll(dry[:,::-1],int(beat*.75*delay*SR),axis=0)*gain
    ns['save'](name,buf,True)
manifest_path=ns['ROOT']/'manifest.json'
manifest=json.loads(manifest_path.read_text()); manifest.update(ns['manifest'])
manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(ns['manifest']))
