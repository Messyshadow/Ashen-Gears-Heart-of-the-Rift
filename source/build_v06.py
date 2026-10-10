"""Blender 4.2: four regional kits, four companions and four boss silhouettes."""
import bpy,math,random,sys,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'source'))
random.seed(600);bpy.context.preferences.filepaths.save_version=0
def G(p):return Vector((p[0],-p[2],p[1]))
def clear():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(n,c,metal=0,emit=0):
    m=bpy.data.materials.new(n);m.use_nodes=True;m.diffuse_color=(*c,1);p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.48
    if emit:p.inputs['Emission Color'].default_value=(*c,1);p.inputs['Emission Strength'].default_value=emit
    return m
def box(n,p,s,m,bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1,location=G(p));o=bpy.context.object;o.name=n;o.dimensions=(s[0],s[2],s[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
    if bevel:q=o.modifiers.new('Forged edges','BEVEL');q.width=bevel;q.segments=2;bpy.ops.object.modifier_apply(modifier=q.name)
    return o
def cyl(n,p,r,d,m,axis='y',verts=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=d,location=G(p));o=bpy.context.object;o.name=n;o.data.materials.append(m)
    if axis=='x':o.rotation_euler.y=math.pi/2
    if axis=='z':o.rotation_euler.x=math.pi/2
    q=o.modifiers.new('Rim bevel','BEVEL');q.width=.018;q.segments=2;bpy.ops.object.modifier_apply(modifier=q.name);return o
def sphere(n,p,r,m):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=r,location=G(p));o=bpy.context.object;o.name=n;o.data.materials.append(m);return o
def ring(n,p,r,t,m):
    bpy.ops.mesh.primitive_torus_add(major_radius=r,minor_radius=t,major_segments=32,minor_segments=8,location=G(p),rotation=(math.pi/2,0,0));o=bpy.context.object;o.name=n;o.data.materials.append(m);return o
def begin():return set(bpy.context.scene.objects)
def join(n,b):
    objects=[o for o in bpy.context.scene.objects if o not in b and o.type=='MESH'];bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();o=bpy.context.object;o.name=n
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True);bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR');return o
def save(n,animated=False):
    bpy.context.scene.frame_set(0)
    for image in bpy.data.images:
        if image.source=='FILE' and not image.packed_file:
            try:image.pack()
            except RuntimeError:pass
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source'/f'{n}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/f'{n}.glb'),export_format='GLB',export_yup=True,export_animations=animated,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_lights=False)
clear()
with bpy.data.libraries.load(str(ROOT/'source/industrial_kit_v04.blend'),link=False) as (src,dst):
    dst.materials=[n for n in src.materials if any(k in n.lower() for k in ['oxidized','rusty brass','chipped limestone','aged crate'])]
iron=next(m for m in bpy.data.materials if 'oxidized' in m.name.lower());brass=next(m for m in bpy.data.materials if 'rusty brass' in m.name.lower());stone=next(m for m in bpy.data.materials if 'chipped limestone' in m.name.lower());wood=next(m for m in bpy.data.materials if 'aged crate' in m.name.lower())
aqua=mat('Verdigris enamel',(.055,.25,.23),.6);green=mat('Ironroot leaves',(.09,.23,.11));cyan=mat('Lab cyan glass',(.03,.65,.84),.25,1.7);red=mat('Crimson blood vessel',(.45,.025,.055),.2,1.0);bone=mat('Bone ivory',(.64,.61,.44));purple=mat('Spore violet',(.3,.035,.49),.3,1)
b=begin();cyl('water main',(0,2,0),.42,4,aqua)
for y in [.1,1.3,2.7,3.9]:cyl('flange',(0,y,0),.58,.16,brass)
for y in [.1,3.9]:
    for i in range(8):t=i*math.tau/8;cyl('bolt',(.50*math.cos(t),y,.50*math.sin(t)),.045,.22,iron)
