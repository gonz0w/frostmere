"""Deterministic original chiptune score and SFX. Requires numpy; no sampled assets."""
from pathlib import Path
import json, wave
import numpy as np
SR=22050
ROOT=Path(__file__).resolve().parents[1]/'assets/audio'
rng=np.random.default_rng(4917)
manifest={}
def waveform(f,t,kind):
 p=2*np.pi*f*t
 if kind=='bell': return np.sin(p)*np.exp(-t*2)+.3*np.sin(p*2.01)*np.exp(-t*5)
 if kind=='sine': return np.sin(p)
 out=np.zeros_like(t)
 for h in range(1,16):
  if f*h>SR*.44: break
  if kind=='tri': a=0 if h%2==0 else (-1)**((h-1)//2)/h**2
  elif kind=='pulse': a=np.sin(np.pi*h*.28)/h
  else: a=1/h
  out+=a*np.sin(p*h)
 return out*.65

def note(m,dur,kind='tri',gain=.15):
 t=np.arange(max(1,int(dur*SR)))/SR
 f=440*2**((m-69)/12)
 env=np.minimum(t/.018,1)*np.minimum((dur-t)/.09,1)
 if kind=='bell': env*=np.exp(-t*1.5)
 return waveform(f,t,kind)*np.maximum(env,0)*gain

def add(buf,a,start,pan=0):
 idx=(int(start*SR)+np.arange(len(a)))%len(buf)
 buf[idx,0]+=a*np.sqrt((1-pan)/2); buf[idx,1]+=a*np.sqrt((1+pan)/2)

def drum(kind):
 d={'kick':.23,'snare':.16,'hat':.065}[kind]; t=np.arange(int(SR*d))/SR
 if kind=='kick': return np.sin(2*np.pi*(48*t+6*(1-np.exp(-t*28))))*np.exp(-t*22)*.3
 noise=rng.uniform(-1,1,len(t)); noise=np.diff(noise,prepend=0)*.5
 return noise*np.exp(-t*(35 if kind=='snare' else 85))*(.16 if kind=='snare' else .07)

def save(name,buf,loop=False):
 peak=float(np.max(np.abs(buf))); buf=buf*(.78/max(peak,.001))
 n=min(66 if loop else 256,len(buf)//4)
 buf[:n]*=np.linspace(0,1,n)[:,None]; buf[-n:]*=np.linspace(1,0,n)[:,None]
 pcm=np.round(buf*32767).astype('<i2')
 path=ROOT/(('music/' if loop else 'sfx/')+name+'.wav')
 with wave.open(str(path),'wb') as w: w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
 manifest[name]={'seconds':round(len(buf)/SR,3),'peak':round(float(np.max(abs(buf))),4),'rms':round(float(np.sqrt(np.mean(buf**2))),4),'loop':loop}

def score(name,bpm,realm,battle):
 beat=60/bpm; bars=32; buf=np.zeros((round(bars*4*beat*SR),2))
 roots={'north':[50,46,53,48,50,46,48,45], 'crystal':[60,57,53,55,60,64,53,55], 'hell':[40,41,40,43,40,46,41,40]}[realm]
 motifs={'north':[[12,15,19,17,15,12,10,7],[7,12,14,15,19,17,14,12],[15,17,19,22,19,17,15,14],[12,10,7,10,14,12,7,0]],'crystal':[[12,16,19,23,24,23,19,16],[19,16,14,12,16,19,21,19],[24,23,19,16,17,21,19,16],[14,19,23,21,19,16,14,12]],'hell':[[0,0,12,1,0,7,6,1],[0,12,0,3,0,1,6,7],[0,0,1,0,6,0,3,1],[12,0,7,6,1,0,1,0]]}[realm]
 for bar in range(bars):
  root=roots[(bar//2)%8]; start=bar*4*beat
  chord=[0,4,7,11] if realm=='crystal' else [0,3,7,10] if realm=='north' else [0,7,12]
  for j,n in enumerate(chord): add(buf,note(root+n,4.1*beat,'tri',.055 if realm!='hell' else .027),start,(-.6+j*.4))
  for step in range(8 if battle or realm=='hell' else 4):
   at=start+step*(.5 if battle or realm=='hell' else 1)*beat
   bass=root-12+(12 if step%4==3 else 0)
   add(buf,note(bass,beat*(.36 if battle else .7),'saw' if realm=='hell' else 'tri',.16),at)
  motif=motifs[(bar//4)%4]
  for step in range(8):
   if not battle and step in [3,6]: continue
   pitch=root+motif[(step+bar%2*2)%8]+(12 if realm=='crystal' else 0)
   add(buf,note(pitch,beat*(.42 if battle else .8),'bell' if realm=='crystal' else 'pulse',.10 if battle else .065),start+step*.5*beat,-.16)
  if realm!='hell':
   for step in range(8): add(buf,note(root+12+chord[(step+bar)%len(chord)],beat*.23,'bell',.035),start+step*.5*beat,.55)
  for step in range(8):
   if battle or (realm=='hell') or step in [0,4]: add(buf,drum('hat')*(1 if battle else .3),start+step*.5*beat,.3)
   if step in [0,4] or (battle and step==7): add(buf,drum('kick')*(1 if battle else .38),start+step*.5*beat)
   if step in [2,6] and (battle or realm=='hell'): add(buf,drum('snare'),start+step*.5*beat,-.2)
 # Circular stereo echoes preserve tails at the loop boundary.
 dry=buf.copy()
 for n,g in [(1,.19),(2,.10),(3,.05)]: buf+=np.roll(dry[:,::-1],int(beat*.75*n*SR),axis=0)*g
 save(name,buf,True)
for args in [('wander',76,'north',False),('battle',132,'north',True),('aeralis',92,'crystal',False),('aeralis_battle',144,'crystal',True),('crucible',94,'hell',False),('crucible_battle',152,'hell',True)]: score(*args)
for name,notes,kind in [('interact',[72,79],'tri'),('loot',[72,76,79,84],'bell'),('quest',[62,65,69,74,77],'pulse'),('enchant',[72,79,84,88],'bell'),('heal',[60,64,67,72],'tri'),('portal',[48,55,62,69,76,83],'bell'),('error',[45,43],'pulse')]:
 buf=np.zeros((int(SR*(len(notes)*.09+.38)),2))
 for i,m in enumerate(notes): add(buf,note(m,.34,kind,.2),i*.09)
 save(name,buf)
for name in ['swing','hit','block','gun','bow','spell','step','forge','gather','death']:
 dur={'spell':.55,'death':.9,'step':.09,'gun':.18}.get(name,.28); t=np.arange(int(SR*dur))/SR
 noise=rng.uniform(-1,1,len(t)); decay=np.exp(-t*{'step':55,'gun':34,'death':5}.get(name,20))
 f={'swing':450,'hit':100,'block':1300,'gun':65,'bow':200,'spell':500,'step':95,'forge':1800,'gather':340,'death':110}[name]
 tone=np.sin(2*np.pi*(f*t+(180*t*t if name=='spell' else -f*.35*t*t/dur)))
 sig=(noise*(.75 if name in ['swing','gun','step','gather'] else .25)+tone*.65)*decay
 if name in ['forge','block']: sig+=np.sin(2*np.pi*f*1.43*t)*np.exp(-t*12)*.25
 save(name,np.column_stack([sig,sig]))
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Generated',len(manifest),'original audio assets;',round(sum(x['seconds'] for x in manifest.values()),1),'seconds')

# Keep the station extension and combined manifest in sync on a full rebuild.
if __name__ == '__main__':
 import subprocess, sys
 subprocess.run([sys.executable, str(Path(__file__).with_name('build_station_audio.py'))], check=True)

 subprocess.run([sys.executable, str(Path(__file__).with_name("build_combat_audio.py"))], check=True)
 subprocess.run([sys.executable, str(Path(__file__).with_name("build_intro_audio.py"))], check=True)
