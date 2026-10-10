"""Append the complete campaign without renumbering any 0.6 save-room identity."""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
doc=(ROOT/'docs/01_地图与关卡设计.md').read_text(encoding='utf-8')
names={}
for line in doc.splitlines():
 if re.match(r'\| R\d\d-(\d\d|H[12]) \|',line):
  c=[x.strip() for x in line.split('|')[1:-1]];names[c[0]]=c[1]
p=ROOT/'scripts/content_v06.gd';s=json.loads((ROOT/'source/baseline_v06.json').read_text(encoding='utf-8'))['content'].replace('0.6.1','1.0.0')
roster=json.loads(re.search(r'const ROSTER=(\[.*?\])\nconst ENEMIES=',s,re.S)[1])
assert len(roster)==7,'Pinned baseline must have seven roles'
new=[
 ('雷牙','雷刃忍者','leiya','leiya',95,'空中双刃连击，雷电破势；迁木园四雷暗阁招募。','ninja'),
 ('佩奇','魔法科技师','peiqi','peiqi',95,'符墨弹与绘笔风暴；绘笔分站审计招募。','ink'),
 ('炉灯','蒸汽机器人','ludeng','ludeng',135,'拳锤、泄压护盾；蒸汽提升间解除强制协议。','steam'),
 ('缇娅','驯龙师','tiya','tiya',105,'长枪与幼龙火焰；熔海卵窟保护幼龙。','dragon'),
 ('黎照','光刃剑客','lizhao','lizhao',110,'光刃双斩、破盾；武士会馆解放剑誓。','light'),
 ('巴洛','枪炮师','baluo','baluo',110,'远距炮弹、近距弹幕；停火军火棚救援。','cannon'),
 ('莫恩','亡灵法师','moen','moen',95,'魂钉、骨牢控制；档案院退出魂契。','necromancer'),
 ('塞琳','牧师','selin','selin',100,'净化铃与有限治疗；不灭祈堂守护。','healer'),
 ('鸦眼','神射手','yayan','yayan',95,'贯穿步枪、三线狙击；观测狙击台招募。','rifle'),
 ('星烬','星烬魔法师','xingjin','xingjin',100,'星弹、三源共鸣；镜渊断观台归还观测核。','star')]
skills=json.loads((ROOT/'data/skills.json').read_text(encoding='utf-8'))
for i,(name,role,model,flag,hp,desc,kind) in enumerate(new,7):
 roster.append(dict(name=name,role=role,model=model+'_v10',hp=hp,flag=flag,skills=[skills[str(i)][n]['name'] for n in ['C1','C2','M2']],desc=desc,archetype=kind))
s=re.sub(r'const ROSTER=\[.*?\]\nconst ENEMIES=',lambda _: 'const ROSTER='+json.dumps(roster,ensure_ascii=False,indent=1)+'\nconst ENEMIES=',s,flags=re.S)
regions=['余烬维修所','灰闸囚厂','锈脊齿轮井','雾肺水务区','黑棘迁木园','夜血城堡','神笔实验室','烬海熔炉','白骨东渡遗城','幽冥档案院','雷墓轨道堡','镜渊裂界','灰烬冠城']
s=re.sub(r'const REGIONS=.*',lambda _: 'const REGIONS='+json.dumps(regions,ensure_ascii=False),s)
s=re.sub(r'const STARTS=.*','const STARTS=[11,0,8,18,26,34,42,50,58,66,74,82,90]',s)
enemies=json.loads(re.search(r'const ENEMIES=(\{.*?\})\nconst QUESTS=',s,re.S)[1])
for kind,name,model,hp,extra in [
 ('imp','熔浆小鬼','imp',100,{}),('skeleton','束魂武士','skeleton',120,{}),('werewolf','月血狼人','werewolf',130,{}),('scorpion','轨道蝎卫','scorpion',145,{}),('mirror_beast','镜相猎兽','mirror_beast',150,{}),('shield','冠城盾卫','shield',170,{'human':True,'shield':True}),('sniper','磁轨狙手','sniper',105,{'human':True,'ranged':True}),('specter','档案幽魂','specter',95,{'flying':True,'ranged':True})]:
 enemies[kind]=dict(name=name,model=model+'_v10',hp=hp,**extra)
