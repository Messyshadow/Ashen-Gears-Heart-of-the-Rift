extends RefCounted
var ui: Control
var map_view: Control
const EMBLEM=preload("res://assets/ui/ashen_arts.svg")
const PAGES=["map","inventory","equipment","skills","journal","roster","settings"]
const NAMES=["地图","背包","装备","技能","任务","同伴","系统"]
const CATEGORIES=["全部","weapon","armor","accessory","rune","wrap","consumable","material","quest"]
const CATEGORY_NAMES=["全部","武器","护甲","饰品","铭文","护套","补给","材料","证物"]
var roster_page := 0
var journal_page := 0

func manages(value: String) -> bool:return value in ["skills","inventory","equipment","shop","craft","map","journal"]
func frame() -> void:
 var w: float=ui.size.x;var h: float=ui.size.y
 ui.draw_rect(Rect2(Vector2.ZERO,ui.size),Color(.012,.022,.029,.98))
 ui.draw_rect(Rect2(w*.025,h*.105,w*.95,h*.81),Color(.027,.039,.044))
 ui.draw_rect(Rect2(w*.025,h*.105,w*.95,h*.81),Color(.43,.32,.18),false,2)
 for corner in [Vector2(w*.025,h*.105),Vector2(w*.975,h*.105),Vector2(w*.025,h*.915),Vector2(w*.975,h*.915)]:
  ui.draw_arc(corner,18,0,TAU,24,ui.GOLD,1);ui.draw_circle(corner,4,ui.GOLD)
 ui.text_at(Vector2(w*.045,h*.974),"灰烬齿轮 · 裂界之心   /   "+ui.game.controls.label("inventory")+" 背包   "+ui.game.controls.label("skills")+" 技能   Esc 返回",15,ui.MUTED)
 if ui.game.toast_clock>0:ui.text_at(Vector2(w*.40,h*.97),ui.game.status,16,ui.GOLD)
func navigation() -> void:
 var w: float=ui.size.x;var h: float=ui.size.y;var g: Node3D=ui.game
 for i in PAGES.size():
  ui.add_button(("◆ " if g.screen==PAGES[i] else "")+NAMES[i],Vector2(w*(.08+i*.111),h*.029),func():g.set_screen(PAGES[i]),w*.103)
 ui.add_button("返回",Vector2(w*.872,h*.942),func():g.set_screen("play"),w*.1)
func draw_screen() -> void:
 var g: Node3D=ui.game;var w: float=ui.size.x;var h: float=ui.size.y
 if not manages(g.screen):return
 frame()
 if g.screen=="map":return
 if g.screen=="journal":draw_journal();return
 if g.screen=="skills":
  var s: RefCounted=g.skills;var profile: Dictionary=g.Content.ROSTER[s.actor];var node: Dictionary=s.catalog(s.actor)[s.selected]
  ui.text_at(Vector2(w*.052,h*.18),profile.name+" · "+profile.role,28,ui.GOLD)
  ui.text_at(Vector2(w*.052,h*.235),"ASHEN ARTS / 专属招式",16,ui.MUTED)
  ui.draw_texture_rect(EMBLEM,Rect2(w*.094,h*.661,w*.075,h*.116),false)
  ui.draw_line(Vector2(w*.235,h*.14),Vector2(w*.235,h*.875),ui.GOLD,1)
  ui.draw_line(Vector2(w*.656,h*.14),Vector2(w*.656,h*.875),ui.GOLD,1)
  ui.text_at(Vector2(w*.27,h*.18),"招式工坊",31,ui.GOLD)
  ui.text_at(Vector2(w*.47,h*.18),"技能点 %d  ·  齿芯 %d"%[g.skill_points,g.inventory.owned("gear_core")],19,ui.TEXT)
  for branch in range(3):
   ui.text_at(Vector2(w*(.295+branch*.129),h*.26),["战斗","身法","共鸣"][branch],22,ui.MUTED)
   for tier in range(3):
    var id: String=["C","M","T"][branch]+str(tier+1);var p:=Vector2(w*(.319+branch*.129),h*(.366+tier*.178));var lv: int=s.level(s.actor,id)
    if tier<2:ui.draw_line(p+Vector2(0,28),p+Vector2(0,h*.178-28),ui.GOLD if lv>0 else Color(.20,.31,.38),2)
    ui.draw_arc(p,30,0,TAU,48,ui.GOLD if id==s.selected else Color(.26,.64,.86) if lv>0 else Color(.28,.33,.35),2)
    ui.draw_arc(p,36,-PI*.8,PI*.8,40,Color(.39,.29,.16),1)
    icon(p,id,ui.GOLD if lv>0 else ui.MUTED)
    ui.text_at(p+Vector2(-21,58),"Lv.%d"%lv,15,ui.MUTED)
  ui.text_at(Vector2(w*.682,h*.173),node.name,29,ui.GOLD)
  ui.text_at(Vector2(w*.88,h*.173),"Lv.%d / 3"%s.level(s.actor,s.selected),17,ui.MUTED)
  wrap_text(Vector2(w*.681,h*.565),node.description,w*.266,17,ui.TEXT)
  ui.text_at(Vector2(w*.681,h*.704),"消耗 %d  /  冷却 %d 秒"%[node.resource,node.cooldown],18,ui.MUTED)
  var next: int=s.level(s.actor,s.selected)+1
  ui.text_at(Vector2(w*.681,h*.756),"下一等级 Lv.%d  ·  %d 技能点 / %d 齿芯"%[mini(3,next),s.point_cost(s.actor,s.selected),next-1],17,ui.GOLD)
  var reason: String=s.requirement(s.actor,s.selected)
  wrap_text(Vector2(w*.681,h*.804),"可以学习 / 升级" if reason.is_empty() else reason,w*.26,16,Color(.35,.75,.63) if reason.is_empty() else Color(.77,.43,.30))
 else:draw_inventory()
