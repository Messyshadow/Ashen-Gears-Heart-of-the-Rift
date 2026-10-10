extends Node3D
const Content=preload("res://scripts/content_v06.gd")
const Player = preload("res://scripts/player_v04.gd")
const Enemy = preload("res://scripts/enemy_v04.gd")
var scene_cache: Dictionary={}
var template_cache: Dictionary={}
var party: Array=[0]
var controls: Node
var progression: RefCounted
var settings_return := "pause"
var map_region := 1
var doorway_cooldown := 0.0
var phase_cooldown := 0.0
var rooms: Array
var room := 0
var index := 4
var data: Dictionary
var world: Node3D
var player: CharacterBody3D
var camera: Camera3D
var rig: Node3D
var target := Vector3.ZERO
var pad := -1
var paused := true
var screen := "title"
var status := ""
var toast_clock := 0.0
var landing_count := 0
var camera_impact := 0.0
var hatch: Node3D
var hatch_target := 0.0
var hatch_collision: StaticBody3D
var dusts: Array[Dictionary] = []
var enemies: Array = []
var props: Array = []
var audio_system: Node
var ui: Control
var flags: Dictionary = {}
var visited: Dictionary = {}
var defeated: Dictionary = {}
var opened: Dictionary = {}
var party_hp: Array = [100.0,110.0,95.0,105.0,90.0,100.0,120.0]
var active_slot := 0
var magic := 100.0
var scrap := 0
var weapon_rank := 0
var weapons: Dictionary={"dagger":true}
var equipped_weapon := "dagger"
var skill_points := 3
var learned: Dictionary = {}
var skill_cooldown := 0.0
var switch_cooldown := 0.0
var potion := 3
var checkpoint_room := 0
var checkpoint_pos := Vector3(-10,7,0)
var nearest: Dictionary = {}
var story := ""
var story_origin := ""
var gear := [true,false,false]
var water := [false,false,0,false]
var save_path := "user://ashen_save_v04.json"
var qa_mode := false
var compatibility_smoke := false
var capture_dir := ""
var main_clock := 0.0
var environment: Environment
var sun: DirectionalLight3D
var graphics: Node
var atmosphere_materials: Dictionary={}
var batched_meshes: Dictionary={}
var hud_clock := 0.0
var particle_mesh: SphereMesh
var particle_materials: Dictionary={}
var projectile_mesh: BoxMesh
var projectile_materials: Dictionary={}
var actor_materials: Dictionary={}
var world_builder: RefCounted
var hitstop := 0.0
var overview := false
var transition_pending := false
var quitting := false

func _ready() -> void:
	rooms=JSON.parse_string(FileAccess.get_file_as_string("res://data/rooms.json"))
	for arg in OS.get_cmdline_user_args():
		if arg=="--qa":qa_mode=true;save_path="user://qa_save.json"
		if arg=="--compat-smoke":qa_mode=true;compatibility_smoke=true;save_path="user://qa_compat_save.json"
		if arg.begins_with("--capture-dir="):capture_dir=arg.trim_prefix("--capture-dir=")
	get_tree().auto_accept_quit=false;get_window().close_requested.connect(request_quit)
	setup_input();setup_environment()
	controls=preload("res://scripts/controls_settings.gd").new();controls.game=self;add_child(controls)
	progression=preload("res://scripts/progression_v06.gd").new();progression.game=self
	graphics=preload("res://scripts/graphics_settings.gd").new();graphics.game=self;add_child(graphics)
	var canvas := CanvasLayer.new();add_child(canvas)
	ui=preload("res://scripts/hud.gd").new();ui.game=self;canvas.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	refresh_pad();Input.joy_connection_changed.connect(func(_id,_on):refresh_pad())
	load_room(0)
	set_screen("title")
	if compatibility_smoke:call_deferred("run_compatibility_smoke")
	elif qa_mode:call_deferred("run_qa")

func setup_input() -> void:
	var actions := {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN],"jump":[KEY_SPACE],"light":[KEY_J],"heavy":[KEY_K],"dodge":[KEY_SHIFT],"guard":[KEY_L],"modifier":[KEY_CTRL],"grapple":[KEY_Q],"interact":[KEY_E],"switch":[KEY_F],"weapon":[KEY_V],"item":[KEY_R],"map":[KEY_M],"skills":[KEY_T],"pause":[KEY_ESCAPE],"run":[KEY_ALT],"overview":[KEY_TAB],"roster":[KEY_C],"journal":[KEY_N],"phase":[KEY_G]}
	for action in actions:
		if not InputMap.has_action(action):InputMap.add_action(action)
		for code in actions[action]:
			var key := InputEventKey.new();key.physical_keycode=code;InputMap.action_add_event(action,key)
	for pair in [["jump",JOY_BUTTON_A],["light",JOY_BUTTON_X],["heavy",JOY_BUTTON_Y],["dodge",JOY_BUTTON_B],["guard",JOY_BUTTON_LEFT_SHOULDER],["modifier",JOY_BUTTON_RIGHT_SHOULDER],["interact",JOY_BUTTON_DPAD_UP],["item",JOY_BUTTON_DPAD_DOWN],["map",JOY_BUTTON_BACK],["pause",JOY_BUTTON_START]]:
		var b := InputEventJoypadButton.new();b.button_index=pair[1];InputMap.action_add_event(pair[0],b)
	for pair in [["grapple",JOY_AXIS_TRIGGER_LEFT],["switch",JOY_AXIS_TRIGGER_RIGHT]]:
		var b := InputEventJoypadMotion.new();b.axis=pair[1];b.axis_value=1;InputMap.action_add_event(pair[0],b)
	var weapon_button:=InputEventJoypadButton.new();weapon_button.button_index=JOY_BUTTON_RIGHT_STICK;InputMap.action_add_event("weapon",weapon_button)
	for pair in [["light",MOUSE_BUTTON_LEFT],["heavy",MOUSE_BUTTON_RIGHT]]:
		var b := InputEventMouseButton.new();b.button_index=pair[1];InputMap.action_add_event(pair[0],b)

