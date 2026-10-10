extends RefCounted
var game: Node3D
var pressure_time := 0.0
var lava_clock := 0.0
var form_time := 0.0
var form_pulse := 0.0
var resonance := 0.0
var quest_states: Dictionary={}
var quests: RefCounted
const ABILITIES={"ability_lava":["lava_license","熔界护套"],"ability_anchor":["heavy_anchor","重锚牵引"],"ability_sight":["true_sight","真视灯"],"ability_rail":["rail_slide","轨链滑行"],"ability_resonance":["resonance_tool","共鸣封界"]}
func handle(kind: String) -> bool:
 var g: Node3D=game
 if not quests:quests=preload("res://scripts/quest_system.gd").new();quests.setup(g)
 if quests.handle(kind):return true
 if kind in ["shop","craft"]:g.set_screen(kind);return true
 if kind.begins_with("loot_"):
  if g.alive_count()>0:g.toast("先清理守卫再打开遗物箱");return true
  var id: String=kind.trim_prefix("loot_")
  if not g.opened.has(g.nearest.uid):g.inventory.grant(id);g.scrap+=25;g.skill_points+=1;g.consume_prop();g.sound("chest");g.save_game();g.toast("获得 "+g.inventory.CATALOG[id].name)
  return true
 if ABILITIES.has(kind):
  var ability: Array=ABILITIES[kind];g.flags[ability[0]]=true
  if kind=="ability_lava":g.inventory.grant("lava_wrap");g.inventory.wrap="lava_wrap";g.inventory.grant("coolant",3)
  g.skill_points+=2;g.consume_prop();g.save_game();g.show_story(ability[1]+"已解锁，全队共用。\n"+{"ability_lava":"普通熔浆消耗热负荷，每秒 +8；100 时保护失效。返回平台冷却或背包使用冷却剂。","ability_anchor":"在重锚开关旁 E 拉开重门。只作用于标记的锚点。","ability_sight":"姓名锁和旧碑文现在可读取；已发现房间可在地图标记。","ability_rail":"中继升降平台已经接通。平台停稳后 E 上行或下行。","ability_resonance":"按机械、魔法、电能顺序接通三源锁，可关闭裂雷与镜门。"}[kind]);return true
 if kind=="pressure_a":g.flags.pressure_closed=true;pressure_time=0;g.toast("压力正在降低，等待两秒")
 elif kind=="pressure_b":
  if not g.flags.get("pressure_closed",false) or pressure_time<2:g.toast("先关闭热压阀，等蒸汽完全散去");return true
  g.flags.pressure_done=true;g.toast("炉门固定，热压井可通过")
 elif kind=="anchor_pull":
  if not g.flags.get("heavy_anchor",false):g.toast("先取得重锚牵引工具");return true
  g.flags.anchor_open=true;g.toast("船坞重门已拉开")
 elif kind in ["name_a","name_b","name_c"]:
  var wanted: int=["name_a","name_b","name_c"].find(kind);var current: int=int(g.flags.get("names_step",0))
  if wanted!=current:g.flags.names_step=0;g.toast("名字错序已复位：米菈 → 阿芙 → 赫律");return true
  g.flags.names_step=current+1
  if current==2:g.flags.names_done=true;g.toast("真实姓名恢复，档案门开启")
  else:g.toast("已确认姓名 %d / 3"%(current+1))
 elif kind=="name_reset":g.flags.names_step=0
 elif kind=="rail_off":g.flags.rail_power=false;g.toast("磁轨已断电，可切换路线")
 elif kind=="rail_route":
  if g.flags.get("rail_power",true):g.toast("先断电，避免转运车进入炉线");return true
  g.flags.rail_routed=true
 elif kind=="rail_on":
  if not g.flags.get("rail_routed",false):g.toast("先断电并转接安全轨道");return true
  g.flags.rail_power=true;g.flags.train_saved=true;g.toast("列车安全驶出转运线")
 elif kind=="gravity":g.flags.gravity_high=not g.flags.get("gravity_high",false);g.toast("镜桥上升" if g.flags.gravity_high else "镜桥下降")
 elif kind.begins_with("core") and kind in ["core1","core2","core3"]:g.flags[kind]=true;g.consume_prop();g.toast("观测核已归还记录，三个核心不会消耗")
 elif kind in ["source_a","source_b","source_c"]:
  if not g.flags.get("resonance_tool",false):g.toast("先取得共鸣封界器");return true
  var step: int=int(g.flags.get("source_step",0));var wanted: int=["source_a","source_b","source_c"].find(kind)
  if step!=wanted:g.flags.source_step=0;g.toast("三源错序，重新从机械源开始");return true
  g.flags.source_step=step+1
  if step==2:g.flags.sources_done=true;g.toast("三源联锁稳定，镜台开放")
 elif kind=="separation_core":
  if not g.flags.get("boss11",false):g.toast("先击败三相兽，释放米菈投影");return true
  for id in ["separation_core","mila_wish"]:
   if g.inventory.owned(id)==0:g.inventory.grant(id)
  g.flags.mila_wish=true;g.consume_prop();g.show_story("米菈：我愿与你一起执行分离，而不是由你决定我的生命。\n水、气、电三个锚点须承担新供能。\n未修复时，我们仍可返回维修所。")
 elif kind in ["lock_power","lock_blood","lock_rift"]:
  var ability: String={"lock_power":"rail_slide","lock_blood":"phase_step","lock_rift":"resonance_tool"}[kind]
  if not g.flags.get(ability,false):g.toast("缺少所需工具，可返回之前区域学习");return true
  if g.alive_count()>0:g.toast("先清理炉锁守卫");return true
  g.flags[kind]=true;g.toast("炉锁关闭，最终竖井通路开放")
 elif kind in ["anchor_water","anchor_air","anchor_power"]:
  var flag: String={"anchor_water":"steam","anchor_air":"root_bridge","anchor_power":"circuit"}[kind]
  if not g.flags.get(flag,false):g.toast("先修复对应区域机关，再来安装城市锚点");return true
  if not g.flags.get(kind,false):g.flags[kind]=true;g.skill_points+=2;g.inventory.grant("ether",2)
  g.toast("城市锚点已修复 · "+{"anchor_water":"水","anchor_air":"气","anchor_power":"电"}[kind])
 elif kind=="final_warning":g.show_story("前方是摄政王座。\n可在此存档、整备，或回维修所补做城市锚点。\n最终选择后仍可回终战前继续探索。")
 elif kind=="ending":
  if not g.flags.get("boss12",false) or not g.flags.get("mila_wish",false):g.toast("先击败摄政并保全米菈的意愿");return true
  g.set_screen("ending");return true
 elif kind=="quest_board":g.set_screen("journal");return true
 else:return false
 g.sound("gear_latch");g.save_game();return true
