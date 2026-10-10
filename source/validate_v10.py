"""Validate shipped GLB rigs/clips, referenced textures and pinned older asset bytes."""
from pathlib import Path
import json,hashlib,subprocess
from optimize_assets import decode
ROOT=Path(__file__).resolve().parents[1]
checks=[]
def check(ok,label,detail=None):
 checks.append(dict(passed=bool(ok),check=label,detail=detail))
 if not ok:raise ValueError(label)
actors=['leiya','peiqi','ludeng','tiya','lizhao','baluo','moen','selin','yayan','xingjin']
enemies=['imp','skeleton','werewolf','scorpion','mirror_beast','shield','sniper','specter','smelter','general','judge','emperor','triphase','regent']
for name in actors+enemies:
 path=ROOT/f'assets/models/{name}_v10.glb';doc,blob=decode(path)
 clips={a['name']:a for a in doc.get('animations',[])}
 required=['RoleLight','RoleHeavy','RoleSkill','DoubleJump','LadderUp','AirDash','Roll','Guard'] if name in actors else ['PassageWalk','Heavy','BowShot','Hurt']
 check(all(c in clips and len(clips[c]['channels'])>=7 for c in required),'Weighted animation coverage '+name,required)
 check(bool(doc.get('skins')) and any('JOINTS_0' in p['attributes'] and 'WEIGHTS_0' in p['attributes'] for m in doc['meshes'] for p in m['primitives']),'Skin weights '+name)
 for image in doc.get('images',[]):
  if 'uri' in image:check((path.parent/image['uri']).exists(),'Referenced texture '+name)
kit,blob=decode(ROOT/'assets/models/late_kit_v10.glb')
check(len([n for n in kit['nodes'] if 'mesh' in n])==10,'Ten original late region landmark parts')
originals=subprocess.check_output(['git','ls-tree','-r','--name-only','d537a57','assets/models'],cwd=ROOT).decode().splitlines()
for path in originals:
 if not path.endswith('.glb'):continue
 original=subprocess.check_output(['git','show','d537a57:'+path],cwd=ROOT)
 check(hashlib.sha256((ROOT/path).read_bytes()).digest()==hashlib.sha256(original).digest(),'0.6.1 model byte preservation '+Path(path).name)
report={'version':'1.0.0','checks':checks,'failures':sum(not c['passed'] for c in checks),'scope':'Resource and skin/clip presence checks; animation aesthetics and balancing require human acceptance.'}
(ROOT/'qa/asset_validation_v10.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print('V10_ASSETS',len(checks),'checks, zero failures')