func refresh_pad() -> void:
	var pads := Input.get_connected_joypads();pad=pads[0] if not pads.is_empty() else -1

func setup_environment() -> void:
	var env := WorldEnvironment.new();var e := Environment.new();environment=e;env.environment=e;add_child(env)
	e.background_mode=Environment.BG_COLOR;e.background_color=Color(.017,.027,.036)
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color(.36,.46,.56);e.ambient_light_energy=.56
	var sky := Sky.new();var s := ProceduralSkyMaterial.new()
	s.sky_top_color=Color(.09,.13,.18);s.sky_horizon_color=Color(.20,.24,.28);s.ground_bottom_color=Color(.035,.041,.05);s.ground_horizon_color=Color(.12,.14,.17)
	sky.sky_material=s;e.sky=sky;e.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC;e.glow_enabled=true;e.glow_intensity=.6
	e.ssao_enabled=true;e.ssao_radius=.45;e.ssao_intensity=1
	e.fog_enabled=true;e.fog_light_color=Color(.07,.11,.15);e.fog_density=.003
	var moon := DirectionalLight3D.new();sun=moon;add_child(moon);moon.rotation_degrees=Vector3(-32,-20,0);moon.light_color=Color(.92,.81,.65);moon.light_energy=1.35;moon.shadow_enabled=true;moon.directional_shadow_max_distance=70
	var fill := DirectionalLight3D.new();add_child(fill);fill.rotation_degrees=Vector3(-20,145,0);fill.light_color=Color(.52,.68,.87);fill.light_energy=.65
	rig=Node3D.new();add_child(rig);camera=Camera3D.new();rig.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=12.5;camera.position=Vector3(0,2,30);camera.rotation_degrees.x=-3.8;camera.far=110;camera.current=true
	audio_system=preload("res://scripts/audio_manager.gd").new();audio_system.game=self;add_child(audio_system)

func vector(a: Array) -> Vector3:return Vector3(float(a[0]),float(a[1]),float(a[2]))

func load_room(number: int, spawn_override: Variant = null) -> void:
	if number<0 or number>=rooms.size():push_warning("Invalid room target: %d"%number);transition_pending=false;return
	room=number;index=int(rooms[room].template);doorway_cooldown=.4
	if is_instance_valid(world):remove_child(world);world.queue_free()
	if is_instance_valid(player):remove_child(player);player.queue_free()
	enemies.clear();props.clear();dusts.clear();hatch=null;hatch_collision=null;hatch_target=0
	world=Node3D.new();add_child(world)
	data=rooms[room]
	world_builder=preload("res://scripts/world_v04.gd").new()
	world_builder.build(self,rooms[room])
	transition_pending=false
	for anchor in rooms[room].get("anchors",[]):
		var n := marker("◇  钩索锚点",Color(.18,.68,1));world.add_child(n);n.position=vector(anchor)+Vector3(0,.55,0)
	for i in range(rooms[room].enemies.size()):
		var spec: Dictionary=rooms[room].enemies[i];var uid := "%s:%d"%[rooms[room].id,i]
		var definition: Dictionary=Content.ENEMIES.get(spec.kind,{})
		if definition.get("boss",false) and flags.get(definition.flag,false):continue
		var enemy := Enemy.new();enemy.game=self;enemy.kind=spec.kind;enemy.uid=uid;enemy.position=vector(spec.p);enemy.facing=spec.face;world.add_child(enemy);enemies.append(enemy)
	for spec in rooms[room].props:
		var uid: String = rooms[room].id+":"+spec.kind
		if opened.has(uid):continue
		add_prop(spec.kind,vector(spec.p),spec.text,uid)
	if rooms[room].has("checkpoint"):add_prop("save",vector(rooms[room].checkpoint),"休息灯 · 保存并恢复","")
	add_prop("exit",vector(rooms[room].exit),"本阶段终点 · 查看完成情况" if data.get("terminal",false) else "→ "+rooms[int(data.next)].id+" · "+rooms[int(data.next)].name,"")
	if room>0 and room!=11:add_prop("back",vector(rooms[room].back),"← "+rooms[int(data.previous)].id+" · "+rooms[int(data.previous)].name,"")
	apply_atmosphere()
	world_builder.batch_static_parts()
	graphics.apply_world_quality()
	player=Player.new();player.game=self;add_child(player);player.position=vector(rooms[room].spawn) if spawn_override==null else spawn_override
	audio_system.set_room(rooms[room].style)
	visited[rooms[room].id]=true
	checkpoint_room=room;checkpoint_pos=player.position
	target=player.position+Vector3(0,1.4,0);rig.position=target
	nearest={}
	if screen=="play" and rooms[room].has("story") and not flags.get("story_"+rooms[room].id,false):
		flags["story_"+rooms[room].id]=true;show_story(rooms[room].story,false)
	if screen!="title":save_game()
	ui.queue_redraw()