func wrap_text(pos: Vector2,value: String,width: float,font_size: int,col: Color) -> void:
 var line: String="";var y: float=pos.y
 for c in value:
  if ui.font.get_string_size(line+c,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width:
   ui.text_at(Vector2(pos.x,y),line,font_size,col);y+=font_size*1.6;line=""
  line+=c
 if not line.is_empty():ui.text_at(Vector2(pos.x,y),line,font_size,col)
func icon(p: Vector2,id: String,col: Color) -> void:
 var radius:=14.0
 if id.begins_with("C"):
  ui.draw_line(p+Vector2(-radius,radius),p+Vector2(radius,-radius),col,3);ui.draw_line(p+Vector2(-9,-2),p+Vector2(2,9),col,2)
 elif id.begins_with("M"):
  for j in range(3):ui.draw_line(p+Vector2(-14,8-j*8),p+Vector2(13,-j*8),col,2)
 else:
  ui.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-18),p+Vector2(11,0),p+Vector2(0,18),p+Vector2(-11,0)]),col);ui.draw_circle(p,5,Color(.025,.04,.05))
func build() -> void:
 var g: Node3D=ui.game;var w: float=ui.size.x;var h: float=ui.size.y
 navigation()
 if g.screen=="journal":build_journal();return
 if g.screen=="map":
  map_view=preload("res://scripts/world_map.gd").new();map_view.game=g;ui.add_child(map_view);map_view.position=Vector2(w*.037,h*.125);map_view.size=Vector2(w*.925,h*.765);ui.graphics_controls.append(map_view);return
 if g.screen=="skills":
  var s: RefCounted=g.skills
  var selector:=OptionButton.new();ui.add_child(selector);ui.graphics_controls.append(selector);selector.position=Vector2(w*.052,h*.285);selector.size=Vector2(w*.16,h*.05)
  for actor in g.Content.ROSTER.size():selector.add_item(g.Content.ROSTER[actor].name+("" if actor in g.available_slots() else " · 未招募"))
  selector.select(s.actor);selector.item_selected.connect(s.choose_actor)
  for i in range(3):ui.add_button(["战斗技","身法技","共鸣形态"][i],Vector2(w*.052,h*(.405+i*.091)),func():s.selected=["C1","M1","T1"][i];ui.rebuild_buttons(),w*.16)
  ui.add_button("查看角色名册",Vector2(w*.052,h*.795),func():g.ui.extension.roster_selected=s.actor;g.set_screen("roster"),w*.16)
  for branch in range(3):
   for tier in range(3):
    var id: String=["C","M","T"][branch]+str(tier+1)
    ui.add_button(s.catalog(s.actor)[id].name,Vector2(w*(.261+branch*.129),h*(.413+tier*.178)),func():s.selected=id;ui.rebuild_buttons(),w*.116)
  ui.build_preview(Vector2(w*.681,h*.218),Vector2(w*.266,h*.285),s.actor,s.animation(s.actor,s.selected),true)
  ui.add_button("学习 / 升级招式",Vector2(w*.681,h*.836),func():s.upgrade(s.actor,s.selected),w*.266)
 else:build_inventory()

