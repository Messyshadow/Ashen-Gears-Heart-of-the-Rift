"""Blender source for ten equipped actors, fourteen enemy silhouettes, and six regional kits."""
import bpy,math,json,sys,ast,random
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'source'))
bpy.context.preferences.filepaths.save_version=0
# Reuse geometry helpers without executing any old build or overwriting old assets.
tree=ast.parse((ROOT/'source/build_v06.py').read_text(encoding='utf-8'))
helpers=ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ['G','clear','mat','box','cyl','sphere','ring','begin','join','save','attach']],type_ignores=[])
exec(compile(helpers,'geometry_helpers','exec'))
def action(arm,name,kind,variant):
 a=bpy.data.actions.new(name);arm.animation_data.action=a;frames=36
 for f in range(frames+1):
  t=f/frames;k=math.sin(math.pi*t);pose=arm.pose.bones
  for bone in pose:bone.rotation_mode='XYZ';bone.location=(0,0,0);bone.rotation_euler=(0,0,0)
  pose['foreR'].rotation_euler.x=-.3;pose['foreL'].rotation_euler.x=-.3
  if kind in ['rifle','cannon','ink']:
   pose['armR'].rotation_euler.x=-1.25*k;pose['armL'].rotation_euler.x=-1.45*k;pose['foreR'].rotation_euler.z=.5*k;pose['torso'].rotation_euler.x=.15*k
   if variant==2:pose['root'].location.y=-.12*k;pose['torso'].rotation_euler.z=.6*math.sin(math.tau*t)
  elif kind in ['necromancer','healer','star']:
   pose['armR'].rotation_euler.x=-2.1*k;pose['armL'].rotation_euler.x=-(.8+variant*.35)*k;pose['torso'].rotation_euler.z=.18*math.sin(math.tau*t);pose['scarf'].rotation_euler.x=.6*k
  elif kind=='steam':
   pose['armR'].rotation_euler.x=-1.8*k;pose['armL'].rotation_euler.x=-1.7*k if variant>0 else -.5*k;pose['torso'].rotation_euler.x=-.3*k;pose['root'].location.z=-.12*k
  else:
   pose['armR'].rotation_euler.x=-1.8*k;pose['armR'].rotation_euler.z=(.9 if kind=='ninja' else .6)*math.sin(math.tau*t)
   pose['armL'].rotation_euler.x=-1.7*k if kind=='ninja' else -.65*k;pose['torso'].rotation_euler.z=-(.3+variant*.14)*math.sin(math.tau*t)
   pose['thighL'].rotation_euler.x=-.35*k;pose['root'].location.y=-.08*k
  for bone in pose:bone.keyframe_insert(data_path='location',frame=f);bone.keyframe_insert(data_path='rotation_euler',frame=f)
 arm.animation_data.action=None;track=arm.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,0,a)
