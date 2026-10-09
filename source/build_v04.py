"""Blender 4.2: shared textured kit, three actors, traversal clips and enemy art."""
import bpy,math,json,sys,random
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/models'
sys.path.insert(0,str(ROOT/'source'))
from rooms_v04 import build
rooms=build();random.seed(400)
bpy.context.preferences.filepaths.save_version=0
def G(p):return Vector((p[0],-p[2],p[1]))
def clear():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,c,metal=0,emit=0):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*c,1)
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.68
    if emit:p.inputs['Emission Color'].default_value=(*c,1);p.inputs['Emission Strength'].default_value=emit
    return m
def box(n,p,s,m,bevel=.035):
    bpy.ops.mesh.primitive_cube_add(size=1,location=G(p));o=bpy.context.object;o.name=n;o.dimensions=(s[0],s[2],s[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
    if bevel:
        q=o.modifiers.new('Worn edges','BEVEL');q.width=bevel;q.segments=2;bpy.ops.object.modifier_apply(modifier=q.name)
    return o
def cyl(n,p,r,d,m,axis='y'):
    bpy.ops.mesh.primitive_cylinder_add(vertices=20,radius=r,depth=d,location=G(p));o=bpy.context.object;o.name=n
    if axis=='z':o.rotation_euler.x=math.pi/2
    if axis=='x':o.rotation_euler.y=math.pi/2
    o.data.materials.append(m);q=o.modifiers.new('Forged rim','BEVEL');q.width=.025;q.segments=2;bpy.ops.object.modifier_apply(modifier=q.name);return o
def begin():return set(bpy.context.scene.objects)
def join(n,before):
    objects=[o for o in bpy.context.scene.objects if o not in before and o.type=='MESH'];bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();o=bpy.context.object;o.name=n
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR');return o
def save(n,animated=False):
    for image in bpy.data.images:
        if image.source=='FILE' and not image.packed_file:
            try:image.pack()
            except RuntimeError:pass
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source'/f'{n}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(OUT/f'{n}.glb'),export_format='GLB',export_yup=True,export_animations=animated,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_lights=False)
clear()
with bpy.data.libraries.load(str(ROOT/'source/passage_01.blend'),link=False) as (src,dst):
    dst.materials=[n for n in src.materials if any(k in n.lower() for k in ['chipped limestone','worn coping','oxidized','rusty brass','aged crate'])]
def find(term,fallback):return next((m for m in bpy.data.materials if term in m.name.lower()),fallback)
iron=mat('V04 iron',(.10,.13,.15),.8);copper=mat('V04 copper',(.32,.15,.06),.8);stone=mat('V04 stone',(.27,.29,.3));wood=mat('V04 wood',(.19,.09,.034))
stone=find('chipped limestone',stone);iron=find('oxidized',iron);copper=find('rusty brass',copper);wood=find('aged crate',wood)
hot=mat('V04 Furnace glow',(1,.23,.02),0,3);blue=mat('V04 Arc glass',(.02,.48,.95),.2,2);coal=mat('V04 coal',(.035,.045,.05),.15)
b=begin()
box('beam',(0,-.4,0),(4,.8,3.2),iron)
for x in [-1.5,-.5,.5,1.5]:box('tread',(x,-.06,0),(.96,.14,3.2),stone)
for x in [-1.8,-1,-.2,.6,1.4]:cyl('rivet',(x,-.42,1.63),.065,.09,copper,'z')
box('underpipe',(0,-.76,-1.2),(4,.13,.13),copper);join('Platform',b)
b=begin()
for x in [-2.85,2.85]:
    for y in [.5,1.5,2.5,3.5]:box('pier',(x,y,0),(.9,.94,1.1),stone)
for a in range(15):
    t=(a+.5)*math.pi/15;obj=box('voussoir',(2.9*math.cos(t),3.9+2.9*math.sin(t),0),(.66,.8,1.12),stone);obj.rotation_euler.y=math.pi/2-t
join('Arch',b)
b=begin()
for x in [-1,1]:box('rail post',(x,.65,0),(.10,1.3,.1),iron)
box('handrail',(0,1.23,0),(2.2,.1,.1),copper);box('rail mid',(0,.53,0),(2.2,.07,.07),iron);join('Rail',b)
b=begin();box('pipe',(0,2.0,0),(.36,4,.36),iron)
for y in [0,1.3,2.7,4]:cyl('flange',(0,y,0),.29,.12,copper)
join('Pipe',b)
b=begin()
for x in [-.4,.4]:box('ladder rail',(x,2,0),(.1,4,.1),iron)
for y in [a*.32 for a in range(13)]:cyl('rung',(0,y,.04),.055,.8,copper,'x')
join('Ladder',b)
b=begin()
box('lantern base',(0,0,0),(.45,.7,.25),iron);box('glass',(0,0,.16),(.25,.45,.11),hot)
for y in [-.4,.4]:box('rim',(0,y,.14),(.5,.11,.4),copper)
join('Lantern',b)
b=begin();box('chest',(0,.42,0),(1,.84,.8),wood)
for x in [-.43,.43]:box('band',(x,.42,0),(.12,.86,.83),iron)
box('latch',(0,.55,.43),(.14,.22,.08),copper);join('Crate',b)
b=begin()
cyl('boiler',(0,2,0),1.2,4,iron)
for y in [.1,1.2,3,4]:cyl('band',(0,y,0),1.27,.17,copper)
for x in [-.55,0,.55]:box('hot vent',(x,2,1.15),(.18,2.7,.1),hot)
join('Boiler',b)
b=begin();cyl('hub',(0,0,0),.35,.45,copper,'z')
for rad in [1.2,1.7]:
    bpy.ops.mesh.primitive_torus_add(major_radius=rad,minor_radius=.14,major_segments=32,minor_segments=8,location=G((0,0,0)),rotation=(math.pi/2,0,0));bpy.context.object.data.materials.append(iron)
for a in range(20):
    t=a*math.tau/20;o=box('tooth',(1.87*math.cos(t),1.87*math.sin(t),0),(.32,.32,.4),copper);o.rotation_euler.y=-t
for a in range(6):
    t=a*math.tau/6;o=box('spoke',(.85*math.cos(t),.85*math.sin(t),0),(1.5,.15,.18),iron);o.rotation_euler.y=-t
join('Gear',b)
b=begin()
box('gate backing',(0,1.6,-.1),(2.8,3.2,.35),iron)
for x in [-1.4,1.4]:box('gate pier',(x,1.7,0),(.35,3.4,.7),stone)
box('lintel',(0,3.4,0),(3.2,.3,.7),copper)
for x in [-1,-.5,0,.5,1]:box('gate bar',(x,1.7,.18),(.09,3.2,.1),copper)
join('Gate',b)
b=begin();cyl('coil',(0,1.5,0),.25,3,blue)
for y in [0,1.5,3]:cyl('cap',(0,y,0),.43,.2,iron)
join('Coil',b)
b=begin()
for i in range(22):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=random.uniform(.4,.9),location=G((random.uniform(-1.7,1.7),random.uniform(.1,.55),random.uniform(-.6,.6))));o=bpy.context.object;o.data.materials.append(coal)
join('CoalPile',b)
b=begin();box('cage',(0,1.7,0),(3.3,3.4,1.2),iron)
for x in [-1.2,-.8,-.4,0,.4,.8,1.2]:box('cage bar',(x,1.7,.66),(.06,3.2,.06),copper)
join('Cell',b)
b=begin()
for row in range(6):
    for col in range(8):box('old wall brick',(-3.6+col*.96+(row%2)*.20,row*.52+.25,0),(.91,.48,.36),stone,.025)
