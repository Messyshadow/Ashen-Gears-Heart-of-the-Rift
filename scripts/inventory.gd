extends RefCounted
# Persistent quantities and per-character equipment; equipped items remain owned.
var game: Node3D
var items: Dictionary={}
var equipment: Dictionary={}
var wrap := ""
var selected := "dagger"
var category := "全部"
var page := 0
var actor := -1
const SLOTS=["weapon","armor","accessory1","accessory2","rune"]
const SLOT_NAMES={"weapon":"武器","armor":"护甲","accessory1":"饰品 I","accessory2":"饰品 II","rune":"核心铭文","wrap":"环境护套"}
const QUALITY=["普通","精良","稀有","独特"]
const CATALOG={
 "native_1":{"name": "扳手拳臂", "type": "weapon", "quality": 1, "actor": 1, "desc": "机械重砸与修补；这位角色的专属武器。", "stats": {}},
 "native_2":{"name": "弧刃短弓", "type": "weapon", "quality": 1, "actor": 2, "desc": "远程箭矢；这位角色的专属武器。", "stats": {}},
 "native_3":{"name": "白骨剑", "type": "weapon", "quality": 1, "actor": 3, "desc": "剑气返刃；这位角色的专属武器。", "stats": {}},
 "native_4":{"name": "影织双刃", "type": "weapon", "quality": 1, "actor": 4, "desc": "快速束缚；这位角色的专属武器。", "stats": {}},
 "native_5":{"name": "赤汞刺剑", "type": "weapon", "quality": 1, "actor": 5, "desc": "血瓶远攻；这位角色的专属武器。", "stats": {}},
 "native_6":{"name": "导电拳刃", "type": "weapon", "quality": 1, "actor": 6, "desc": "近战群体破势；这位角色的专属武器。", "stats": {}},
 "native_7":{"name": "雷印双刃", "type": "weapon", "quality": 1, "actor": 7, "desc": "三段雷刃连击；这位角色的专属武器。", "stats": {}},
 "native_8":{"name": "符文喷枪", "type": "weapon", "quality": 1, "actor": 8, "desc": "减速符墨；这位角色的专属武器。", "stats": {}},
 "native_9":{"name": "蒸汽拳锤", "type": "weapon", "quality": 1, "actor": 9, "desc": "重击与护盾；这位角色的专属武器。", "stats": {}},
 "native_10":{"name": "幼龙长枪", "type": "weapon", "quality": 1, "actor": 10, "desc": "龙息与长枪；这位角色的专属武器。", "stats": {}},
 "native_11":{"name": "黎明光刃", "type": "weapon", "quality": 1, "actor": 11, "desc": "两段光斩；这位角色的专属武器。", "stats": {}},
 "native_12":{"name": "铆火手炮", "type": "weapon", "quality": 1, "actor": 12, "desc": "范围炮击；这位角色的专属武器。", "stats": {}},
 "native_13":{"name": "魂名法杖", "type": "weapon", "quality": 1, "actor": 13, "desc": "魂钉与骨仆；这位角色的专属武器。", "stats": {}},
 "native_14":{"name": "守夜圣铃", "type": "weapon", "quality": 1, "actor": 14, "desc": "净化与有限治疗；这位角色的专属武器。", "stats": {}},
 "native_15":{"name": "鹰目步枪", "type": "weapon", "quality": 1, "actor": 15, "desc": "贯穿狙击；这位角色的专属武器。", "stats": {}},
 "native_16":{"name": "三源星杖", "type": "weapon", "quality": 1, "actor": 16, "desc": "星弹与共鸣；这位角色的专属武器。", "stats": {}},
 "dagger":{"name":"裂影匕首","type":"weapon","quality":0,"actor":0,"desc":"轻巧的初始兵器，快速三段刺击。","stats":{}},
 "katana":{"name":"灰钢太刀","type":"weapon","quality":1,"actor":0,"desc":"煤仓遗留长刃。长距离三连斩与重劈；V 切换。","stats":{}},
 "iron_armor":{"name":"铆钉护甲","type":"armor","quality":1,"price":80,"desc":"旧工坊的护胸，降低所有直接伤害。","stats":{"defense":.08}},
 "furnace_armor":{"name":"炉卫甲","type":"armor","quality":2,"price":180,"desc":"热锻护甲，强化生命与防护。","stats":{"hp":20,"defense":.12}},
 "rift_armor":{"name":"封界鳞甲","type":"armor","quality":3,"desc":"镜渊遗物。轻量装甲抵御融合体的攻击。","stats":{"hp":30,"defense":.15}},
 "gear_ring":{"name":"转矩齿环","type":"accessory","quality":1,"price":65,"desc":"传动齿环提高近战、箭矢与施法伤害。","stats":{"damage":.08}},
 "wind_thread":{"name":"烟线护符","type":"accessory","quality":2,"price":100,"desc":"纱隐的旧烟线，耐力恢复加快。","stats":{"stamina":.20}},
 "blood_mirror":{"name":"镜血饰品","type":"accessory","quality":3,"desc":"血堡暗镜中保存的名字，命中恢复少量生命。","stats":{"leech":.04}},
 "light_bell":{"name":"净化铃纹","type":"accessory","quality":2,"desc":"祈堂之铃，生命上限提升。","stats":{"hp":25}},
 "power_chain":{"name":"电链饰品","type":"accessory","quality":3,"desc":"隔离雷核后回收的电链，强化输出与魔力恢复。","stats":{"damage":.12,"magic":.30}},
 "bone_rune":{"name":"东渡剑名纹","type":"rune","quality":2,"desc":"自愿留下的剑名，重击与技能威力提升。","stats":{"damage":.10}},
 "steam_rune":{"name":"蒸汽盾铭文","type":"rune","quality":2,"desc":"炉灯解除协议后的礼物，提高防护与耐力回复。","stats":{"defense":.06,"stamina":.10}},
 "star_rune":{"name":"星烬共鸣核","type":"rune","quality":3,"desc":"归还观测核后获得的共鸣核心。","stats":{"damage":.15,"magic":.25}},
 "lava_wrap":{"name":"熔界护套","type":"wrap","quality":2,"desc":"全队共用，保护普通熔浆；热负荷达 100 仍需离开冷却。","stats":{}},
 "water_wrap":{"name":"潜水护套","type":"wrap","quality":1,"price":90,"desc":"密封潜行护套，减少水区环境伤害。","stats":{}},
 "poison_wrap":{"name":"净气护套","type":"wrap","quality":1,"price":90,"desc":"滤芯降低毒区环境伤害。","stats":{}},
 "ether":{"name":"魔力补剂","type":"consumable","quality":0,"price":15,"desc":"恢复 40 魔力，战斗中也可使用。","stats":{}},
 "medkit":{"name":"急救包","type":"consumable","quality":1,"price":25,"desc":"当前角色恢复 70 生命，备用倒地者可在休息灯恢复。","stats":{}},
 "coolant":{"name":"冷却剂","type":"consumable","quality":1,"price":15,"desc":"降低熔界护套热负荷 50。","stats":{}},
 "gear_core":{"name":"齿芯","type":"material","quality":0,"price":6,"desc":"机械残留材料，用于工坊制作。","stats":{}},
 "bone_steel":{"name":"骨钢","type":"material","quality":1,"price":8,"desc":"东渡遗城遗留的骨钢。","stats":{}},
 "red_mercury":{"name":"赤汞","type":"material","quality":1,"price":8,"desc":"炼金容器回收材料。","stats":{}},
 "ember":{"name":"熔核屑","type":"material","quality":1,"price":8,"desc":"熔海稳定凝结的炉芯材料。","stats":{}},
 "soul_page":{"name":"魂名残页","type":"material","quality":1,"price":8,"desc":"自愿留下的魂页，可用于封界铭文。","stats":{}},
 "rift_crystal":{"name":"裂界晶","type":"material","quality":2,"price":12,"desc":"镜渊的分离结晶。","stats":{}},
 "manifest":{"name":"伪签转运表","type":"quest","quality":3,"desc":"米菈被强征的第一份证据。不可出售。","stats":{}},
 "lab_evidence":{"name":"原始实验日志","type":"quest","quality":3,"desc":"三源分离的实验记录。不可出售。","stats":{}},
 "separation_core":{"name":"三源分离核心","type":"quest","quality":3,"desc":"米菈共同分离炉心所需的核心。不可出售。","stats":{}},
 "mila_wish":{"name":"米菈的意愿","type":"quest","quality":3,"desc":"她愿意共同承担分离的代价，请修复三个城市锚点。","stats":{}}
}
const RECIPES={"iron_armor":{"gear_core":5},"furnace_armor":{"gear_core":6,"ember":5},"bone_rune":{"bone_steel":5,"soul_page":3},"lava_wrap":{"ember":3,"gear_core":3},"rift_armor":{"rift_crystal":6,"bone_steel":4},"star_rune":{"rift_crystal":5,"soul_page":5}}

