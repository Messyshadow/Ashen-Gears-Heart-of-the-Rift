"""Blender 4.2.9: build original machinery/enemies and combat clips.
Run blender -b --python source/build_ashen.py. Reference passages stay editable.
"""
import bpy, math, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/models'
def G(p): return Vector((p[0],-p[2],p[1]))
def mat(name,col,metal=0,emit=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*col,1)
    p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.58
    if emit:p.inputs['Emission Color'].default_value=(*col,1);p.inputs['Emission Strength'].default_value=emit
    return m
def box(name,p,size,m):
    bpy.ops.mesh.primitive_cube_add(size=1,location=G(p));o=bpy.context.object;o.name=name
    o.dimensions=Vector((size[0],size[2],size[1]));bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(m);be=o.modifiers.new('Forged edges','BEVEL');be.width=.045;be.segments=2
    bpy.ops.object.modifier_apply(modifier=be.name);return o
def cyl(name,p,r,depth,m,axis='y'):
    bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=r,depth=depth,location=G(p));o=bpy.context.object;o.name=name
    if axis=='z':o.rotation_euler.x=math.pi/2
    if axis=='x':o.rotation_euler.y=math.pi/2
    o.data.materials.append(m);be=o.modifiers.new('Rim','BEVEL');be.width=.035;be.segments=2
    bpy.ops.object.modifier_apply(modifier=be.name);return o
def save(name):
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source'/f'{name}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(OUT/f'{name}.glb'),export_format='GLB',export_yup=True,export_animations=False,export_lights=False)
def reset():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    return mat('Blackened iron',(.085,.11,.13),.8),mat('Scuffed copper',(.30,.14,.055),.75),mat('Furnace glass',(1,.16,.012),.1,4),mat('Arc blue',(.015,.38,1),.3,3)
iron,copper,hot,blue=reset()
for x in [-5,5]:
    cyl('Steam chimney',(x,6,-3),.42,12,iron)
    for y in [1,4,7,10]:
        cyl('Pipe coupling',(x,y,-3),.59,.22,copper)
        for a in range(8):box('Coupling bolt',(x+.51*math.cos(a*math.tau/8),y,-3+.51*math.sin(a*math.tau/8)),(.1,.32,.1),iron)
cyl('Central furnace',(0,6,-5),2,10,iron)
for y in [1.1,3.4,6.8,10.8]:cyl('Furnace collar',(0,y,-5),2.24,.25,copper)
for a in range(12):
    angle=a*math.tau/12
    box('Orange furnace slit',(1.92*math.cos(angle),6,-5+1.92*math.sin(angle)),(.18,7,.18),hot)
for x,y in [(-6,5),(5,9),(6,2)]:
    cyl('Gear hub',(x,y,-8),.48,.5,copper,'z')
    cyl('Gear wheel',(x,y,-8),2,.3,iron,'z')
    for a in range(20):
        angle=a*math.tau/20
        o=box('Gear tooth',(x+2.07*math.cos(angle),y+2.07*math.sin(angle),-8),(.35,.35,.48),copper);o.rotation_euler.y=-angle
for x in [-2.6,2.6]:
    cyl('Arc cell',(x,2,-1.6),.27,3,blue)
    for y in [.4,3.6]:cyl('Arc cap',(x,y,-1.6),.43,.22,copper)
save('furnace_assembly')
iron,copper,hot,blue=reset()
box('Dog chassis',(0,.68,0),(1.5,.58,.63),iron)
box('Dog jaw',(.85,.64,0),(.5,.33,.53),copper)
for z in [-.34,.34]:
    box('Dog eye',(.78,.88,z),(.2,.08,.07),hot)
    for x in [-.52,.51]:
        o=box('Leg',(x,.24,z),(.14,.5,.15),copper)
        box('Claw',(x+.1,.045,z),(.38,.09,.22),iron)
cyl('Spine pressure',(0,1.06,0),.12,1.25,copper,'x')
save('mechanical_hound')
iron,copper,hot,blue=reset()
box('Execution torso',(0,1.95,0),(1.6,1.4,.9),iron)
cyl('Core eye',(0,2.16,.48),.34,.16,hot,'z')
box('Helmet',(0,3.05,0),(.8,.55,.65),copper)
for x in [-.65,.65]:
    cyl('Leg piston',(x,.7,0),.2,1.2,copper)
    box('Boot',(x,.12,.1),(.6,.25,.85),iron)
    box('Shoulder',(x*1.9,2.55,0),(.8,.55,.8),copper)
    cyl('Arm piston',(x*2,1.75,0),.22,1.1,iron)