for x in [-3.7,3.7]:box('wall brace',(x,1.5,.22),(.15,3.2,.16),iron)
join('WallPanel',b)
b=begin()
for i in range(12):
    bpy.ops.mesh.primitive_torus_add(major_radius=.10,minor_radius=.026,major_segments=12,minor_segments=6,location=G((0,i*.16,0)),rotation=(math.pi/2,0,0) if i%2==0 else (0,math.pi/2,0));bpy.context.object.data.materials.append(iron)
join('Chain',b)
b=begin();box('flag',(0,2.5,0),(2,3.2,.05),wood);box('pole',(0,4.2,0),(2.3,.1,.1),copper);join('Banner',b)
save('industrial_kit_v04')
# Original mechanical enemies with exposed axles, armour bands and horns.
clear();b=begin();box('turret base',(0,.3,0),(.9,.6,1),iron);cyl('turret',(0,.9,0),.45,.7,copper);cyl('barrel',(.7,1.0,0),.14,1.25,iron,'x');box('eye',(.4,1.25,.45),(.22,.13,.1),hot);join('GunTurret',b);save('turret_v04')
clear();b=begin();cyl('drone core',(0,0,0),.38,.4,iron,'z')
for x in [-.7,.7]:cyl('rotor',(x,.08,0),.35,.09,copper)
box('eye',(0,0,.25),(.22,.15,.1),blue);join('Drone',b);save('drone_v04')
clear();b=begin();box('braced torso',(0,2.0,0),(1.55,1.25,.85),iron);cyl('chest reactor',(0,2.1,.48),.3,.1,hot,'z')
box('bull helm',(0,3.05,0),(.95,.67,.75),copper)
for s in [-1,1]:
    for i in range(3):
        o=cyl('horn',(s*(.55+i*.15),3.36+i*.18,0),.14-i*.035,.45,copper);o.rotation_euler.y=s*.6
    cyl('leg',(s*.52,.73,0),.23,1.3,iron);box('boot',(s*.52,.15,.15),(.6,.3,.8),copper)
    box('pauldron',(s*1.0,2.65,0),(.7,.6,.8),copper);cyl('arm',(s*1.1,1.8,0),.22,1.25,iron)