func reset() -> void:
 items={"dagger":1,"ether":2};equipment={"0":{"weapon":"dagger"}};wrap="";selected="dagger";page=0;actor=-1

func restore(payload: Dictionary) -> void:
 reset()
 var saved: Variant=payload.get("inventory",{})
 if saved is Dictionary:
  for id in saved:
   if CATALOG.has(id) and (saved[id] is int or saved[id] is float):items[id]=clampi(int(saved[id]),0,9999)
 if game.weapons.get("katana",false):items.katana=1
 equipment=payload.get("equipment",{"0":{"weapon":game.equipped_weapon}}).duplicate(true)
 wrap=str(payload.get("wrap",""))
 if not CATALOG.has(wrap) or int(items.get(wrap,0))<=0:wrap=""
 # Reject orphaned/invalid slots instead of granting bonuses from edited or old data.
 var assigned: Dictionary={}
 for actor in equipment:
  if not equipment[actor] is Dictionary:equipment[actor]={};continue
  if int(actor)<0 or int(actor)>=game.Content.ROSTER.size():equipment[actor]={};continue
  for slot in equipment[actor].keys():
   var id: String=str(equipment[actor][slot])
   if not compatible(id,int(actor),str(slot)) or int(assigned.get(id,0))>=owned(id):equipment[actor].erase(slot)
   else:assigned[id]=int(assigned.get(id,0))+1
 if not equipment.has("0"):equipment["0"]={}
 equipment["0"]["weapon"]=game.equipped_weapon
 for slot in game.available_slots():on_recruit(slot)

