"""Original procedural Foley, industrial ambience and music. Requires numpy.
No downloaded/third-party audio. 48 kHz, stereo, 16-bit PCM WAV.
"""
import hashlib,json,math,wave,shutil,subprocess
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/audio';OUT.mkdir(parents=True,exist_ok=True)
SR=48000;RNG=np.random.default_rng(40401);records=[]
def noise(n,cutoff=1500):
    a=RNG.normal(0,1,n);freq=np.fft.rfftfreq(n,1/SR)
    a=np.fft.irfft(np.fft.rfft(a)/(1+(freq/cutoff)**2),n)
    return a/(np.std(a)+1e-9)*.22
def tvec(d):return np.arange(round(d*SR))/SR
def impact(d=.45,weight=1,metal=True):
    t=tvec(d);a=noise(len(t),4000 if metal else 1200)*np.exp(-t*40)*1.3
    a+=.55*np.sin(2*np.pi*(80*weight*t+35*weight*.045*(1-np.exp(-t/.045))))*np.exp(-t*18)
    if metal:
        for f,amp in [(380,.20),(673,.12),(1081,.08),(1643,.05)]:a+=amp*np.sin(2*np.pi*f*weight*t)*np.exp(-t*(7+f/320))
    else:a+=noise(len(t),350)*np.exp(-t*17)*.8
    return a
def swoosh(d=.32,power=1):
    t=tvec(d);u=t/d;env=np.sin(np.pi*u)**1.4
    a=noise(len(t),3000)*env*power
    a+=.13*np.sin(2*np.pi*(170*t+310*t*t))*env
    return a
def arc(d=.65,down=False):
    t=tvec(d);a=noise(len(t),6500)*np.exp(-t*12)*.7
    for f in [420,630,840]:a+=.12*np.sin(2*np.pi*(f*t+(-220 if down else 150)*t*t))*np.exp(-t*5)
    return a
def cue(d=.8,notes=(440,660,880)):
    a=np.zeros(round(d*SR))
    for i,f in enumerate(notes):
        start=int(i*.11*SR);t=np.arange(len(a)-start)/SR
        a[start:]+=.22*(np.sin(2*np.pi*f*t)+.25*np.sin(2*np.pi*f*2.01*t))*np.exp(-t*7)*np.minimum(t*250,1)
    return a
