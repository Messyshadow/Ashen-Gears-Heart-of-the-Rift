extends RefCounted
var game: Node3D
var checks: Array=[]
var directory := ""
func wait(t: float=.15) -> void:await game.get_tree().create_timer(t).timeout
func check(ok: bool,name: String,detail: Variant=null) -> void:
 checks.append({"pass":ok,"check":name,"detail":detail});print("PASS " if ok else "FAIL ",name," ",detail)
func enter(number: int) -> void:game.load_room(number);game.set_screen("play");await wait()
func clear() -> void:
 for e in game.enemies:
  if is_instance_valid(e):e.hurt(99999,1)
 game.set_screen("play");await wait(.06)
func use(kind: String) -> void:
 game.nearest={}
 for prop in game.props:
  if prop.kind==kind:game.nearest=prop;break
 game.interact();game.set_screen("play")
func capture(name: String) -> void:
 if directory.is_empty():return
 await RenderingServer.frame_post_draw;game.get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))
func run(g: Node3D,path: String) -> Array:
 game=g;directory=path;game.new_game();await wait(.25)
 check(game.rooms.size()==126 and game.Content.ROSTER.size()==17 and game.Content.STARTS.size()==13,"完整世界：126 房间、主角与 16 同伴、12 个主线区域")
 var ids: Dictionary={};var graph_ok:=true;var layouts: Dictionary={}
 for r in game.rooms:
  ids[r.id]=true;layouts[JSON.stringify([r.platforms,r.ladders,r.slopes])]=true
  if r.next<0 or r.next>=126 or r.previous<0 or r.previous>=126:graph_ok=false
  for prop in r.props:
   if prop.kind.begins_with("portal") and (int(prop.kind.trim_prefix("portal"))<0 or int(prop.kind.trim_prefix("portal"))>=126):graph_ok=false
 check(ids.size()==126 and graph_ok and layouts.size()>100,"唯一房间身份、百种路线布局、全部门与支路目标有效",layouts.size())
 var all_skills:=true
 for actor in 17:
  if game.skills.catalog(actor).size()!=9:all_skills=false
 check(all_skills,"17 套专属技能树，153 个命名节点")
 var inv: RefCounted=game.inventory
 check(inv.owned("dagger")==1 and inv.owned("katana")==0,"新档初始匕首，太刀必须开箱获得")
 inv.grant("gear_ring");inv.grant("iron_armor");inv.grant("light_bell");inv.grant("medkit")
 check(inv.equip("gear_ring") and is_equal_approx(game.damage_multiplier(),1.08),"装备饰品实际增加攻击属性")
 check(not inv.equip("gear_ring","accessory2"),"同一实体装备不能同时占据两个槽位")
 inv.grant("gear_ring");check(inv.equip("gear_ring","accessory2") and is_equal_approx(game.damage_multiplier(),1.16),"拥有两件饰品时可分别装备两槽")
 check(inv.equip("iron_armor") and game.defense_multiplier()<.93,"护甲属性实际降低伤害")
 var health: float=game.max_hp();check(inv.equip("light_bell","accessory2") and game.max_hp()==health+25,"生命饰品改变生命上限")
 game.party_hp[0]=30;check(inv.use("medkit") and game.party_hp[0]==100 and inv.owned("medkit")==0,"背包消耗品恢复生命并消耗一件")
 game.magic=50;check(inv.use("ether") and game.magic==90,"魔力补剂实际恢复魔力")
 check(not inv.use("dagger") and not inv.equip("native_1"),"背包拒绝错误类别使用与未拥有武器")
 await enter(11);game.player.position=game.vector(game.data.checkpoint);await wait(.15)
 game.scrap=500;check(inv.buy("medkit") and game.scrap==475,"休息灯商店真实消耗货币并发货")
 inv.items.gear_core=4;var quantity: int=inv.owned("iron_armor");check(not inv.craft("iron_armor") and inv.owned("gear_core")==4 and inv.owned("iron_armor")==quantity,"制作材料不足时全部数量不变")
 inv.items.gear_core=5;check(inv.craft("iron_armor") and inv.owned("gear_core")==0 and inv.owned("iron_armor")==quantity+1,"固定配方一次性扣材料并发装备")
 var gear: Dictionary=inv.equipment.duplicate(true);var bag: Dictionary=inv.items.duplicate(true)
 game.save_game();inv.reset();check(game.load_game() and inv.equipment==gear and inv.items==bag,"背包数量、人物装备和属性随存档恢复")
 game.save_game();var invalid_save: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.save_path));invalid_save.equipment=[]
 var invalid_file:=FileAccess.open(game.save_path,FileAccess.WRITE);invalid_file.store_string(JSON.stringify(invalid_save));invalid_file.close()
 check(game.load_game() and inv.equipment==gear,"格式合法但背包字段损坏的主存档安全恢复备份")
 var isolated_payload: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.save_path+".backup"))
 isolated_payload.equipment["1"]={"armor":"iron_armor","accessory1":"light_bell"};isolated_payload.inventory.iron_armor=1
 inv.restore(isolated_payload)
 check(inv.assigned_count("iron_armor")<=1 and inv.assigned_count("light_bell")<=inv.owned("light_bell"),"存档恢复不允许同一件装备重复分配给多个角色")
 inv.items=bag.duplicate(true);inv.equipment=gear.duplicate(true);game.save_game()
 game.skill_points=50;inv.grant("gear_core",30);game.learned={};game.skills.levels={}
 check(not game.skills.upgrade(0,"C2"),"技能前置未满足时拒绝学习")
 check(game.skills.upgrade(0,"C1") and game.learned.has("0_0"),"基本技能学习接通实际战斗招式")
 var points: int=game.skill_points;check(game.skills.upgrade(0,"C1") and game.skills.level(0,"C1")==2 and game.skill_points<points,"技能升级扣点数与材料并保留等级")
 game.flags.rescued=true;game.inventory.on_recruit(1);game.skills.choose_actor(1);await wait(.2)
 check(game.screen=="skills" and game.active_slot==0 and game.skills.actor==1,"技能页可独立查看候补角色，不切换当前出战人物")
 check(game.skills.upgrade(1,"C1") and game.skills.level(0,"C1")==2 and game.skills.level(1,"C1")==1,"不同人物的学习进度独立")
 var frozen: Vector3=game.player.position;Input.action_press("right");await wait(.1);Input.action_release("right");check(game.player.position==frozen,"技能学习与预览暂停游戏战斗")
 var previews:=true
 for actor in 17:
  var model: Node3D=game.instantiate_model(game.Content.ROSTER[actor].model);var animator: AnimationPlayer=model.find_child("AnimationPlayer",true,false)
  for node in game.skills.NODES:
   if not animator.has_animation(game.skills.animation(actor,node)):previews=false;print("MISSING_PREVIEW ",actor," ",node," ",game.skills.animation(actor,node))
  model.free()
 check(previews,"153 个技能预览的角色与动画资源均存在")
 game.flags.boss5=true;check(game.skills.upgrade(0,"T1"),"章节条件满足后共鸣分支可学习")
 game.set_screen("play");game.campaign.resonance=100;game.campaign.transform();check(game.campaign.form_time==12 and game.campaign.resonance==0,"共鸣形态真实启动、扣共享资源并限定持续时间")
 game.campaign.form_time=0;game.skills.choose_actor(7);await wait(.25);await capture("02_skills_leiya")
 game.ui.extension.roster_selected=7;game.set_screen("roster");await wait(.2)
 var link: Button=null
 for b in game.ui.buttons:
  if b.text=="查看此人技能":link=b
 if link:link.pressed.emit()
 check(game.screen=="skills" and game.skills.actor==7,"名册按钮直达所选人物的专属技能页")
 await enter(50);game.set_screen("map");await wait(.2);var map: Control=game.ui.v10.map_view
 check(is_instance_valid(map) and map.connections(49).has(50) and map.connections(50).has(49),"世界地图使用真实双向房间连接")
 var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true;wheel.position=Vector2(100,120);var before_zoom: float=map.zoom;map._gui_input(wheel)
 check(map.zoom>before_zoom,"地图滚轮缩放实际生效")
 map.regional=true;game.map_region=7;map.fit();var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_RIGHT;click.pressed=true;click.position=map.transformed(map.room_rect(50)).get_center();map._gui_input(click)
 check(game.map_marks.has(game.rooms[50].id),"地图自定义标记写入持久状态")
 map._gui_input(click);check(not game.map_marks.has(game.rooms[50].id),"重复标记操作可移除标记")
 var old_offset: Vector2=map.offset;map.offset+=Vector2(123,24);map.grab_focus()
 var recenter_event:=InputEventKey.new();recenter_event.physical_keycode=KEY_R;recenter_event.pressed=true;Input.parse_input_event(recenter_event);await wait(.1)
 check(map.offset!=old_offset+Vector2(123,24),"地图 R 键通过真实输入事件定位玩家")
 for r in game.rooms:game.visited[r.id]=true
 map.regional=false;map.fit();await wait(.2);await capture("01_world_map")
 game.set_screen("inventory");inv.category="全部";inv.page=0;await wait(.2);await capture("03_inventory")
 game.set_screen("equipment");await wait(.2);await capture("04_equipment")
 # Real late-room construction, controller strikes and enemy damage for every new actor.
 for actor in range(7,17):
  game.flags[game.Content.ROSTER[actor].flag]=true;game.inventory.on_recruit(actor);game.party=[0,actor];game.active_slot=actor;game.party_hp=game.full_health();await enter(58)
  var enemy: Node=game.Enemy.new();enemy.game=game;enemy.kind="human";enemy.uid="qa_actor_"+str(actor);enemy.position=Vector3(-15,0,0);game.world.add_child(enemy);game.enemies.append(enemy);enemy.state="recover";enemy.clock=-20
  game.player.position=Vector3(-17,0,0);game.player.facing=1;await wait(.15);var hp: float=enemy.hp;game.player.begin_attack(false);await wait(.8)
  check(not is_instance_valid(enemy) or enemy.hp<hp,"新增角色真实轻击 / 投射命中 · "+game.Content.ROSTER[actor].name)
 game.active_slot=0;game.party=[0];game.party_hp=game.full_health()
 await enter(51);use("pressure_b");check(not game.flags.get("pressure_done",false),"热压炉门拒绝跳过泄压过程")
 use("pressure_a");await wait(2.1);use("pressure_b");check(game.flags.get("pressure_done",false),"两秒泄压后炉门可以固定")
 await enter(54);await clear();use("ability_lava");check(game.flags.get("lava_license",false) and inv.wrap=="lava_wrap","熔界许可发放并启用全队护套")
 await enter(55);await clear();game.party_hp=game.full_health();game.player.position=Vector3(0,-1.15,0);game.player.velocity=Vector3.ZERO;var hp: float=game.party_hp[0];await wait(1)
 check(game.heat>4 and game.party_hp[0]==hp,"岩浆护套承受热负荷并保护角色")
 inv.wrap="";game.player.invulnerable=0;await wait(.7);check(game.party_hp[0]<hp,"没有护套时岩浆产生实际周期伤害")
 await enter(62);use("ability_anchor");await enter(63);use("anchor_pull");check(game.flags.get("anchor_open",false),"重锚工具解开船坞门")
 await enter(67);use("name_b");check(not game.flags.get("names_done",false),"档案姓名锁错序安全复位")
 for kind in ["name_a","name_b","name_c"]:use(kind)
 check(game.flags.get("names_done",false),"三条真名按顺序恢复档案门")
 await enter(75);use("rail_route");check(not game.flags.get("train_saved",false),"带电状态拒绝转接列车")
 for kind in ["rail_off","rail_route","rail_on"]:use(kind)
 check(game.flags.get("train_saved",false),"断电转轨上电后救下列车")
 await enter(76);use("ability_rail");check(game.flags.get("rail_slide",false) and not game.world_builder.moving.is_empty(),"轨链教学接通实体中继升降平台")
 await enter(87);use("source_a");check(not game.flags.get("sources_done",false),"未取得工具时三源锁拒绝通行")
 await enter(86);use("ability_resonance");await enter(87)
 for kind in ["source_a","source_b","source_c"]:use(kind)
 check(game.flags.get("sources_done",false),"全队共鸣工具稳定三源锁")
 var late_rooms:=true
 for number in range(50,126):
  await enter(number)
  if game.world_builder.batched_instances<=0 or not is_instance_valid(game.player.visual):late_rooms=false
 check(late_rooms,"76 个新增房间均可构建，场景合批与角色模型有效")
 var forward:=true;var backward:=true
 for r in game.rooms:
  if not str(r.get("gate","")).is_empty():game.flags[r.gate]=true
  if r.has("entry_gate"):game.flags[r.entry_gate]=true
 game.flags.mila_wish=true
 for number in range(50,126):
  await enter(number);await clear();game.player.position=game.vector(game.rooms[number].exit)+Vector3(-1,.04,0);game.player.velocity=Vector3.ZERO;await wait(.42)
  Input.action_press("right");await wait(.32);Input.action_release("right");await wait(.08)
  if number==97:
   if game.room!=97 or game.screen!="ending":forward=false
  elif game.room!=int(game.rooms[number].next):forward=false;print("V10_FORWARD_FAIL ",number," -> ",game.room)
  await enter(number);await clear();game.player.position=game.vector(game.rooms[number].back)+Vector3(1,.04,0);game.player.velocity=Vector3.ZERO;await wait(.42)
  Input.action_press("left");await wait(.32);Input.action_release("left");await wait(.08)
  if game.room!=int(game.rooms[number].previous):backward=false;print("V10_BACK_FAIL ",number," -> ",game.room)
 check(forward,"76 个新增前门实际步行进入目标，炉心停留最终选择")
 check(backward,"76 个新增后门实际步行回访，支路回主路而非区域原点")
 var contracts: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/quests.json"));var quests_ok:=true
 for q in contracts:
  await enter(q.room);use("quest_"+q.id);await enter(q.proof_room);use("proof_"+q.id);await enter(q.room);await clear();use("quest_"+q.id)
  var old_money: int=game.scrap;var quest_quantity: int=inv.owned(q.reward);use("quest_"+q.id)
  if int(game.campaign.quest_states.get(q.id,0))!=3 or game.scrap!=old_money or inv.owned(q.reward)!=quest_quantity:quests_ok=false;print("QUEST_FAIL ",q.id)
 check(quests_ok and contracts.size()==28,"20 支线与 8 隐藏委托可接取、找证物、返回交付，奖励唯一")
 var recruited_ok:=true
 await enter(17);await clear();use("recruit")
 for actor in range(3,17):
  game.flags.erase(game.Content.ROSTER[actor].flag)
  if actor==8:game.flags.lab_evidence=true
  if actor==16:
   for core in ["core1","core2","core3"]:game.flags[core]=true
  var location: int=-1
  for number in game.rooms.size():
   for prop in game.rooms[number].props:
    if prop.kind=="recruit"+str(actor):location=number
  if location<0:recruited_ok=false;continue
  await enter(location);await clear();use("recruit"+str(actor));var recruit_points: int=game.skill_points;use("recruit"+str(actor))
  if not game.available_slots().has(actor) or inv.owned("native_%d"%actor)!=1 or game.skill_points!=recruit_points:recruited_ok=false
 check(recruited_ok and game.available_slots().size()==17,"所有新增同伴在各自实际招募点加入，重复交谈不复制武器或点数")
 var elite_ok:=true
 for elite in range(1,9):
  var kind: String="elite%d"%elite;game.flags[kind]=false;var location: int=-1
  for number in game.rooms.size():
   for foe in game.rooms[number].enemies:
    if foe.kind==kind:location=number
  if location<0:elite_ok=false;continue
  await enter(location);await clear();var elite_money: int=game.scrap;await enter(location)
  if not game.flags.get(kind,false) or not game.enemies.is_empty() or game.scrap!=elite_money:elite_ok=false
 check(elite_ok,"八个隐藏精英实体战斗与击败存档，回访不复活或重复奖励")
 # Bosses must actually sense, wind up and cause damage, then preserve defeat state.
 for number in [56,64,72,80,88,96]:
  var flag: String=game.rooms[number].gate;game.flags[flag]=false;await enter(number);var boss: Node=game.enemies[0]
  game.player.position=boss.position+Vector3(-5,0,0);game.player.velocity=Vector3.ZERO;game.player.invulnerable=0;game.party_hp=game.full_health();hp=game.party_hp[0];boss.state="chase";boss.clock=0;boss.cooldown=0;await wait(1.9)
  check(boss.attacks>0 and game.party_hp[0]<hp,"后六章 Boss 感知、预警与实际伤害 · "+boss.kind)
  boss.hurt(boss.max_hp*.55,1);game.set_screen("play");await wait(.12);check(boss.phase_two,"后六章 Boss 半血强化 · "+boss.kind)
  await clear();await enter(number);check(game.enemies.is_empty(),"后六章 Boss 回访不重复奖励 · "+flag)
 await enter(89);use("separation_core");check(game.flags.get("mila_wish",false) and inv.owned("separation_core")==1,"主线提供米菈真实意愿和唯一分离核心")
 for pair in [[92,"lock_power"],[93,"lock_blood"],[94,"lock_rift"]]:
  await enter(pair[0]);await clear();game.flags.phase_step=true;use(pair[1]);check(game.flags.get(pair[1],false),"冠城炉锁整合工具 · "+pair[1])
 await enter(97);game.set_screen("ending");await capture("11_ending_choice")
 game.campaign.complete_ending(1);check(not game.flags.get("ending1",false),"城市锚点不足时不能共同分离")
 game.flags.steam=true;game.flags.root_bridge=true;game.flags.circuit=true;await enter(102)
 for kind in ["anchor_water","anchor_air","anchor_power"]:use(kind)
 check(game.flags.get("anchor_water",false) and game.flags.get("anchor_air",false) and game.flags.get("anchor_power",false),"三个城市锚点均可回访修复")
 for choice in [1,2,3]:
  game.campaign.complete_ending(choice);check(game.flags.get("ending"+str(choice),false) and game.checkpoint_room==95,"结局 %d 保存档案并回终战前安全房"%choice)
 game.set_screen("play");game.save_game();game.load_game();check(game.room==95 and game.flags.get("ending1",false) and game.flags.get("ending3",false),"通关存档载入保留多个结局与探索状态")
 for pair in [[56,"05_furnace"],[60,"06_bonecity"],[68,"07_archive"],[78,"08_rail"],[88,"09_rift"],[96,"10_crown"]]:
  var room_data: Dictionary=game.rooms[pair[0]]
  for foe in room_data.enemies:
   var definition: Dictionary=game.Content.ENEMIES[foe.kind]
   if definition.get("boss",false):game.flags[definition.flag]=false
  await enter(pair[0]);game.player.invulnerable=10;game.overview=true;await wait(.35);await capture(pair[1])
 game.overview=false;game.set_screen("play")
 var file:=FileAccess.open("user://v10_runtime.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks},"  "));file.close();return checks