bosses=[('smelter','羊角熔铸王',1050,['热浪','炉矛','冲锋']),('general','白骨将军',1100,['剑气','骨阵','冲锋']),('judge','千名亡灵法官',1150,['魂弹','魂潮','契约刺']),('emperor','风暴蝎帝',1200,['雷弹','震地','冲锋']),('triphase','裂界三相兽',1300,['镜弹','血潮','复写突进']),('regent','灰冠摄政·赫律',1500,['王剑','裁稿波','冲锋'])]
for n,(kind,name,hp,patterns) in enumerate(bosses,7):enemies[kind]=dict(name=name,model=kind+'_v10',hp=hp,boss=True,flag='boss'+str(n),patterns=patterns,extended=True)
for i,base in enumerate(['hound','thorn','blood_guard','smelter','general','judge','emperor','mirror_beast'],1):
 original=enemies[base].copy();original.update(name=['裂齿犬王','铁棘古树','镜血侍臣','熔巢幼王','无名剑魂','千页典狱','裂雷巨鳗','镜相首领'][i-1],hp=480+i*55,boss=True,flag='elite'+str(i),extended=True,patterns=['震地','远射','冲锋']);enemies['elite'+str(i)]=original
s=re.sub(r'const ENEMIES=\{.*?\}\nconst QUESTS=',lambda _: 'const ENEMIES='+json.dumps(enemies,ensure_ascii=False,indent=1)+'\nconst QUESTS=',s,flags=re.S)
quests=json.loads(s.split('const QUESTS=')[1])
goals=['制作熔界护套、解除强制协议，击败熔铸王。','取得重锚牵引，解放东渡剑誓，击败白骨将军。','真视名字顺序，解除强制魂契，击败亡灵法官。','救下列车，接通轨链，击败风暴蝎帝。','收集三源观测核，封界三锁，击败三相兽。','解开三炉锁，击败摄政，与米菈选择城市的未来。']
for i in range(7,13):quests.append(dict(title=regions[i],flag='boss'+str(i),region=i,goal=goals[i-7]))
s=s.split('const QUESTS=')[0]+'const QUESTS='+json.dumps(quests,ensure_ascii=False,indent=1)+'\n'
p.write_text(s,encoding='utf-8')
rooms=json.loads((ROOT/'source/baseline_v06.json').read_text(encoding='utf-8'))['rooms'];assert len(rooms)==50
def prop(kind,x,y,text):return dict(kind=kind,p=[x,y,0],text=text)
def enemy(kind,x,y,face=-1):return dict(kind=kind,p=[x,y,0],face=face)
styles={7:'furnace',8:'bonecity',9:'archive',10:'rail',11:'rift',12:'crown'}
kindpairs={7:['imp','werewolf'],8:['skeleton','sniper'],9:['specter','skeleton'],10:['scorpion','sniper'],11:['mirror_beast','specter'],12:['shield','sniper']}
def room(region,number,side=False,return_to=None):
 idx=len(rooms);rid=f'R{region:02}-'+(f'H{number}' if side else f'{number:02}')
 # Authored tier shapes vary by room and region. Entrances stay on stable ground.
 tier=(number+region)%3+3;upper=tier+3+(region%2);cut=-6+region*.37+number*.21
 platforms=[[-22,22,0],[-18,cut,tier],[cut+4,22,upper]]
 ladders=[dict(x=-13,low=0,high=tier,z=-.25,hatch=False),dict(x=15,low=0,high=upper,z=-.25,hatch=False)]
 stairs=[]
 if number in [1,4,8]:stairs=[dict(a=[-20,0],b=[cut,tier],z=0,width=3,thick=.25)]
 if number in [2,3] and not side:
  platforms.append([-9+number,13,upper+3]);ladders.append(dict(x=4+number,low=upper,high=upper+3,z=-.25,hatch=False))
 exit_y=upper if number in [3,4,5,6] else 0
 e=[] if number in [1,8] else [enemy(kindpairs[region][0],1,0),enemy(kindpairs[region][1],17,upper)]
 if number==7 and not side:e=[enemy(bosses[region-7][0],6,0)];exit_y=0
 r=dict(id=rid,name=names.get(rid,rid),region=region,style=styles[region],theme=styles[region],template=0,kit=True,platforms=platforms,ladders=ladders,slopes=stairs,spawn=[-19,0,0],back=[-20,0,0],exit=[20,exit_y,0],previous=idx-1,next=idx+1,checkpoint=[-19,0,0],gate='boss'+str(region) if number in [7,8] and not side else '',terminal=False,enemies=e,props=[],hint='左门回访，右门推进。中层支路可寻找同伴和装备；休息灯保存与传送。',bounds=[-22,22,-2,max(p[2] for p in platforms)+5])
 if side:r.update(previous=return_to,next=return_to,next_spawn=[-9,0,0],back_spawn=[-9,0,0],exit=[20,0,0],gate='');r['hint']='支线房间：领取奖励后，两侧出口均返回入口所在主线房间。'
 if number in [2,4,6] and not side:r['props'].append(prop('chest',-10,tier,'区域补给 · 铁屑与齿芯'))
 if number==1 and not side:r['props'].append(prop('travel',-12,0,'封界站 · 已探索区域传送'));r['story']=regions[region]+'\n'+goals[region-7]
 rooms.append(r);return r