join('WaterPipe',b)
b=begin();ring('wheel rim',(0,0,0),1.55,.12,brass);cyl('wheel axle',(0,0,0),.23,.6,iron,'z')
for i in range(12):
    a=i*math.tau/12;o=box('paddle',(1.45*math.cos(a),1.45*math.sin(a),0),(.35,.50,.55),wood);o.rotation_euler.y=-a
    o=box('spoke',(.75*math.cos(a),.75*math.sin(a),0),(1.4,.09,.10),iron);o.rotation_euler.y=-a
join('WaterWheel',b)
b=begin();cyl('reservoir',(0,1.7,0),1.1,3.4,aqua)
for y in [.12,1.7,3.28]:cyl('tank band',(0,y,0),1.15,.17,iron)
for x in [-.6,0,.6]:box('water gauge',(x,1.7,1.08),(.14,2.5,.07),cyan)
join('WaterTank',b)
b=begin();cyl('vent',(0,.3,0),.4,.6,iron);ring('valve',(0,1.2,.3),.32,.04,brass);box('stem',(0,.7,0),(.14,.9,.14),aqua);join('SteamVent',b)
b=begin();cyl('iron trunk',(0,3.0,0),.45,6,iron,verts=12)
for s in [-1,1]:
    for y in [1.8,3.5,4.7]:
        o=cyl('branch',(s*1.0,y+.3,0),.18,2.8,brass,verts=12);o.rotation_euler.y=-s*.65
        crown=sphere('iron leaves',(s*1.9,y+1.2,0),1.25,green);crown.scale=(1.3,.65,.8)
for x in [-1,0,1]:
    o=cyl('rail root',(x,.2,0),.25,2.4,iron,'x');o.rotation_euler.z=x*.35
join('IronTree',b)
b=begin()
for i in range(8):
    a=i*.55;o=cyl('root chain',(.6*math.sin(a),i*.45,0),.17,.8,brass);o.rotation_euler.y=.5*math.cos(a)
join('RootVine',b)
b=begin()
for x in [-.6,0,.6]:
    cyl('spore stem',(x,.5,0),.05,1,iron);cap=sphere('spore cap',(x,1,0),.35,purple);cap.scale.z=.45
join('SporeCluster',b)
b=begin()
for i in range(17):
    a=i*math.pi/16;o=box('dome brace',(8*math.cos(a),8*math.sin(a),0),(.15,.7,.22),iron);o.rotation_euler.y=-a
for y in [2.5,5]:box('dome beam',(0,y,0),(14,.12,.14),brass)
join('GlassDome',b)
b=begin()
for x in [-1.2,1.2]:box('gothic pier',(x,2.4,0),(.3,4.8,.5),stone)
for s in [-1,1]:
    for i in range(6):
        t=i/5;o=box('pointed arch',(s*(1.2-t),4.7+1.2*t,0),(.31,.4,.5),stone);o.rotation_euler.y=s*.65
for x in [-.65,0,.65]:box('window bars',(x,2.9,.06),(.065,4.3,.08),brass)
box('blood glass',(0,2.6,-.1),(2.2,4.4,.12),red);join('GothicWindow',b)
b=begin();box('bookshelf',(0,1.6,0),(2.4,3.2,.65),wood)
for y in [.2,1,1.8,2.6,3.15]:box('shelf edge',(0,y,.4),(2.5,.1,.2),brass)
for y in [.55,1.35,2.15,2.9]:
    for i in range(10):box('bound book',(-1+i*.22,y,.38),(.16,.58,.25),red if i%3==0 else iron if i%3==1 else bone)
join('Bookshelf',b)
b=begin();ring('clock face',(0,0,0),1.7,.18,brass);cyl('dial',(0,0,-.1),1.55,.14,iron,'z',32)
for i in range(12):
    t=i*math.tau/12;o=box('tick',(1.35*math.sin(t),1.35*math.cos(t),.10),(.075,.25,.045),bone);o.rotation_euler.y=t
