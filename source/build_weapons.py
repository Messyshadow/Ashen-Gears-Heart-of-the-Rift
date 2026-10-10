"""Blender 4.2: bone-bound curved katana and shared initial double-jump clips.

Run alone after build_v04.py, or called by it. Existing locomotion and textures
are kept; exported textures are shared byte-for-byte by optimize_assets.py.
"""
import bpy, math, json, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'source'))

def action(arm, name):
    for track in list(arm.animation_data.nla_tracks):
        if track.name == name: arm.animation_data.nla_tracks.remove(track)
    a = bpy.data.actions.new(name)
    arm.animation_data.action = a
    frames = 18 if name == 'DoubleJump' else 30 if name == 'KatanaHeavy' else 16
    for f in range(frames + 1):
        t = f / frames
        p = arm.pose.bones
        for bone in p:
            bone.rotation_mode = 'XYZ'; bone.location = (0, 0, 0); bone.rotation_euler = (0, 0, 0)
        p['foreR'].rotation_euler.x = -.3; p['foreL'].rotation_euler.x = -.3
        pulse = math.sin(math.pi * t)
        if name == 'DoubleJump':
            p['torso'].rotation_euler.x = -.6 * pulse
            p['thighL'].rotation_euler.x = -1.2 * pulse; p['shinL'].rotation_euler.x = 1.7 * pulse
            p['thighR'].rotation_euler.x = -.6 * pulse; p['shinR'].rotation_euler.x = 1.2 * pulse
            p['armL'].rotation_euler.z = -.7 * pulse; p['armR'].rotation_euler.z = .7 * pulse
        else:
            # Four poses: horizontal cut, rising cut, overhead finisher, slow heavy.
            swing = math.sin(math.pi * min(1, t / .72))
            side = -1 if name == 'Katana2' else 1
            p['torso'].rotation_euler.z = side * (.35 - .8 * t) * pulse
            p['armR'].rotation_euler.x = -1.25 - 1.2 * swing
            p['armL'].rotation_euler.x = -1.15 - 1.1 * swing
            p['foreR'].rotation_euler.x = -.55 - .45 * swing
            p['foreL'].rotation_euler.x = -.65 - .6 * swing
            p['armR'].rotation_euler.z = side * (.9 - 1.8 * t) * pulse
            p['armL'].rotation_euler.z = side * (.7 - 1.4 * t) * pulse
            p['thighL'].rotation_euler.x = -.35 * pulse
            p['shinL'].rotation_euler.x = .45 * pulse
            if name in ['Katana3', 'KatanaHeavy']:
                wind = math.sin(math.pi * min(1, t / .55))
                p['armR'].rotation_euler.x = -2.9 * wind
                p['armL'].rotation_euler.x = -2.7 * wind
                p['torso'].rotation_euler.x = -.4 * pulse
                p['root'].location.y = -.12 * pulse
        p['scarf'].rotation_euler.x = .25 + .2 * pulse
        for bone in p:
            bone.keyframe_insert(data_path='location', frame=f)
            bone.keyframe_insert(data_path='rotation_euler', frame=f)
    for curve in a.fcurves:
        for key in curve.keyframe_points: key.interpolation = 'BEZIER'
    arm.animation_data.action = None
    track = arm.animation_data.nla_tracks.new(); track.name = name
    track.strips.new(name, 0, a)

def material(name, color, metal):
    m = bpy.data.materials.new(name); m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Metallic'].default_value = metal; p.inputs['Roughness'].default_value = .32
    return m

def katana(arm):
    steel = material('Grey steel katana', (.43, .52, .58), .85)
    brass = material('Katana brass fittings', (.4, .21, .07), .8)
    wrap = material('Katana dark grip', (.045, .055, .065), .15)
    # A gently curved, tapered blade with a bright bevel, in bone-local space.
    verts = []; faces = []; rings = 13
    for i in range(rings):
        t = i / (rings - 1); y = .25 + 1.28 * t
        center = .13 * t * t; width = .075 * (1 - .65 * t) if i < rings - 1 else .002
        verts.extend([(center-width, y, 0), (center, y, .022), (center+width, y, 0), (center, y, -.022)])
    for i in range(rings-1):
        for j in range(4): faces.append((i*4+j, i*4+(j+1)%4, (i+1)*4+(j+1)%4, (i+1)*4+j))
    faces.extend([(3,2,1,0), tuple((rings-1)*4+j for j in range(4))])
    mesh = bpy.data.meshes.new('Forged curved blade'); mesh.from_pydata(verts, [], faces); mesh.materials.append(steel)
    blade = bpy.data.objects.new('Grey steel katana blade', mesh); bpy.context.collection.objects.link(blade)
    equipment = [blade]
    for name, location, dimensions, mat in [
        ('Katana grip',(0,.10,0),(.075,.30,.075),wrap),
        ('Katana guard',(0,.265,0),(.23,.035,.18),brass),
        ('Katana pommel',(0,-.055,0),(.085,.035,.085),brass)]:
        bpy.ops.mesh.primitive_cube_add(size=1)
        o = bpy.context.object; o.name = name; o.dimensions = dimensions
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        o.data.materials.append(mat); o.location = location; equipment.append(o)
    # Join first so blade, guard and grip share one pivot and stay connected.
    bpy.ops.object.select_all(action='DESELECT')
    for o in equipment: o.select_set(True)
    bpy.context.view_layer.objects.active = blade; bpy.ops.object.join()
    blade.parent = arm; blade.parent_type = 'BONE'
    blade.parent_bone = 'handR' if 'handR' in arm.pose.bones else 'foreR'
    blade.location = (0, .08, .02); blade.rotation_euler.x = -math.pi / 2
    for o in list(bpy.context.scene.objects):
        if o.type == 'MESH' and o.name == 'Starting dagger': bpy.data.objects.remove(o, do_unlink=True)

def export(name):
    bpy.context.preferences.filepaths.save_version = 0
    for arm in [o for o in bpy.context.scene.objects if o.type == 'ARMATURE']:
        arm.animation_data.action = None
        for p in arm.pose.bones: p.rotation_euler = (0,0,0); p.location = (0,0,0)
    bpy.context.scene.frame_set(0)
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'source' / (name+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(ROOT / 'assets/models' / (name+'.glb')), export_format='GLB', export_yup=True,
        export_animations=True, export_animation_mode='NLA_TRACKS', export_force_sampling=True, export_lights=False)

def build_weapons():
    for name in ['kain_v04', 'luomao_v04', 'yise_v04']:
        bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'source' / (name+'.blend')))
        arm = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
        action(arm, 'DoubleJump')
        if name == 'kain_v04':
            for clip in ['Katana1', 'Katana2', 'Katana3', 'KatanaHeavy']: action(arm, clip)
        export(name)
        if name == 'kain_v04': katana(arm); export('kain_katana_v04')
    from optimize_assets import optimize
    optimize(report_name='weapon_asset_optimization.json')
    (ROOT/'qa/weapon_assets.json').write_text(json.dumps({'version':'0.4.3','weapon':'Blender curved steel katana, bone-bound hand equipment',
        'clips':['Katana1','Katana2','Katana3','KatanaHeavy'],'initial_mobility':'DoubleJump on all three actors','textures':'Shared without resampling'},indent=2),encoding='utf-8')
    print('WEAPONS BUILD COMPLETE', flush=True)

if __name__ == '__main__': build_weapons()