func draw_inventory() -> void:
 var g: Node3D=ui.game;var inv: RefCounted=g.inventory;var w: float=ui.size.x;var h: float=ui.size.y
 ui.text_at(Vector2(w*.06,h*.18),{"inventory":"随身背包","equipment":"装备整备","shop":"灰街商店","craft":"铆火工坊"}[g.screen],34,ui.GOLD)
 var actor: int=g.active_slot if inv.actor<0 else inv.actor
 ui.text_at(Vector2(w*.67,h*.18),g.Content.ROSTER[actor].name+" / 铁屑 %d"%g.scrap,21,ui.GOLD)
 ui.text_at(Vector2(w*.06,h*.237),"冷却药剂 %d   ·   物品 %d 类   ·   共用护套 %s"%[g.potion,inv.entries().size(),"无" if inv.wrap.is_empty() else inv.CATALOG[inv.wrap].name],18,ui.MUTED)
 ui.draw_line(Vector2(w*.646,h*.255),Vector2(w*.646,h*.86),ui.GOLD)
 var item: Dictionary=inv.CATALOG.get(inv.selected,{})
 if item.is_empty():return
 ui.text_at(Vector2(w*.68,h*.36),item.name,29,ui.GOLD)
 ui.text_at(Vector2(w*.68,h*.41),inv.QUALITY[item.quality]+" / 持有 %d · 已装备 %d"%[inv.owned(inv.selected),inv.assigned_count(inv.selected)],18,ui.MUTED)
 wrap_text(Vector2(w*.68,h*.474),item.desc,w*.25,19,ui.TEXT)
 var row:=0
 for stat in item.stats:
  ui.text_at(Vector2(w*.68,h*(.60+row*.046)),{"hp":"生命上限","defense":"减伤","damage":"伤害加成","stamina":"耐力恢复","magic":"魔力恢复","leech":"命中吸血"}.get(stat,stat)+"  +"+str(item.stats[stat]*100 if stat!="hp" else item.stats[stat])+("%" if stat!="hp" else ""),18,Color(.37,.75,.63));row+=1
 if g.screen=="craft" and inv.RECIPES.has(inv.selected):
  var needs: Array=[]
  for id in inv.RECIPES[inv.selected]:needs.append(inv.CATALOG[id].name+" %d/%d"%[inv.owned(id),inv.RECIPES[inv.selected][id]])
  wrap_text(Vector2(w*.68,h*.65),"需要："+" / ".join(needs),w*.25,17,ui.MUTED)
 if g.screen=="equipment":
  var stats: Dictionary=inv.stats(actor)
  ui.text_at(Vector2(w*.06,h*.85),"生命 %d / %d · 伤害 +%d%% · 减伤 %d%%"%[g.party_hp[actor],g.actor_hp(actor),(float(stats.get("damage",0))+g.skills.bonus(actor,"damage"))*100,(float(stats.get("defense",0))+g.skills.bonus(actor,"defense"))*100],18,ui.GOLD)