actors=[('leiya','ninja','kain_v04',(.03,.20,.29)),('peiqi','ink','yise_v04',(.36,.16,.06)),('ludeng','steam','luomao_v04',(.28,.21,.09)),('tiya','dragon','kain_katana_v04',(.27,.09,.055)),('lizhao','light','kain_katana_v04',(.53,.49,.30)),('baluo','cannon','luomao_v04',(.12,.17,.14)),('moen','necromancer','kain_v04',(.13,.09,.24)),('selin','healer','kain_v04',(.43,.39,.25)),('yayan','rifle','yise_v04',(.06,.11,.16)),('xingjin','star','kain_v04',(.16,.12,.35))]
for n,kind,base,color in actors:
 bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source'/f'{base}.blend'));arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH':continue
  if any(t in o.name.lower() for t in ['starting dagger','grey steel katana','repair hammer','short bow','bow string']):bpy.data.objects.remove(o,do_unlink=True);continue
  for slot in o.material_slots:
   if slot.material and any(t in slot.material.name.lower() for t in ['fabric','scarf','twill']):
    tinted=slot.material.copy();tinted.name=n+' cloth';tinted.diffuse_color=(*color,1);shader=tinted.node_tree.nodes.get('Principled BSDF');inp=shader.inputs['Base Color']
    if inp.is_linked:
     original=inp.links[0].from_socket;mix=tinted.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(*color,1);tinted.node_tree.links.new(original,mix.inputs[1]);tinted.node_tree.links.new(mix.outputs[0],inp)
    else:inp.default_value=(*color,1)
    slot.material=tinted
 iron=mat(n+' forged equipment',(.15,.19,.22),.8);gold=mat(n+' brass',(.52,.36,.15),.7);energy=mat(n+' emblem',(.1,.6,1) if kind in ['ninja','rifle'] else (.82,.48,.12) if kind in ['light','healer','steam'] else (.5,.11,.65),.3,1.5)
 if kind in ['rifle','cannon','ink']:
  b=begin();box('receiver',(0,.15,0),(.16,.45,.22),iron);cyl('barrel',(0,.50,0),.08 if kind=='rifle' else .14,.6,iron);box('stock',(0,-.10,0),(.12,.25,.17),gold);ring('muzzle',(0,.82,0),.10,.025,energy);o=join(n+' ranged weapon',b);attach(o,arm,'foreR',(0,.08,.06))
 elif kind in ['necromancer','healer','star']:
  b=begin();cyl('staff',(0,.55,0),.035,1.7,gold);ring('staff crown',(0,1.45,0),.17,.04,energy);sphere('focal crystal',(0,1.45,0),.09,energy);o=join(n+' ritual staff',b);attach(o,arm,'foreR',(0,.04,.04))
 elif kind=='steam':
  for side in ['R','L']:
   b=begin();box('piston',(0,0,0),(.35,.38,.30),iron);cyl('fist valve',(0,.25,0),.14,.30,gold);o=join('steam gauntlet '+side,b);attach(o,arm,'fore'+side,(0,.06,.04))
  b=begin();cyl('boiler',(0,.1,0),.24,.55,gold);cyl('exhaust',(.17,.45,0),.06,.30,iron);o=join('back boiler',b);attach(o,arm,'torso',(0,.1,-.26))
 else:
  for side in (['R','L'] if kind=='ninja' else ['R']):
   b=begin();box('blade',(0,.43,0),(.07 if kind=='ninja' else .11,.9 if kind!='dragon' else 1.4,.04),energy if kind=='light' else iron);box('cross guard',(0,-.01,0),(.25,.04,.055),gold);cyl('grip',(0,-.13,0),.045,.23,gold);o=join(n+' blade '+side,b);attach(o,arm,'fore'+side,(0,.07,.04))
 if kind=='dragon':
  b=begin();sphere('young dragon body',(0,.3,0),.14,gold);sphere('head',(0,.48,.1),.10,energy)
  for side in [-1,1]:o=box('dragon wing',(side*.22,.35,0),(.36,.035,.21),iron);o.rotation_euler.y=side*.3
  o=join('young dragon companion',b);attach(o,arm,'torso',(.36,.35,-.12))
 elif kind in ['star','healer','light']:
  b=begin();ring('halo',(0,.1,0),.24,.023,energy);o=join(n+' halo',b);attach(o,arm,'head',(0,.28,-.08))
 else:
  b=begin();box('pauldron',(0,.05,0),(.32,.20,.35),iron);sphere('role emblem',(0,.15,.12),.055,energy);o=join(n+' pauldron',b);attach(o,arm,'armL',(0,.07,0))
 for variant,clip in enumerate(['RoleLight','RoleHeavy','RoleSkill']):action(arm,clip,kind,variant)
 arm.animation_data.action=None
 for bone in arm.pose.bones:bone.location=(0,0,0);bone.rotation_euler=(0,0,0)
 save(n+'_v10',True);print('ACTOR',n,flush=True)
clear();iron=mat('v10 blackened iron',(.10,.13,.15),.8);gold=mat('v10 hammered brass',(.49,.30,.10),.75);wood=mat('v10 aged eastern timber',(.18,.085,.04));bone=mat('v10 bone limestone',(.61,.59,.43));red=mat('v10 furnace emission',(.95,.17,.02),.3,1.6);blue=mat('v10 magnetic blue',(.025,.45,.9),.4,1.5);violet=mat('v10 rift violet',(.37,.08,.62),.3,1.5)
for n in ['imp','skeleton','werewolf','scorpion','mirror_beast','shield','sniper','specter','smelter','general','judge','emperor','triphase','regent']:
 clear();b=begin();boss=n in ['smelter','general','judge','emperor','triphase','regent'];scale=1.8 if boss else 1.0
 if n in ['scorpion','emperor','mirror_beast','werewolf','triphase']:
  core=sphere('armored abdomen',(0,.65*scale,0),.55*scale,iron if n in ['scorpion','emperor'] else violet if n in ['mirror_beast','triphase'] else bone);core.scale=(1.3,1,.7)
  for side in [-1,1]:
   for i in range(3):o=cyl('Leg '+str(side)+str(i),((i-1)*.45*scale,.3*scale,side*.65*scale),.065*scale,.95*scale,gold,'z');o.rotation_euler.x=side*.55
  if n in ['scorpion','emperor']:
   for i in range(5):sphere('tail segment',(-.7*scale-i*.13*scale,1*scale+i*.22*scale,0),.13*scale,gold)
   sphere('electric sting',(-1.2*scale,2.1*scale,0),.18*scale,blue)
  else:
   for side in [-1,1]:cyl('tusk',(.7*scale,1*scale,side*.3*scale),.08*scale,.55*scale,bone)
   for i in range(3 if n=='triphase' else 1):sphere('mirror eye',(.6*scale,.9*scale,(i-1)*.25*scale),.15*scale,violet)
 elif n in ['specter','judge']:
  sphere('soul',(0,1.1*scale,0),.46*scale,violet);ring('archive halo',(0,1.5*scale,-.1),.7*scale,.07*scale,gold)
  for i in range(6):o=box('floating page',(.7*scale*math.cos(i*math.tau/6),.8*scale+.3*math.sin(i),.35),(.28,.45,.045),bone);o.rotation_euler.z=i*.4
 else:
  box('cuirass',(0,1.2*scale,0),(.75*scale,.7*scale,.45*scale),iron);sphere('head',(0,1.85*scale,0),.25*scale,bone if n in ['skeleton','general'] else gold)
  for side in [-1,1]:
   cyl('Leg '+str(side),(side*.25*scale,.4*scale,0),.10*scale,.8*scale,iron);box('boot',(side*.25*scale,.08*scale,.10),(.30*scale,.16*scale,.36*scale),gold);cyl('arm',(side*.52*scale,1.1*scale,0),.10*scale,.65*scale,gold)
  if n in ['smelter','imp','regent']:
   for side in [-1,1]:o=cyl('horn',(side*.3*scale,2.15*scale,0),.09*scale,.65*scale,red if n=='imp' else gold);o.rotation_euler.y=side*.55
   sphere('furnace chest',(0,1.2*scale,.26*scale),.21*scale,red)
  if n=='shield':box('large shield',(-.52,.9,.2),(.55,1.1,.12),iron)
  elif n=='sniper':cyl('long rifle',(.6,1.1,0),.08,1.3,iron,'x')
  else:cyl('polearm',(.65*scale,1.0*scale,0),.035*scale,2.4*scale,gold);box('blade',(.65*scale,2.1*scale,0),(.20*scale,.5*scale,.06),blue if n=='general' else red)
 join(n+' silhouette',b);save(n+'_v10');print('ENEMY',n,flush=True)
