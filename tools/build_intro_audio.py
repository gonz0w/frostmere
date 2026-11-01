"""Original deterministic opening music and ward cues; no samples or dependencies."""
from array import array
from pathlib import Path
import json
import math
import random
import struct
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / "assets/audio"


def write(name, left, right, loop):
    peak = max(max(abs(x) for x in left), max(abs(x) for x in right))
    gain = (0.48 if loop else 0.62) / max(peak, 0.001)
    pcm = bytearray()
    energy = 0.0
    for a, b in zip(left, right):
        a *= gain; b *= gain
        energy += a*a + b*b
        pcm.extend(struct.pack("<hh", round(a*32767), round(b*32767)))
    path = ROOT / ("music" if loop else "sfx") / (name + ".wav")
    with wave.open(str(path), "wb") as out:
        out.setnchannels(2); out.setsampwidth(2); out.setframerate(RATE); out.writeframes(pcm)
    return {"seconds": len(left)/RATE, "peak": round(peak*gain, 4),
            "rms": round(math.sqrt(energy/(len(left)*2)), 4), "loop": loop}


def score():
    # Eight slow six-second phrases: D minor, a distant flat second, then home.
    duration = 48
    size = RATE * duration
    left = array("d", [0]) * size; right = array("d", [0]) * size
    notes = [50, 57, 53, 60, 51, 58, 53, 57]
    for phrase, note in enumerate(notes):
        for voice, offset in enumerate([0, 7, 12]):
            frequency = 440 * 2 ** ((note+offset-69)/12)
            for i in range(RATE*8):
                t = i/RATE
                envelope = min(t/1.5, 1) * max(0, 1-t/8)**2
                phase = math.tau*frequency*t
                tone = (math.sin(phase) - math.sin(phase*3)/9 + math.sin(phase*5)/25)
                value = tone*envelope*(0.13 if voice == 0 else 0.06)
                index = (phrase*RATE*6 + i) % size
                left[index] += value * (0.65 if voice == 1 else 1)
                right[index] += value * (0.65 if voice == 2 else 1)
        # Sparse, rounded bell notes retain the old-school synth character.
        for i in range(RATE*4):
            t = i/RATE; frequency = 440*2**((note+24-69)/12)
            value = (math.sin(math.tau*frequency*t)+0.2*math.sin(math.tau*frequency*2*t))*math.exp(-t*1.7)*min(t/.035,1)*0.09
            index = (phrase*RATE*6+RATE*3+i) % size
            left[index] += value; right[(index+int(.18*RATE)) % size] += value*.8
    # Integer-cycle sub drone wraps continuously; no sharp percussion.
    for i in range(size):
        t = i/RATE
        drone = .045*math.sin(math.tau*round(36.708*duration)*t/duration)
        fade = min(1, i/(RATE*.04), (size-1-i)/(RATE*.04))
        left[i] = (left[i]+drone)*fade; right[i] = (right[i]+drone)*fade
    return left, right


def cue(name, duration):
    rng = random.Random(7221); phase = 0.0; noise = 0.0
    samples = array("d")
    for i in range(round(RATE*duration)):
        t = i/RATE; u = t/duration
        noise = noise*.96 + rng.uniform(-1, 1)*.04
        if name == "ward_approach":
            phase += math.tau*(49-13*u)/RATE
            signal = .4*math.sin(phase)+.13*math.sin(phase*1.5)+noise*.35
            envelope = min(t/.35, 1)*max(0, 1-u)**.6
        else:
            signal = sum(math.sin(math.tau*f*t)*gain for f, gain in [(146.83,.3),(220,.12),(293.66,.08)])
            envelope = min(t/.045,1)*math.exp(-t*2)*min((duration-t)/.12,1)
        samples.append(signal*envelope)
    return samples, array("d", samples)


if __name__ == "__main__":
    manifest_path = ROOT / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    manifest["intro"] = write("intro", *score(), True)
    for name, duration in [("ward_approach", 2.8), ("ward_holds", 1.8)]:
        manifest[name] = write(name, *cue(name, duration), False)
    manifest_path.write_text(json.dumps(manifest, indent=2)+"\n")
    print("Generated original 48-second opening loop and two ward cues")
