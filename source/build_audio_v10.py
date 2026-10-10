"""Six original late-region ambient loops, streamed Vorbis rather than per-frame synthesis."""
import json,subprocess,wave
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1];rate=48000;duration=20;t=np.arange(rate*duration)/rate;rng=np.random.default_rng(1000)
noise=rng.normal(0,1,len(t));air=np.convolve(noise,np.ones(150)/150,mode='same');slow=np.convolve(noise,np.ones(800)/800,mode='same')
records=[]
for i,name in enumerate(['amb_smelter','amb_bonecity','amb_archive','amb_rail','amb_rift','amb_crown']):
 track=.045*air+.08*slow+.013*np.sin(2*np.pi*[45,60,40,100,55,35][i]*t)*(1+.25*np.sin(2*np.pi*t/20))
 for start in np.arange(.3,20,[1.7,3.2,2,1,2.5,4][i]):
  d=t-start;mask=(d>=0)&(d<.32);track+=mask*.045*np.sin(2*np.pi*([340,700,1800,1200,550,160][i]*d))*np.exp(-np.maximum(d,0)*[18,14,45,35,10,8][i])
 seam=2400;blend=np.linspace(0,1,seam);track[-seam:]=track[-seam:]*(1-blend)+track[:seam]*blend;stereo=np.column_stack([track,np.roll(track,23)])
 wav=ROOT/'build'/f'{name}.wav';outpath=ROOT/'assets/audio'/f'{name}.ogg'
 with wave.open(str(wav),'wb') as out:out.setnchannels(2);out.setsampwidth(2);out.setframerate(rate);out.writeframes((np.clip(stereo,-.6,.6)*32767).astype('<i2').tobytes())
 subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','4',str(outpath)],check=True)
 records.append(dict(name=name,seconds=20,peak=float(np.max(np.abs(stereo))),bytes=outpath.stat().st_size))
(ROOT/'qa/audio_assets_v10.json').write_text(json.dumps(dict(original=True,tracks=records),indent=2),encoding='utf-8')
p=ROOT/'scripts/audio_manager.gd';s=p.read_text(encoding='utf-8')
s=s.replace('"amb_lab"]','"amb_lab","amb_smelter","amb_bonecity","amb_archive","amb_rail","amb_rift","amb_crown"]')
s=s.replace('if style=="laboratory":ambient_name="amb_lab"','if style=="laboratory":ambient_name="amb_lab"\n\tif style in ["bonecity","archive","rail","rift","crown"]:ambient_name="amb_"+style\n\tif style=="furnace":ambient_name="amb_smelter"')
p.write_text(s,encoding='utf-8')
p=ROOT/'scripts/qa_audio.gd';s=p.read_text(encoding='utf-8').replace('audio.streams.size()==57','audio.streams.size()==63').replace('57 个声音资源加载','63 个声音资源加载');p.write_text(s,encoding='utf-8')
print('Six original ambience beds; 63 audio assets total.')
