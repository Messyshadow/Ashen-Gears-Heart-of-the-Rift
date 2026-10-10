extends RefCounted
var game: Node3D
var directory := ""
var checks: Array=[]
func check(ok: bool,name: String) -> void:
	checks.append({"pass":ok,"check":name,"room":game.room,"state":game.player.snapshot()});print("PASS " if ok else "FAIL ",name)
func settle(t: float=.3) -> void:await game.get_tree().create_timer(t).timeout
func drive(action: String,t: float) -> void:
	Input.action_press(action);await settle(t);Input.action_release(action);await game.get_tree().physics_frame
func place(p: Vector3) -> void:
	game.player.position=p;game.player.velocity=Vector3.ZERO;game.player.hurt_clock=0;game.player.attack_clock=0;game.player.motion="ground"
func enter(i: int) -> void:
	game.load_room(i);game.set_screen("play");await settle(.25)
func prop(kind: String) -> Dictionary:
	for item in game.props:
		if item.kind==kind:return item
	return {}
func use(kind: String) -> void:
	game.nearest=prop(kind);game.interact();game.set_screen("play")
func clear_enemies() -> void:
	for e in game.enemies:
		if is_instance_valid(e):e.hurt(9999,1)
	game.set_screen("play");await settle(.1)
func capture(name: String) -> void:
	if directory.is_empty():return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))