box('pile hammer',(1.1,.75,.2),(.9,.9,.9),iron)
for y in [.4,.9]:box('hammer band',(1.1,y,.2),(1.02,.14,1),copper)
join('Minotaur',b);save('minotaur_v04')
# Animated actor variants, all use the inherited common skeleton.
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source/ashen_actor.blend'))
copper=mat('V04 actor brass',(.32,.18,.07),.8)
iron=mat('V04 actor iron',(.09,.12,.14),.75)
blue=mat('V04 bow string',(.10,.48,.8),.3)
arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');arm.animation_data.action=None
new=['Run','Crouch','Roll','AirDash','WallHold','WallKick','Vault','Slam','HookPull','MechLight','MechHeavy','BowShot']
for name in new:
    a=bpy.data.actions.new(name);arm.animation_data.action=a
    frames=24 if name in ['Run','Crouch','WallHold'] else 18
    for f in range(frames+1):
        t=f/frames;k=math.sin(math.pi*t);cycle=t*math.tau;p=arm.pose.bones
        for bone in p:bone.rotation_mode='XYZ';bone.location=(0,0,0);bone.rotation_euler=(0,0,0)
        p['root'].location.y=-.06;p['foreR'].rotation_euler.x=-.3;p['foreL'].rotation_euler.x=-.3
        if name=='Run':
            for s,phase in [('L',cycle),('R',cycle+math.pi)]:
                p['thigh'+s].rotation_euler.x=.72*math.sin(phase);p['shin'+s].rotation_euler.x=max(0,.8*math.cos(phase));p['arm'+s].rotation_euler.x=-.4*math.sin(phase)
            p['torso'].rotation_euler.x=-.2;p['root'].location.y=-.06+.04*math.sin(cycle*2)
        elif name=='Crouch':
            p['root'].location.y=-.36;p['torso'].rotation_euler.x=-.4
            for s,phase in [('L',cycle),('R',cycle+math.pi)]:p['thigh'+s].rotation_euler.x=-.7+.17*math.sin(phase);p['shin'+s].rotation_euler.x=1.1;p['arm'+s].rotation_euler.x=-.3
        elif name=='Roll':p['torso'].rotation_euler.x=-.75;p['root'].location.y=-.45;p['thighL'].rotation_euler.x=-1;p['shinL'].rotation_euler.x=1.5;p['thighR'].rotation_euler.x=.3
        elif name in ['WallHold','WallKick','HookPull']:
            p['armR'].rotation_euler.x=-2.4;p['armL'].rotation_euler.x=-2.0;p['thighL'].rotation_euler.x=-.8;p['shinL'].rotation_euler.x=1.0;p['torso'].rotation_euler.x=-.1
            if name=='WallKick':p['thighR'].rotation_euler.x=-.8*k;p['armL'].rotation_euler.z=.6*k
        elif name in ['AirDash','Vault']:
            p['torso'].rotation_euler.x=-.6;p['thighL'].rotation_euler.x=-1.2;p['shinL'].rotation_euler.x=1.1;p['armR'].rotation_euler.x=-.6;p['armL'].rotation_euler.x=-.8
        elif name=='Slam':p['armR'].rotation_euler.x=-2.4*(1-t);p['torso'].rotation_euler.x=-.5*k;p['thighL'].rotation_euler.x=-.6;p['shinL'].rotation_euler.x=.8
        elif name=='BowShot':p['armL'].rotation_euler.x=-1.45;p['armR'].rotation_euler.x=-1.4;p['foreR'].rotation_euler.x=-1.4+.8*k;p['torso'].rotation_euler.z=.15
        else:
            p['armR'].rotation_euler.x=-2.5*k;p['torso'].rotation_euler.x=.4*math.sin(cycle);p['root'].location.y=-.06-.18*k
            p['armL'].rotation_euler.x=-.8*k
        p['scarf'].rotation_euler.x=.25+.13*k
        for bone in p:bone.keyframe_insert(data_path='location',frame=f);bone.keyframe_insert(data_path='rotation_euler',frame=f)
    track=arm.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,0,a);track.mute=False
