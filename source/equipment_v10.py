from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
p=ROOT/'scripts/inventory.gd';s=p.read_text(encoding='utf-8')
weapons=[('扳手拳臂','机械重砸与修补'),('弧刃短弓','远程箭矢'),('白骨剑','剑气返刃'),('影织双刃','快速束缚'),('赤汞刺剑','血瓶远攻'),('导电拳刃','近战群体破势'),('雷印双刃','三段雷刃连击'),('符文喷枪','减速符墨'),('蒸汽拳锤','重击与护盾'),('幼龙长枪','龙息与长枪'),('黎明光刃','两段光斩'),('铆火手炮','范围炮击'),('魂名法杖','魂钉与骨仆'),('守夜圣铃','净化与有限治疗'),('鹰目步枪','贯穿狙击'),('三源星杖','星弹与共鸣')]
new=[]
for i,(name,desc) in enumerate(weapons,1):
 new.append(' "native_%d":'%i+json.dumps(dict(name=name,type='weapon',quality=1,actor=i,desc=desc+'；这位角色的专属武器。',stats={}),ensure_ascii=False)+',')
s=s.replace('const CATALOG={','const CATALOG={\n'+'\n'.join(new),1)
s=s.replace('if slot=="weapon":game.equip_weapon(id)','if slot=="weapon" and game.active_slot==0:game.equip_weapon(id)')
s=s.replace('equipment["0"]["weapon"]=game.equipped_weapon','if not equipment.has("0"):equipment["0"]={}\n equipment["0"]["weapon"]=game.equipped_weapon\n for slot in game.available_slots():on_recruit(slot)',1)
s+='''
func on_recruit(actor: int) -> void:
 if actor<=0:return
 var id: String="native_%d"%actor
 if not CATALOG.has(id):return
 if owned(id)==0:grant(id)
 if not equipment.has(str(actor)):equipment[str(actor)]={}
 if not equipment[str(actor)].has("weapon"):equipment[str(actor)]["weapon"]=id
'''
p.write_text(s,encoding='utf-8')
p=ROOT/'scripts/progression_v06.gd';s=p.read_text(encoding='utf-8');s=s.replace('g.consume_prop();g.field_slots();','g.inventory.on_recruit(slot);g.consume_prop();g.field_slots();',1);p.write_text(s,encoding='utf-8')
p=ROOT/'scripts/game.gd';s=p.read_text(encoding='utf-8');s=s.replace('flags.ranger=true;skill_points+=3;','flags.ranger=true;inventory.on_recruit(2);skill_points+=3;',1).replace('flags.rescued=true;skill_points+=2;','flags.rescued=true;inventory.on_recruit(1);skill_points+=2;',1);p.write_text(s,encoding='utf-8')
print('16 class weapons, independent equipment ownership and old-save restoration.')
