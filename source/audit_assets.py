"""Audit embedded GLB resources without a Blender or Godot dependency."""
import hashlib,json,struct
from pathlib import Path
root=Path(__file__).resolve().parents[1]
records=[]
for p in sorted((root/'assets/models').glob('*.glb')):
    b=p.read_bytes()
    assert b[:4]==b'glTF',p
    count=struct.unpack_from('<I',b,12)[0]
    data=json.loads(b[20:20+count])
    records.append(dict(file=p.name,bytes=len(b),mesh_count=len(data.get('meshes',[])),animations=[a.get('name') for a in data.get('animations',[])],embedded_images=sum('bufferView' in i for i in data.get('images',[])),sha256=hashlib.sha256(b).hexdigest()))
(root/'qa/asset_audit.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf8')
print('Audited',len(records),'GLB resources')
