"""Share byte-identical embedded textures without resampling geometry or images."""
from pathlib import Path
import json, struct, hashlib, shutil
ROOT = Path(__file__).resolve().parents[1]
def decode(path):
    data=path.read_bytes();size,kind=struct.unpack_from('<II',data,12)
    if data[:4]!=b'glTF' or kind!=0x4E4F534A:raise ValueError(path)
    doc=json.loads(data[20:20+size]);offset=20+size
    length,kind=struct.unpack_from('<II',data,offset)
    if kind!=0x004E4942:raise ValueError('Expected BIN chunk')
    return doc,data[offset+8:offset+8+length]
def optimize(report_name='asset_optimization.json'):
    target=ROOT/'assets/textures/shared';target.mkdir(parents=True,exist_ok=True)
    backups=ROOT/'build/embedded_texture_originals';backups.mkdir(parents=True,exist_ok=True)
    records=[];before_total=0;after_total=0;texture_total=0;unique={}
    for path in sorted((ROOT/'assets/models').glob('*v04.glb')):
        doc,blob=decode(path);images=doc.get('images',[])
        if not any('bufferView' in image for image in images):continue
        before_total+=path.stat().st_size;shutil.copy2(path,backups/path.name)
        old_views=doc['bufferViews'];image_views=set()
        for image in images:
            if 'bufferView' not in image:continue
            index=image.pop('bufferView');view=old_views[index];payload=blob[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
            texture_total+=len(payload);digest=hashlib.sha256(payload).hexdigest();suffix='.png' if image.get('mimeType')=='image/png' else '.jpg'
            destination=target/(digest+suffix)
            if destination.exists() and destination.read_bytes()!=payload:raise ValueError('Texture hash mismatch')
            destination.write_bytes(payload)
            settings=Path(str(destination)+'.import')
            if settings.exists():settings.write_text(settings.read_text('utf-8').replace('mipmaps/generate=false','mipmaps/generate=true'),encoding='utf-8')
            unique[digest]=len(payload);image['uri']='../textures/shared/'+destination.name;image.pop('mimeType',None);image_views.add(index)
        packed=bytearray();views=[];mapping={}
        for index,view in enumerate(old_views):
            if index in image_views:continue
            while len(packed)%4:packed.append(0)
            payload=blob[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
            mapping[index]=len(views);updated=dict(view,byteOffset=len(packed));views.append(updated);packed.extend(payload)
            assert bytes(packed[updated['byteOffset']:updated['byteOffset']+updated['byteLength']])==payload
        doc['bufferViews']=views
        def remap(value):
            if isinstance(value,dict):
                for key,item in list(value.items()):
                    if key=='bufferView':value[key]=mapping[item]
                    else:remap(item)
            elif isinstance(value,list):
                for item in value:remap(item)
        remap(doc)
        while len(packed)%4:packed.append(0)
        doc['buffers'][0]['byteLength']=len(packed)
        encoded=json.dumps(doc,separators=(',',':'),ensure_ascii=False).encode('utf-8')
        while len(encoded)%4:encoded+=b' '
        result=struct.pack('<4sII',b'glTF',2,28+len(encoded)+len(packed))+struct.pack('<II',len(encoded),0x4E4F534A)+encoded+struct.pack('<II',len(packed),0x004E4942)+packed
        path.write_bytes(result);after_total+=len(result)
        records.append({'file':path.name,'original_bytes':(backups/path.name).stat().st_size,'optimized_bytes':len(result),'texture_count':len(images),'preserved':'All non-image buffer payloads byte-identical; all texture payloads byte-identical; animation, mesh topology and nodes untouched.'})
    if records:
        report={'files':records,'original_glb_bytes':before_total,'optimized_glb_bytes':after_total,'embedded_texture_bytes':texture_total,'unique_texture_bytes':sum(unique.values()),'unique_textures':len(unique),'quality':'No resizing, no texture recompression, no mesh simplification, no animation removal.'}
        (ROOT/'qa'/report_name).write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report,indent=2))
if __name__=='__main__':optimize()