clear()
b=begin();cyl('furnace vessel',(0,2.5,0),1.5,5,iron,verts=24)
for y in [.2,2.5,4.8]:ring('furnace bands',(0,y,0),1.55,.14,gold)
for x in [-.65,0,.65]:box('furnace slit',(x,2.5,1.48),(.24,3.5,.08),red)
join('FurnaceTower',b)
b=begin();box('eastern pillar',(0,2.5,0),(.7,5,.7),wood)
for y in [3.7,5]:box('lintel',(0,y,0),(5,.30,1),wood)
for x in [-2,-1,0,1,2]:o=box('roof tile',(x,5.4-.12*abs(x),0),(1.2,.18,2.1),iron);o.rotation_euler.y=x*.10
join('EasternRoof',b)
b=begin();box('archive',(0,2.4,0),(3,4.8,.8),wood)
for y in [.1,1.2,2.4,3.6,4.7]:box('shelf',(0,y,.5),(3.2,.16,.3),gold)
for x in range(12):
 for y in [.65,1.8,3.0,4.2]:box('file spine',(-1.25+x*.23,y,.5),(.18,.8,.30),bone if x%3 else iron)
join('ArchiveShelf',b)
b=begin()
for side in [-1,1]:box('rail',(side*1.1,0,0),(.18,.30,8),iron)
for z in [-3,-1,1,3]:box('sleepers',(0,-.15,z),(3,.2,.3),wood);box('magnet',(1.1,.3,z),(.34,.4,.6),blue)
join('MagneticRail',b)
b=begin()
for i in range(7):ring('magnet winding',(0,i*.42,0),.62,.08,gold)
cyl('electric core',(0,1.4,0),.25,3.1,blue);join('MagneticCoil',b)
b=begin()
for i in range(6):o=box('mirror shard',(.8*math.sin(i),i*.65,0),(.50,.95,.18),violet);o.rotation_euler.y=.4*math.cos(i)
join('RiftShard',b)
b=begin();box('throne platform',(0,.25,0),(5,.5,3),iron);box('backrest',(0,2,0),(2,3.5,.5),gold)
for side in [-1,1]:box('armrest',(side*1.25,1,0),(.5,1.5,2),iron);cyl('crown spire',(side*.7,4,0),.1,1.4,red)
join('CrownThrone',b)
b=begin();ring('rift portal',(0,2.8,0),2.2,.12,iron);ring('portal glow',(0,2.8,.1),2,.055,violet);join('RiftPortal',b)
b=begin();cyl('bone lantern',(0,1.5,0),.2,3,bone);sphere('soul light',(0,2.8,0),.25,blue);join('BoneLantern',b)
b=begin();box('train car',(0,1,0),(5,2,2.7),iron)
for x in [-1.8,0,1.8]:box('windows',(x,1.5,1.36),(.85,.65,.05),blue)
for x in [-1.6,1.6]:cyl('wheel',(x,.1,0),.45,3,gold,'z')
join('TrainCar',b)
save('late_kit_v10')
from optimize_assets import optimize
optimize(report_name='asset_optimization_v10.json',pattern='*v10.glb')
(ROOT/'qa/art_v10.json').write_text(json.dumps({'actors':[n for n,_,_,_ in actors],'enemies':14,'kit_parts':10,'clips':['RoleLight','RoleHeavy','RoleSkill'],'original_assets_preserved':True},indent=2),encoding='utf-8')
print('V10 BLENDER BUILD COMPLETE',flush=True)