func add_prop(kind: String, pos: Vector3, text_value: String, uid: String) -> void:
	var label := marker(("→  " if kind=="exit" else "←  " if kind=="back" else "✦  ")+text_value,Color(.22,.68,1) if kind in ["save","grapple","wall"] else Color(.97,.64,.27))
	world.add_child(label);label.position=pos+Vector3(0,3.6 if kind in ["exit","back"] else 2.1,0);label.font_size=26;label.pixel_size=.01
	var model: String="Gate" if kind in ["exit","back","side","hub"] else "Coil" if kind in ["save","grapple","wall"] else "Crate"
	if int(data.get("region",1))>=3:
		model={"chest":"Chest","root_light":"Lantern","root_lock":"Terminal","root_reset":"Terminal","mirror_a":"ClockFace","mirror_b":"ClockFace","mirror_reset":"BloodVessel","scan":"LabTank","copy":"Terminal","plate_left":"CircuitPylon","plate_right":"CircuitPylon","power":"Terminal","split":"CircuitPylon","coolant":"WaterTank","door_link":"Terminal","insulate":"CircuitPylon","power_reset":"Terminal","phase_step":"HologramRing","airdash":"Coil"}.get(kind,model)
	var prop: MeshInstance3D=world_builder.part(model,pos+Vector3(0,0,-.65),Vector3.ONE if kind in ["exit","back","side","hub"] else Vector3(.6,.6,.6))
	prop.set_meta("static_part",false)
	if kind in ["exit","back"]:prop.rotation.y=PI/2
	if kind=="rescue":
		var friend: Node3D=instantiate_model("luomao_v04");world.add_child(friend);friend.position=pos+Vector3(0,0,-.7);friend.rotation.y=-PI/2
		friend.find_child("AnimationPlayer",true,false).play("PassageIdle")
		prop.set_meta("companion",friend)
	if kind.begins_with("recruit"):
		var slot: int=2 if kind=="recruit" else int(kind.trim_prefix("recruit"))
		var friend: Node3D=instantiate_model(Content.ROSTER[slot].model);world.add_child(friend);friend.position=pos+Vector3(0,0,-.9);friend.rotation.y=-PI/2
		friend.find_child("AnimationPlayer",true,false).play("PassageIdle")
		prop.set_meta("companion",friend)
	props.append({"kind":kind,"p":pos,"text":text_value,"uid":uid,"label":label,"mesh":prop})

func marker(text_value: String, color: Color) -> Label3D:
	var label := Label3D.new();label.text=text_value;label.font_size=38;label.pixel_size=.008;label.modulate=color;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=false;return label

func body(shape: Shape3D, pos: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new();world.add_child(b);b.position=pos;var cs := CollisionShape3D.new();cs.shape=shape;b.add_child(cs);return b

func apply_atmosphere() -> void:
	for mesh in world.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			if mesh.get_surface_override_material(i) is ShaderMaterial:continue
			var original: StandardMaterial3D=mesh.mesh.surface_get_material(i)
			if not original or original.emission_enabled:continue
			var key: int=original.get_instance_id()
			if atmosphere_materials.has(key):mesh.set_surface_override_material(i,atmosphere_materials[key]);continue
			var mat := ShaderMaterial.new();mat.shader=preload("res://scripts/ruin_depth.gdshader")
			atmosphere_materials[key]=mat
			for pair in [["base_color",original.albedo_color],["metalness",original.metallic],["base_texture",original.albedo_texture],["has_texture",original.albedo_texture!=null],["normal_texture",original.normal_texture],["has_normal",original.normal_enabled],["rough_texture",original.roughness_texture],["has_roughness",original.roughness_texture!=null],["base_roughness",original.roughness]]:mat.set_shader_parameter(pair[0],pair[1])
			mesh.set_surface_override_material(i,mat)

func open_hatch() -> void:
	hatch_target=deg_to_rad(-108)
	if hatch_collision:hatch_collision.set_deferred("collision_layer",0)

func _process(dt: float) -> void:
	main_clock+=dt
	toast_clock=maxf(0,toast_clock-dt)
	if not is_instance_valid(player):return
	if not paused:
		doorway_cooldown=maxf(0,doorway_cooldown-dt);phase_cooldown=maxf(0,phase_cooldown-dt)
		hitstop=maxf(0,hitstop-dt)
		world_builder.tick(dt)
		switch_cooldown=maxf(0,switch_cooldown-dt);skill_cooldown=maxf(0,skill_cooldown-dt);magic=minf(100,magic+dt*3)
		if hatch:hatch.rotation.x=lerpf(hatch.rotation.x,hatch_target,1-exp(-dt*5))
		update_nearest()
		check_auto_exit()
		if water[0] and not water[1]:water[2]=minf(2,water[2]+dt*.5)
		if water[1]:water[2]=maxf(0,water[2]-dt*.6)
		if water[3] and water[2]<=.03 and flags.get("water_stable",false) and not flags.get("steam",false):flags.steam=true;toast("压力联锁完成 · 出口已开启");save_game()
		if flags.get("circuit_pending",false) and flags.get("route_power",false):
			flags.circuit_time=float(flags.get("circuit_time",0))+dt
			if flags.circuit_time>=2:flags.circuit=true;flags.circuit_pending=false;sound("gear_start");toast("冷却联锁完成 · 实验室门锁开启");save_game()
		for i in range(dusts.size()-1,-1,-1):
			var d := dusts[i];d.life-=dt
			if d.life<=0:d.node.queue_free();dusts.remove_at(i);continue
			d.node.position+=d.velocity*dt;d.velocity.y-=dt*3;d.node.scale+=Vector3.ONE*dt*.3
		var desired: Vector3=player.position+Vector3(clampf(player.velocity.x*.25,-1.5,1.5),1.8,0)
		if player.velocity.y < -3:desired.y-=clampf(-player.velocity.y*.10,0,1.4)
		var half := camera.size*get_viewport().get_visible_rect().size.x/get_viewport().get_visible_rect().size.y*.5
		desired.x=clampf(desired.x,-22+half,22-half)
		desired.y=clampf(desired.y,3.0,float(rooms[room].bounds[3])-1)
		if overview:desired=Vector3(0,(float(rooms[room].bounds[3])-5)*.5+1,0)
		var view_aspect: float=get_viewport().get_visible_rect().size.x/get_viewport().get_visible_rect().size.y
		camera.size=lerpf(camera.size,maxf(46.0/view_aspect,float(rooms[room].bounds[3])+4) if overview else 12.5,1-exp(-dt*4))
		target=target.lerp(desired,1-exp(-dt*6));rig.position=target+Vector3(0,-camera_impact,0)
		camera_impact=move_toward(camera_impact,0,dt*.8)
	hud_clock+=dt
	if hud_clock>=1.0/30 or screen in ["graphics","graphics_confirm"]:
		hud_clock=0;ui.queue_redraw()

func update_nearest() -> void:
	nearest={};var distance := 1.65
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.can_assassinate():nearest={"kind":"assassinate","enemy":enemy,"text":controls.label("interact")+"  暗杀 · 未警觉的人类"};return
	for prop in props:
		if prop.get("used",false):continue
		var diff: Vector3=prop.p-player.position
		var d := absf(diff.x)
		if d<distance and absf(diff.y)<.65 and absf(diff.z)<2:
			distance=d;nearest=prop

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("overview") and screen=="play":overview=not overview
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F11:
		graphics.settings.mode=0 if graphics.settings.mode==1 else 1;graphics.apply_settings();graphics.save_settings()
	if screen=="graphics_confirm":
		if event.is_action_pressed("pause"):graphics.revert()
		return
	if screen in ["graphics","audio","controls"] and event.is_action_pressed("pause"):controls.capturing="";set_screen("settings");return
	if screen=="settings" and event.is_action_pressed("pause"):set_screen(settings_return);return
	if screen=="chapter_complete" and event.is_action_pressed("pause"):return
	if screen=="story":
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("pause"):set_screen(story_origin)
		return
	if event.is_action_pressed("pause"):
		set_screen("pause" if screen=="play" else "play" if screen in ["pause","map","skills","roster","journal","travel","rest"] else "title");return
	if screen in ["play","map","skills","roster","journal"]:
		if event.is_action_pressed("roster"):set_screen("play" if screen=="roster" else "roster");return
		if event.is_action_pressed("journal"):set_screen("play" if screen=="journal" else "journal");return
		if event.is_action_pressed("map"):set_screen("play" if screen=="map" else "map");return
		if event.is_action_pressed("skills"):set_screen("play" if screen=="skills" else "skills");return
	if paused:return
	if event.is_action_pressed("interact"):interact()
	if event.is_action_pressed("switch"):switch_actor()
	if event.is_action_pressed("phase"):phase_step()
	if event.is_action_pressed("weapon") and not event.is_echo():switch_weapon()
	if event.is_action_pressed("item"):
		if potion>0 and party_hp[active_slot]<max_hp():potion-=1;party_hp[active_slot]=minf(max_hp(),party_hp[active_slot]+45);toast("使用冷却药剂 · 恢复 45 生命")
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_1,KEY_2,KEY_3]:
		var slots: Array=field_slots()
		if event.keycode-KEY_1<slots.size():switch_actor(slots[event.keycode-KEY_1])

