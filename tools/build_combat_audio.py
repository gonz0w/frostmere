"""Original deterministic combat cues; standard library only, no sampled audio."""
from pathlib import Path
import json
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'assets/audio'
RATE = 22050
CUES = {'finish_shell': .55, 'finish_crystal': .7, 'finish_furnace': .85, 'root_warning': .75, 'brine_warning': .65, 'ash_warning': .85,
        'solar_warning': .8, 'power_impact': .32, 'step_grass': .18, 'step_snow': .22, 'step_stone': .14, 'step_wood': .2, 'step_metal': .24}

def synth(name, duration):
    rng = random.Random(4917)
    phase = 0.0
    samples = []
    for i in range(round(RATE * duration)):
        t = i / RATE
        u = t / duration
        noise = rng.uniform(-1, 1)
        if name == 'finish_crystal':
            signal = .12*noise*math.exp(-t*35)
            for j, frequency in enumerate([1568, 2349, 3136, 1865]):
                delay = j*.038
                if t >= delay:
                    age = t-delay
                    signal += .22*math.sin(2*math.pi*frequency*age)*math.exp(-age*(9+j*2))
        elif name == 'finish_shell':
            phase += 2*math.pi*(65+150*math.exp(-t*25))/RATE
            signal = .48*math.sin(phase)*math.exp(-t*12)
            for delay in [0, .045, .095]:
                if t >= delay: signal += .26*noise*math.exp(-(t-delay)*55)
        elif name == 'finish_furnace':
            phase += 2*math.pi*(38+100*math.exp(-t*12))/RATE
            signal = (.5*math.sin(phase)+.22*noise)*math.exp(-t*6)
            signal += .14*math.sin(2*math.pi*173*t)*math.exp(-t*13)
        elif name.startswith('step_'):
            if name == 'step_wood':
                signal = (.5*math.sin(2*math.pi*115*t)+.2*math.sin(2*math.pi*238*t)+.12*noise)*math.exp(-t*22)
            elif name == 'step_metal':
                signal = (.35*math.sin(2*math.pi*420*t)+.22*math.sin(2*math.pi*691*t)+.16*noise*math.exp(-t*40))*math.exp(-t*19)
            elif name == 'step_stone':
                signal = (.45*math.sin(2*math.pi*155*t)+.35*noise)*math.exp(-t*38)
            elif name == 'step_snow':
                signal = noise*(.4+.2*math.sin(t*140))*math.exp(-t*12)
            else:
                signal = (.3*noise+.2*math.sin(2*math.pi*75*t))*math.exp(-t*22)
        elif name == 'root_warning':
            frequency = 88 - 28*u + 5*math.sin(t*29)
            phase += 2*math.pi*frequency/RATE
            signal = .6*math.sin(phase)+.2*math.sin(phase*2.03)+.06*noise
        elif name == 'brine_warning':
            frequency = 170 + 180*(.5+.5*math.sin(t*35))
            phase += 2*math.pi*frequency/RATE
            signal = math.sin(phase)*(.25+.25*math.sin(t*52))+.07*noise
        elif name == 'ash_warning':
            phase += 2*math.pi*(65+35*u)/RATE
            signal = (.18+.3*u)*noise+.22*math.sin(phase)+.12*math.sin(phase*1.5)
        elif name == 'solar_warning':
            phase += 2*math.pi*(180+650*u*u)/RATE
            signal = .4*math.sin(phase)+.17*math.sin(phase*2)+.08*math.sin(phase*3)
        else:
            phase += 2*math.pi*(45+110*math.exp(-t*35))/RATE
            signal = (.65*math.sin(phase)+.3*noise*math.exp(-t*25))*math.exp(-t*10)
        envelope = min(1, t/.018, (duration-t)/.055)
        samples.append(signal*max(0,envelope))
    peak = max(abs(x) for x in samples)
    ceiling = .45 if name.startswith("finish_") else .62
    return [x*ceiling/max(peak,.001) for x in samples]

def main():
    path = ROOT/'manifest.json'
    manifest = json.loads(path.read_text())
    for name, duration in CUES.items():
        samples = synth(name, duration)
        pcm = b''.join(struct.pack('<hh', round(x*32767), round(x*32767)) for x in samples)
        with wave.open(str(ROOT/'sfx'/f'{name}.wav'), 'wb') as out:
            out.setnchannels(2); out.setsampwidth(2); out.setframerate(RATE); out.writeframes(pcm)
        manifest[name] = {'seconds': round(len(samples)/RATE,3), 'peak': round(max(abs(x) for x in samples),4),
                          'rms': round(math.sqrt(sum(x*x for x in samples)/len(samples)),4), 'loop': False}
    path.write_text(json.dumps(manifest, indent=2)+'\n')
    print('Generated', len(CUES), 'original combat and footstep cues')

if __name__ == '__main__':
    main()