box('Chain hammer',(1.45,.76,0),(.9,.85,.8),copper)
for x in [-.55,.55]:box('Helmet spike',(x,3.5,0),(.15,.55,.15),iron)
save('execution_machine')
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source/hero_passages.blend'))
arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
keep=['StairUp','StairDown','LadderUp','LadderDown','LadderIdle','LadderEnter','LadderExit','HatchEnter','HatchExit','PassageIdle','PassageWalk','PassageLand','PassageFall','PassageJump']
for t in list(arm.animation_data.nla_tracks):arm.animation_data.nla_tracks.remove(t)
arm.animation_data.action=None
for a in list(bpy.data.actions):
    if a.name not in keep:bpy.data.actions.remove(a)
for name,frames in [('Dagger1',12),('Dagger2',14),('Dagger3',19),('Heavy',27),('Guard',30),('Dodge',12),('Hurt',12),('Skill',24)]:
    a=bpy.data.actions.new(name);arm.animation_data.action=a
    for f in range(frames+1):
        t=f/frames;p=arm.pose.bones
        for bone in p:bone.rotation_mode='XYZ';bone.rotation_euler=(0,0,0);bone.location=(0,0,0)
        k=math.sin(math.pi*t)
        p['root'].location.y=-.07
        p['thighL'].rotation_euler.x=-.15;p['thighR'].rotation_euler.x=.15
        p['foreL'].rotation_euler.x=-.35;p['foreR'].rotation_euler.x=-.5
        if name.startswith('Dagger'):
            direction=-1 if name=='Dagger2' else 1
            p['torso'].rotation_euler.z=direction*(.5-1.0*t)*k
            p['armR'].rotation_euler.x=-1.5*k;p['armR'].rotation_euler.z=direction*(1.5*t-.75)*k
            p['foreR'].rotation_euler.x=-.8+.65*k
        elif name in ['Heavy','Skill']:
            p['armR'].rotation_euler.x=-2.7*k;p['armL'].rotation_euler.x=-2.3*k
            p['torso'].rotation_euler.x=.35*math.sin(t*math.tau);p['root'].location.y=-.07-.15*k
        elif name=='Guard':p['armL'].rotation_euler.x=-1.5;p['foreL'].rotation_euler.x=-1.2;p['armR'].rotation_euler.x=-.9
        elif name=='Dodge':p['torso'].rotation_euler.x=-.65;p['root'].location.y=-.35;p['thighL'].rotation_euler.x=-.6;p['shinL'].rotation_euler.x=.9
        elif name=='Hurt':p['torso'].rotation_euler.x=.5*k;p['armL'].rotation_euler.z=-.4*k
        p['scarf'].rotation_euler.x=.22+.1*k
        for bone in p:
            bone.keyframe_insert(data_path='rotation_euler',frame=f);bone.keyframe_insert(data_path='location',frame=f)
    keep.append(name)
arm.animation_data.action=None
for name in keep:
    track=arm.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,0,bpy.data.actions[name])
    track.mute=False
# Dagger bound to right-hand bone in rest space.
steel=mat('Dagger steel',(.52,.62,.67),.88)
hand=arm.data.bones.get('handR') or arm.data.bones['foreR']
o=box('Starting dagger',(0,0,0),(.07,.36,.035),steel)
o.parent=arm;o.parent_type='BONE';o.parent_bone=hand.name;o.location=(0,.08,.02)
bpy.context.scene.render.fps=30;bpy.context.scene.frame_set(0)
arm.animation_data.action=bpy.data.actions['PassageIdle']
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source/ashen_actor.blend'))
arm.animation_data.action=None
bpy.ops.export_scene.gltf(filepath=str(OUT/'ashen_actor.glb'),export_format='GLB',export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True)
(ROOT/'qa/animation_manifest.json').write_text(json.dumps({'blender':'4.2.9','clips':keep,'reference':'hero_passages.blend','new_combat_clips':8},indent=2),encoding='utf8')
print('ASHEN ASSETS COMPLETE',flush=True)