func build_inventory() -> void:
 var g: Node3D=ui.game;var inv: RefCounted=g.inventory;var w: float=ui.size.x;var h: float=ui.size.y
 var entries: Array=inv.entries()
 if g.screen=="equipment":
  var selector:=OptionButton.new();ui.add_child(selector);ui.graphics_controls.append(selector);selector.position=Vector2(w*.06,h*.28);selector.size=Vector2(w*.27,h*.045)
  var actors: Array=g.available_slots()
  for actor in actors:selector.add_item(g.Content.ROSTER[actor].name)
  var actor: int=g.active_slot if inv.actor<0 else inv.actor
  selector.select(actors.find(actor));selector.item_selected.connect(func(i):inv.actor=actors[i];ui.rebuild_buttons())
  var slots: Array=inv.SLOTS.duplicate();slots.append("wrap")
  for i in slots.size():
   var slot: String=slots[i];var id: String=inv.wrap if slot=="wrap" else str(inv.equipment.get(str(actor),{}).get(slot,""))
   ui.add_button(inv.SLOT_NAMES[slot]+" / "+(inv.CATALOG[id].name if inv.CATALOG.has(id) else "空"),Vector2(w*.06,h*(.36+i*.07)),func():inv.category="accessory" if slot.begins_with("accessory") else slot;g.set_screen("inventory"),w*.40)
   ui.add_button("卸下",Vector2(w*.48,h*(.36+i*.07)),inv.unequip.bind(slot),w*.1)
 elif g.screen in ["shop","craft"]:
  entries=[]
  for id in (inv.RECIPES.keys() if g.screen=="craft" else inv.CATALOG.keys()):
   if g.screen=="craft" or inv.CATALOG[id].get("price",0)>0:entries.append(id)
 else:
  for i in CATEGORIES.size():ui.add_button(CATEGORY_NAMES[i],Vector2(w*(.052+i*.064),h*.277),func():inv.category=CATEGORIES[i];inv.page=0;ui.rebuild_buttons(),w*.06)
 if g.screen!="equipment":
  inv.page=clampi(inv.page,0,maxi(0,ceili(entries.size()/12.0)-1))
  for i in range(inv.page*12,mini(entries.size(),inv.page*12+12)):
   var id: String=entries[i];var item: Dictionary=inv.CATALOG[id];var row: int=i%12
   ui.add_button(("◆ " if inv.selected==id else "")+item.name+" ×%d"%inv.owned(id),Vector2(w*(.06+(row%3)*.19),h*(.36+floori(row/3.0)*.107)),func():inv.selected=id;ui.rebuild_buttons(),w*.174)
  ui.add_button("上一页",Vector2(w*.06,h*.84),func():inv.page=maxi(0,inv.page-1);ui.rebuild_buttons(),w*.12)
  ui.add_button("下一页",Vector2(w*.20,h*.84),func():inv.page=mini(ceili(entries.size()/12.0)-1,inv.page+1);ui.rebuild_buttons(),w*.12)
 var item: Dictionary=inv.CATALOG.get(inv.selected,{})
 if not item.is_empty():
  if g.screen=="shop":ui.add_button("购买 / %d 铁屑"%item.get("price",0),Vector2(w*.68,h*.75),inv.buy.bind(inv.selected),w*.25)
  elif g.screen=="craft":ui.add_button("制作",Vector2(w*.68,h*.75),inv.craft.bind(inv.selected),w*.25)
  elif item.type=="consumable":ui.add_button("使用 · 当前出战人物",Vector2(w*.68,h*.75),inv.use.bind(inv.selected),w*.25)
  elif item.type in ["weapon","armor","accessory","rune","wrap"]:
   ui.add_button("装备"+(" · 饰品 I" if item.type=="accessory" else ""),Vector2(w*.68,h*.75),inv.equip.bind(inv.selected,""),w*.25)
   if item.type=="accessory":ui.add_button("装备 · 饰品 II",Vector2(w*.68,h*.82),inv.equip.bind(inv.selected,"accessory2"),w*.25)
  elif item.type=="material":ui.add_button("出售一件 / 休息灯附近",Vector2(w*.68,h*.75),inv.sell.bind(inv.selected),w*.25)

func journal_entries() -> Array:
 var g: Node3D=ui.game;var entries: Array=[]
 for q in g.Content.QUESTS:entries.append({"title":q.title,"description":q.goal,"status":"已完成" if g.flags.get(q.flag,false) else "主线进行中","room":g.Content.STARTS[q.region]})
 var contracts: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/quests.json"))
 for q in contracts:
  var state: int=int(g.campaign.quest_states.get(q.id,0))
  entries.append({"title":q.id+" · "+q.title,"description":q.description,"status":["未接取","寻找证物","返回交付","已完成"][state],"room":q.room})
 return entries
func draw_journal() -> void:
 var entries: Array=journal_entries();var w: float=ui.size.x;var h: float=ui.size.y
 ui.text_at(Vector2(w*.06,h*.18),"任务档案",34,ui.GOLD)
 ui.text_at(Vector2(w*.62,h*.18),"主线 12 / 支线 20 / 隐藏 8",21,ui.MUTED)
 for i in range(journal_page*6,mini(journal_page*6+6,entries.size())):
  var q: Dictionary=entries[i];var y: float=h*(.28+(i%6)*.092)
  ui.text_at(Vector2(w*.06,y),q.title,23,ui.GOLD)
  ui.text_at(Vector2(w*.81,y),q.status,18,Color(.35,.75,.60) if q.status=="已完成" else ui.MUTED)
  wrap_text(Vector2(w*.06,y+h*.032),q.description,w*.82,17,ui.MUTED)
 ui.text_at(Vector2(w*.40,h*.86),"%d / %d"%[journal_page+1,ceili(entries.size()/6.0)],18,ui.MUTED)
func build_journal() -> void:
 var w: float=ui.size.x;var h: float=ui.size.y
 ui.add_button("上一页",Vector2(w*.06,h*.845),func():journal_page=maxi(0,journal_page-1);ui.rebuild_buttons(),w*.18)
 ui.add_button("下一页",Vector2(w*.65,h*.845),func():journal_page=mini(ceili(journal_entries().size()/6.0)-1,journal_page+1);ui.rebuild_buttons(),w*.18)