rooms[49].update(next=50,terminal=False,hint='实验日志已保全。右门前往烬海熔炉；左门返回实验室，封界站可回访。')
for region in range(7,13):
 for number in range(1,9):room(region,number)
rooms[50]['previous']=49
rooms[52]['props'].append(prop('recruit9',-8,rooms[52]['platforms'][1][2],'炉灯 · 解除强制搬运协议'))
rooms[54]['props'].append(prop('ability_lava',-10,rooms[54]['platforms'][1][2],'熔界护套 · 装配并学习潜行'))
rooms[51]['props'] += [prop('pressure_a',-9,0,'关闭热压阀'),prop('pressure_b',8,0,'泄压后固定炉门')];rooms[51]['gate']='pressure_done'
rooms[55]['lava_pool']=[-4,8,-1.2];rooms[55]['platforms']=[[-22,-4,0],[-4,8,-1.2],[8,22,0],[-9,10,3],[10,22,7]];rooms[55]['ladders']=[dict(x=-8,low=0,high=3,z=-.25,hatch=False),dict(x=16,low=0,high=7,z=-.25,hatch=False)];rooms[55]['exit']=[20,7,0]
rooms[60]['props'].append(prop('recruit11',-9,rooms[60]['platforms'][1][2],'黎照 · 解除旧誓约'))
rooms[62]['props'].append(prop('ability_anchor',-10,rooms[62]['platforms'][1][2],'重锚牵引器 · 全队工具'));rooms[62]['gate']='heavy_anchor';rooms[63]['props'].append(prop('anchor_pull',-10,0,'重锚 · 拉开船坞重门'));rooms[63]['gate']='anchor_open'
rooms[67]['props'] += [prop('name_a',-10,0,'真名 ① 米菈'),prop('name_b',0,0,'真名 ② 阿芙'),prop('name_c',10,0,'真名 ③ 赫律'),prop('name_reset',-17,0,'姓名锁复位')];rooms[67]['gate']='names_done'
rooms[70]['props'].append(prop('ability_sight',-9,rooms[70]['platforms'][1][2],'真视灯 · 读取隐去的记录'));rooms[71]['props'].append(prop('recruit13',-8,rooms[71]['platforms'][1][2],'莫恩 · 自愿契约退出条款'))
rooms[75]['props'] += [prop('rail_off',-9,0,'断开轨道电源'),prop('rail_route',3,0,'转接安全轨道'),prop('rail_on',10,0,'上电放行转运列车')];rooms[75]['gate']='train_saved'
rooms[76]['props'].append(prop('ability_rail',-9,rooms[76]['platforms'][1][2],'轨链滑行 · 启动中继平台'));rooms[76]['gate']='rail_slide';rooms[76]['elevators']=[dict(x=-4,low=0,high=8,width=5)];rooms[78]['props'].append(prop('recruit15',-9,rooms[78]['platforms'][1][2],'鸦眼 · 交出未发警报'))
rooms[83]['props'].append(prop('gravity',-9,0,'镜引力开关 · 调整浮桥高度'));rooms[83]['floats']=[dict(x=0,low=.2,high=3,width=6)]
for i,number in enumerate([83,84,85]):rooms[number]['props'].append(prop('core'+str(i+1),-8,rooms[number]['platforms'][1][2],'观测核 · 三源记录'))
rooms[86]['props'].append(prop('ability_resonance',-10,rooms[86]['platforms'][1][2],'共鸣封界器 · 三源锁工具'))
rooms[87]['props'] += [prop('source_a',-10,0,'源锁 · 机械'),prop('source_b',0,0,'源锁 · 魔法'),prop('source_c',10,0,'源锁 · 电能')];rooms[87]['gate']='sources_done'
rooms[89]['props'] += [prop('separation_core',-8,0,'米菈投影 · 分离核心与真实意愿')]
for number,ability,kind in [(92,'rail_slide','lock_power'),(93,'phase_step','lock_blood'),(94,'resonance_tool','lock_rift')]:
 rooms[number]['props'].append(prop(kind,-9,0,'冠城炉锁 · '+{'lock_power':'轨链','lock_blood':'裂隙','lock_rift':'共鸣'}[kind]));rooms[number]['gate']=kind
