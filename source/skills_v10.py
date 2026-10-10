"""Use authored names; player-facing descriptions reflect implemented mechanics."""
import re,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
text=(ROOT/'docs/02_玩法与开发设计.md').read_text(encoding='utf-8')
# Keep existing save slot identities (Weiluo=5, Zero7=6).
ids={'P00':0,'C01':1,'C02':2,'C03':3,'C04':4,'C06':5,'C08':6,'C05':7,'C07':8,'C09':9,'C10':10,'C11':11,'C12':12,'C13':13,'C14':14,'C15':15,'C16':16}
result={str(i):{} for i in range(17)}
for line in text.splitlines():
 if not re.match(r'\| (P00|C\d\d)-[CMT][123] \|',line):continue
 cells=[c.strip() for c in line.split('|')[1:-1]]
 prefix,node=cells[0].split('-');slot=ids[prefix]
 desc={
 'C1':'角色的专属基本技能。Ctrl + J 发动；学习后可再次升级提升伤害。',
 'C2':'角色的专属范围技能。Ctrl + K 发动；多段、投射或护盾效果依职业变化。',
 'C3':'职业高阶攻击。Ctrl + Shift 发动；长前摇与较大破势，消耗 36 魔力。',
 'M1':'被动：每级生命上限 +5，耐力回复 +8%。翻滚预览展示起手与落地。',
 'M2':'空中 Ctrl + Space，一次短冲刺；每次腾空一次，消耗 16 魔力。',
 'M3':'被动：每级受到的伤害降低 2%。保留地形与二段跳次数限制。',
 'T1':'B 发动共鸣形态。消耗 100 共鸣，持续 12 秒，伤害 +20%、防护 +10%。',
 'T2':'共鸣形态内生效：每级再提高 5% 伤害。不会获得环境免疫或新通行资格。',
 'T3':'共鸣期间 Ctrl + Shift 发动终式，消耗剩余形态时间，强力范围攻击后恢复常态。'
 }[node]
 result[str(slot)][node]={'name':cells[1].split('·')[-1],'description':desc,'branch':{'C':'战斗','M':'身法','T':'共鸣'}[node[0]],'resource':{'C1':18,'C2':28,'C3':36,'M2':16,'T1':100}.get(node,0),'cooldown':{'C1':4,'C2':7,'C3':10,'M2':5}.get(node,0)}
assert all(len(v)==9 for v in result.values()),[(k,len(v)) for k,v in result.items()]
(ROOT/'data/skills.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print('17 character trees, 153 authored nodes')