box('clock hand',(0,.65,.15),(.10,1.3,.05),brass);box('hour hand',(.40,0,.17),(.8,.12,.06),brass);join('ClockFace',b)
b=begin();cyl('blood ampoule',(0,1.8,0),.4,3.6,red)
for y in [.1,1.8,3.5]:cyl('ampoule cap',(0,y,0),.58,.18,brass)
join('BloodVessel',b)
b=begin();ring('chandelier',(0,0,0),1.1,.11,iron)
for i in range(8):
    t=i*math.tau/8;cyl('candle',(math.cos(t),.3,math.sin(t)),.07,.6,bone);sphere('flame',(math.cos(t),.68,math.sin(t)),.09,red)
cyl('chain',(0,1,0),.06,2,brass);join('Chandelier',b)
b=begin();cyl('tank core',(0,2,0),.55,4,cyan)
for y in [.1,1.2,2.8,3.9]:cyl('tank bands',(0,y,0),.86,.18,iron)
for x in [-.65,.65]:box('tank brace',(x,2,0),(.16,4,.18),brass)
sphere('sample silhouette',(0,2,.1),.42,purple);join('LabTank',b)
b=begin();box('terminal',(0,.7,0),(1.4,1.4,.85),iron);box('screen',(0,1.3,.45),(1.2,.7,.12),cyan)
for x in [-.45,-.15,.15,.45]:box('key',(x,.9,.6),(.12,.08,.10),brass)
join('Terminal',b)
b=begin();cyl('circuit',(0,2,0),.12,4,cyan)
for y in [.3,1.4,2.6,3.7]:ring('coil loop',(0,y,0),.43,.07,brass)
box('circuit foot',(0,.1,0),(.8,.2,.7),iron);join('CircuitPylon',b)
b=begin();ring('hologram',(0,0,0),1.8,.035,cyan)
for i in range(8):
    t=i*math.tau/8;sphere('glyph',(1.8*math.cos(t),1.8*math.sin(t),0),.12,purple)
join('HologramRing',b)
b=begin();box('chest base',(0,.4,0),(1.3,.8,.85),wood);cyl('rounded lid',(0,.8,0),.45,1.25,wood,'x')
for x in [-.48,.48]:box('chest band',(x,.5,0),(.10,1.1,.92),iron)
box('chest lock',(0,.55,.48),(.18,.26,.12),brass);join('Chest',b)
save('regional_kit_v06')
# New monsters have different silhouettes; their articulated visual roots are animated in Godot.
clear();b=begin();sphere('soul',(0,.6,0),.48,cyan)
for s in [-1,1]:o=cyl('wing',(s*.5,.55,0),.075,1.1,iron,'x');o.rotation_euler.z=s*.4
ring('soul ring',(0,.6,0),.65,.05,brass);join('Wraith',b);save('wraith_v06')
clear();b=begin();sphere('crawler body',(0,.6,0),.6,green)
for s in [-1,1]:
    for x in [-.6,0,.6]:o=cyl('thorn leg',(x,.35,s*.5),.06,.8,brass);o.rotation_euler.x=s*.7
for x in [-.4,0,.4]:o=cyl('spine',(x,1.1,0),.06,.65,iron);o.rotation_euler.y=x*.5
join('ThornCrawler',b);save('thorn_v06')
clear();b=begin();sphere('mother core',(0,1.6,0),1.25,aqua)
for i in range(8):
    t=i*math.tau/8;o=cyl('pipe limb',(2.0*math.cos(t),.65,1.3*math.sin(t)),.18,2.0,brass);o.rotation_euler.y=math.cos(t)*.7;o.rotation_euler.x=math.sin(t)*.7
for x in [-.5,.5]:sphere('mother eye',(x,2,1.0),.23,cyan)
ring('mouth',(0,1,1.25),.5,.15,iron);join('PipeMother',b);save('mother_v06')
clear();b=begin();cyl('witch trunk',(0,1.8,0),.45,3.6,iron);sphere('witch crown',(0,3.3,0),.65,green)
for s in [-1,1]:
    o=cyl('root arm',(s*1.0,2.2,0),.16,2.2,brass);o.rotation_euler.y=-s*.8
    for i in range(3):o=cyl('crown spike',(s*(.4+i*.3),3.6+i*.15,0),.09,.85,iron);o.rotation_euler.y=s*.7
