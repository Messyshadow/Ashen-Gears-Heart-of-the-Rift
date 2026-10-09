extends RefCounted
var checks: Array=[]
var game: Node3D
var directory := ""
func check(ok: bool, value: String) -> void:
	checks.append({"pass":ok,"check":value,"state":game.player.snapshot()})
	print("PASS " if ok else "FAIL ",value)
func settle(time: float = .4) -> void:await game.get_tree().create_timer(time).timeout
func drive(action: String, time: float) -> void:
	Input.action_press(action);await settle(time);Input.action_release(action);await game.get_tree().physics_frame
func capture(name: String) -> void:
	if directory.is_empty():return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))
func run(g: Node3D, path: String) -> void:
	game=g;directory=path
	if not directory.is_empty():DirAccess.make_dir_recursive_absolute(directory)
	await settle(.5);await capture("00_title")
	game.new_game();game.set_screen("play");await settle(.4)
	check(game.player.is_on_floor(),"煤仓起点支撑")
	await drive("right",.8);check(game.player.position.x>-9,"实际输入向右行走")
	var y: float=game.player.position.y
	await drive("jump",.20);check(game.player.position.y>y+.3,"起跳离地")
	await settle(.8);check(game.player.is_on_floor(),"落地接地")
	game.player.position=Vector3(-.7,7,0);await settle(.3);await drive("down",1.4)
	check(game.player.motion=="ladder" and game.player.position.y<6,"开井盖并攀下")
	check(game.hatch_target<0,"井盖开启且解除碰撞")
	await capture("01_hatch")
	await drive("down",3.9);await settle(.7);check(game.player.position.y<.4 and game.player.motion=="ground","井口到下层无卡死")
	game.load_room(1);game.set_screen("play");await settle(.4)
	var e: Node=game.enemies[0]
	game.player.position=e.position+Vector3(-1,0,0);game.player.facing=1;game.player.crouching=true
	check(e.can_assassinate(),"背向未警觉人类允许暗杀")
	game.update_nearest();game.interact();await settle(.2)
	check(game.defeated.has("R01-02:0"),"暗杀一次记录击败旗标")
	game.player.attack_clock=0;game.player.position=Vector3(-.7,0,0);await settle(.3);await drive("up",4.8);await settle(.6)
	check(game.player.position.y>6.8 and game.player.motion=="ground","竖梯从下层返回上层")
	await capture("02_ladder")
	game.load_room(2);game.set_screen("play");await settle(.4)
	check(not game.enemies[0].can_assassinate(),"机械犬禁止暗杀")
	Input.action_press("right")
	for i in range(65):
		await settle(.1)
		if game.player.position.x>2.5 and absf(game.player.position.y-4)<.4:break
	Input.action_release("right")
	await drive("left",.9)
	check(game.player.switch_lane==1,"折返平台改变深度轨道")
	await drive("left",3.2);check(game.player.position.y<.8 and game.player.switch_lane==1,"双段楼梯抵达底层")
	await capture("03_stairs")
	game.load_room(3);game.set_screen("play");await settle(.4)
	game.player.position=Vector3(4,0,0);game.update_nearest();game.interact()
	check(not game.flags.get("rescued",false),"救援受守卫阻挡")
	for enemy in game.enemies:
		if is_instance_valid(enemy):enemy.hurt(999,1)
	await settle(.2);game.update_nearest();game.interact()
	check(game.flags.get("rescued",false),"战后洛铆加入")
	game.set_screen("play");game.player.hurt_clock=0;game.player.attack_clock=0;game.switch_cooldown=0
	game.player.position=Vector3(5,3,0);game.player.velocity=Vector3(3,-2,0)
	var p: Vector3=game.player.position;var v: Vector3=game.player.velocity
	game.switch_actor(1)
	check(game.active_slot==1 and game.player.position==p and game.player.velocity==v,"空中切换保留位置速度")
	game.load_room(4);game.set_screen("play");await settle(.4)
	game.player.position=Vector3(-6,0,0);game.update_nearest();game.interact();game.set_screen("play")
	check(game.flags.get("grapple",false),"维修台发放钩索")
	game.load_room(5);game.set_screen("play");await settle(.4)
	game.player.position=Vector3(3,7,0);game.player.velocity=Vector3.ZERO;await settle(.1)
	check(game.selected_anchor()!=null,"标记锚点范围和遮挡选择")
	Input.action_press("grapple");await settle(.2);Input.action_release("grapple");await settle(1.5)
	check(game.player.position.y>9.7 and game.player.position.x>8,"钩索实际输入抵达高台")
	await capture("04_grapple")
	game.load_room(6);game.set_screen("play");await settle(.5)
	var boss: Node=game.enemies[0]
	check(not boss.can_assassinate(),"Boss 禁止暗杀")
	game.player.position=Vector3(4.1,0,0);game.player.facing=1;boss.state="recover";boss.clock=-20;await settle(.2)
	var before: float=boss.hp
	await drive("heavy",.05);await settle(.5)
	check(boss.hp<before,"重击有效帧造成真实伤害")
	await capture("05_boss")
	game.player.attack_clock=0;game.player.hurt_clock=0;game.player.invulnerable=0;game.player.guard_clock=.05;game.player.guarding=true;game.player.facing=1
	var hp: float=game.party_hp[game.active_slot]
	game.damage_player(20,-1,boss)
	check(game.party_hp[game.active_slot]==hp and boss.state=="stunned","完美弹反不掉血且破势")
	game.player.invulnerable=.1;game.damage_player(20,-1,boss);check(game.party_hp[game.active_slot]==hp,"闪避无敌窗口拒绝伤害")
	boss.hurt(999,1);await settle(.2);check(game.flags.get("boss",false),"击败典刑机提交唯一核心旗标")
	game.set_screen("play");game.load_room(7);await settle(.4);game.player.position=Vector3(-5,0,0);game.update_nearest();game.interact()
	check(game.flags.get("manifest",false),"转运表揭示伪造签名")
	game.set_screen("play");game.load_room(9);await settle(.4)
	for k in ["gear1","gear0","gear1","gear2"]:
		for prop in game.props:
			if prop.kind==k:game.nearest=prop;game.interact();break
	check(game.flags.get("gear",false),"P01 先拔锁销接惰轮合离合，错序可恢复")
	await capture("06_gears")
	game.load_room(10);game.set_screen("play");await settle(.4)
	for prop in game.props:
		if prop.kind=="water":game.nearest=prop;game.interact();break
	await settle(2.2)
	for k in ["water","confirm","steam"]:
		for prop in game.props:
			if prop.kind==k:game.nearest=prop;game.interact();break
	await settle(2.4)
	check(game.flags.get("steam",false),"简化 P02 中水位稳定旁路排水解锁")
	game.learn_skill(0);check(game.learned.has("%d_0"%game.active_slot),"技能点学习招式")
	game.checkpoint_room=10;game.checkpoint_pos=Vector3(-12,0,0);game.save_game()
	var scrap: int=game.scrap;game.scrap=0;game.flags={};game.load_game()
	check(game.flags.get("boss",false) and game.flags.get("gear",false) and game.scrap==scrap,"原子存档读取恢复奖励与机关")
	game.set_screen("map");await settle(.1);await capture("07_map")
	game.set_screen("skills");await settle(.1);await capture("08_skills")
	game.set_screen("play");game.load_room(11);await settle(.3);await capture("09_hub")
	var route_ok := true
	for i in range(11):
		game.load_room(i,game.vector(game.rooms[i].exit));game.set_screen("play");await settle(.25)
		game.update_nearest()
		if game.nearest.get("kind","")!="exit":route_ok=false;continue
		game.interact();await settle(.15)
		if game.room!=int(game.rooms[i].next):route_ok=false
	check(route_ok,"11 个前进门在实体楼层可达且连接正确")
	game.set_screen("play");game.load_room(4);await settle(.2)
	game.player.position=game.vector(game.rooms[4].exit);game.player.velocity=Vector3.ZERO;await settle(.2);game.update_nearest()
	game.flags.grapple=false;game.interact();await settle(.1)
	check(game.room==4,"能力门在未取得钩索时拒绝通行")
	game.flags.grapple=true
	game.save_game();game.save_game()
	var corrupt := FileAccess.open(game.save_path,FileAccess.WRITE);corrupt.store_string("{interrupted");corrupt.close()
	check(game.load_game() and game.flags.get("grapple",false),"中断损坏主存档后恢复有效备份")
	game.set_screen("map");var stop: Vector3=game.player.position;await drive("right",.3)
	check(game.player.position==stop,"地图暂停运动与敌人逻辑")
	var failures := 0
	for item in checks:if not item.pass:failures+=1
	var report := {"checks":checks,"failures":failures,"input":"Godot Input actions and physics; no physical controller or full human playthrough","engine":Engine.get_version_info().string}
	var report_path := directory.get_base_dir().path_join("runtime_tests.json") if not directory.is_empty() else "user://runtime_tests.json"
	var out := FileAccess.open(report_path,FileAccess.WRITE);out.store_string(JSON.stringify(report,"  "));out.close()
	print("QA_FINISHED ",checks.size()," checks, ",failures," failures")
	game.get_tree().quit(1 if failures>0 else 0)