arm.animation_data.action=None;bpy.context.scene.render.fps=30
for p in arm.pose.bones:p.rotation_euler=(0,0,0);p.location=(0,0,0)
save('kain_v04',True)
# Variant colours and equipment are editable bone-bound Blender geometry.
def attach(o,bone,loc):o.parent=arm;o.parent_type='BONE';o.parent_bone=bone;o.location=loc
equip=[]
for s in [-1,1]:
    o=box('Mechanic shoulder',(0,0,0),(.42,.25,.4),copper);attach(o,'armL' if s<0 else 'armR',(0,0,0));equip.append(o)
o=box('Repair hammer',(0,0,0),(.40,.27,.28),iron);attach(o,'handR' if 'handR' in arm.pose.bones else 'foreR',(0,.14,0));equip.append(o)
for o in bpy.context.scene.objects:
    if o.type=='MESH' and o.name=='Starting dagger':bpy.data.objects.remove(o,do_unlink=True)
save('luomao_v04',True)
for o in equip:bpy.data.objects.remove(o,do_unlink=True)
green=mat('Ranger cloak',(.06,.19,.14),.1)
for o in bpy.context.scene.objects:
    if o.type=='MESH':
        for slot in o.material_slots:
            if slot.material and 'fabric' in slot.material.name.lower():slot.material=green
b=begin()
for i in range(10):
    t=-1.1+2.2*i/9;o=cyl('Bow limb',(.4*math.cos(t),.4*math.sin(t),0),.025,.16,copper);o.rotation_euler.y=-t
box('bow string',(.18,0,0),(.018,.75,.018),blue);bow=join('Ranger bow',b);attach(bow,'handL' if 'handL' in arm.pose.bones else 'foreL',(0,.10,0))
save('yise_v04',True)
(ROOT/'qa/animation_v04.json').write_text(json.dumps(dict(version='0.4.0',new_clips=new,actors=['kain_v04','luomao_v04','yise_v04'],room_layouts=len(rooms)),indent=2),encoding='utf8')
print('V04 BLENDER BUILD COMPLETE',flush=True)