rooms[95]['props'].append(prop('final_warning',-10,0,'米菈 · 终战前整备与返回'))
rooms[97].update(next=97,terminal=True,hint='炉心最终选择。三个城市锚点决定能否共同分离；可随时返回维修所补做。');rooms[97]['props'] += [prop('ending',8,0,'与米菈决定灰炉城的未来'),prop('portal95',-9,0,'返回终战前整备'),prop('travel',-13,0,'返回城市锚点')]
# Five hub rooms, joined via explicit two-way portals.
for number in range(2,7):
 idx=len(rooms);r=dict(rooms[11]);r=json.loads(json.dumps(r));r.update(id=f'R00-{number:02}',name=names[f'R00-{number:02}'],region=0,previous=11,next=11,enemies=[],terminal=False,gate='',platforms=[[-22,22,0],[-14+number,12,3+number*.2]],ladders=[dict(x=-8,low=0,high=3+number*.2,z=-.25,hatch=False)],slopes=[],spawn=[-19,0,0],back=[-20,0,0],exit=[20,0,0],checkpoint=[-19,0,0],props=[prop('portal11',-12,0,'返回余烬广场')],hint='维修所安全区：整备、交易、制作与城市锚点；左右门返回广场。');rooms.append(r);rooms[11]['props'].append(prop('portal'+str(idx),-15+(number-2)*6,0,r['name']))
