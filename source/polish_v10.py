from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
p=ROOT/'data/rooms.json';rooms=json.loads(p.read_text(encoding='utf-8'))
for r in rooms:
 if r['region']==0:r['map'][1]+=145
 if int(r['region'])>=7:r['rest']=r['id'].endswith(('-01','-06','-08'))
p.write_text(json.dumps(rooms,ensure_ascii=False,indent=2),encoding='utf-8')
p=ROOT/'data/skills.json';trees=json.loads(p.read_text(encoding='utf-8'))
effects=[('向前刺击，单次高破势。','齿刃旋转三次，攻击附近目标。'),('机械臂前砸，修补少量自身生命。','机械臂重砸附近敌人。'),('弓箭远射。','快速发射三箭。'),('骨剑飞出后返刃，去程与回程分别命中。','三次斩击，打破敌人架势。'),('丝线束缚附近敌人并切割。','安全短位移后近身突袭。'),('血瓶命中后恢复自身少量生命。','赤汞瓶命中后溅射邻近敌人。'),('电弧拳控制附近敌人并群体破势。','三秒绝缘护盾，承受伤害减半。'),('雷刃两次迅速切割并短时束缚敌人。','三段雷刃连斩。'),('符墨弹命中后短时减速敌人。','强化符墨弹与范围束缚。'),('活塞重拳群体击退。','锅炉震荡与三秒护盾。'),('幼龙吐火，命中后扩散周围伤害。','长枪和龙翼两次范围横扫。'),('光刃前斩，高单体伤害。','十字两段光刃范围斩。'),('手炮弹命中后爆炸溅射附近敌人。','连续两发重炮爆炸。'),('魂钉束缚敌人，召唤四秒骨仆，最多两个。','骨牢控制周围敌人，魂弹追击。'),('圣铃净化攻击，短时护盾。','圣域为三名出战成员恢复少量生命。'),('符文步枪发射贯穿弹。','连续三次贯穿狙击。'),('三源星弹贯穿敌人。','三次星弹贯穿。')]
for actor in range(17):
 for i,node in enumerate(['C1','C2']):trees[str(actor)][node]['description']=effects[actor][i]+(' Ctrl + J 发动。' if i==0 else ' Ctrl + K 发动。')+' 升级强化攻击属性。'
 trees[str(actor)]['C3']['description']='职业高阶招式「'+trees[str(actor)]['C3']['name']+'」。Ctrl + Shift 发动，长前摇后强力范围攻击；每级提高伤害。'
 trees[str(actor)]['M2']['description']='空中 Ctrl + Space，一次短冲刺；每次腾空一次。初始消耗 16 魔力，升级每级减少 2 魔力与 0.5 秒冷却。'
p.write_text(json.dumps(trees,ensure_ascii=False,indent=2),encoding='utf-8')
p=ROOT/'scripts/game.gd';s=p.read_text(encoding='utf-8').replace('if rooms[room].has("checkpoint"):add_prop','if rooms[room].has("checkpoint") and data.get("rest",true):add_prop',1)
s=s.replace('active_slot=next;switch_cooldown=1;','active_slot=next;campaign.form_time=0;switch_cooldown=1;',1)
s=s.replace('func actor_down() -> void:\n','func actor_down() -> void:\n\tcampaign.form_time=0\n',1)
p.write_text(s,encoding='utf-8')
p=ROOT/'scripts/qa_v06.gd';s=p.read_text(encoding='utf-8').replace('KEY_B','KEY_H').replace('跳跃 B','跳跃 H').replace('B 键实际','H 键实际');p.write_text(s,encoding='utf-8')
p=ROOT/'scripts/hud.gd';s=p.read_text(encoding='utf-8').replace('\textension.build()','\textension.build()\n\tif game.screen in ["roster","settings"]:v10.navigation()',1)
s=s.replace('text_at(Vector2(42,170),','bar(Vector2(42,188),180,game.campaign.resonance,100,Color(.55,.26,.76))\n\ttext_at(Vector2(230,193),"B 共鸣" if game.campaign.form_time<=0 else "形态 %.1f秒"%game.campaign.form_time,13,MUTED)\n\tif game.inventory.wrap=="lava_wrap":text_at(Vector2(42,215),"熔界护套 · 热负荷 %d / 100"%game.heat,15,GOLD)\n\ttext_at(Vector2(42,170),',1)
p.write_text(s,encoding='utf-8')
print('Unique skill descriptions, late safe rooms, unified navigation and thermal feedback.')