def write(name,a,loop=False,level=.78,category='sfx'):
    a=np.asarray(a,dtype=float)
    if a.ndim==1:
        delayed=np.roll(a,round(SR*.002));a=np.column_stack((a*.98,delayed*.98))
    if loop:
        # Join the noise/reverb tail back to the start without an abrupt seam.
        k=round(SR*.05);w=np.linspace(0,1,k)[:,None];a[-k:]=a[-k:]*(1-w)+a[:k]*w
    else:
        k=min(192,len(a)//8);a[:k]*=np.linspace(0,1,k)[:,None];a[-k:]*=np.linspace(1,0,k)[:,None]
    a*=level/max(np.max(np.abs(a)),1e-9);pcm=np.rint(np.clip(a,-.98,.98)*32767).astype('<i2')
    p=OUT/(name+'.wav')
    with wave.open(str(p),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes(pcm.tobytes())
    records.append(dict(file=p.name,seconds=round(len(a)/SR,3),peak=round(float(np.max(np.abs(a))),4),rms=round(float(np.sqrt(np.mean(a*a))),4),loop=loop,category=category,sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
for material in ['stone','metal']:
    for i in range(3):write(f'foot_{material}_{i+1}',impact(.23,.85+i*.06,material=='metal')*.5)
for i in range(2):
    write(f'ladder_{i+1}',impact(.3,1.5+i*.1,True))
    write(f'hit_metal_{i+1}',impact(.6,.7+i*.15,True))
    write(f'hit_flesh_{i+1}',impact(.42,.8+i*.1,False))
    write(f'whoosh_light_{i+1}',swoosh(.24+i*.04))
for name,d,power in [('jump',.26,.6),('dash',.50,1.6),('roll',.38,1),('wall_jump',.30,.85),('vault',.32,.7),('whoosh_heavy',.48,1.35),('boss_charge',.75,1.5)]:write(name,swoosh(d,power))
for name,d,weight,metal in [('land_soft',.3,1.15,False),('land_heavy',.6,.7,True),('player_hurt',.4,.6,False),('guard',.35,1.7,True),('grapple_attach',.45,1.7,True),('elevator_stop',.6,.6,True),('gear_latch',.4,1.6,True),('press_hit',1.0,.4,True),('boss_smash',1.0,.4,True),('shockwave',.8,.5,False)]:write(name,impact(d,weight,metal))
write('bow_fire',swoosh(.24)+impact(.24,2.3,True)*.25)
write('grapple_launch',swoosh(.5)+arc(.5)*.3)
write('skill',arc(.85));write('parry',arc(.6)+impact(.6,1.4,True))
write('enemy_fire',impact(.38,1.1,True)+swoosh(.38)*.5)
write('enemy_windup',cue(.38,(330,440)));write('press_warning',cue(.55,(220,330,440)))
write('boss_roar',arc(1.2,True)+impact(1.2,.4,True))
write('elevator_start',arc(.9,True)+impact(.9,.65,True)*.7)
write('gear_start',arc(.85,True)+impact(.85,.8,True))
for name,notes in [('chest',(440,660,880)),('save',(220,330,440,660)),('switch',(392,523)),('door',(165,220)),('ui',(660,))]:write(name,cue(.8,notes),level=.58)
# Looping machinery beds; broad-band wind is audible on laptop speakers.
for name in ['furnace','wind','gears','workshop']:
    t=tvec(12);a=noise(len(t),320 if name!='wind' else 1800)*(.55+.15*np.sin(2*np.pi*t/12))
    for f,amp in [(55,.18),(110,.10),(220,.03)]:a+=amp*np.sin(2*np.pi*f*t)*(1+.15*np.sin(2*np.pi*t/6))
    if name=='gears':a+=.12*np.sin(2*np.pi*330*t)*np.maximum(0,np.sin(2*np.pi*t*2))**12
    if name=='workshop':a*=.7;a+=.10*np.sin(2*np.pi*220*t)
    write('amb_'+name,a,True,.46,'ambience')
# Original minor-key motif, reverb taps, kick, metal snare and clockwork hats.
def music(mode):
    n=16*SR;a=np.zeros(n);beat=.5
    roots=[110,87.307,130.813,97.999]
    def add(voice,start,gain=1):
        at=round(start*SR)
        for delay,vol in [(0,1),(.185,.19),(.37,.10)]:
            idx=at+round(delay*SR);ids=(np.arange(len(voice))+idx)%n;a[ids]+=voice*gain*vol
    for bar,root in enumerate(roots):
        for degree in [1,2**(3/12),2**(7/12)]:
            t=tvec(4);pad=np.sin(2*np.pi*root*degree*t)+.15*np.sin(2*np.pi*root*degree*2*t)
            add(pad*np.sin(np.pi*t/4)**.7,bar*4,.07)
        for b in range(8):
            t=tvec(.45);add(np.sin(2*np.pi*root*t)*np.exp(-t*8),bar*4+b*beat,.12)
            note=root*2*[1,2**(7/12),2**(10/12),2**(3/12)][b%4]
            t=tvec(.7);add((np.sin(2*np.pi*note*t)+.3*np.sin(2*np.pi*note*2.01*t))*np.exp(-t*6),bar*4+b*beat,.075)
            if mode!='explore':
                if b%2==0:
                    t=tvec(.4);add(np.sin(2*np.pi*(52*t+5*(1-np.exp(-t*30))))*np.exp(-t*13),bar*4+b*beat,.52 if mode=='boss' else .38)
                else:add(impact(.25,1.7,True),bar*4+b*beat,.20)
                for off in [0,.25]:
                    t=tvec(.10);add(noise(len(t),8000)*np.exp(-t*55),bar*4+b*beat+off,.25)
    return a
for mode in ['explore','combat','boss']:write('music_'+mode,music(mode),True,.63,'music')
ffmpeg=shutil.which('ffmpeg')
if ffmpeg:
    for entry in records:
        if not entry['loop']:continue
        p=OUT/entry['file'];dest=p.with_suffix('.ogg')
        subprocess.run([ffmpeg,'-v','error','-y','-i',str(p),'-c:a','libvorbis','-q:a','5',str(dest)],check=True)
        entry['runtime_file']=dest.name;entry['runtime_sha256']=hashlib.sha256(dest.read_bytes()).hexdigest()
(ROOT/'qa/audio_assets.json').write_text(json.dumps(dict(version='0.4.1',sample_rate=SR,channels=2,license='Original synthesis in source/build_audio.py; no external recordings',assets=records),indent=2),encoding='utf8')
print('Generated',len(records),'original WAV assets')
