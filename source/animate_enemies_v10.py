"""Retain late enemy geometry and add weighted locomotion/attack/hurt rigs."""
import bpy,math,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'source'))
bpy.context.preferences.filepaths.save_version=0
names=['imp','skeleton','werewolf','scorpion','mirror_beast','shield','sniper','specter','smelter','general','judge','emperor','triphase','regent']
for n in names:
 bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source'/f'{n}_v10.blend'))
 if any(o.type=='ARMATURE' for o in bpy.context.scene.objects):continue
 boss=n in ['smelter','general','judge','emperor','triphase','regent'];scale=1.8 if boss else 1
 human=n in ['imp','skeleton','shield','sniper','smelter','general','regent']
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];data=bpy.data.armatures.new(n+' rig');arm=bpy.data.objects.new('Armature',data);bpy.context.collection.objects.link(arm);bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
 bones={}
 def bone(name,head,tail,parent='root'):
  b=data.edit_bones.new(name);b.head=tuple(v*scale for v in head);b.tail=tuple(v*scale for v in tail)
  if parent and parent in bones:b.parent=bones[parent]
  bones[name]=b
 bone('root',(0,0,0),(0,0,.45),'');bone('torso',(0,0,.6),(0,0,1.6));bone('head',(0,0,1.6),(0,0,2.1),'torso')
 for side,x in [('R',.25),('L',-.25)]:bone('leg'+side,(x,0,.7),(x,0,.10));bone('arm'+side,(x*2,0,1.5),(x*2,0,.75),'torso')
 bpy.ops.object.mode_set(mode='OBJECT')
 for mesh in meshes:
  groups={name:mesh.vertex_groups.new(name=name) for name in bones}
  for v in mesh.data.vertices:
   x,y,z=(mesh.matrix_world@v.co)/scale
   tag=('head' if z>1.63 else 'arm'+('R' if x>0 else 'L') if abs(x)>.43 and z>.7 else 'leg'+('R' if x>0 else 'L') if z<.65 else 'torso') if human else ('leg'+('R' if y>0 else 'L') if z<.48 else 'head' if z>1.6 else 'torso')
   groups[tag].add([v.index],1,'REPLACE')
  modifier=mesh.modifiers.new('Skeletal deformation','ARMATURE');modifier.object=arm;mesh.parent=arm
 for clip in ['PassageWalk','Heavy','BowShot','Hurt']:
  action=bpy.data.actions.new(clip);arm.animation_data_create();arm.animation_data.action=action
  for frame in range(37):
   t=frame/36;wave=math.sin(math.tau*t);k=math.sin(math.pi*t);pose=arm.pose.bones
   for p in pose:p.rotation_mode='XYZ';p.rotation_euler=(0,0,0);p.location=(0,0,0)
   if clip=='PassageWalk':
    pose['legR'].rotation_euler.x=.24*wave;pose['legL'].rotation_euler.x=-.24*wave;pose['armR'].rotation_euler.x=-.18*wave;pose['armL'].rotation_euler.x=.18*wave;pose['torso'].location.z=.025*scale*math.sin(math.pi*t)**2
   elif clip=='Heavy':pose['armR'].rotation_euler.x=-1.4*k;pose['armL'].rotation_euler.x=-.7*k;pose['torso'].rotation_euler.z=.24*wave
   elif clip=='BowShot':pose['armR'].rotation_euler.x=-1.3*k;pose['armL'].rotation_euler.x=-1.2*k;pose['head'].rotation_euler.x=-.12*k
   else:pose['torso'].rotation_euler.x=.22*k;pose['head'].rotation_euler.x=.25*k
   for p in pose:p.keyframe_insert(data_path='location',frame=frame);p.keyframe_insert(data_path='rotation_euler',frame=frame)
  arm.animation_data.action=None;track=arm.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,0,action)
 for p in arm.pose.bones:p.location=(0,0,0);p.rotation_euler=(0,0,0)
 bpy.context.scene.frame_set(0);bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source'/f'{n}_v10.blend'))
 bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/f'{n}_v10.glb'),export_format='GLB',export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_lights=False)
 print('RIGGED',n,flush=True)
from optimize_assets import optimize
optimize(report_name='enemy_rig_optimization_v10.json',pattern='*v10.glb')
print('14 late enemy rigs and 56 locomotion / attack / hurt clips exported.',flush=True)