func owned(id: String) -> int:return int(items.get(id,0))
func grant(id: String, amount: int=1) -> bool:
 if not CATALOG.has(id) or amount<=0:return false
 items[id]=mini(9999,owned(id)+amount);return true
func stats(actor: int) -> Dictionary:
 var total: Dictionary={}
 for id in equipment.get(str(actor),{}).values():
  if not CATALOG.has(id):continue
  for stat in CATALOG[id].stats:total[stat]=float(total.get(stat,0))+float(CATALOG[id].stats[stat])
 return total
func compatible(id: String,actor: int,slot: String) -> bool:
 if not CATALOG.has(id):return false
 var item: Dictionary=CATALOG[id]
 if item.get("actor",actor)!=actor:return false
 return item.type==("accessory" if slot in ["accessory1","accessory2"] else slot)
func assigned_count(id: String) -> int:
 var count:=0
 for actor in equipment:
  for value in equipment[actor].values():
   if value==id:count+=1
 return count+(1 if wrap==id else 0)
func equip(id: String, slot: String="") -> bool:
 if owned(id)<=0 or not CATALOG.has(id):game.toast("尚未拥有这件物品");return false
 if not game.can_switch_weapon():game.toast("收招后再更换装备");return false
 var item: Dictionary=CATALOG[id];var target: int=game.active_slot if actor<0 else actor;var actor_key: String=str(target)
 if slot.is_empty():slot="accessory1" if item.type=="accessory" else str(item.type)
 if not target in game.available_slots() or not compatible(id,target,slot):game.toast("该角色或槽位无法使用此物品");return false
 if slot=="wrap":
  if game.player.position.y < -.1:game.toast("先返回安全平台再更换护套");return false
  wrap=id
 else:
  if not equipment.has(actor_key):equipment[actor_key]={}
  if equipment[actor_key].get(slot,"")==id:return true
  if assigned_count(id)>=owned(id):game.toast("这件装备已分配给其他槽位或同伴");return false
  equipment[actor_key][slot]=id
  if slot=="weapon" and target==0:game.equip_weapon(id)
 game.party_hp[target]=minf(game.party_hp[target],game.actor_hp(target))
 game.sound("gear_latch");game.save_game();game.ui.rebuild_buttons();return true
