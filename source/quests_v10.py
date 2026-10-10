"""Persistent side/hidden contracts: accept, find evidence, clear and deliver."""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
rooms=json.loads((ROOT/'data/rooms.json').read_text(encoding='utf-8'))
meta=json.loads((ROOT/'data/campaign_v10.json').read_text(encoding='utf-8'));side={k:int(v) for k,v in meta['side_indices'].items()}
sq_locations=[(2,1),(4,1),(6,1),(7,1),(7,1),(8,1),(9,1),(1,2),(3,1),(5,1),(6,2),(9,2),(10,1),(3,2),(4,2),(6,2),(0,3),(4,1),(9,1),(6,1)]
sq_names=['暗矿撤离','幼徒的呼吸','失控绘笔','炉灯的自由','不卖的龙卵','最后一批军火','守夜的名单','煤仓幸存者','孤魂渡口','赤汞旧账','零七以前','东渡剑名','未发出的警报','城锚·水','城锚·气','城锚·电','阿芙的运输表','两种忍道','契约退出条款','铆火与符墨']
hq_locations=[(4,2),(11,1),(5,2),(7,2),(8,2),(10,2),(11,2),(12,1)]
hq_names=['四雷暗阁','星烬断观','假镜后的名字','熔海余烬','东渡未寄信','裂雷测站','镜兽巢','摄政的旧扳手']
rewards=['gear_ring','wind_thread','steam_rune','steam_rune','furnace_armor','bone_rune','light_bell','iron_armor','bone_rune','blood_mirror','power_chain','bone_rune','power_chain','water_wrap','poison_wrap','steam_rune','gear_ring','wind_thread','light_bell','steam_rune']
entries=[]
for hidden,names,locations in [(False,sq_names,sq_locations),(True,hq_names,hq_locations)]:
 for i,(name,pair) in enumerate(zip(names,locations),1):
  room=98+pair[1]-2 if pair[0]==0 else side[f'{pair[0]}:{pair[1]}']
  # Proof lives in a separate neighboring main room, requiring a return trip.
  proof=int(rooms[room]['previous']) if pair[0]!=0 else 10
  qid=('HQ' if hidden else 'SQ')+f'{i:02}'
  reward=['wind_thread','star_rune','blood_mirror','furnace_armor','bone_rune','power_chain','star_rune','rift_armor'][i-1] if hidden else rewards[i-1]
  entries.append(dict(id=qid,title=name,hidden=hidden,room=room,proof_room=proof,reward=reward,description=f"在{rooms[room]['name']}接取委托；去{rooms[proof]['name']}找证物，返回清理追兵并交付。"))
  rooms[room]['props'].append(dict(kind='quest_'+qid,p=[-16+(i%3)*2,0,0],text=name+' · 委托 / 交付'))
  rooms[proof]['props'].append(dict(kind='proof_'+qid,p=[-3+(i%5),rooms[proof]['platforms'][1][2] if len(rooms[proof]['platforms'])>1 else 0,0],text=name+' · 保全证物'))
assert len(entries)==28
(ROOT/'data/quests.json').write_text(json.dumps(entries,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'data/rooms.json').write_text(json.dumps(rooms,ensure_ascii=False,indent=2),encoding='utf-8')
print('20 side contracts + 8 hidden contracts with persistent evidence and return objectives.')