func run(g: Node3D,path: String) -> int:
	game=g;directory=path
	if not path.is_empty():DirAccess.make_dir_recursive_absolute(path)
	await settle(.5);await capture("00_title")
	game.new_game();game.set_screen("play");await settle(.3)
	check(game.player.is_on_floor(),"煤仓安全入口接地")
	check(game.enemies.size()>0 and is_instance_valid(game.enemies[0]),"首室有真实巡逻敌人")
	var start: float=game.player.position.x
	await drive("right",.6);check(game.player.position.x>start+2,"实际行走输入推进")
	Input.action_press("run");await drive("right",.5);Input.action_release("run");check(game.player.velocity.x>6,"Alt 冲跑速度")
	await drive("down",.1);Input.action_press("down");await settle(.1);check(game.player.capsule.height<1.2,"蹲行改变碰撞高度");Input.action_release("down")
	await clear_enemies();place(Vector3(-4,0,0));await settle(.2)
	await drive("jump",.18);check(game.player.position.y>.7,"跳跃实际离地");await settle(.9);check(game.player.is_on_floor(),"跳跃落地")
	place(Vector3(18.5,0,0));await settle(.1);await drive("right",.5);await settle(.15)
	check(game.room==1,"右门实际步行自动进入下一房，不返回煤仓")
	check(game.checkpoint_room==1,"换房同步当前重试入口")
	await clear_enemies();place(Vector3(-12,0,0));await settle(.2);await drive("up",1.9);await settle(.3)
	check(game.player.position.y>3.8 and game.player.motion=="ground","巡逻廊竖梯真实输入登顶")
	place(Vector3(-2,0,0));game.player.facing=1;await settle(.2);await drive("jump",.05);await settle(.5)
	check(game.player.vaults>0 and game.player.position.x>0,"低障碍触发翻越动作并越过")
	await enter(2);game.overview=true;await settle(1);await capture("01_press")
	check(game.rooms[2].platforms.size()==4 and not game.world_builder.hazards.is_empty(),"压料车间独立三层及压锤")
	await enter(3);game.overview=false;place(Vector3(14,0,0));use("rescue");check(not game.flags.get("rescued",false),"救援受活守卫阻挡")
	await clear_enemies();use("rescue");check(game.flags.get("rescued",false),"击退守卫后救出洛铆")
	place(Vector3(-16,0,0));await settle(.2);await drive("right",4.4);await settle(.2);check(game.player.position.y>4.8 and game.player.position.x>2,"囚门整段斜梯实际步行抵达监视廊")
	place(Vector3(0,3,0));game.player.velocity=Vector3(3,-2,0);var p: Vector3=game.player.position;var v: Vector3=game.player.velocity
	game.switch_cooldown=0;game.switch_actor(1);check(game.active_slot==1 and game.player.position==p and game.player.velocity==v,"空中切换保留位置和速度")
	await enter(4);use("grapple");check(game.flags.get("grapple",false),"维修台解锁钩索")
	use("mobility");check(game.learned.has("1_2"),"身法训练解锁角色空冲")
	await enter(5);await clear_enemies();place(Vector3(-8,0,0));game.player.facing=1;await settle(.15)
	check(game.selected_anchor()!=null,"断桥锚点可选且未被平台遮挡")
	await drive("grapple",.1);await settle(1.1)
	check(game.player.position.x> -4 and game.player.position.y>1.8,"钩索实际跨越首段断桥")
	await drive("grapple",.1);await settle(1.0);check(game.player.position.x>2 and game.player.position.y>3.7,"钩索连续抵达第二高台")
	await capture("02_grapple")
	await drive("grapple",.1);await settle(1.1);check(game.player.position.x>11 and game.player.position.y>3.7,"连续钩索第三段接入右侧通行平台")
	place(Vector3(10,4,0));await settle(.3);await drive("jump",.18);Input.action_press("modifier");await drive("jump",.05);Input.action_release("modifier")
	check(game.player.air_dash_used and game.player.dash_clock>0,"空中冲刺一次性实际输入")
	await settle(.35);await drive("heavy",.04);check(game.player.slamming,"空中重击触发下砸");await settle(.7);check(not game.player.slamming,"下砸接地结束")
	await enter(6);game.overview=true;await settle(.6);await capture("03_execution")
	var boss: Node=game.enemies[0];check(not boss.can_assassinate(),"典刑机禁止暗杀")
	place(boss.position+Vector3(-2.2,0,0));boss.state="recover";boss.clock=-10;game.player.facing=1;await settle(.2)
	var before: float=boss.hp;await drive("heavy",.03);await settle(.55);check(boss.hp<before,"机械师重击有效帧命中 Boss")
	game.player.attack_clock=0;game.player.hurt_clock=0;game.player.invulnerable=0;game.player.guarding=true;game.player.guard_clock=.05;game.player.facing=1
	var hp: float=game.party_hp[1];game.damage_player(20,-1,boss);check(game.party_hp[1]==hp and boss.state=="stunned","完美弹反无伤并中断 Boss")
	game.player.guarding=false;game.player.dodge_clock=.2;game.player.dodge_elapsed=.1;game.damage_player(20,-1,boss);check(game.party_hp[1]==hp,"翻滚有效无敌窗口")
	game.player.dodge_clock=0;boss.hurt(260,1);await settle(.1);check(boss.phase_two,"典刑机半血切换过载阶段")
	await clear_enemies();check(game.flags.get("boss",false),"击败典刑机解锁主线门")
	await enter(6);check(game.enemies.is_empty(),"唯一 Boss 重访不重生")
	await enter(7);use("manifest");check(game.flags.get("manifest",false),"出货门转运表唯一奖励")
	await enter(8);await clear_enemies();place(Vector3(-2,.02,0));await settle(.3);game.interact();await settle(2.4)
	check(game.player.position.y>5.7,"吊运台实际携带角色上行")
	game.overview=true;await settle(.5);await capture("04_lift")
	await enter(9);await clear_enemies();use("gear1");check(not game.gear[1],"锁销未拔错序不会启动惰轮")
	use("gear0");place(Vector3(-12,0,0));await settle(.2);await drive("up",1.9);await settle(.2);check(game.player.position.y>3.8,"四层井第一段梯子")
	use("gear1");place(Vector3(10,4,0));await settle(.15);await drive("up",1.9);await settle(.2);check(game.player.position.y>7.8,"四层井第二段梯子")
	use("gear2");check(game.flags.get("gear",false),"齿轮锁销惰轮离合三层联动")
	place(Vector3(-3,8,0));await settle(.2);await drive("up",1.9);await settle(.2);check(game.player.position.y>11.8,"四层井第三段梯子登顶")
	game.overview=true;await settle(.5);await capture("05_gears")
	await enter(10);use("wall");check(game.flags.get("wall",false),"壁抓能力解锁")
	place(Vector3(-5.5,.02,0));await settle(.2);Input.action_press("right");await drive("jump",.22);await settle(.08)
	check(game.player.is_on_wall() and game.player.wall_clock>0,"蓝纹墙真实碰撞抓壁")
	await drive("jump",.08);Input.action_release("right");check(game.player.wall_jumps>0 and game.player.velocity.x<0,"抓壁后 Space 蹬墙")
	await clear_enemies();place(Vector3(-12,0,0));await settle(.2);await drive("up",1.9);await settle(.2)
	check(game.player.position.y>3.8,"壁抓井左侧梯子进入壁抓路线")
	place(Vector3(-10.3,4,0));game.player.velocity.x=7.8;Input.action_press("right");Input.action_press("run");await drive("jump",.65);Input.action_release("right");Input.action_release("run");await settle(.08)
	check(game.player.position.x> -6.3 and game.player.position.y>4.9,"壁抓井第一跳抵达左壁顶支撑台")
	place(Vector3(-4.8,5,0));await settle(.2);game.player.velocity.x=7.8;Input.action_press("right");Input.action_press("run");await drive("jump",.57);Input.action_release("right");Input.action_release("run");await settle(.12)
	check(game.player.position.x> -1.7 and game.player.position.y>6.8,"壁抓井第二跳抵达高壁顶")
	place(Vector3(-.1,7,0));await settle(.2);game.player.velocity.x=7.8;Input.action_press("right");Input.action_press("run");await drive("jump",.6);Input.action_release("right");Input.action_release("run");await settle(.3)
	check(game.player.position.x>3 and game.player.position.y>6.8,"壁抓井越过高壁接入右侧出口层")
	await enter(17);place(Vector3(18,5,0));use("recruit");check(not game.flags.get("ranger",false),"伊瑟救援受矿牢守卫阻挡")
	await clear_enemies();use("recruit");var points: int=game.skill_points;use("recruit");check(game.flags.get("ranger",false) and game.skill_points==points,"伊瑟加入第三槽且奖励不重复")
	await enter(14);game.switch_cooldown=0;game.switch_actor(2);check(game.active_slot==2,"第三槽切换游侠")
	var foe: Node=game.enemies[0];place(foe.position+Vector3(-6,0,0));game.player.facing=1;foe.state="recover";foe.clock=-20;await settle(.2);before=foe.hp
	await drive("light",.04);await settle(.8);check(foe.hp<before,"伊瑟弓箭真实飞行命中敌人")
	await enter(15);boss=game.enemies[0];boss.hurt(310,1);await settle(.1);check(boss.phase_two,"牛头督工半血狂暴阶段");game.overview=true;await settle(.5);await capture("06_minotaur")
	game.overview=false;place(boss.position+Vector3(-4,0,0));await settle(.6);await capture("10_combat")
	await clear_enemies();check(game.flags.get("boss2",false),"牛头督工击败开启维修桥")
	await enter(16);use("completion");points=game.skill_points;use("completion");check(game.skill_points==points,"图纸交付奖励不重复")
	var layouts: Dictionary={};var supported:=true
	for r in game.rooms.slice(0,18):
		layouts[r.style+JSON.stringify(r.platforms)]=true
		var found:=false
		for floor_spec in r.platforms:
			if r.exit[0]>=floor_spec[0] and r.exit[0]<=floor_spec[1] and absf(r.exit[1]-floor_spec[2])<.01:found=true
		if not found:supported=false
	check(layouts.size()==18 and supported,"18 个房间布局身份独立且所有出口有实体楼层支撑")
	var route_ok:=true
	for i in range(18):
		await enter(i);await clear_enemies();place(game.vector(game.rooms[i].exit)+Vector3(-1,.02,0));await settle(.42);await drive("right",.3);await settle(.1)
		if game.room!=int(game.rooms[i].next):route_ok=false;print("ROUTE_FAIL ",i," -> ",game.room)
	check(route_ok,"18 个前门实际步行连接目标，第二章终点接入水务区")
	await enter(4);game.flags.grapple=false;place(Vector3(20,6,0));await settle(.2);game.update_nearest();game.interact();await settle(.1);check(game.room==4,"未取得钩索时能力门拒绝通行");game.flags.grapple=true
	await enter(12);place(Vector3(0,-4,0));await settle(.3);check(game.room==12 and game.player.position.x< -18,"坠落在当前房间重试，不退回首室")
	await enter(0);await clear_enemies();var money: int=game.scrap;await enter(0);check(game.enemies.size()==1,"普通守卫重访刷新");await clear_enemies();check(game.scrap==money,"刷新普通敌人不重复领取铁屑")
	game.save_game();game.save_game();var file:=FileAccess.open(game.save_path,FileAccess.WRITE);file.store_string("{interrupted");file.close();check(game.load_game() and game.flags.get("boss2",false),"损坏主存档恢复备份与关键 Boss 进度")
	game.set_screen("map");var stop: Vector3=game.player.position;await drive("right",.2);check(game.player.position==stop,"地图暂停运动");await capture("07_map")
	await enter(13);await clear_enemies();place(Vector3(-19,0,0));await settle(.2);await drive("right",4.3);await settle(.2);check(game.player.position.y>5.8,"轴承台整段楼梯抵达升降台层")
	await enter(16);place(Vector3(-13,0,0));await settle(.2);await drive("right",3.5);await settle(.2);check(game.player.position.y>3.8,"维修桥斜梯抵达图纸交付层")
	await enter(0);await clear_enemies();place(Vector3(-18,0,0));await settle(.2);use("save");await settle(.3);var saved_p: Vector3=game.player.position;game.load_game();check(game.player.position.distance_to(saved_p)<.01,"休息灯与继续游戏保持已保存的位置")
	game.set_screen("skills");await settle(.2);check(is_instance_valid(game.ui.preview) and game.ui.preview.get_child(0).world_3d!=game.get_world_3d(),"招式预览使用隔离的三维世界");await capture("08_skills")
	await enter(11);game.overview=false;await settle(.5);await capture("09_hub")
	checks.append_array(await preload("res://scripts/qa_audio.gd").new().run(game,directory))
	checks.append_array(await preload("res://scripts/qa_graphics.gd").new().run(game,directory))
	checks.append_array(await preload("res://scripts/qa_weapons.gd").new().run(game,directory))
	checks.append_array(await preload("res://scripts/qa_v06.gd").new().run(game,directory))
	checks.append_array(await preload("res://scripts/qa_actions.gd").new().run(game,directory.get_base_dir().path_join("action_screenshots") if not directory.is_empty() else ""))
	var failures:=0
	for item in checks:
		if not item.pass:failures+=1
	var executable: String=OS.get_executable_path()
	var pack: String=executable.get_basename()+".pck"
	var report: Dictionary={"version":game.Content.VERSION,"checks":checks,"failures":failures,"engine":Engine.get_version_info().string,"executable":executable,"executable_sha256":FileAccess.get_sha256(executable),"pack_sha256":FileAccess.get_sha256(pack) if FileAccess.file_exists(pack) else "","input":"Godot input actions and isolated physics acceptance; no physical controller or full human playthrough"}
	var report_path: String=directory.get_base_dir().path_join("runtime_tests.json") if not directory.is_empty() else "user://runtime_tests.json"
	var out:=FileAccess.open(report_path,FileAccess.WRITE);out.store_string(JSON.stringify(report,"  "));out.close()
	print("QA_FINISHED ",checks.size()," checks, ",failures," failures");return failures
