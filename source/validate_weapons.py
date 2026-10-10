"""Compare new actor exports to the released 0.4.2 assets in Git."""
import json, struct, hashlib, subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BASELINE='c32d75a'
def decode(data):
    size=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+size])
    return doc,data[28+size:]
def accessor(doc,blob,index):
    a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
    # Blender exports tightly packed accessors; include types/counts in signature.
    start=v.get('byteOffset',0)+a.get('byteOffset',0)
    size={5126:4,5125:4,5123:2,5121:1}[a['componentType']]*{'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]*a['count']
    return (a['componentType'],a['type'],a['count'],hashlib.sha256(blob[start:start+size]).hexdigest())
def animation_signatures(doc,blob):
    out={}
    for anim in doc.get('animations',[]):
        channels={}
        for ch in anim['channels']:
            s=anim['samplers'][ch['sampler']];target=ch['target']
            key=doc['nodes'][target['node']]['name']+':'+target['path']
            channels[key]=(s.get('interpolation','LINEAR'),accessor(doc,blob,s['input']),accessor(doc,blob,s['output']))
        out[anim['name']]=channels
    return out
records=[]
for name in ['kain_v04','luomao_v04','yise_v04']:
    path='assets/models/'+name+'.glb'
    old=subprocess.run(['git','show',BASELINE+':'+path],cwd=ROOT,check=True,stdout=subprocess.PIPE).stdout
    before,bb=decode(old);after,ab=decode((ROOT/path).read_bytes())
    old_clips=animation_signatures(before,bb);new_clips=animation_signatures(after,ab)
    kept=all(new_clips.get(k)==v for k,v in old_clips.items())
    record={'actor':name,'baseline':BASELINE,'original_clips':len(old_clips),'new_clips':len(new_clips),
        'original_animation_samples_byte_identical':kept,'original_mesh_count':len(before['meshes']),'new_mesh_count':len(after['meshes']),
        'original_shared_texture_uris_preserved':set(i['uri'] for i in before['images'])==set(i['uri'] for i in after['images'])}
    records.append(record)
    if not kept:record['changed_clips']=[k for k,v in old_clips.items() if new_clips.get(k)!=v]
katana,kb=decode((ROOT/'assets/models/kain_katana_v04.glb').read_bytes())
out={'version':'0.4.3','actors':records,'katana_equipment_nodes':[n['name'] for n in katana['nodes'] if 'katana' in n.get('name','').lower()],
    'katana_clips':[a['name'] for a in katana['animations'] if a['name'].startswith('Katana')]}
(ROOT/'qa/weapon_asset_validation.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
assert all(r['original_animation_samples_byte_identical'] and r['original_shared_texture_uris_preserved'] and r['original_mesh_count']==r['new_mesh_count'] for r in records)