func set_screen(value: String) -> void:
	screen=value;paused=screen!="play"
	if value=="map":map_region=int(data.get("region",1))
	if audio_system:audio_system.update_targets()
	if is_instance_valid(player):player.set_animation_paused(paused)
	ui.rebuild_buttons()

func new_game() -> void:
	flags={};visited={};defeated={};opened={};party_hp=full_health();active_slot=0;magic=100;scrap=0;skill_points=3;learned={};potion=3;weapon_rank=0
	weapons={"dagger":true};equipped_weapon="dagger";party=[0]
	gear=[true,false,false];water=[false,false,0,false];checkpoint_room=0;checkpoint_pos=Vector3(-19,0,0)
	set_screen("play");load_room(0);save_game()

func max_hp() -> float:return Content.ROSTER[active_slot].hp

func interact() -> void:
	if world_builder.activate_deck():return
	if nearest.is_empty():return
	var kind: String=nearest.kind
	if progression.handle(kind):return
	if kind=="assassinate":
		nearest.enemy.hurt(999,player.facing);player.attack_clock=.8;player.attack_total=.8;player.attack_hit=true;player.attack_clip="Katana3" if active_slot==0 and equipped_weapon=="katana" else "Dagger3";player.invulnerable=.5;sound("hit_flesh_1");toast("暗杀成功 · 机械与 Boss 不能暗杀");return
	if kind in ["exit","back","loop","hub","shortcut","side","rust_loop","rust_shortcut"]:
		if kind=="exit":
			var gate: String=rooms[room].get("gate","")
			if not gate.is_empty() and not flags.get(gate,false):toast("尚未完成本室目标 · "+rooms[room].hint,3);return
			var next := int(rooms[room].next)
			if data.get("terminal",false):
				flags.stage_complete=true;checkpoint_room=room;checkpoint_pos=player.position;save_game();transition_pending=false;set_screen("chapter_complete");return
			sound("door");call_deferred("load_room",next,vector(data.next_spawn) if data.has("next_spawn") else null);return
		if kind=="back":
			var previous := int(rooms[room].previous)
			call_deferred("load_room",previous,vector(data.back_spawn) if data.has("back_spawn") else vector(rooms[previous].exit)+Vector3(-2,.1,0));return
		if kind=="loop":call_deferred("load_room",0);return
		if kind=="hub":call_deferred("load_room",11);return
		if kind=="shortcut":flags.shortcut=true;call_deferred("load_room",1);return
		if kind=="side":call_deferred("load_room",17);return
		if kind=="rust_loop":call_deferred("load_room",8);return
		if kind=="rust_shortcut":call_deferred("load_room",9);return
	if kind=="save":
		sound("save")
		checkpoint_room=room;checkpoint_pos=player.position
		party_hp=full_health();magic=100;player.stamina=100;potion=3;save_game();toast("休息灯已保存 · 全队恢复，普通敌人刷新");call_deferred("rest_at_lamp",player.position);return
	if kind=="wall":flags.wall=true;show_story("壁抓与壁跳已学会。\n跳向蓝色标记墙，按住朝墙方向抓壁；Space 蹬墙。\n抓壁最多 0.65 秒，空中切人不会刷新次数。");save_game();return
	if kind in ["mobility","training"]:
		learned["%d_2"%active_slot]=true;show_story("身法训练：Alt 冲跑，S 蹲行，Shift 翻滚。\n低障碍前 Space 翻越；空中 K 下砸。\nCtrl + Space 空中冲刺，每次腾空一次，消耗 16 魔力。");save_game();return
	if kind=="recruit":
		if flags.get("ranger",false):return
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.hp>0:toast("先击退矿牢守卫");return
		flags.ranger=true;skill_points+=3;opened[nearest.uid]=true;nearest.used=true;nearest.label.visible=false;nearest.mesh.visible=false;show_story("伊瑟：这份名册，我会带给还活着的人。\n伊瑟自愿加入。3 或 F 切换第三槽，弓箭可以远距支援。");save_game();return
	if kind=="completion":
		if opened.has(nearest.uid):return
		flags.slice_complete=true;skill_points+=1;opened[nearest.uid]=true;nearest.used=true;nearest.label.visible=false;nearest.mesh.visible=false;show_story("总井图纸交付。灰闸囚厂与锈脊齿轮井回环开放。\n接下来要修复雾肺水务区，寻找米菈的真实去向。\nR01 / R02 已完成。右侧继续进入雾肺水务区。
左侧可回访旧房间，休息灯保存恢复。");save_game();return
	if kind=="chest":scrap+=20;toast(nearest.text);sound("chest")
	if kind=="katana_chest":
		if opened.has(nearest.uid) or nearest.get("used",false):return
		if not can_switch_weapon():toast("收招后再打开宝箱");return
		weapons.katana=true;equip_weapon("katana");sound("chest");toast("获得灰钢太刀 · J 三连斩 / K 重劈 · V 切换匕首",5)
	if kind=="rescue":
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.hp>0:toast("先击退囚门守卫");return
		flags.rescued=true;skill_points+=2;show_story("洛铆：项圈熄了……这次由我自己决定。\n洛铆加入队伍。F 或 1 / 2 切换凯恩与洛铆。\n他用机械重击拆开装甲，你负责找到妹妹。",false)
	if kind=="grapple":flags.grapple=true;show_story("锚点钩索已修复。\n按住 Q 预选蓝色锚点，松开发射，空格可以释放。\n钩索只连接标记锚点。",false)
	if kind=="manifest":flags.manifest=true;show_story("转运表：米菈 · 自愿稳定员。\n凯恩：这个签名不是她写的。\n洛铆：总井图纸在锈井。先把表留好。",false)
	if kind=="hub_story":show_story("阿芙：我会接住这批幸存者。\n洛铆：换人别换掉脚下的路。你在空中，我接手也在空中。\n阿芙：去工坊整备，再沿锈井找总图。",false);return
	if kind=="upgrade":
		if weapon_rank>=3:toast("当前武器已达样片上限");return
		if scrap<40:toast("需要 40 铁屑");return
		scrap-=40;weapon_rank+=1;save_game();toast("武器强化 · 伤害 +15%");return
	if kind.begins_with("gear"):
		if flags.get("gear",false):toast("齿轮联动已完成");return
		if kind=="gear_reset":gear=[true,false,false];toast("齿轮已复位 · 先拔锁销");return
		sound("gear_latch");var n := int(kind.trim_prefix("gear"))
		if n==0:
			if gear[2]:toast("先断开离合器");return
			gear[0]=not gear[0];toast("锁销已固定" if gear[0] else "锁销已拔出")
		if n==1:
			if gear[0] or gear[2]:toast("先拔锁销，并断开离合器");return
			gear[1]=not gear[1];toast("惰轮已接入 A 与 C" if gear[1] else "惰轮已移开")
		if n==2:
			gear[2]=not gear[2]
			if gear[1] and not gear[0] and gear[2]:flags.gear=true;sound("gear_start");skill_points+=1;save_game();toast("P01 完成 · 输出顺时针，升降带接通")
			else:toast("输出停摆 · 检查锁销与惰轮")
		return
	if kind in ["water","steam","confirm","steam_reset"]:
		if kind=="steam_reset":water=[false,false,0,false];flags.water_stable=false;toast("压力已复位");return
		if kind=="water":
			water[0]=not water[0]
			if not water[0] and water[2]>.7 and water[2]<1.6:flags.water_stable=true
			toast("加水阀开启" if water[0] else "加水阀关闭")
		if kind=="steam":water[1]=not water[1];toast("排水阀开启" if water[1] else "排水阀关闭")
		if kind=="confirm":
			if water[0] or not flags.get("water_stable",false):toast("先关闭排水，加水至中水位，再关加水阀");return
			water[3]=true;toast("蒸汽旁路已开启 · 打开排水阀露出出口")
		return
	if kind in ["chest","katana_chest","rescue","grapple","manifest"]:
		opened[nearest.uid]=true;nearest.used=true;nearest.label.visible=false;nearest.mesh.visible=false;save_game()

func available_slots() -> Array:
	var slots: Array=[0]
	for slot in range(1,Content.ROSTER.size()):
		if flags.get(Content.ROSTER[slot].flag,false):slots.append(slot)
	return slots
func field_slots() -> Array:
	var unlocked: Array=available_slots();var result: Array=[]
	for slot in party:
		var normalized: int=int(slot)
		if normalized in unlocked and not normalized in result and result.size()<3:result.append(normalized)
	for slot in unlocked:
		if result.size()<3 and not slot in result:result.append(slot)
	party=result;return party
func actor_model(slot: int) -> String:
	return "kain_katana_v04" if slot==0 and equipped_weapon=="katana" else Content.ROSTER[slot].model
func actor_label(slot: int) -> String:
	return "凯恩 · "+weapon_name() if slot==0 else Content.ROSTER[slot].name+" · "+Content.ROSTER[slot].role
func full_health() -> Array:
	var values: Array=[]
	for actor in Content.ROSTER:values.append(float(actor.hp))
	return values
func instantiate_model(model: String) -> Node3D:
	if not scene_cache.has(model):scene_cache[model]=load("res://assets/models/"+model+".glb")
	var node: Node3D=scene_cache[model].instantiate()
	var palettes: Dictionary={"shenjin_v06":Vector3(.85,.80,.65),"shayin_v06":Vector3(.34,.12,.62),"weiluo_v06":Vector3(.8,.10,.17),"zero7_v06":Vector3(.10,.65,.85)}
	if palettes.has(model):
		for mesh in node.find_children("*","MeshInstance3D",true,false):
			for surface in mesh.mesh.get_surface_count():
				var original: StandardMaterial3D=mesh.mesh.surface_get_material(surface)
				if not original or not "cloth" in original.resource_name.to_lower():continue
				var key: String=model+":"+str(original.get_instance_id())
				if not actor_materials.has(key):
					var material:=ShaderMaterial.new();material.shader=preload("res://scripts/ruin_depth.gdshader")
					for pair in [["base_color",original.albedo_color],["metalness",original.metallic],["base_texture",original.albedo_texture],["has_texture",original.albedo_texture!=null],["normal_texture",original.normal_texture],["has_normal",original.normal_enabled],["rough_texture",original.roughness_texture],["has_roughness",original.roughness_texture!=null],["base_roughness",original.roughness],["remap_color",true],["remap_tint",palettes[model]]]:material.set_shader_parameter(pair[0],pair[1])
					actor_materials[key]=material
				mesh.set_surface_override_material(surface,actor_materials[key])
	return node
func kit_parts(model: String) -> Dictionary:
	if not template_cache.has(model):
		var node: Node3D=instantiate_model(model);add_child(node);node.visible=false;var parts: Dictionary={}
		for mesh in node.find_children("*","MeshInstance3D",true,false):parts[mesh.name]=mesh
		template_cache[model]={"node":node,"parts":parts}
	return template_cache[model].parts
func alive_count() -> int:
	var count:=0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.hp>0:count+=1
	return count
func consume_prop() -> void:
	if nearest.uid.is_empty():return
	opened[nearest.uid]=true;nearest.used=true;nearest.label.visible=false;nearest.mesh.visible=false
	var companion: Variant=nearest.mesh.get_meta("companion") if nearest.mesh.has_meta("companion") else null
	if is_instance_valid(companion):companion.queue_free()
func can_organize() -> bool:
	if room!=11:
		if not data.has("checkpoint") or player.position.distance_to(vector(data.checkpoint))>3:return false
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.hp>0 and enemy.state!="patrol" and enemy.position.distance_to(player.position)<12:return false
	return true
func assign_party(slot: int, position_index: int) -> void:
	if not can_organize() or not can_switch_weapon():toast("收招后，在休息灯附近且脱离战斗时调整编队");return
	if not slot in available_slots() or position_index<0 or position_index>2:return
	if party_hp[slot]<=0:toast("先在休息灯恢复这位同伴");return
	field_slots()
	var old: int=party.find(slot)
	if position_index>=party.size():party.append(slot)
	elif old>=0:var swap: int=party[position_index];party[position_index]=slot;party[old]=swap
	else:party[position_index]=slot
	if not active_slot in party:active_slot=party[0];player.set_actor(active_slot)
	save_game();ui.rebuild_buttons()
func fast_travel(target_room: int) -> void:
	if not can_organize():toast("在安全休息灯附近使用已发现通道");return
	if target_room not in Content.STARTS or not visited.has(rooms[target_room].id):return
	set_screen("play");load_room(target_room,vector(rooms[target_room].get("checkpoint",rooms[target_room].spawn)))
func phase_step() -> void:
	if not flags.get("phase_step",false):toast("在薄壁裂隙厅学习相移");return
	if phase_cooldown>0 or magic<16 or not can_switch_weapon():return
	for wall in data.get("phase_walls",[]):
		if absf(player.position.x-wall.x)>2.8 or (wall.x-player.position.x)*player.facing<=0:continue
		var destination:=Vector3(wall.x+player.facing*1.1,player.position.y+.05,0)
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=player.capsule;query.margin=.001;query.transform=Transform3D(Basis.IDENTITY,destination+Vector3(0,.86,0));query.collision_mask=1
		var floor_ray:=PhysicsRayQueryParameters3D.create(destination+Vector3(0,.2,0),destination+Vector3(0,-1,0),1)
		if not get_world_3d().direct_space_state.intersect_shape(query).is_empty() or get_world_3d().direct_space_state.intersect_ray(floor_ray).is_empty():toast("相移落点不安全");return
		magic-=16;phase_cooldown=2;spawn_sparks(player.position+Vector3(0,1,0),true);player.position=destination;player.invulnerable=.25;sound("dash",destination);return

func weapon_name() -> String:return "灰钢太刀" if equipped_weapon=="katana" else "裂影匕首"

func can_switch_weapon() -> bool:
	return player.attack_clock<=0 and player.hurt_clock<=0 and player.dodge_clock<=0 and player.dash_clock<=0 and player.motion!="vault" and not player.slamming

func equip_weapon(value: String) -> void:
	equipped_weapon=value;player.combo=0;player.combo_clock=0;player.queued_attack=false
	if active_slot==0:player.set_actor(0)

func switch_weapon() -> void:
	if active_slot!=0:toast("匕首与太刀由凯恩使用");return
	if not weapons.get("katana",false):toast("煤仓入口补给宝箱藏有灰钢太刀");return
	if not can_switch_weapon():return
	equip_weapon("dagger" if equipped_weapon=="katana" else "katana");sound("switch");save_game();toast("凯恩 · "+weapon_name())

func switch_actor(slot: int = -1) -> void:
	var slots: Array=field_slots()
	if slots.size()==1:toast("救援后可以切换同伴");return
	if switch_cooldown>0 or player.hurt_clock>0 or player.attack_clock>0 or player.motion=="vault":return
	var next: int=slots[(slots.find(active_slot)+1)%slots.size()] if slot<0 else slot
	if not next in slots or party_hp[next]<=0 or next==active_slot:return
	sound("switch");active_slot=next;switch_cooldown=1;player.set_actor(next);toast(actor_label(next))

func menu_actor(slot: int) -> void:
	if slot in field_slots() and party_hp[slot]>0 and can_switch_weapon():active_slot=slot;player.set_actor(slot);ui.rebuild_buttons()
	else:toast("角色收招且存活时才能切换；休息灯可恢复全队")

func actor_down() -> void:
	player.attack_clock=0;player.queued_attack=false;player.slamming=false;player.grappling=false;player.shield_clock=0
	for slot in field_slots():
		if party_hp[slot]>0:active_slot=slot;player.set_actor(slot);toast("接替倒地同伴");return
	party_hp=full_health();magic=100;potion=3
	show_story("回声暂歇。你将在当前房间安全入口醒来。");call_deferred("load_room",room)

func reset_player() -> void:
	party_hp[active_slot]=maxf(1,party_hp[active_slot]-10)
	call_deferred("load_room",room);toast("坠落受伤 · 在本室入口重试，不退回煤仓")

func environment_damage(amount: float) -> void:
	if player.invulnerable>0:return
	if player.shield_clock>0:amount*=.5
	party_hp[active_slot]=maxf(0,party_hp[active_slot]-amount);player.invulnerable=.8;player.hurt_clock=.25
	if party_hp[active_slot]<=0:actor_down()

func damage_player(amount: float, facing: float, source: Node) -> void:player.receive_damage(amount,facing,source)

func selected_anchor() -> Variant:
	var best: Variant=null;var distance := 12.0
	for a in rooms[room].get("anchors",[]):
		var p := vector(a);var d := player.position.distance_to(p)
		if d<distance and (p.x-player.position.x)*player.facing>1.0:
			var query := PhysicsRayQueryParameters3D.create(player.position+Vector3(0,1,0),p+Vector3(0,.25,0),1)
			if get_world_3d().direct_space_state.intersect_ray(query).is_empty():best=p;distance=d
	return best

func learn_skill(slot: int) -> void:
	var id := "%d_%d"%[active_slot,slot]
	if learned.has(id):toast("招式已学会");return
	if skill_points<=0:toast("技能点不足");return
	learned[id]=true;skill_points-=1;save_game();ui.rebuild_buttons();toast("招式已学会 · Ctrl + J / K")

func toast(value: String, duration: float = 2.5) -> void:status=value;toast_clock=duration
func show_story(value: String, _unused: bool = false) -> void:
	story_origin=screen if screen in ["map","journal"] else "play";story=value;set_screen("story")

func save_game() -> bool:
	var payload := {"schema":1,"party":party,"version":Content.VERSION,"room":checkpoint_room,"p":[checkpoint_pos.x,checkpoint_pos.y,checkpoint_pos.z],"flags":flags,"visited":visited,"defeated":defeated,"opened":opened,"party_hp":party_hp,"active":active_slot,"magic":magic,"scrap":scrap,"weapon_rank":weapon_rank,"weapons":weapons,"equipped_weapon":equipped_weapon,"skill_points":skill_points,"learned":learned,"potion":potion,"gear":gear,"water":water}
	var temp := save_path+".tmp";var file := FileAccess.open(temp,FileAccess.WRITE)
	if not file:toast("保存失败 · 目录不可写");return false
	file.store_string(JSON.stringify(payload));file.close()
	if JSON.parse_string(FileAccess.get_file_as_string(temp))==null:return false
	if FileAccess.file_exists(save_path):DirAccess.copy_absolute(save_path,save_path+".backup")
	var result := DirAccess.rename_absolute(temp,save_path)
	if result!=OK:toast("保存失败 · "+error_string(result));return false
	return true

func load_game() -> bool:
	var saved: Variant=null
	for path in [save_path,save_path+".backup"]:
		if FileAccess.file_exists(path):
			var parser := JSON.new()
			if parser.parse(FileAccess.get_file_as_string(path))!=OK:continue
			var candidate: Variant=parser.data
			if candidate is Dictionary and candidate.get("schema",0)==1 and candidate.get("room",-1)>=0 and candidate.get("room",999)<rooms.size() and candidate.get("p",[]).size()==3:
				saved=candidate;break
	if saved==null:toast("没有可用存档");return false
	flags=saved.flags;visited=saved.visited;defeated=saved.defeated;opened=saved.opened;party_hp=saved.party_hp;active_slot=int(saved.active);magic=float(saved.magic);scrap=int(saved.scrap);weapon_rank=int(saved.weapon_rank);skill_points=int(saved.skill_points);learned=saved.learned;potion=int(saved.potion);gear=saved.gear;water=saved.water
	while party_hp.size()<Content.ROSTER.size():party_hp.append(Content.ROSTER[party_hp.size()].hp)
	party=saved.get("party",[0,1,2]);field_slots()
	if not active_slot in party:active_slot=party[0]
	weapons=saved.get("weapons",{"dagger":true});weapons.dagger=true
	equipped_weapon="katana" if saved.get("equipped_weapon","dagger")=="katana" and weapons.get("katana",false) else "dagger"
	checkpoint_room=int(saved.room);checkpoint_pos=vector(saved.p);set_screen("play");load_room(checkpoint_room,checkpoint_pos);return true

func sound(kind: String,pos: Vector3=Vector3.INF) -> void:
	var aliases: Dictionary={"step":"foot_metal_1","hammer":"boss_smash","metal":"hit_metal_1","hit":"player_hurt","swing":"whoosh_light_1","arc":"skill"}
	audio_system.play_event(aliases.get(kind,kind),pos)

func footstep() -> void:
	var material: String="stone" if player.position.y<.3 and rooms[room].style in ["coal","prison","hub","mine","stock"] else "metal"
	sound("foot_%s_%d"%[material,randi_range(1,3)],player.position)

func preview_audio() -> void:
	for cue in ["whoosh_light_1","hit_metal_1","dash","jump","land_heavy","gear_start"]:
		if screen!="audio":return
		sound(cue)
		await get_tree().create_timer(.5).timeout

func spawn_dust(pos: Vector3, force: float) -> void:particles(pos,force,Color(.43,.37,.29,.24))
func spawn_sparks(pos: Vector3, metal: bool) -> void:particles(pos,2,Color(1,.43,.05) if metal else Color(.8,.14,.07))
func particles(pos: Vector3, force: float, col: Color) -> void:
	if particle_mesh==null:
		particle_mesh=SphereMesh.new();particle_mesh.radius=.045;particle_mesh.height=.09;particle_mesh.radial_segments=6;particle_mesh.rings=3
	var key:=col.to_html()
	if not particle_materials.has(key):
		var material:=StandardMaterial3D.new();material.albedo_color=col;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;particle_materials[key]=material
	var count: int=7
	for i in range(count):
		var n:=MeshInstance3D.new();n.mesh=particle_mesh;n.material_override=particle_materials[key];n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(n);n.position=pos;dusts.append({"node":n,"life":.45,"velocity":Vector3(randf_range(-1.5,1.5)*force,randf_range(.5,2),0)})

func run_qa() -> void:
	var suite: RefCounted=preload("res://scripts/qa_v04.gd").new()
	var failures: int=await suite.run(self,capture_dir)
	suite=null
	audio_system.halt()
	await get_tree().create_timer(.15).timeout
	get_tree().quit(1 if failures>0 else 0)

func check_auto_exit() -> void:
	if transition_pending or paused or doorway_cooldown>0:return
	for prop in props:
		if prop.kind=="back" and player.position.distance_to(prop.p)<.8 and player.move_axis()<-.2:
			nearest=prop;transition_pending=true;interact();return
		if prop.kind=="exit" and player.position.distance_to(prop.p)<.8 and player.move_axis()>.2:
			var gate: String=rooms[room].get("gate","")
			if gate.is_empty() or flags.get(gate,false):nearest=prop;transition_pending=true;interact()

func melee_hit(amount: float,reach: float,direction: float,area: bool) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy):continue
		var d: Vector3=enemy.position-player.position
		if absf(d.x)>reach or absf(d.y)>1.7 or absf(d.z)>1.5 or (not area and direction*d.x<-.3):continue
		var query:=PhysicsRayQueryParameters3D.create(player.position+Vector3(0,1,0),enemy.position+Vector3(0,1,0),1)
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty():enemy.hurt(amount,direction,30 if amount>=35 else 12);hitstop=.045

