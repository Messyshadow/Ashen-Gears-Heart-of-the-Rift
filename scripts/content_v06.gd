extends RefCounted
const VERSION="1.0.0"
const REGIONS=["余烬维修所", "灰闸囚厂", "锈脊齿轮井", "雾肺水务区", "黑棘迁木园", "夜血城堡", "神笔实验室", "烬海熔炉", "白骨东渡遗城", "幽冥档案院", "雷墓轨道堡", "镜渊裂界", "灰烬冠城"]
const STARTS=[11,0,8,18,26,34,42,50,58,66,74,82,90]
const ROSTER=[
 {
  "name": "凯恩",
  "role": "裂影行者",
  "model": "kain_v04",
  "hp": 100.0,
  "flag": "",
  "skills": [
   "裂影刺",
   "齿刃旋舞",
   "裂影空冲"
  ],
  "desc": "匕首快攻 / 太刀长斩；煤仓入口宝箱获得太刀。"
 },
 {
  "name": "洛铆",
  "role": "机械师",
  "model": "luomao_v04",
  "hp": 110.0,
  "flag": "rescued",
  "skills": [
   "铜核修补击",
   "齿轮过载",
   "机械推进"
  ],
  "desc": "锤击装甲、修复自身；断电囚门救援。"
 },
 {
  "name": "伊瑟",
  "role": "矿族游侠",
  "model": "yise_v04",
  "hp": 95.0,
  "flag": "ranger",
  "skills": [
   "穿甲射击",
   "裂界强弓",
   "游侠空冲"
  ],
  "desc": "远程弓箭；四层轴承台侧门进入矿牢招募。"
 },
 {
  "name": "沈烬",
  "role": "白骨剑客",
  "model": "shenjin_v06",
  "hp": 105.0,
  "flag": "shenjin",
  "skills": [
   "返刃",
   "破阵三叠",
   "踏刃空冲"
  ],
  "desc": "骨剑连斩、返刃飞剑；水务区折返维修梯招募。"
 },
 {
  "name": "纱隐",
  "role": "影织忍者",
  "model": "shayin_v06",
  "hp": 90.0,
  "flag": "shayin",
  "skills": [
   "影缚",
   "影步突袭",
   "烟步空冲"
  ],
  "desc": "快速双刃、束缚和位移；迁木园双忍藏室招募。"
 },
 {
  "name": "维萝",
  "role": "血契炼金术士",
  "model": "weiluo_v06",
  "hp": 100.0,
  "flag": "weiluo",
  "skills": [
   "血瓶回流",
   "赤汞爆裂",
   "雾血空冲"
  ],
  "desc": "刺剑、血瓶与命中吸血；夜血城堡炼金室招募。"
 },
 {
  "name": "零七",
  "role": "电能改造人",
  "model": "zero7_v06",
  "hp": 120.0,
  "flag": "zero7",
  "skills": [
   "电链震击",
   "绝缘护盾",
   "电踏空冲"
  ],
  "desc": "电能拳刃、群体破势与护盾；实验室活体仓招募。"
 },
 {
  "name": "雷牙",
  "role": "雷刃忍者",
  "model": "leiya_v10",
  "hp": 95,
  "flag": "leiya",
  "skills": [
   "雷步斩",
   "落雷连刃",
   "空连借势"
  ],
  "desc": "空中双刃连击，雷电破势；迁木园四雷暗阁招募。",
  "archetype": "ninja"
 },
 {
  "name": "佩奇",
  "role": "魔法科技师",
  "model": "peiqi_v10",
  "hp": 95,
  "flag": "peiqi",
  "skills": [
   "符墨弹",
   "绘笔风暴",
   "转笔弹步"
  ],
  "desc": "符墨弹与绘笔风暴；绘笔分站审计招募。",
  "archetype": "ink"
 },
 {
  "name": "炉灯",
  "role": "蒸汽机器人",
  "model": "ludeng_v10",
  "hp": 135,
  "flag": "ludeng",
  "skills": [
   "泄压拳",
   "锅炉震荡",
   "重落缓冲"
  ],
  "desc": "拳锤、泄压护盾；蒸汽提升间解除强制协议。",
  "archetype": "steam"
 },
 {
  "name": "缇娅",
  "role": "驯龙师",
  "model": "tiya_v10",
  "hp": 105,
  "flag": "tiya",
  "skills": [
   "龙息点燃",
   "双翼横扫",
   "翔落转枪"
  ],
  "desc": "长枪与幼龙火焰；熔海卵窟保护幼龙。",
  "archetype": "dragon"
 },
 {
  "name": "黎照",
  "role": "光刃剑客",
  "model": "lizhao_v10",
  "hp": 110,
  "flag": "lizhao",
  "skills": [
   "弧光斩",
   "十字曜切",
   "空中切返"
  ],
  "desc": "光刃双斩、破盾；武士会馆解放剑誓。",
  "archetype": "light"
 },
 {
  "name": "巴洛",
  "role": "枪炮师",
  "model": "baluo_v10",
  "hp": 110,
  "flag": "baluo",
  "skills": [
   "破壳弹",
   "近距炮幕",
   "空炮定姿"
  ],
  "desc": "远距炮弹、近距弹幕；停火军火棚救援。",
  "archetype": "cannon"
 },
 {
  "name": "莫恩",
  "role": "亡灵法师",
  "model": "moen_v10",
  "hp": 95,
  "flag": "moen",
  "skills": [
   "魂钉",
   "骨牢合围",
   "骨台跃迁"
  ],
  "desc": "魂钉、骨牢控制；档案院退出魂契。",
  "archetype": "necromancer"
 },
 {
  "name": "塞琳",
  "role": "牧师",
  "model": "selin_v10",
  "hp": 100,
  "flag": "selin",
  "skills": [
   "净祟铃",
   "守夜圣域",
   "祈光缓降"
  ],
  "desc": "净化铃与有限治疗；不灭祈堂守护。",
  "archetype": "healer"
 },
 {
  "name": "鸦眼",
  "role": "神射手",
  "model": "yayan_v10",
  "hp": 95,
  "flag": "yayan",
  "skills": [
   "标靶贯穿",
   "三线狙击",
   "空中稳枪"
  ],
  "desc": "贯穿步枪、三线狙击；观测狙击台招募。",
  "archetype": "rifle"
 },
 {
  "name": "星烬",
  "role": "星烬魔法师",
  "model": "xingjin_v10",
  "hp": 100,
  "flag": "xingjin",
  "skills": [
   "星火弹",
   "裂界星雨",
   "空星反推"
  ],
  "desc": "星弹、三源共鸣；镜渊断观台归还观测核。",
  "archetype": "star"
 }
]
const ENEMIES={
 "human": {
  "model": "kain_v04",
  "hp": 65,
  "human": true
 },
 "ranged": {
  "model": "yise_v04",
  "hp": 65,
  "human": true,
  "ranged": true
 },
 "hound": {
  "model": "mechanical_hound",
  "hp": 95
 },
 "turret": {
  "model": "turret_v04",
  "hp": 85,
  "ranged": true
 },
 "drone": {
  "model": "drone_v04",
  "hp": 50,
  "ranged": true,
  "flying": true
 },
 "boss": {
  "model": "execution_machine",
  "hp": 480,
  "boss": true,
  "flag": "boss",
  "patterns": [
   "落锤",
   "链钩",
   "震地"
  ]
 },
 "minotaur": {
  "model": "minotaur_v04",
  "hp": 600,
  "boss": true,
  "flag": "boss2",
  "patterns": [
   "冲锋",
   "落锤",
   "震地"
  ]
 },
 "wraith": {
  "model": "wraith_v06",
  "hp": 75,
  "ranged": true,
  "flying": true
 },
 "thorn": {
  "model": "thorn_v06",
  "hp": 105
 },
 "blood_guard": {
  "model": "weiluo_v06",
  "hp": 110,
  "human": true
 },
 "scribe": {
  "model": "zero7_v06",
  "hp": 100,
  "human": true,
  "ranged": true
 },
 "mother": {
  "model": "mother_v06",
  "hp": 720,
  "boss": true,
  "flag": "boss3",
  "patterns": [
   "毒潮",
   "管刺",
   "震地"
  ]
 },
 "witch": {
  "model": "witch_v06",
  "hp": 760,
  "boss": true,
  "flag": "boss4",
  "patterns": [
   "孢弹",
   "根刺",
   "冲锋"
  ]
 },
 "lord": {
  "model": "lord_v06",
  "hp": 850,
  "boss": true,
  "flag": "boss5",
  "patterns": [
   "血矛",
   "冲锋",
   "血潮"
  ]
 },
 "editor": {
  "model": "editor_v06",
  "hp": 920,
  "boss": true,
  "flag": "boss6",
  "patterns": [
   "墨弹",
   "裁稿波",
   "复写突进"
  ]
 },
 "imp": {
  "name": "熔浆小鬼",
  "model": "imp_v10",
  "hp": 100
 },
 "skeleton": {
  "name": "束魂武士",
  "model": "skeleton_v10",
  "hp": 120
 },
 "werewolf": {
  "name": "月血狼人",
  "model": "werewolf_v10",
  "hp": 130
 },
 "scorpion": {
  "name": "轨道蝎卫",
  "model": "scorpion_v10",
  "hp": 145
 },
 "mirror_beast": {
  "name": "镜相猎兽",
  "model": "mirror_beast_v10",
  "hp": 150
 },
 "shield": {
  "name": "冠城盾卫",
  "model": "shield_v10",
  "hp": 170,
  "human": true,
  "shield": true
 },
 "sniper": {
  "name": "磁轨狙手",
  "model": "sniper_v10",
  "hp": 105,
  "human": true,
  "ranged": true
 },
 "specter": {
  "name": "档案幽魂",
  "model": "specter_v10",
  "hp": 95,
  "flying": true,
  "ranged": true
 },
 "smelter": {
  "name": "羊角熔铸王",
  "model": "smelter_v10",
  "hp": 1050,
  "boss": true,
  "flag": "boss7",
  "patterns": [
   "热浪",
   "炉矛",
   "冲锋"
  ],
  "extended": true
 },
 "general": {
  "name": "白骨将军",
  "model": "general_v10",
  "hp": 1100,
  "boss": true,
  "flag": "boss8",
  "patterns": [
   "剑气",
   "骨阵",
   "冲锋"
  ],
  "extended": true
 },
 "judge": {
  "name": "千名亡灵法官",
  "model": "judge_v10",
  "hp": 1150,
  "boss": true,
  "flag": "boss9",
  "patterns": [
   "魂弹",
   "魂潮",
   "契约刺"
  ],
  "extended": true
 },
 "emperor": {
  "name": "风暴蝎帝",
  "model": "emperor_v10",
  "hp": 1200,
  "boss": true,
  "flag": "boss10",
  "patterns": [
   "雷弹",
   "震地",
   "冲锋"
  ],
  "extended": true
 },
 "triphase": {
  "name": "裂界三相兽",
  "model": "triphase_v10",
  "hp": 1300,
  "boss": true,
  "flag": "boss11",
  "patterns": [
   "镜弹",
   "血潮",
   "复写突进"
  ],
  "extended": true
 },
 "regent": {
  "name": "灰冠摄政·赫律",
  "model": "regent_v10",
  "hp": 1500,
  "boss": true,
  "flag": "boss12",
  "patterns": [
   "王剑",
   "裁稿波",
   "冲锋"
  ],
  "extended": true
 },
 "elite1": {
  "model": "mechanical_hound",
  "hp": 535,
  "name": "裂齿犬王",
  "boss": true,
  "flag": "elite1",
  "extended": true,
  "patterns": [
   "震地",
   "远射",
   "冲锋"
  ]
 },
 "elite2": {
  "model": "thorn_v06",
  "hp": 590,
  "name": "铁棘古树",
  "boss": true,
  "flag": "elite2",
  "extended": true,
  "patterns": [
   "震地",
   "远射",
   "冲锋"
  ]
 },
 "elite3": {
  "model": "weiluo_v06",
  "hp": 645,
  "human": true,
  "name": "镜血侍臣",
  "boss": true,
  "flag": "elite3",
  "extended": true,
  "patterns": [
   "震地",
   "远射",
   "冲锋"
  ]
 },
 "elite4": {
  "name": "熔巢幼王",
  "model": "smelter_v10",
  "hp": 700,
  "boss": true,
  "flag": "elite4",
  "patterns": [
   "震地",
   "远射",
   "冲锋"
  ],
  "extended": true
 },
 "elite5": {
  "name": "无名剑魂",
  "model": "general_v10",
  "hp": 755,
  "boss": true,
  "flag": "elite5",
  "patterns": [
   "震地",
   "远射",
   "冲锋"
  ],
  "extended": true
 },
 "elite6": {
  "name": "千页典狱",
  "model": "judge_v10",
  "hp": 810,
  "boss": true,
  "flag": "elite6",
  "patterns": [
   "震地",
   "远射",
   "冲锋"
  ],
  "extended": true
 },
 "elite7": {
  "name": "裂雷巨鳗",
  "model": "emperor_v10",
  "hp": 865,
  "boss": true,
  "flag": "elite7",
  "patterns": [
   "震地",
   "远射",
   "冲锋"
  ],
  "extended": true
 },
 "elite8": {
  "name": "镜相首领",
  "model": "mirror_beast_v10",
  "hp": 920,
  "boss": true,
  "flag": "elite8",
  "extended": true,
  "patterns": [
   "震地",
   "远射",
   "冲锋"
  ]
 }
}
const QUESTS=[
 {
  "title": "断电之夜",
  "flag": "boss",
  "region": 1,
  "goal": "救出洛铆、修复钩索，击败链狱典刑机。"
 },
 {
  "title": "总井转运表",
  "flag": "boss2",
  "region": 2,
  "goal": "恢复配速井，打倒牛头督工，沿维修桥进入水务区。"
 },
 {
  "title": "水下的名字",
  "flag": "boss3",
  "region": 3,
  "goal": "中水位稳定后开蒸汽旁路，再排水；在母体排水室阻止管喉之母。"
 },
 {
  "title": "被锁住的根庭",
  "flag": "boss4",
  "region": 4,
  "goal": "引迁木桥至灯位并锁定，学习空冲，击败迁木女巫。"
 },
 {
  "title": "自愿之名",
  "flag": "boss5",
  "region": 5,
  "goal": "对齐双镜，取得血契旧账，招募维萝，击败血契侯爵。"
 },
 {
  "title": "被删改的记忆",
  "flag": "boss6",
  "region": 6,
  "goal": "复制重块压住双板；断电接分流、冷却、门锁和绝缘，再上电，击败校稿者。"
 },
 {
  "title": "烬海熔炉",
  "flag": "boss7",
  "region": 7,
  "goal": "制作熔界护套、解除强制协议，击败熔铸王。"
 },
 {
  "title": "白骨东渡遗城",
  "flag": "boss8",
  "region": 8,
  "goal": "取得重锚牵引，解放东渡剑誓，击败白骨将军。"
 },
 {
  "title": "幽冥档案院",
  "flag": "boss9",
  "region": 9,
  "goal": "真视名字顺序，解除强制魂契，击败亡灵法官。"
 },
 {
  "title": "雷墓轨道堡",
  "flag": "boss10",
  "region": 10,
  "goal": "救下列车，接通轨链，击败风暴蝎帝。"
 },
 {
  "title": "镜渊裂界",
  "flag": "boss11",
  "region": 11,
  "goal": "收集三源观测核，封界三锁，击败三相兽。"
 },
 {
  "title": "灰烬冠城",
  "flag": "boss12",
  "region": 12,
  "goal": "解开三炉锁，击败摄政，与米菈选择城市的未来。"
 }
]
