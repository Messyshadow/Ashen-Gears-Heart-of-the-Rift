"""Original deterministic regional ambience; no external recordings."""
from pathlib import Path
import json, subprocess, wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
rate=48000;duration=20;n=rate*duration;t=np.arange(n)/rate
rng=np.random.default_rng(606)
def filtered_noise(window):
    noise=rng.normal(0,1,n)
    return np.convolve(noise,np.ones(window)/window,mode='same')
air=filtered_noise(90);slow=filtered_noise(1200)
tracks={}
water=.06*air+.12*slow+.008*np.sin(2*np.pi*67*t)
for start in np.arange(.6,20,1.3):
    d=t-start;mask=(d>=0)&(d<.24);water+=mask*.05*np.sin(2*np.pi*(820*d-700*d*d))*np.exp(-np.maximum(d,0)*24)
tracks['amb_water']=water
tracks['amb_garden']=.1*slow+.025*air+.008*np.sin(2*np.pi*43*t)*(1+.3*np.sin(2*np.pi*t/20))
castle=.05*slow+.015*air+.013*np.sin(2*np.pi*55*t)
for start in np.arange(0,20,1.0):
    d=t-start;mask=(d>=0)&(d<.07);castle+=mask*.04*np.sin(2*np.pi*1800*d)*np.exp(-np.maximum(d,0)*55)
tracks['amb_castle']=castle
tracks['amb_lab']=.025*air+.04*slow+.008*np.sin(2*np.pi*100*t)+.004*np.sin(2*np.pi*300*t)*(1+.2*np.cos(2*np.pi*t/20))
records=[]
for name,track in tracks.items():
    # Periodic harmonics and short seam crossfade prevent loop clicks.
    seam=2400;blend=np.linspace(0,1,seam);track[-seam:]=track[-seam:]*(1-blend)+track[:seam]*blend
    track=np.clip(track,-.6,.6);stereo=np.column_stack([track,np.roll(track,17)])
    wav=ROOT/'build'/f'{name}.wav';ogg=ROOT/'assets/audio'/f'{name}.ogg'
    with wave.open(str(wav),'wb') as out:out.setnchannels(2);out.setsampwidth(2);out.setframerate(rate);out.writeframes((stereo*32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','4',str(ogg)],check=True)
    records.append({'name':name,'seconds':duration,'peak':float(np.max(np.abs(track))),'bytes':ogg.stat().st_size})
(ROOT/'qa/audio_assets_v06.json').write_text(json.dumps({'version':'0.6.0','original':True,'tracks':records},indent=2),encoding='utf-8')
print('Generated four regional ambient loops')
