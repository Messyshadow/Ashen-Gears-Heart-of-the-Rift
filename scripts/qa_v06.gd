extends RefCounted
var game: Node3D
var checks: Array=[]
var directory := ""
func wait(t: float=.2) -> void:await game.get_tree().create_timer(t).timeout
func check(ok: bool,name: String,detail: Variant=null) -> void:
	checks.append({"pass":ok,"check":name,"detail":detail});print("PASS " if ok else "FAIL ",name," ",detail)
func use(kind: String) -> void:
	game.nearest={}
	for prop in game.props:
		if prop.kind==kind:game.nearest=prop;break
	game.interact();game.set_screen("play")
func enter(number: int) -> void:game.load_room(number);game.set_screen("play");await wait(.15)
func clear() -> void:
	for enemy in game.enemies:
		if is_instance_valid(enemy):enemy.hurt(9999,1)
	game.set_screen("play");await wait(.1)
func place(p: Vector3) -> void:game.player.position=p;game.player.velocity=Vector3.ZERO;game.player.attack_clock=0;game.player.hurt_clock=0;game.player.motion="ground";game.player.grappling=false
func capture(name: String) -> void:
	if directory.is_empty():return
	await RenderingServer.frame_post_draw;game.get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))
func run(g: Node3D,path: String) -> Array:
	game=g;directory=path;game.new_game();game.set_screen("play")
	check(game.rooms.size()==50 and game.Content.ROSTER.size()==7,"50 房间、七名可收集角色与六个主线区域")
	var distinct: Dictionary={};var doors_supported:=true;var ids: Dictionary={}
	for r in game.rooms:
		ids[r.id]=true;distinct[JSON.stringify([r.platforms,r.ladders,r.slopes])]=true
		if int(r.next)<0 or int(r.next)>=50 or int(r.previous)<0 or int(r.previous)>=50:doors_supported=false
		for doorway in [r.exit,r.back,r.spawn]:
			var found:=false
			for floor in r.platforms:
				if float(doorway[0])>=float(floor[0]) and float(doorway[0])<=float(floor[1]) and absf(float(doorway[1])-float(floor[2]))<.05:found=true
			if not found:doors_supported=false
	check(ids.size()==50 and distinct.size()>=40 and doors_supported,"房间身份、独立路线布局及前后门入口均有实体地面",distinct.size())
	# Test closed progression gates before solving them.
	for number in [19,27,35,43,47]:
		await enter(number);place(game.vector(game.rooms[number].exit));use("exit");await wait(.05)
		check(game.room==number,"未解机关阻挡区域门 %s"%game.rooms[number].id)
	await enter(19);use("steam_reset");use("confirm");check(not game.water[3],"水务区错序不能直接开启旁路")
	use("water");await wait(2.1);use("water");use("confirm");use("steam");await wait(2.2)
	check(game.flags.get("steam",false),"水务区真实加水、停水、旁路、排水联锁完成")
	check(not game.world_builder.extension.floats.is_empty(),"水位控制有实体碰撞浮筒平台")
	game.overview=true;await wait(.4);await capture("16_water")
	await enter(27);use("root_lock");check(not game.flags.get("root_bridge",false),"迁木桥未到灯位不能锁定")
	use("root_light");await wait(7);use("root_lock");check(game.flags.get("root_bridge",false),"迁木桥实际移动到灯位并锁定")
	await capture("17_garden")
	await enter(35);use("mirror_a");check(not game.flags.get("clock_open",false),"单镜不足以开钟锁")
	use("mirror_b");check(game.flags.get("clock_open",false),"双镜对齐开启钟锁")
	await capture("18_castle")
	await enter(43);use("plate_left");check(not game.flags.get("plate_left",false),"复制机关错序压板拒绝交付")
	use("scan");use("copy");use("plate_left");use("plate_right");check(game.flags.get("copy_complete",false),"登记、复制、双压板联锁完成")
	await capture("19_lab")
	await enter(47);use("power");check(not game.flags.get("circuit",false) and not game.flags.get("route_power",false),"错序上电保护跳闸且可以重接")
	for kind in ["split","coolant","door_link","insulate"]:use(kind)
	use("power");await wait(2.2);check(game.flags.get("circuit",false),"断电接四路、绝缘再上电冷却两秒联锁完成")
	# Collection is blocked by live enemies, persists, and never repeats rewards.
	game.flags.rescued=true;game.flags.ranger=true;game.party=[0,1,2]
	for pair in [[21,3],[30,4],[38,5],[45,6]]:
		await enter(pair[0]);var kind: String="recruit%d"%pair[1];use(kind)
		check(not pair[1] in game.available_slots(),"守卫存在时不能招募 %s"%game.Content.ROSTER[pair[1]].name)
		await clear();use(kind);var points: int=game.skill_points;use(kind)
		check(pair[1] in game.available_slots() and game.skill_points==points,"招募记录与唯一奖励 %s"%game.Content.ROSTER[pair[1]].name)
	check(game.available_slots().size()==7 and game.field_slots().size()==3,"七名角色收集完成，出战编队限制三人")
	await enter(29);use("airdash");check(game.learned.has("6_2"),"空冲训练同步已招募同伴")
	await enter(39);use("phase_step");await clear();place(Vector3(-1.8,.04,0));game.player.facing=1;game.magic=100;await wait(.15);game.phase_step()
	check(game.player.position.x>.8 and game.magic<=85,"标记薄壁安全相移实际跨墙并扣魔力")
	await enter(11);place(game.vector(game.data.checkpoint));await wait(.15)
	game.assign_party(3,0);game.assign_party(4,1);game.assign_party(5,2)
	check(game.field_slots()==[3,4,5],"休息灯三人编队可替换收集角色")
	game.ui.extension.roster_selected=3;game.set_screen("roster");await wait(.2);await capture("20_roster");game.set_screen("play")
	game.save_game();game.party=[0,1,2];game.load_game();game.set_screen("play");check(game.party==[3,4,5] and game.available_slots().size()==7,"继续游戏恢复七名收集记录与三人编队")
	# Real attacks use the imported clips and affect an actual enemy.
	for slot in range(3,7):
		await enter(11);place(game.vector(game.data.checkpoint));game.assign_party(slot,0);game.switch_cooldown=0;game.active_slot=slot;game.player.set_actor(slot)
		await enter(1);var enemy: Node=game.enemies[0];enemy.state="recover";enemy.clock=-20;place(enemy.position+Vector3(-1.6,0,0));game.player.facing=1;await wait(.2)
		var hp: float=enemy.hp;game.player.begin_attack(false);await wait(.65)
		check(is_instance_valid(enemy) and enemy.hp<hp,"新同伴轻击骨骼动作与有效帧命中 %s"%game.Content.ROSTER[slot].name)
		game.player.attack_clock=0;game.player.hurt_clock=0;game.learned["%d_0"%slot]=true;game.skill_cooldown=0;game.magic=100;enemy.state="recover";enemy.clock=-20;hp=enemy.hp;game.player.begin_skill(0);await wait(.8)
		check(not is_instance_valid(enemy) or enemy.hp<hp,"新同伴招式真实命中 %s"%game.Content.ROSTER[slot].name)
	# Walk every forward and backward doorway with all appropriate gates satisfied.
	await enter(11);place(game.vector(game.data.checkpoint));game.player.begin_attack(false);var before_party: Array=game.party.duplicate();var before_active: int=game.active_slot
	game.menu_actor(4);game.assign_party(0,0);check(game.active_slot==before_active and game.party==before_party,"攻击未收招时技能与名册菜单不能强制换人或取消攻击")
	await wait(.6);game.party_hp[4]=0;game.menu_actor(4);game.assign_party(4,0);check(game.active_slot==before_active and game.party==before_party,"菜单不能切入或编入已倒地同伴")
	game.party_hp=game.full_health()
	var fallen: int=game.active_slot;var replacement: int=-1
	for member in game.field_slots():
		if member!=fallen and game.party_hp[member]>0:replacement=member;break
	game.player.begin_attack(false);game.party_hp[fallen]=1;game.player.invulnerable=0;game.environment_damage(20);await wait(.35)
	check(game.active_slot==replacement and game.player.attack_clock<=0,"环境伤害击倒攻击中的角色后安全接替，不继承缺失的专属攻击动画",{"fallen":fallen,"expected":replacement,"actual":game.active_slot})
	game.player.shield_clock=2;game.player.invulnerable=0;var shield_hp: float=game.party_hp[game.active_slot];game.environment_damage(10);check(is_equal_approx(game.party_hp[game.active_slot],shield_hp-5),"护盾减伤同样覆盖环境与物理机关")
	game.player.shield_clock=0;game.party_hp=game.full_health()
	for q in game.Content.QUESTS:game.flags[q.flag]=true
	game.flags.gear=true;game.flags.grapple=true;game.flags.manifest=true;game.flags.wall=true
	var forward_ok:=true;var backward_ok:=true
	for number in range(50):
		await enter(number);await clear();place(game.vector(game.rooms[number].exit)+Vector3(-1,.04,0));await wait(.42)
		Input.action_press("right");await wait(.32);Input.action_release("right");await wait(.08)
		if number==49:
			if game.room!=49 or game.screen!="chapter_complete":forward_ok=false
		elif game.room!=int(game.rooms[number].next):forward_ok=false;print("V06_FORWARD_FAIL ",number," -> ",game.room)
		if number==0 or number==11:continue
		await enter(number);await clear();place(game.vector(game.rooms[number].back)+Vector3(1,.04,0));await wait(.42)
		Input.action_press("left");await wait(.32);Input.action_release("left");await wait(.08)
		if game.room!=int(game.rooms[number].previous):backward_ok=false;print("V06_BACK_FAIL ",number," -> ",game.room)
	check(forward_ok,"50 个前门实际步行推进，最终终点明确停留完成界面")
	check(backward_ok,"48 个左门实际步行回访前室，不退回区域原点")
	for number in [24,32,40,48]:
		var flag: String=game.rooms[number].gate;game.flags[flag]=false;await enter(number);var boss: Node=game.enemies[0];boss.hurt(boss.max_hp*.52,1);await wait(.1)
		check(boss.phase_two and not boss.can_assassinate(),"新 Boss 半血二阶段与暗杀限制 %s"%boss.kind)
		game.party_hp=game.full_health();place(boss.position+Vector3(-5,0,0));game.player.invulnerable=0;game.player.guarding=false;var hp_before: float=game.party_hp[game.active_slot];boss.state="chase";boss.clock=0;boss.cooldown=0
		await wait(1.65);check(boss.attacks>0 and game.party_hp[game.active_slot]<hp_before,"新 Boss 感知、前摇与实体攻击伤害 %s"%boss.kind)
		await clear();var money: int=game.scrap;await enter(number);check(game.enemies.is_empty() and game.scrap==money,"新 Boss 唯一击败记录与回访 %s"%flag)
	await enter(11);place(game.vector(game.data.checkpoint));game.fast_travel(26);check(game.room==26,"休息灯传送可回访已发现迁木园")
	var old_keys: Dictionary=game.controls.keys.duplicate();check(game.controls.bind_key("jump",KEY_B),"按键设置真实重绑跳跃 B")
	await wait(.25);var key:=InputEventKey.new();key.physical_keycode=KEY_B;key.keycode=KEY_B;key.pressed=true;Input.parse_input_event(key);await wait(.12);key.pressed=false;Input.parse_input_event(key)
	check(game.player.position.y>.4,"重绑后的 B 键实际触发角色跳跃")
	var found:=false
	for event in InputMap.action_get_events("jump"):
		if event is InputEventKey and event.physical_keycode==KEY_B:found=true
	check(found and not game.controls.bind_key("light",KEY_B),"重绑生效并拒绝重复占用")
	game.controls.keys=old_keys;game.controls.apply();game.controls.save()
	var config:=ConfigFile.new();check(config.load(game.controls.config_path)==OK and int(config.get_value("keys","jump",0))==KEY_SPACE,"按键设置写入可恢复的配置文件")
	var original: Dictionary=game.graphics.settings.duplicate(true);game.graphics.settings.fog=false;game.graphics.settings.glow=false;game.graphics.settings.brightness=1.25;game.graphics.apply_settings(false)
	check(not game.environment.fog_enabled and not game.environment.glow_enabled and is_equal_approx(game.environment.ambient_light_energy,.7),"雾气、辉光与环境亮度设置实际生效")
	game.graphics.settings=original;game.graphics.apply_settings(false)
	var window_size: Vector2i=DisplayServer.window_get_size();DisplayServer.window_set_size(Vector2i(960,540));await wait(.2);game.open_graphics();await wait(.15)
	var no_overlap:=true
	for i in range(10):
		var a: Control=game.ui.graphics_controls[i];var b: Control=game.ui.graphics_controls[i+1]
		if a.position.y+a.size.y>b.position.y+1:no_overlap=false
	check(no_overlap,"960×540 小窗口下十一项画面控件不重叠")
	DisplayServer.window_set_size(window_size);await wait(.2)
	game.open_settings();check(game.screen=="settings","统一设置入口")
	await capture("21_settings");game.set_screen("controls");await wait(.2);check(game.ui.buttons.size()>=10,"按键大类显示实际操作控件");await capture("22_controls")
	game.set_screen("map");game.map_region=6;game.ui.rebuild_buttons();await wait(.2);check(game.ui.buttons.size()==15,"区域分页地图显示七个区域与八个房间");await capture("23_map")
	game.set_screen("play");await enter(49)
	for prop in game.props:
		if prop.kind=="exit":game.nearest=prop;break
	game.interact();check(game.screen=="chapter_complete" and game.flags.get("stage_complete",false),"R06 终点保存阶段完成记录，回访入口明确")
	await capture("24_final")
	var report:=FileAccess.open(directory.get_base_dir().path_join("v06_runtime.json") if not directory.is_empty() else "user://v06_runtime.json",FileAccess.WRITE);report.store_string(JSON.stringify({"version":"0.6.0","checks":checks},"  "));report.close()
	game.set_screen("play");return checks
