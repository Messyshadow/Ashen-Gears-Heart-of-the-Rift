"""Original short heavy-impact bass layer; no external samples."""
from pathlib import Path
import math,random,struct,wave
ROOT=Path(__file__).resolve().parents[1]
rng=random.Random(101);rate=44100
with wave.open(str(ROOT/'assets/audio/hit_weight.wav'),'wb') as f:
 f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate)
 f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,.48*math.exp(-t*24)*math.sin(2*math.pi*(95*t-90*t*t))+.14*rng.uniform(-1,1)*math.exp(-t*95)))*32767)) for t in [i/rate for i in range(int(rate*.20))]))