func fire_projectile(pos: Vector3,direction: float,amount: float,friendly: bool,source: Node) -> void:
	var shot:=preload("res://scripts/projectile.gd").new();shot.game=self;shot.position=pos;shot.direction=direction;shot.damage=amount;shot.friendly=friendly;shot.source=source
	shot.travel=Vector3(direction,0,0)
	if not friendly and is_instance_valid(source) and source.ranged():shot.travel=(player.position+Vector3(0,.9,0)-pos).normalized()
	if friendly:
		var best:=12.0
		for enemy in enemies:
			if not is_instance_valid(enemy):continue
			var diff: Vector3=enemy.position+Vector3(0,.9,0)-pos
			if diff.x*direction>0 and absf(diff.y)<3 and diff.length()<best:best=diff.length();shot.travel=diff.normalized()
	world.add_child(shot)

func open_graphics() -> void:
	graphics.return_screen="settings";set_screen("graphics")
func chapter_return(target_room: int) -> void:
	set_screen("play");load_room(target_room)

func request_quit() -> void:
	if quitting:return
	quitting=true;paused=true;audio_system.halt()
	await get_tree().create_timer(.15).timeout
	get_tree().quit()

func open_settings() -> void:
	settings_return="title" if screen=="title" else "pause";set_screen("settings")