for i in range(6):
    t=i*math.tau/6;o=cyl('root feet',(1.1*math.cos(t),.5,1.1*math.sin(t)),.14,1.7,brass);o.rotation_euler.y=math.cos(t)*.8
join('RootWitch',b);save('witch_v06')
clear();b=begin();box('lord cuirass',(0,2,0),(1.35,1.35,.8),iron);sphere('blood crown',(0,3.1,0),.52,red)
for s in [-1,1]:
    cyl('lord leg',(s*.45,.7,0),.18,1.4,iron);box('lord boot',(s*.45,.15,.1),(.5,.3,.7),brass)
    o=box('cape wing',(s*.85,1.9,-.4),(.8,2.8,.1),red);o.rotation_euler.y=s*.2
    cyl('lord arm',(s*.85,2,0),.18,1.5,brass)
cyl('blood spear',(1.15,1.8,.2),.07,3.8,iron);sphere('spear crystal',(1.15,3.75,.2),.24,red);join('BloodLord',b);save('lord_v06')
clear();b=begin();box('editor core',(0,2,0),(1.6,1.7,.95),iron);box('faceless panel',(0,3.4,0),(1.0,.9,.6),cyan)
for s in [-1,1]:
    cyl('editor leg',(s*.5,.65,0),.20,1.3,brass);box('editor boot',(s*.5,.1,.2),(.65,.2,.8),iron)
    for i in range(3):o=cyl('writing arm',(s*(1.1+i*.3),2.0+i*.4,0),.10,2.0,iron);o.rotation_euler.y=s*.7
    box('blade quill',(s*1.8,1.7,.15),(.12,2.2,.38),cyan)
ring('halo',(0,3.5,-.6),1.1,.08,purple);join('FacelessEditor',b);save('editor_v06')

def add_action(arm,name):
    a=bpy.data.actions.new(name);arm.animation_data.action=a;frames=24
    for f in range(frames+1):
        t=f/frames;k=math.sin(math.pi*t);p=arm.pose.bones
        for bone in p:bone.rotation_mode='XYZ';bone.location=(0,0,0);bone.rotation_euler=(0,0,0)
        p['foreR'].rotation_euler.x=-.3;p['foreL'].rotation_euler.x=-.3
        if name.startswith('Bone'):
            p['armR'].rotation_euler.x=-1.8*k;p['armR'].rotation_euler.z=.8*math.sin(math.tau*t)
            p['torso'].rotation_euler.z=-.3*math.sin(math.tau*t);p['armL'].rotation_euler.x=-.6*k
            if name=='BoneThrust':p['armR'].rotation_euler.x=-1.55*k;p['foreR'].rotation_euler.x=-.7*(1-k)
        elif name.startswith('Shadow'):
            p['root'].location.y=-.12*k;p['torso'].rotation_euler.x=-.35*k
            p['armR'].rotation_euler.x=-1.9*k;p['armL'].rotation_euler.x=-1.8*math.sin(math.pi*min(1,t*1.3))
            p['armR'].rotation_euler.z=.65*k;p['armL'].rotation_euler.z=-.65*k
        elif name=='RapierThrust':p['armR'].rotation_euler.x=-1.55*k;p['torso'].rotation_euler.z=.35*k;p['thighL'].rotation_euler.x=-.4*k
        elif name=='BloodCast':p['armL'].rotation_euler.x=-1.8*k;p['foreL'].rotation_euler.x=-.8*k;p['armR'].rotation_euler.x=-.6*k
        else:
            p['armR'].rotation_euler.x=-1.8*k;p['armL'].rotation_euler.x=-1.8*k if name=='ElectricBurst' else -.7*k
            p['torso'].rotation_euler.x=-.22*k;p['root'].location.y=-.1*k
        p['scarf'].rotation_euler.x=.25+.18*k
        for bone in p:bone.keyframe_insert(data_path='location',frame=f);bone.keyframe_insert(data_path='rotation_euler',frame=f)
    arm.animation_data.action=None;track=arm.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,0,a)