rooms[98]['props'] += [prop('craft',-3,0,'铆火工坊 · 材料制作'),prop('upgrade',5,0,'强化武器')]
rooms[99]['props'] += [prop('quest_board',0,0,'同伴委托 · 城市协作任务')]
rooms[100]['props'] += [prop('shop',0,0,'灰街商店 · 装备与补给')]
rooms[101]['props'] += [prop('recruit8',0,0,'佩奇 · 审计失控绘笔'),prop('craft',9,0,'绘笔配方台')]
rooms[102]['props'] += [prop('anchor_water',-8,0,'城市锚点 · 水'),prop('anchor_air',0,0,'城市锚点 · 气'),prop('anchor_power',8,0,'城市锚点 · 电'),prop('travel',14,0,'封界站 · 区域传送')]
# Two authored branches per region; preserve the existing R02-H1 mining room at 17.
starts=[None,0,8,18,26,34,42,50,58,66,74,82,90]
side_indices={};elite_regions={1:1,4:2,5:3,7:4,8:5,9:6,10:7,11:8}
for region in range(1,13):
 for number in [1,2]:
  if region==2 and number==1:side_indices[(region,number)]=17;continue
  parent=starts[region]+(2 if number==1 else 5)
  if region==2:parent=13 if number==2 else 12
  idx=len(rooms);side_indices[(region,number)]=idx
  if region>=7:r=room(region,number,True,parent)
  else:
   r=json.loads(json.dumps(rooms[parent]));r.update(id=f'R{region:02}-H{number}',name=names.get(f'R{region:02}-H{number}','遗物支路'),previous=parent,next=parent,terminal=False,gate='',next_spawn=[-10,0,0],back_spawn=[-10,0,0],props=[],enemies=[enemy(['hound','ranged','wraith','thorn','blood_guard','scribe'][region-1],6,0)],spawn=[-19,0,0],back=[-20,0,0],exit=[20,0,0]);r.pop('story',None);rooms.append(r)
  r['platforms']=[[-22,22,0],[-18,-6,3+region*.15],[-2,22,6+number*.5]];r['ladders']=[dict(x=-12,low=0,high=3+region*.15,z=-.25,hatch=False),dict(x=13,low=0,high=6+number*.5,z=-.25,hatch=False)];r['slopes']=[];r['bounds']=[-22,22,-2,12]
  r['props'].append(prop('loot_'+(['gear_ring','wind_thread','bone_rune','steam_rune','blood_mirror','furnace_armor','steam_rune','bone_rune','light_bell','power_chain','star_rune','rift_armor'][region-1]),9,6+number*.5,'独特藏匣 · 装备奖励'))
  rooms[parent]['props'].append(prop('portal'+str(idx),-7,0,r['name']+' · 支路入口'))
  if number==2 and region in elite_regions:r['enemies']=[enemy('elite'+str(elite_regions[region]),5,0)]
  r['hint']='清理敌人后领取装备与委托奖励；两侧出口均返回 '+rooms[parent]['name']+'。'
recruits={(4,2):7,(7,1):10,(8,1):12,(9,1):14,(11,1):16}
for pair,actor in recruits.items():rooms[side_indices[pair]]['props'].append(prop('recruit'+str(actor),-9,rooms[side_indices[pair]]['platforms'][1][2],roster[actor]['name']+' · 解除束缚后交谈'))
gates={(4,2):'phase_step',(7,2):'lava_license',(8,2):'rail_slide',(9,2):'true_sight',(10,2):'resonance_tool',(11,2):'resonance_tool',(12,1):'heavy_anchor'}
for pair,gate in gates.items():rooms[side_indices[pair]]['entry_gate']=gate
# Spatial map metadata and graph. Main routes zig-zag vertically; branches sit off the trunk.
origins={0:(600,440),1:(80,50),2:(490,50),3:(900,50),4:(1310,50),5:(80,390),6:(490,390),7:(900,390),8:(1310,390),9:(80,730),10:(490,730),11:(900,730),12:(1310,730)}
counts={}
for r in rooms:
 region=r['region'];o=origins[region];n=counts.get(region,0);counts[region]=n+1
 if 'H' in r['id']:x,y=((-1 if r['id'].endswith('1') else 4)*70,110)
 elif region==0:x,y=((n%3)*65,(n//3)*70)
 else:
  order=int(r['id'].split('-')[1])-1;x=(order%4 if order<4 else 3-order%4)*75;y=(order//4)*105
 r['map']=[o[0]+x,o[1]+y,60,50+(r['bounds'][3]-8)*2]
assert len(rooms)==126 and len({r['id'] for r in rooms})==126
(ROOT/'data/rooms.json').write_text(json.dumps(rooms,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'data/campaign_v10.json').write_text(json.dumps({'version':'1.0.0','rooms':126,'roles':17,'main_bosses':12,'elites':8,'side_indices':{f'{k[0]}:{k[1]}':v for k,v in side_indices.items()}},indent=2),encoding='utf-8')
print('126 rooms, 17 playable actors, 12 main bosses, 8 elites; old indices retained.')