func fire_spell(pos: Vector3,direction: float,power: float,kind: String) -> void:
	var shot:=preload("res://scripts/spell_v06.gd").new();shot.game=self;shot.position=pos;shot.direction=direction;shot.damage=power;shot.kind=kind;shot.owner_slot=active_slot;world.add_child(shot)
func snare_nearby(reach: float) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.position.distance_to(player.position)<reach:
			var ray:=PhysicsRayQueryParameters3D.create(player.position+Vector3(0,1,0),enemy.position+Vector3(0,1,0),1)
			if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():enemy.state="stunned";enemy.clock=-.45;spawn_sparks(enemy.position+Vector3(0,1,0),false)

func rest_at_lamp(pos: Vector3) -> void:
	load_room(room,pos)
	if not qa_mode:set_screen("rest")
func projectile_visual(friendly: bool) -> MeshInstance3D:
	if not projectile_mesh:projectile_mesh=BoxMesh.new();projectile_mesh.size=Vector3(.5,.055,.055)
	if not projectile_materials.has(friendly):
		var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color(.2,.75,1) if friendly else Color(1,.4,.04);mat.emission_enabled=true;mat.emission=mat.albedo_color*2;projectile_materials[friendly]=mat
	var n:=MeshInstance3D.new();n.mesh=projectile_mesh;n.material_override=projectile_materials[friendly];return n

func run_compatibility_smoke() -> void:
	var records: Array=[]
	graphics.set_quality("low",false);Engine.max_fps=60
	for number in [0,9,19,27,35,43,48]:
		active_slot=0 if number<18 else 3+(number%4);load_room(number);set_screen("play")
		for frame in range(45):await get_tree().process_frame
		particles(player.position+Vector3(0,1,0),1,Color(.3,.6,1));sound("dash",player.position)
		records.append({"room":number,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"slot":active_slot,"effects":dusts.size()})
	var executable:=OS.get_executable_path();var pack:=executable.get_basename()+".pck"
	var report: Dictionary={"version":Content.VERSION,"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"rooms":records,"executable_sha256":FileAccess.get_sha256(executable),"pack_sha256":FileAccess.get_sha256(pack)}
	var file:=FileAccess.open(capture_dir if not capture_dir.is_empty() else "user://compatibility_v06.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	audio_system.halt();await get_tree().create_timer(.15).timeout;get_tree().quit()