def attach(o,arm,bone,loc):o.parent=arm;o.parent_type='BONE';o.parent_bone=bone;o.location=loc
variants=[('shenjin_v06','kain_katana_v04',['BoneSlash','BoneThrust'],(.50,.47,.36)),('shayin_v06','kain_v04',['ShadowStrike','ShadowBind'],(.08,.055,.15)),('weiluo_v06','kain_katana_v04',['RapierThrust','BloodCast'],(.32,.035,.06)),('zero7_v06','luomao_v04',['ElectricPunch','ElectricBurst'],(.035,.23,.32))]
for n,base,clips,color in variants:
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source'/f'{base}.blend'));arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    cloak=mat(n+' cloak',color,.1)
    for o in list(bpy.context.scene.objects):
        if o.type=='MESH':
            if o.name in ['Starting dagger','Grey steel katana blade','Repair hammer']:bpy.data.objects.remove(o,do_unlink=True);continue
            for slot in o.material_slots:
                if slot.material and any(token in slot.material.name.lower() for token in ['fabric','scarf','twill']):
                    tinted=slot.material.copy();tinted.name=n+' cloth';tinted.diffuse_color=(*color,1)
                    shader=next(node for node in tinted.node_tree.nodes if node.type=='BSDF_PRINCIPLED');base_input=shader.inputs['Base Color']
                    if base_input.is_linked:
                        original=base_input.links[0].from_socket;mix=tinted.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(*color,1)
                        tinted.node_tree.links.new(original,mix.inputs[1]);tinted.node_tree.links.new(mix.outputs[0],base_input)
                    else:base_input.default_value=(*color,1)
                    slot.material=tinted
    equipmat=mat(n+' equipment',(.7,.65,.45) if n.startswith('shenjin') else (.12,.19,.23),.75)
    glow=mat(n+' energy',(.1,.6,1) if n.startswith('zero7') else (.6,.03,.08),.2,1.5)
    if n.startswith('shenjin') or n.startswith('weiluo'):
        b=begin();box('long blade',(0,.55,0),(.12 if n.startswith('shenjin') else .045,1.15,.035),equipmat)
        box('hilt',(0,-.1,0),(.055,.25,.055),equipmat);box('guard',(0,.05,0),(.23,.06,.06),equipmat)
        o=join('Bone sword' if n.startswith('shenjin') else 'Crimson rapier',b);attach(o,arm,'foreR',(0,.08,.02))
        if n.startswith('weiluo'):
            o=sphere('Alchemy vial',(0,0,0),.10,glow);attach(o,arm,'foreL',(0,.1,.06))
    elif n.startswith('shayin'):
        for side in ['R','L']:
            b=begin();box('kunai',(0,.15,0),(.07,.40,.04),equipmat);box('kunai grip',(0,-.10,0),(.055,.16,.055),cloak);o=join('Shadow blade '+side,b);attach(o,arm,'fore'+side,(0,.08,.02))
    else:
        for side in ['R','L']:
            o=box('Conductive fist '+side,(0,0,0),(.28,.24,.24),equipmat);attach(o,arm,'fore'+side,(0,.06,.04))
            o=box('Electric edge '+side,(0,0,0),(.04,.45,.06),glow);attach(o,arm,'fore'+side,(0,.09,.21))
    for clip in clips:add_action(arm,clip)
    arm.animation_data.action=None
    for p in arm.pose.bones:p.location=(0,0,0);p.rotation_euler=(0,0,0)
    save(n,True)
from optimize_assets import optimize
optimize(report_name='asset_optimization_v06.json',pattern='*v06.glb')
from rooms_v06 import build
build()
(ROOT/'qa/art_v06.json').write_text(json.dumps({'version':'0.6.0','kit_parts':18,'companions':[v[0] for v in variants],'bosses':['mother','witch','lord','editor'],'clips':[c for v in variants for c in v[2]],'scope':'Original Blender procedural geometry; shared original demo PBR materials. Prototype art, not finished sculpted characters.'},indent=2),encoding='utf-8')
print('V06 BLENDER BUILD COMPLETE',flush=True)