func unequip(slot: String) -> bool:
 if slot=="weapon" or not game.can_switch_weapon():return false
 if slot=="wrap":wrap=""
 else:
  var target: int=game.active_slot if actor<0 else actor
  if equipment.has(str(target)):equipment[str(target)].erase(slot)
  game.party_hp[target]=minf(game.party_hp[target],game.actor_hp(target))
 game.save_game();game.ui.rebuild_buttons();return true
func use(id: String) -> bool:
 if owned(id)<=0:return false
 if id=="ether":
  if game.magic>=100:return false
  game.magic=minf(100,game.magic+40)
 elif id=="medkit":
  if game.party_hp[game.active_slot]>=game.max_hp():return false
  game.party_hp[game.active_slot]=minf(game.max_hp(),game.party_hp[game.active_slot]+70)
 elif id=="coolant":
  if game.heat<=0:return false
  game.heat=maxf(0,game.heat-50)
 else:return false
 items[id]=owned(id)-1;game.sound("save");game.save_game();game.ui.rebuild_buttons();return true
func buy(id: String) -> bool:
 if not game.can_organize() or not CATALOG.has(id):game.toast("靠近休息灯才能交易");return false
 var cost: int=int(CATALOG[id].get("price",0))
 if cost<=0 or game.scrap<cost:game.toast("铁屑不足");return false
 game.scrap-=cost;grant(id);game.save_game();game.ui.rebuild_buttons();return true
func sell(id: String) -> bool:
 if not game.can_organize() or owned(id)<=assigned_count(id) or CATALOG[id].type not in ["material","consumable"]:return false
 items[id]=owned(id)-1;game.scrap+=maxi(1,int(CATALOG[id].get("price",4))/2);game.save_game();game.ui.rebuild_buttons();return true
func craft(id: String) -> bool:
 if not game.can_organize() or not RECIPES.has(id):return false
 for material in RECIPES[id]:
  if owned(material)<RECIPES[id][material]:game.toast("材料不足 · 查看配方需求");return false
 for material in RECIPES[id]:items[material]=owned(material)-RECIPES[id][material]
 grant(id);game.sound("gear_start");game.save_game();game.ui.rebuild_buttons();return true
func loot(kind: String, uid: String) -> void:
 if game.defeated.has(uid):return
 var material: String="ember" if kind in ["imp","smelter"] else "bone_steel" if kind in ["skeleton","general"] else "red_mercury" if kind in ["blood_guard","lord"] else "soul_page" if kind in ["wraith","judge"] else "rift_crystal" if kind in ["mirror_beast","triphase","regent"] else "gear_core"
 grant(material,3 if game.Content.ENEMIES[kind].get("boss",false) else 1)
func entries() -> Array:
 var result: Array=[]
 for id in CATALOG:
  if owned(id)>0 and (category=="全部" or CATALOG[id].type==category):result.append(id)
 return result

func on_recruit(actor: int) -> void:
 if actor<=0:return
 var id: String="native_%d"%actor
 if not CATALOG.has(id):return
 if owned(id)==0:grant(id)
 if not equipment.has(str(actor)):equipment[str(actor)]={}
 if not equipment[str(actor)].has("weapon"):equipment[str(actor)]["weapon"]=id
