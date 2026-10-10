"""Check every new imported animation and the unchanged pre-0.6 model bytes."""
from pathlib import Path
import json,hashlib,subprocess
from optimize_assets import decode
ROOT=Path(__file__).resolve().parents[1]
checks=[]
def check(ok,label,detail=None):
    checks.append(dict(passed=bool(ok),check=label,detail=detail))
    if not ok:raise ValueError(label)
kit,blob=decode(ROOT/'assets/models/regional_kit_v06.glb')
names=[n['name'] for n in kit['nodes'] if 'mesh' in n]
check(len(names)==18,'18 regional Blender kit mesh parts',names)
for name,clips in [('shenjin',['BoneSlash','BoneThrust']),('shayin',['ShadowStrike','ShadowBind']),('weiluo',['RapierThrust','BloodCast']),('zero7',['ElectricPunch','ElectricBurst'])]:
    doc,blob=decode(ROOT/f'assets/models/{name}_v06.glb');animations={a['name']:a for a in doc.get('animations',[])}
    check(all(c in animations and len(animations[c]['channels'])>=20 for c in clips),'Independent skeletal attack clips '+name,{c:len(animations[c]['channels']) for c in clips})
    check(all(c in animations for c in ['DoubleJump','PassageWalk','LadderUp','AirDash','Roll','Guard']),'Complete mobility retained '+name)
    check(len(doc.get('skins',[]))==1,'Shared demo skeleton '+name)
for name in ['industrial_kit_v04','kain_v04','kain_katana_v04','luomao_v04','yise_v04','minotaur_v04','execution_machine','mechanical_hound']:
    file=ROOT/f'assets/models/{name}.glb';original=subprocess.check_output(['git','show',f'HEAD:assets/models/{name}.glb'],cwd=ROOT)
    digest=hashlib.sha256(file.read_bytes()).hexdigest()
    check(digest==hashlib.sha256(original).hexdigest(),'0.4.3 source model remains byte-identical '+name,digest)
for name in ['mother','witch','lord','editor','wraith','thorn']:
    doc,blob=decode(ROOT/f'assets/models/{name}_v06.glb');check(len(doc.get('meshes',[]))>0,'Original Blender enemy geometry '+name)
report={'version':'0.6.0','checks':checks,'failures':sum(not c['passed'] for c in checks)}
(ROOT/'qa/asset_validation_v06.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('V06_ASSETS',len(checks),'checks, zero failures')