func entry_allowed(target: int) -> bool:
 var r: Dictionary=game.rooms[target];var gate: String=str(r.get("entry_gate",""))
 if gate.is_empty() or game.flags.get(gate,false):return true
 game.toast("能力门未开启，需要 "+{"phase_step":"裂隙步","lava_license":"熔界护套","rail_slide":"轨链滑行","true_sight":"真视灯","resonance_tool":"共鸣封界","heavy_anchor":"重锚牵引"}.get(gate,gate));return false
func tick(dt: float) -> void:
 if game.paused:return
 if game.flags.get("pressure_closed",false):pressure_time+=dt
 form_time=maxf(0,form_time-dt)
 if form_time>0:
  form_pulse-=dt
  if form_pulse<=0:form_pulse=.45;game.particles(game.player.position+Vector3(0,1,0),.65,Color(.65,.28,1))
 if game.data.has("lava_pool"):
  var pool: Array=game.data.lava_pool;var inside: bool=game.player.position.x>float(pool[0]) and game.player.position.x<float(pool[1]) and game.player.position.y<-.1
  if inside:
   lava_clock+=dt
   if game.inventory.wrap=="lava_wrap" and game.heat<100:game.heat=minf(100,game.heat+dt*8)
   elif lava_clock>.5:lava_clock=0;game.environment_damage(game.max_hp()*.12)
  else:lava_clock=0
func transform() -> void:
 if game.paused or not game.can_switch_weapon() or resonance<100 or game.skills.level(game.active_slot,"T1")<=0:return
 resonance=0;form_time=12;game.sound("skill");game.spawn_sparks(game.player.position+Vector3.UP,true);game.toast(game.skills.catalog(game.active_slot).T1.name+" · 12 秒")
func complete_ending(choice: int) -> void:
 var g: Node3D=game
 if not g.flags.get("boss12",false) or not g.flags.get("mila_wish",false):return
 var anchors: bool=g.flags.get("anchor_water",false) and g.flags.get("anchor_air",false) and g.flags.get("anchor_power",false)
 if choice==1 and not anchors:g.toast("共同分离需要修复水、气、电三个城市锚点");return
 if choice not in [1,2,3]:return
 g.flags["ending"+str(choice)]=true;g.flags.ending_last=choice;g.flags.stage_complete=true
 g.checkpoint_room=95;g.checkpoint_pos=g.vector(g.rooms[95].spawn);g.save_game()
 g.show_story(["余烬黎明\n米菈脱离炉心，在同伴照护下等待身体恢复。\n城市进入短期配给，工联与市民共同维护自治供能。","封炉长夜\n强制供能停止，撤离队带走幸存者。\n米菈被安全封存，等待新的修复方案。","灰冠继承\n凯恩接管炉心，献祭者的声音仍在机器中回响。\n同伴质疑新的灰冠：供能稳定无法抵消奴役。 "][choice-1]+"\n返回终战前可继续探索，结局记录永久保留。")
 g.story_origin="chapter_complete"
