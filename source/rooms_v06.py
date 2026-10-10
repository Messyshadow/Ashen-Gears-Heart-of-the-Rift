"""Extend the stable 0.4 room indices with four authored eight-room regions."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def build():
    from rooms_v04 import build as baseline
    rooms=baseline()
    for r in rooms:
        r['region']=0 if r['id'].startswith('R00') else int(r['id'][1:3]);r['terminal']=False
    rooms[16]['next']=18;rooms[16]['hint']='总井已经恢复。沿维修桥右门进入雾肺水务区；向左可返回督工轴心。'
    rooms[17]['next_spawn']=[-2,6,0];rooms[17]['back_spawn']=[-2,6,0]
    rooms[11]['hint']='维修所：C 名册编队，N 任务，M 地图；在休息灯开启已发现区域传送。'
    rooms[11]['props'].append(dict(kind='travel',p=[-12,0,0],text='封界站 · 已发现区域传送'))
    def room(region,number,name,platforms,exit_y=0,gate='',ladders=(),stairs=(),enemies=(),props=(),hint='',**extra):
        idx=len(rooms);r=dict(id=f'R{region:02}-{number:02}',name=name,region=region,style={3:'water',4:'garden',5:'castle',6:'laboratory'}[region],
            theme={3:'aqua',4:'green',5:'crimson',6:'cyan'}[region],template=0,kit=True,platforms=platforms,spawn=[-19,0,0],back=[-20,0,0],
            exit=[20,exit_y,0],next=idx+1,previous=idx-1,checkpoint=[-19,0,0],gate=gate,terminal=False,
            ladders=[dict(x=x,low=lo,high=hi,z=-.25,hatch=False) for x,lo,hi in ladders],slopes=[dict(a=a,b=b,z=0,width=3,thick=.25) for a,b in stairs],
            enemies=[dict(kind=k,p=[x,y,0],face=f) for k,x,y,f in enemies],props=[dict(kind=k,p=[x,y,0],text=t) for k,x,y,t in props],hint=hint)
        r.update(extra);r['bounds']=[-22,22,-2,max(p[2] for p in platforms)+5];r['title']=r['id']+' / '+name;rooms.append(r);return r
    f=lambda a,b,y:[a,b,y]
    room(3,1,'干管入口',[f(-22,22,0),f(-14,-5,3)],ladders=[(-10,0,3)],props=[('clue_water',-8,3,'维修札记 · 被删去的魂名')],
        hint='新区域 · 雾肺水务区。左门返回维修桥，右门进入泄压厅；休息灯可传送回旧区域。',story='冷却水将灰炉城的名字带进下水道。\n沈烬的束魂铭文在折返维修梯。先恢复泄压系统。')
    room(3,2,'蒸汽泄压厅',[f(-22,22,0),f(-16,-3,4),f(5,22,4)],gate='steam',ladders=[(-12,0,4),(12,0,4)],
        enemies=[('wraith',7,6,-1)],props=[('water',-12,0,'A 加水阀'),('steam',-6,0,'B 排水阀'),('confirm',-7,4,'蒸汽旁路'),('steam_reset',-17,0,'压力安全复位')],
        hint='关闭排水 → 加水至中水位 → 关加水 → 开蒸汽旁路 → 排水。错序可复位。',water_pool=[-3,10,0],floats=[dict(x=1,low=.2,high=2.2,width=4)])
    room(3,3,'下水三层井',[f(-22,22,0),f(-18,-2,4),f(3,22,7)],7,ladders=[(-14,0,4),(8,0,7)],
        enemies=[('wraith',0,6,-1),('hound',10,0,-1),('ranged',17,7,-1)],props=[('chest',-12,4,'水务零件 · 铁屑 +20')],
        hint='青铜水轮井：中层藏匣，右侧长梯接上排水管。幽影不能暗杀。',water_pool=[-10,17,-.8])
    room(3,4,'折返维修梯',[f(-22,22,0),f(-4,22,5),f(-18,-7,8)],5,ladders=[(-12,0,8),(14,0,5)],stairs=[([-16,0],[-4,5])],
        enemies=[('human',-5,0,-1),('wraith',7,7,-1)],props=[('recruit3',7,5,'沈烬 · 解除束魂铭文')],
        hint='清除维修梯守卫，E 招募沈烬；C 名册将骨剑客编入三人队伍。',story='沈烬：铭文在叫我杀你……这不是我的誓约。\n凯恩：我会先拆掉锁，再问你的名字。')
    room(3,5,'浮筒跳跃槽',[f(-22,-8,0),f(-8,22,0),f(-4,3,3),f(8,22,6)],6,ladders=[(15,0,6)],
        enemies=[('thorn',2,0,-1),('wraith',11,8,-1)],props=[('clue_names',0,3,'魂名残页 · 米菈的拒绝签字')],
        hint='二段跳跨过浮筒；空中按 K 下砸。上层残页记录了米菈拒绝签字的事实。',floats=[dict(x=-6,low=.2,high=2,width=3)],water_pool=[-7,8,-.4])
    room(3,6,'管喉育巢',[f(-22,22,0),f(-15,-4,3),f(5,22,5)],5,ladders=[(-10,0,3),(12,0,5)],
        enemies=[('wraith',2,4,-1),('thorn',11,0,-1)],props=[('portal19',-9,3,'泄压厅维修捷径')],
        hint='Boss 前整备；上层捷径返回泄压厅。蒸汽口有橙色预警，可走上层避开。',vents=[dict(x=4,y=0,period=4,phase=0)])
    room(3,7,'母体排水室',[f(-22,22,0),f(-19,-10,4),f(10,19,4)],gate='boss3',ladders=[(-15,0,4),(15,0,4)],
        enemies=[('mother',6,0,-1)],hint='管喉之母：毒潮远射、管刺近击、震地波。半血后毒潮增加；跳上侧台避地波。',water_pool=[-18,18,-1])
    room(3,8,'阀闸回城口',[f(-22,22,0),f(-6,22,4)],4,stairs=[([-18,0],[-6,4])],gate='boss3',
        props=[('portal18',-10,0,'水务回环 · 干管入口'),('travel',-6,4,'封界站 · 旧区域回访')],
        hint='右门进入黑棘迁木园；左门返回排水室。已发现传送点永久保留。')
    room(4,1,'铁根温室',[f(-22,22,0),f(-9,9,3)],ladders=[(-6,0,3)],props=[('chest',4,3,'根庭补给 · 铁屑 +20')],
        hint='新区域 · 黑棘迁木园。玻璃穹顶下的铁根正在毒性循环；右侧通向迁木苗床。',story='伊瑟：这些铁根原本净化空气。\n暖灯仍能引导迁木；关闭毒阀，给幸存者留下路。')
    room(4,2,'迁木苗床',[f(-22,22,0),f(-18,-5,4),f(5,22,4)],4,gate='root_bridge',ladders=[(-12,0,4),(15,0,4)],
        props=[('root_light',-13,0,'右侧暖灯 · 引迁木'),('root_lock',10,0,'桥位固定柄'),('root_reset',-17,0,'迁木安全复位')],
        enemies=[('thorn',13,0,-1)],hint='E 打开暖灯，等迁木到右侧桥位，再 E 固定柄。树冠随平台移动；错位可复位。',root_bridge=dict(low=-7,high=3,y=4,width=5))
    room(4,3,'毒草回廊',[f(-22,22,0),f(-18,-4,4),f(1,22,7)],7,ladders=[(-12,0,4),(9,0,7)],
        enemies=[('thorn',-2,0,-1),('wraith',7,7,-1),('ranged',17,7,-1)],props=[('chest',-8,4,'避毒零件 · 铁屑 +20')],
        hint='毒草口按固定周期喷发，先看橙色提示；上层平台可绕过毒雾。',vents=[dict(x=0,y=0,period=4.5,phase=1),dict(x=10,y=0,period=4.5,phase=0)])
    room(4,4,'孢子跳井',[f(-22,22,0),f(-17,-4,5),f(4,22,8)],8,ladders=[(-11,0,5),(12,0,8)],
        props=[('airdash',-8,5,'A04 空中冲刺 · 全队训练')],enemies=[('wraith',5,10,-1)],
        hint='上层 E 学全队空冲：Ctrl + Space。二段跳与空冲分别每次腾空一次；右梯提供安全退路。',anchors=[[0,7,0],[8,9.2,0]])
    room(4,5,'双忍藏室',[f(-22,22,0),f(-3,22,6),f(-18,-8,3)],6,ladders=[(-13,0,3),(14,0,6)],stairs=[([-15,0],[-3,6])],
        props=[('recruit4',9,6,'纱隐 · 解开影织锁')],enemies=[('blood_guard',0,0,-1),('thorn',10,0,-1),('wraith',13,8,-1)],
        hint='击退藏室追兵后招募纱隐。影织忍者以双刃快攻、影缚与安全短位移战斗。')
    room(4,6,'根轮控制厅',[f(-22,22,0),f(-16,-3,3),f(3,22,5)],5,ladders=[(-10,0,3),(14,0,5)],
        props=[('portal27',-8,3,'苗床维护捷径')],enemies=[('thorn',5,0,-1),('scribe',14,5,-1)],
        hint='Boss 前休息与回退；绕上根輪避开喷口，右侧进入女巫穹室。',vents=[dict(x=1,y=0,period=5,phase=.4)])
    room(4,7,'女巫穹室',[f(-22,22,0),f(-18,-10,3),f(8,18,5)],gate='boss4',ladders=[(-14,0,3),(13,0,5)],
        enemies=[('witch',5,0,-1)],hint='迁木女巫：孢弹、根刺与根行冲锋。半血提高攻速；冲锋前有长预警，留出退路。')
    room(4,8,'地表采光井',[f(-22,22,0),f(-1,22,5)],5,stairs=[([-17,0],[-1,5])],gate='boss4',
        props=[('portal26',-12,0,'迁木园回环'),('travel',4,5,'封界站 · 旧区域回访')],hint='迁木园循环已经解除。沿采光井右门进入夜血城堡；封界站可回访旧区。')
    room(5,1,'血堡吊桥',[f(-22,22,0),f(-12,-3,3),f(7,22,4)],4,ladders=[(-7,0,3),(14,0,4)],
        hint='新区域 · 夜血城堡。齿轮钟控制血液导管；前方双镜可以减速钟摆。',story='维萝：名单上的“自愿”，是他们事后补写的。\n凯恩：我需要原始血契，不是他们的解释。')
    room(5,2,'窥视走廊',[f(-22,22,0),f(-17,-3,4),f(4,22,4)],4,gate='clock_open',ladders=[(-11,0,4),(12,0,4)],
        props=[('mirror_a',-9,0,'镜 A · 对准钟芯'),('mirror_b',8,4,'镜 B · 对准钟芯'),('mirror_reset',-17,0,'双镜复位')],
        enemies=[('blood_guard',1,0,-1)],hint='旋转 A 与 B 让双束光同时照亮钟芯，保持 2 秒后开启走廊门；完成后永久减速钟摆。')
    room(5,3,'钟摆三层塔',[f(-22,22,0),f(-17,-1,4),f(3,22,8)],8,ladders=[(-12,0,4),(11,0,8)],
        enemies=[('blood_guard',-2,0,-1),('ranged',17,8,-1)],props=[('chest',-7,4,'钟塔藏匣 · 铁屑 +20')],
        hint='钟摆攻击前亮橙，暂停时不推进周期。双镜已减速；沿分层竖梯绕过摆锤。',pendulum=dict(x=2,y=0,period=4.8))
    room(5,4,'暗镜书房',[f(-22,22,0),f(-2,22,5),f(-18,-6,8)],5,stairs=[([-16,0],[-2,5])],ladders=[(-12,0,8)],
        enemies=[('blood_guard',6,0,-1),('scribe',13,5,-1)],props=[('blood_record',-10,8,'旧血契 · 米菈的原签名')],
        hint='上层旧血契是可选证据；穿过书房即可前进，证据可随时回访收集。')
    room(5,5,'血契炼金室',[f(-22,22,0),f(-8,8,4),f(9,22,7)],7,ladders=[(-4,0,4),(15,0,7)],
        enemies=[('blood_guard',2,0,-1),('wraith',7,6,-1)],props=[('recruit5',1,4,'维萝 · 解除血瓶封印')],
        hint='击退强征守卫后招募维萝。刺剑近攻，血瓶远射；血瓶回流命中后才治疗。')
    room(5,6,'薄壁裂隙厅',[f(-22,22,0),f(-15,-5,5),f(5,22,5)],5,ladders=[(-10,0,5),(12,0,5)],
        props=[('phase_step',-13,0,'A05 裂隙步 · G 穿过标记薄壁')],enemies=[('blood_guard',11,0,-1)],
        hint='E 学裂隙步，靠近蓝色裂纹壁按 G。只穿标记薄壁，安全落点检测；魔力不足可走上层。',phase_walls=[dict(x=0,y=0,height=4.7)])
    room(5,7,'侯爵宴厅',[f(-22,22,0),f(-19,-11,4),f(9,19,4)],gate='boss5',ladders=[(-15,0,4),(14,0,4)],
        enemies=[('lord',5,0,-1)],hint='血契侯爵：血矛远射、冲锋、双向血潮。半血后矛群增加；利用两侧宴台躲血潮。')
    room(5,8,'棺梯捷径',[f(-22,22,0),f(-5,22,6)],6,ladders=[(13,0,6)],stairs=[([-19,0],[-5,6])],gate='boss5',
        props=[('portal34',-8,0,'血堡回环 · 吊桥'),('travel',4,6,'封界站 · 旧区域回访')],hint='右门进入神笔实验室；已解锁的旧区保持敌人、招募与证据记录。')
    room(6,1,'绘笔登记厅',[f(-22,22,0),f(-15,-4,4)],ladders=[(-9,0,4)],
        props=[('chest',-8,4,'研究物资 · 铁屑 +20')],hint='新区域 · 神笔实验室。复制房、绝缘桥和链路总控都能安全复位。',
        story='零七：我只记得被擦去之前，有人叫过我的名字。\n原始实验日志就在神笔核心台。先停掉校稿机。')
    room(6,2,'复制样本室',[f(-22,22,0),f(-9,9,4),f(13,22,6)],6,ladders=[(-5,0,4),(17,0,6)],gate='copy_complete',
        props=[('scan',-12,0,'扫描原始重块'),('copy',-5,0,'神笔 · 生成一份副本'),('plate_left',0,4,'原块放上左压板'),('plate_right',7,4,'副本放上右压板'),('copy_reset',-17,0,'复制槽复位')],
        enemies=[('scribe',16,6,-1)],hint='扫描重块 → 生成副本 → 左板放原块 → 右板放副本。只有一个复制槽，错序可复位。')
    room(6,3,'绝缘浮桥',[f(-22,-6,0),f(-3,4,2),f(7,22,5),f(-6,22,0)],5,ladders=[(14,0,5)],
        enemies=[('scribe',15,5,-1),('wraith',4,6,-1)],hint='蓝色电柱放电前会变橙；下层安全路与右梯可回退，上层二段跳接空冲。',
        anchors=[[-1,3.3,0],[11,6.3,0]],vents=[dict(x=5,y=0,period=4.2,phase=0)])
    room(6,4,'活体四层仓',[f(-22,22,0),f(-17,-3,4),f(3,22,8),f(-10,15,12)],8,ladders=[(-11,0,4),(10,0,8),(4,8,12)],
        enemies=[('scribe',0,0,-1),('turret',15,8,-1),('wraith',3,11,-1)],props=[('recruit6',0,12,'零七 · 停止记忆覆盖')],
        hint='击退活体仓守卫，攀上第四层 E 解救零七；电能改造人的拳刃与护盾适合近战破势。')
    room(6,5,'神笔核心台',[f(-22,22,0),f(-3,22,6),f(-17,-7,3)],6,stairs=[([-18,0],[-3,6])],ladders=[(-12,0,3)],
        enemies=[('scribe',10,6,-1),('blood_guard',0,0,-1)],props=[('lab_evidence',6,6,'原始实验日志 · 稳定员米菈')],
        hint='E 读取原始日志，取得后永久保留。米菈被转移至更深的炉心，不在本实验室。')
    room(6,6,'链路总控室',[f(-22,22,0),f(-16,-2,4),f(3,22,7)],7,ladders=[(-10,0,4),(12,0,7)],gate='circuit',
        props=[('power',-14,0,'S 总电源'),('split',-7,4,'S → J 分流接线'),('coolant',0,0,'J → C 冷却器接线'),('door_link',8,7,'J → M 门锁接线'),('insulate',15,0,'I 绝缘开关'),('power_reset',-18,0,'安全断路器复位')],
        hint='先断电，接分流、冷却器与门锁，再合绝缘开关；上电冷却 2 秒。上电时不能换线路。')
    room(6,7,'校稿剧场',[f(-22,22,0),f(-18,-9,4),f(10,19,5)],gate='boss6',ladders=[(-14,0,4),(15,0,5)],
        enemies=[('editor',5,0,-1)],hint='无面校稿者：墨弹、裁稿波、复写突进。半血后强化墨弹；左右观测台避波，长前摇再闪避。')
    r=room(6,8,'逃生运输梯',[f(-22,22,0),f(0,22,5)],5,stairs=[([-18,0],[0,5])],gate='boss6',
        props=[('final_report',6,5,'交付实验日志 · 阶段完成'),('travel',-8,0,'封界站 · 所有已发现区域')],
        hint='0.6 阶段终点：交付日志后可回访六大区域与维修所；后续熔炉区域尚未开放。')
    r['next']=len(rooms)-1;r['terminal']=True
    rooms[18]['previous']=16
    (ROOT/'data/rooms.json').write_text(json.dumps(rooms,ensure_ascii=False,indent=2),encoding='utf-8')
    print('V06 ROOMS',len(rooms));return rooms
if __name__=='__main__':build()
