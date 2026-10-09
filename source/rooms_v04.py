"""Authored room layout in Godot metres; no dependency on Blender."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def build():
    old=json.loads((ROOT/'data/rooms.json').read_text(encoding='utf-8-sig'))
    rooms=[]
    def room(i,name,style,platforms,spawn,exit,next_id,ladders=(),stairs=(),gate='',theme='iron'):
        r=dict(id=i,name=name,style=style,theme=theme,platforms=platforms,spawn=spawn,back=[spawn[0]-1,spawn[1],0],exit=exit,next=next_id,ladders=list(ladders),slopes=list(stairs),enemies=[],props=[],checkpoint=spawn,hint='前往金色出口；E 交互，越过出口可自动进入下一室。',gate=gate,template=0)
        rooms.append(r);return r
    def floor(a,b,y):return [a,b,y]
    def ladder(x,lo,hi):return dict(x=x,low=lo,high=hi,z=-.25,hatch=False)
    def stair(a,b):return dict(a=a,b=b,z=0,width=3,thick=.25)
    def enemy(r,kind,x,y=0,face=-1):r['enemies'].append(dict(kind=kind,p=[x,y,0],face=face))
    def prop(r,kind,x,y,text):r['props'].append(dict(kind=kind,p=[x,y,0],text=text))
    # 0 Coal: immediate human encounter, optional upper stash, flat exit.
    r=room('R01-01','煤仓醒室','coal',[floor(-22,22,0),floor(-15,-3,4)],[-19,0,0],[20,0,0],1,[ladder(-6,0,4)],theme='coal')
    r['story']='囚友：这把匕首，能替你拆开一条活路。\n凯恩：先找到送我妹妹下去的转运表。\n前方的巡逻守卫可以暗杀，金色门通向下一室。'
    r['hint']='先走出煤仓：A/D 移动，S 潜行，背后 E 暗杀；金色出口在右侧。'
    enemy(r,'human',-8,face=1);prop(r,'chest',-11,4,'煤仓藏匣 · 铁屑 +20')
    r=room('R01-02','巡逻暗道','conveyor',[floor(-22,22,0),floor(-15,22,4)],[-19,0,0],[20,4,0],2,[ladder(-12,0,4)],theme='blue')
    enemy(r,'human',-6,face=1);enemy(r,'ranged',5,4);enemy(r,'hound',13,0)
    r['conveyors']=[[-11,11,0,1.4]];r['hint']='下层输送带改变脚下速度；左侧梯子上到巡逻廊，右侧出口在上层。'
    r=room('R01-03','压料车间','press',[floor(-22,22,0),floor(-19,-1,4),floor(4,22,4),floor(-18,18,8)],[-19,0,0],[20,0,0],3,[ladder(-14,0,4),ladder(12,4,8)],theme='furnace')
    enemy(r,'hound',-3);enemy(r,'human',10);enemy(r,'turret',8,4);enemy(r,'drone',-4,7)
    r['hazards']=[dict(kind='press',p=[3,0,0],period=4,phase=0)]
    prop(r,'chest',-12,8,'高层压力零件 · 铁屑 +20');r['hint']='三层压料台：注意压锤橙色预警，利用上层绕开机械犬。'
    r=room('R01-04','断电囚门','prison',[floor(-22,22,0),floor(2,22,5)],[-19,0,0],[20,0,0],4,stairs=[stair([-14,0],[2,5])],gate='rescued',theme='prison')
    enemy(r,'human',-7);enemy(r,'hound',2);enemy(r,'ranged',12,5)
    prop(r,'rescue',14,0,'洛铆 · 解除强制项圈');r['hint']='囚门楼梯与监视廊：击退守卫后救出洛铆。F / 1 / 2 切换。'
    r=room('R01-05','钩索维修台','workshop',[floor(-22,22,0),floor(-7,22,6)],[-19,0,0],[20,6,0],5,[ladder(-5,0,6)],gate='grapple',theme='warm')
    prop(r,'grapple',-10,0,'修复 A01 锚点钩索');r['anchors']=[[8,7.3,0],[17,7.3,0]]
    prop(r,'mobility',3,6,'身法训练 · 冲跑、翻越和空中下砸');r['hint']='安全工坊：E 修复钩索。按住 Q 预选前方锚点，松开发射；上层出口。'
    r=room('R01-06','刑柱竖井','grapple',[floor(-22,-7,0),floor(-4,0,2),floor(2,6,4),floor(6,22,4)],[-19,0,0],[20,4,0],6,gate='grapple',theme='void')
    r['anchors']=[[-3,3.3,0],[4,5.3,0],[13,5.3,0]]
    enemy(r,'drone',10,7);enemy(r,'human',17,4)
    prop(r,'shortcut',-9,0,'囚厂捷径 · 巡逻暗道');r['hint']='断裂刑柱：Q 连续连接前方蓝色锚点。坠落将在本室重试。'
    r=room('R01-07','典刑机大厅','execution',[floor(-22,22,0),floor(-18,-7,4),floor(7,18,4)],[-19,0,0],[20,0,0],7,gate='boss',theme='furnace')
    enemy(r,'boss',5);r['hint']='链狱典刑机：落锤、链钩、半血冲击波。橙色预警后 Shift 闪避或 L 弹反。'
    r=room('R01-08','逆向出货门','cargo',[floor(-22,22,0),floor(-2,22,4)],[-19,0,0],[20,4,0],8,stairs=[stair([-15,0],[-2,4])],gate='manifest',theme='cargo')
    prop(r,'manifest',-16,0,'转运表 · 米菈的签名');prop(r,'loop',-17,0,'煤仓回环');prop(r,'hub',-6,0,'前往余烬维修所');enemy(r,'ranged',13,4)
    r['hint']='拿取转运表，沿装卸坡进入锈井。出货厅的吊运轨道与囚厂回环已恢复。'
    r=room('R02-01','锈井入口','lift',[floor(-22,22,0),floor(1,22,6)],[-19,0,0],[20,6,0],9,[ladder(15,0,6)],theme='rust')
    r['elevators']=[dict(x=-2,low=0,high=6,width=5)]
    enemy(r,'hound',7);enemy(r,'ranged',10,6);r['hint']='站上中央吊运台，E 启动升降；右侧竖梯也可以返回。'
    r=room('R02-02','四层配速井','gears',[floor(-22,22,0),floor(-19,-3,4),floor(4,22,4),floor(-5,22,8),floor(-19,22,12)],[-19,0,0],[20,12,0],10,[ladder(-12,0,4),ladder(10,4,8),ladder(-3,8,12)],gate='gear',theme='rust')
    prop(r,'gear0',-15,0,'A 锁销 · 拔出');prop(r,'gear1',7,4,'B 惰轮 · 接入');prop(r,'gear2',1,8,'C 离合 · 合上');prop(r,'gear_reset',-19,0,'齿轮复位')
    enemy(r,'human',-4);enemy(r,'turret',18,4);enemy(r,'drone',3,11)
    r['hint']='四层齿轮井：底层拔锁销，二层接惰轮，三层合离合，四层出井。'
    r=room('R02-03','二层壁抓井','wall',[floor(-22,22,0),floor(-22,-10,4),floor(-6.3,-4.1,5),floor(-1.7,.2,7),floor(3,22,7)],[-19,0,0],[20,7,0],12,[ladder(-12,0,4),ladder(15,0,7)],gate='wall',theme='blue')
    r['walls']=[[-5,0,5],[-.8,0,7]]
    prop(r,'wall',-12,0,'获得 A02 壁抓与壁跳');enemy(r,'hound',8);enemy(r,'ranged',17,7)
    r['hint']='E 学会壁抓：跳向带蓝纹的墙，按住朝墙方向滑落；Space 蹬墙。右梯可回退。'
    # Hub stays at index 11, preserving route references.
    r=room('R00-01','余烬广场','hub',[floor(-22,22,0),floor(-8,8,4)],[-19,0,0],[20,0,0],16,[ladder(-5,0,4)],theme='warm')
    prop(r,'hub_story',-5,0,'阿芙 · 幸存者维修所');prop(r,'upgrade',5,0,'工坊 · 40 铁屑强化');prop(r,'training',0,4,'身法与招式训练');r['hint']='温暖维修所：休息刷新普通敌人。F 切换；T 招式；M 地图。右门回锈井桥。'
    r=room('R02-04','三层投石廊','barrage',[floor(-22,-2,0),floor(-2,3,2),floor(3,22,0),floor(8,22,5)],[-19,0,0],[20,0,0],13,[ladder(17,0,5)],theme='green')
    enemy(r,'ranged',9);enemy(r,'turret',16,5);enemy(r,'drone',2,6);enemy(r,'human',17)
    r['hint']='远程交叉火力：冲跑跳过断层，利用平台遮挡；空中 K 下砸破开守卫。'
    r=room('R02-05','四层轴承台','bearing',[floor(-22,22,0),floor(-5,4,6),floor(7,22,10)],[-19,0,0],[20,10,0],14,[ladder(16,0,10)],stairs=[stair([-18,0],[-5,6])],theme='rust')
    r['elevators']=[dict(x=4,low=6,high=10,width=5)]
    prop(r,'side',-4,6,'暗矿牢房 · 伊瑟的求援');prop(r,'chest',10,10,'总井图纸 · 铁屑 +20')
    enemy(r,'hound',7);enemy(r,'ranged',-2,6);r['hint']='轴承斜梯与升降台组合。中层侧门通向矿族牢房，可招募伊瑟。'
    r=room('R02-06','牛头备料场','stock',[floor(-22,22,0),floor(-20,-6,4)],[-19,0,0],[20,0,0],15,[ladder(-16,0,4)],theme='coal')
    enemy(r,'hound',-3);enemy(r,'human',6);enemy(r,'turret',14)
    prop(r,'rust_shortcut',-8,4,'锈井捷径 · 四层配速井');r['hint']='Boss 前备料场：补满药剂，击退装甲巡逻。上层可打开四层井捷径。'
    r=room('R02-07','督工轴心','minotaur',[floor(-22,22,0),floor(-18,-10,3),floor(10,18,3)],[-19,0,0],[20,0,0],16,[ladder(-16,0,3),ladder(16,0,3)],stairs=[stair([-22,0],[-18,3])],gate='boss2',theme='furnace')
    enemy(r,'minotaur',6);r['hint']='锈脊牛头督工：读出冲锋前摇，跳上侧台躲地震，半血后警惕连续锤击。'
    r=room('R02-08','维修桥回环','bridge',[floor(-22,22,0),floor(0,22,4)],[-19,0,0],[20,4,0],11,stairs=[stair([-12,0],[0,4])],gate='boss2',theme='blue')
    prop(r,'rust_loop',-18,0,'锈井回环 · 锈井入口');prop(r,'completion',5,4,'交付总井图纸');r['hint']='图纸送回维修所，灰闸囚厂与锈脊齿轮井的回环已连通。'
    r=room('R02-H1','暗矿牢房','mine',[floor(-22,22,0),floor(-18,-5,5),floor(4,22,5)],[-19,0,0],[20,0,0],13,[ladder(-12,0,5),ladder(15,0,5)],theme='green')
    enemy(r,'human',-4);enemy(r,'hound',6);enemy(r,'ranged',12,5);prop(r,'recruit',18,5,'伊瑟 · 归还矿族名册')
    r['hint']='可选救援：击退守卫，攀到右侧牢房，伊瑟自愿加入第三槽。'
    for j,r in enumerate(rooms):
        r['bounds']=[-22,22,-2,max([p[2] for p in r['platforms']])+5]
        r['previous']=j-1 if j not in [0,11,12,17] else {0:0,11:7,12:10,17:13}[j]
        r['checkpoint']=r['spawn']
        r['title']=r['id']+' / '+r['name']
        r['kit']=True
        # Safe rails bound the room; exits are literal archways, not small cubes.
    (ROOT/'data/rooms.json').write_text(json.dumps(rooms,ensure_ascii=False,indent=2),encoding='utf8')
    return rooms
if __name__=='__main__':build()
