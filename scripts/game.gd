extends Node3D
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
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
var audio: AudioStreamPlayer
var music: AudioStreamPlayer
var ui: Control
var flags: Dictionary = {}
var visited: Dictionary = {}
var defeated: Dictionary = {}
var opened: Dictionary = {}
var party_hp: Array = [100.0,110.0]
var active_slot := 0
var magic := 100.0
var scrap := 0
var weapon_rank := 0
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
var save_path := "user://ashen_save.json"
var qa_mode := false
var capture_dir := ""
var main_clock := 0.0

func _ready() -> void:
	rooms=JSON.parse_string(FileAccess.get_file_as_string("res://data/rooms.json"))
	for arg in OS.get_cmdline_user_args():
		if arg=="--qa":qa_mode=true;save_path="user://qa_save.json"
		if arg.begins_with("--capture-dir="):capture_dir=arg.trim_prefix("--capture-dir=")
	setup_input();setup_environment()
	var canvas := CanvasLayer.new();add_child(canvas)
	ui=preload("res://scripts/hud.gd").new();ui.game=self;canvas.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	refresh_pad();Input.joy_connection_changed.connect(func(_id,_on):refresh_pad())
	load_room(0)
	set_screen("title")
	if qa_mode:call_deferred("run_qa")

func setup_input() -> void:
	var actions := {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN],"jump":[KEY_SPACE],"light":[KEY_J],"heavy":[KEY_K],"dodge":[KEY_SHIFT],"guard":[KEY_L],"modifier":[KEY_CTRL],"grapple":[KEY_Q],"interact":[KEY_E],"switch":[KEY_F],"item":[KEY_R],"map":[KEY_M],"skills":[KEY_T],"pause":[KEY_ESCAPE]}
	for action in actions:
		InputMap.add_action(action)
		for code in actions[action]:
			var key := InputEventKey.new();key.physical_keycode=code;InputMap.action_add_event(action,key)
	for pair in [["jump",JOY_BUTTON_A],["light",JOY_BUTTON_X],["heavy",JOY_BUTTON_Y],["dodge",JOY_BUTTON_B],["guard",JOY_BUTTON_LEFT_SHOULDER],["modifier",JOY_BUTTON_RIGHT_SHOULDER],["interact",JOY_BUTTON_DPAD_UP],["item",JOY_BUTTON_DPAD_DOWN],["map",JOY_BUTTON_BACK],["pause",JOY_BUTTON_START]]:
		var b := InputEventJoypadButton.new();b.button_index=pair[1];InputMap.action_add_event(pair[0],b)
	for pair in [["grapple",JOY_AXIS_TRIGGER_LEFT],["switch",JOY_AXIS_TRIGGER_RIGHT]]:
		var b := InputEventJoypadMotion.new();b.axis=pair[1];b.axis_value=1;InputMap.action_add_event(pair[0],b)
	for pair in [["light",MOUSE_BUTTON_LEFT],["heavy",MOUSE_BUTTON_RIGHT]]:
		var b := InputEventMouseButton.new();b.button_index=pair[1];InputMap.action_add_event(pair[0],b)

func refresh_pad() -> void:
	var pads := Input.get_connected_joypads();pad=pads[0] if not pads.is_empty() else -1

func setup_environment() -> void:
	var env := WorldEnvironment.new();var e := Environment.new();env.environment=e;add_child(env)
	e.background_mode=Environment.BG_COLOR;e.background_color=Color(.017,.027,.036)
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color(.36,.46,.56);e.ambient_light_energy=.56
	var sky := Sky.new();var s := ProceduralSkyMaterial.new()
	s.sky_top_color=Color(.09,.13,.18);s.sky_horizon_color=Color(.20,.24,.28);s.ground_bottom_color=Color(.035,.041,.05);s.ground_horizon_color=Color(.12,.14,.17)
	sky.sky_material=s;e.sky=sky;e.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC;e.glow_enabled=true;e.glow_intensity=.6
	e.ssao_enabled=true;e.ssao_radius=.45;e.ssao_intensity=1
	e.fog_enabled=true;e.fog_light_color=Color(.07,.11,.15);e.fog_density=.003
	var moon := DirectionalLight3D.new();add_child(moon);moon.rotation_degrees=Vector3(-32,-20,0);moon.light_color=Color(.92,.81,.65);moon.light_energy=1.35;moon.shadow_enabled=true;moon.directional_shadow_max_distance=70
	var fill := DirectionalLight3D.new();add_child(fill);fill.rotation_degrees=Vector3(-20,145,0);fill.light_color=Color(.52,.68,.87);fill.light_energy=.65
	rig=Node3D.new();add_child(rig);camera=Camera3D.new();rig.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=12.5;camera.position=Vector3(0,2,30);camera.rotation_degrees.x=-3.8;camera.far=110;camera.current=true
	audio=AudioStreamPlayer.new();add_child(audio);audio.volume_db=-16
	music=AudioStreamPlayer.new();add_child(music);music.volume_db=-25
	var wav := AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=22050
	var bytes := PackedByteArray();bytes.resize(22050*8*2)
	for i in range(22050*8):
		var t := float(i)/22050
		var tone := sin(TAU*55*t)*.18+sin(TAU*82.5*t)*.10+sin(TAU*110*t)*.07
		tone*=.65+.25*sin(TAU*t/8)
		bytes.encode_s16(i*2,int(tone*13000))
	wav.data=bytes;wav.loop_mode=AudioStreamWAV.LOOP_FORWARD;wav.loop_end=22050*8
	music.stream=wav;music.play()

func vector(a: Array) -> Vector3:return Vector3(float(a[0]),float(a[1]),float(a[2]))

func load_room(number: int, spawn_override: Variant = null) -> void:
	room=clampi(number,0,rooms.size()-1);index=int(rooms[room].template)
	if is_instance_valid(world):remove_child(world);world.queue_free()
	if is_instance_valid(player):remove_child(player);player.queue_free()
	enemies.clear();props.clear();dusts.clear();hatch=null;hatch_collision=null;hatch_target=0
	world=Node3D.new();add_child(world)
	data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/passage_%02d.json"%index))
	world.add_child(load("res://assets/models/passage_%02d.glb"%index).instantiate())
	apply_atmosphere()
	for box in data.boxes:
		var shape := BoxShape3D.new();shape.size=vector(box.size);body(shape,vector(box.p))
	for ramp in data.slopes:
		var pts := PackedVector3Array()
		for end in [ramp.a,ramp.b]:
			for z in [-float(ramp.width)*.5,float(ramp.width)*.5]:
				for depth in [0,-float(ramp.thick)]:pts.append(Vector3(float(end[0]),float(end[1])+depth,float(ramp.z)+z))
		var shape := ConvexPolygonShape3D.new();shape.points=pts;body(shape,Vector3.ZERO)
	for spec in data.lights:
		var light := OmniLight3D.new();world.add_child(light);light.position=vector(spec.p)
		light.light_color=Color(spec.color[0],spec.color[1],spec.color[2]);light.light_energy=spec.energy;light.omni_range=spec.range;light.shadow_enabled=true;light.shadow_bias=.06
	if data.has("hatch"):
		hatch=Node3D.new();world.add_child(hatch);hatch.position=Vector3(0,7,-.8);hatch.add_child(load("res://assets/models/hatch_lid.glb").instantiate())
		var cover := CylinderShape3D.new();cover.radius=.76;cover.height=.08;hatch_collision=body(cover,Vector3(0,6.96,0))
	if rooms[room].get("ledge",false):
		var shape := BoxShape3D.new();shape.size=Vector3(9,.5,3);body(shape,Vector3(12,9.75,0))
		var slab := MeshInstance3D.new();var mesh := BoxMesh.new();mesh.size=shape.size;slab.mesh=mesh;slab.position=Vector3(12,9.75,0)
		var mat := StandardMaterial3D.new();mat.albedo_color=Color(.20,.24,.28);mat.metallic=.7;slab.material_override=mat;world.add_child(slab)
	if room in [2,5,6,9]:
		var furnace: Node3D = load("res://assets/models/furnace_assembly.glb").instantiate();world.add_child(furnace);furnace.position=Vector3(3,0,-4)
		var fire := OmniLight3D.new();world.add_child(fire);fire.position=Vector3(3,4,-6);fire.light_color=Color(1,.22,.04);fire.light_energy=4;fire.omni_range=17
	var lava := MeshInstance3D.new();var plane := PlaneMesh.new();plane.size=Vector2(36,10);lava.mesh=plane;lava.position=Vector3(0,-1.5,-2)
	var lm := ShaderMaterial.new();lm.shader=preload("res://scripts/lava.gdshader");lava.material_override=lm;world.add_child(lava)
	for anchor in rooms[room].get("anchors",[]):
		var n := marker("◇  钩索锚点",Color(.18,.68,1));world.add_child(n);n.position=vector(anchor)+Vector3(0,.55,0)
	for i in range(rooms[room].enemies.size()):
		var spec: Dictionary=rooms[room].enemies[i];var uid := "%s:%d"%[rooms[room].id,i]
		if defeated.has(uid):continue
		var enemy := Enemy.new();enemy.game=self;enemy.kind=spec.kind;enemy.uid=uid;enemy.position=vector(spec.p);enemy.facing=spec.face;world.add_child(enemy);enemies.append(enemy)
	for spec in rooms[room].props:
		var uid: String = rooms[room].id+":"+spec.kind
		if opened.has(uid) and spec.kind in ["chest","rescue","grapple","manifest"]:continue
		add_prop(spec.kind,vector(spec.p),spec.text,uid)
	if rooms[room].has("checkpoint"):add_prop("save",vector(rooms[room].checkpoint),"休息灯 · 保存并恢复","")
	add_prop("exit",vector(rooms[room].exit),"通道 → "+rooms[int(rooms[room].next)].name,"")
	if room>0 and room!=11:add_prop("back",vector(rooms[room].back),"← 返回前室","")
	player=Player.new();player.game=self;add_child(player);player.position=vector(rooms[room].spawn) if spawn_override==null else spawn_override
	player.last_floor=true;visited[rooms[room].id]=true
	target=player.position+Vector3(0,1.4,0);rig.position=target
	nearest={}
	if screen=="play" and rooms[room].has("story") and not flags.get("story_"+rooms[room].id,false):
		flags["story_"+rooms[room].id]=true;show_story(rooms[room].story,false)
	ui.queue_redraw()

func add_prop(kind: String, pos: Vector3, text_value: String, uid: String) -> void:
	var label := marker("✦" if kind in ["save","grapple","rescue"] else "◇",Color(.22,.68,1) if kind in ["save","grapple"] else Color(.97,.64,.27))
	world.add_child(label);label.position=pos+Vector3(0,2.1,0)
	var prop := MeshInstance3D.new();var mesh := BoxMesh.new();mesh.size=Vector3(.6,.9,.55);prop.mesh=mesh
	var m := StandardMaterial3D.new();m.albedo_color=Color(.22,.16,.09);m.metallic=.6;m.emission_enabled=true;m.emission=Color(.02,.13,.2) if kind=="save" else Color(.12,.055,.01)
	prop.material_override=m;world.add_child(prop);prop.position=pos+Vector3(0,.45,-.8)
	if kind=="rescue":
		var friend: Node3D=load("res://assets/models/ashen_actor.glb").instantiate();world.add_child(friend);friend.position=pos+Vector3(0,0,-.7);friend.rotation.y=-PI/2
		friend.find_child("AnimationPlayer",true,false).play("PassageIdle")
	props.append({"kind":kind,"p":pos,"text":text_value,"uid":uid,"label":label,"mesh":prop})

func marker(text_value: String, color: Color) -> Label3D:
	var label := Label3D.new();label.text=text_value;label.font_size=38;label.pixel_size=.008;label.modulate=color;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=false;return label

func body(shape: Shape3D, pos: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new();world.add_child(b);b.position=pos;var cs := CollisionShape3D.new();cs.shape=shape;b.add_child(cs);return b

func apply_atmosphere() -> void:
	for mesh in world.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var original: StandardMaterial3D=mesh.mesh.surface_get_material(i)
			if not original or original.emission_enabled:continue
			var mat := ShaderMaterial.new();mat.shader=preload("res://scripts/ruin_depth.gdshader")
			for pair in [["base_color",original.albedo_color],["metalness",original.metallic],["base_texture",original.albedo_texture],["has_texture",original.albedo_texture!=null],["normal_texture",original.normal_texture],["has_normal",original.normal_enabled],["rough_texture",original.roughness_texture],["has_roughness",original.roughness_texture!=null],["base_roughness",original.roughness]]:mat.set_shader_parameter(pair[0],pair[1])
			mesh.set_surface_override_material(i,mat)

func open_hatch() -> void:
	hatch_target=deg_to_rad(-108)
	if hatch_collision:hatch_collision.set_deferred("collision_layer",0)

func _process(dt: float) -> void:
	main_clock+=dt
	if not is_instance_valid(player):return
	if not paused:
		toast_clock=maxf(0,toast_clock-dt);switch_cooldown=maxf(0,switch_cooldown-dt);skill_cooldown=maxf(0,skill_cooldown-dt);magic=minf(100,magic+dt*3)
		if hatch:hatch.rotation.x=lerpf(hatch.rotation.x,hatch_target,1-exp(-dt*5))
		update_nearest()
		if water[0] and not water[1]:water[2]=minf(2,water[2]+dt*.5)
		if water[1]:water[2]=maxf(0,water[2]-dt*.6)
		if water[3] and water[2]<=.03 and flags.get("water_stable",false) and not flags.get("steam",false):flags.steam=true;toast("压力联锁完成 · 出口已开启");save_game()
		for i in range(dusts.size()-1,-1,-1):
			var d := dusts[i];d.life-=dt
			if d.life<=0:d.node.queue_free();dusts.remove_at(i);continue
			d.node.position+=d.velocity*dt;d.velocity.y-=dt*3;d.node.scale+=Vector3.ONE*dt*.3
		var desired: Vector3=player.position+Vector3(clampf(player.velocity.x*.25,-1.5,1.5),1.8,0)
		if player.velocity.y < -3:desired.y-=clampf(-player.velocity.y*.10,0,1.4)
		var half := camera.size*get_viewport().get_visible_rect().size.x/get_viewport().get_visible_rect().size.y*.5
		desired.x=clampf(desired.x,-18+half,18-half)
		desired.y=clampf(desired.y,3.0,10)
		target=target.lerp(desired,1-exp(-dt*6));rig.position=target+Vector3(0,-camera_impact,0)
		camera_impact=move_toward(camera_impact,0,dt*.8)
	ui.queue_redraw()

func update_nearest() -> void:
	nearest={};var distance := 1.65
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.can_assassinate():nearest={"kind":"assassinate","enemy":enemy,"text":"E  暗杀 · 未警觉的人类"};return
	for prop in props:
		if prop.get("used",false):continue
		var diff: Vector3=prop.p-player.position
		var d := absf(diff.x)
		if d<distance and absf(diff.y)<.65 and absf(diff.z)<2:
			distance=d;nearest=prop

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F11:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if screen=="story":
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("pause"):set_screen("play")
		return
	if event.is_action_pressed("pause"):
		set_screen("pause" if screen=="play" else "play" if screen in ["pause","map","skills"] else "title");return
	if screen in ["play","map","skills"]:
		if event.is_action_pressed("map"):set_screen("play" if screen=="map" else "map");return
		if event.is_action_pressed("skills"):set_screen("play" if screen=="skills" else "skills");return
	if paused:return
	if event.is_action_pressed("interact"):interact()
	if event.is_action_pressed("switch"):switch_actor()
	if event.is_action_pressed("item"):
		if potion>0 and party_hp[active_slot]<max_hp():potion-=1;party_hp[active_slot]=minf(max_hp(),party_hp[active_slot]+45);toast("使用冷却药剂 · 恢复 45 生命")
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_1,KEY_2]:switch_actor(event.keycode-KEY_1)

func set_screen(value: String) -> void:
	screen=value;paused=screen!="play"
	if is_instance_valid(player):player.tree.active=not paused
	ui.rebuild_buttons()

func new_game() -> void:
	flags={};visited={};defeated={};opened={};party_hp=[100.0,110.0];active_slot=0;magic=100;scrap=0;skill_points=3;learned={};potion=3;weapon_rank=0
	gear=[true,false,false];water=[false,false,0,false];checkpoint_room=0;checkpoint_pos=Vector3(-10,7,0)
	set_screen("play");load_room(0);save_game()

func max_hp() -> float:return 110 if active_slot==1 else 100

func interact() -> void:
	if nearest.is_empty():return
	var kind: String=nearest.kind
	if kind=="assassinate":
		nearest.enemy.hurt(999,player.facing);player.attack_clock=.8;player.attack_total=.8;player.attack_hit=true;player.attack_clip="Dagger3";player.invulnerable=.5;toast("暗杀成功 · 机械与 Boss 不能暗杀");return
	if kind in ["exit","back","loop","hub","shortcut"]:
		if kind=="exit":
			var gate: String=rooms[room].get("gate","")
			if not gate.is_empty() and not flags.get(gate,false):toast("尚未完成本室目标 · "+rooms[room].hint,3);return
			var next := int(rooms[room].next)
			if room==10:flags.slice_complete=true;save_game();show_story("总井的回流系统重新启动。\n洛铆：维修所接住了第一批幸存者。\n凯恩：米菈，我会继续往下找你。\n\n序章样片完成。你可以回到维修所，继续探索已开放的房间。",false)
			call_deferred("load_room",next);return
		if kind=="back":
			var previous := room-1
			call_deferred("load_room",previous,vector(rooms[previous].exit)+Vector3(-2,.1,0));return
		if kind=="loop":call_deferred("load_room",0);return
		if kind=="hub":call_deferred("load_room",11);return
		if kind=="shortcut":flags.shortcut=true;call_deferred("load_room",1,Vector3(10,7,0));return
	if kind=="save":
		checkpoint_room=room;checkpoint_pos=player.position
		party_hp=[100.0,110.0];magic=100;player.stamina=100;potion=3;save_game();toast("休息灯已保存 · 全队恢复");return
	if kind=="chest":scrap+=20;toast(nearest.text)
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
		var n := int(kind.trim_prefix("gear"))
		if n==0:
			if gear[2]:toast("先断开离合器");return
			gear[0]=not gear[0];toast("锁销已固定" if gear[0] else "锁销已拔出")
		if n==1:
			if gear[0] or gear[2]:toast("先拔锁销，并断开离合器");return
			gear[1]=not gear[1];toast("惰轮已接入 A 与 C" if gear[1] else "惰轮已移开")
		if n==2:
			gear[2]=not gear[2]
			if gear[1] and not gear[0] and gear[2]:flags.gear=true;skill_points+=1;save_game();toast("P01 完成 · 输出顺时针，升降带接通")
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
	if kind in ["chest","rescue","grapple","manifest"]:
		opened[nearest.uid]=true;nearest.used=true;nearest.label.visible=false;nearest.mesh.visible=false;save_game()

func switch_actor(slot: int = -1) -> void:
	if not flags.get("rescued",false):toast("队伍还没有同伴");return
	if switch_cooldown>0 or player.hurt_clock>0 or player.attack_clock>0 or player.motion in ["enter","exit","turn"]:return
	var next := (active_slot+1)%2 if slot<0 else slot
	if party_hp[next]<=0 or next==active_slot:return
	active_slot=next;switch_cooldown=1;toast("洛铆 · 机械师" if next==1 else "凯恩 · 裂影匕首")
	player.visual.scale=Vector3.ONE*(1.1 if next==1 else 1)

func actor_down() -> void:
	if flags.get("rescued",false) and party_hp[1-active_slot]>0:
		active_slot=1-active_slot;toast("接替倒地同伴");return
	show_story("回声熄灭了。你将在最近的休息灯醒来。",false)
	party_hp=[100.0,110.0];magic=100;potion=3
	call_deferred("load_room",checkpoint_room,checkpoint_pos)

func reset_player() -> void:
	party_hp[active_slot]=maxf(0,party_hp[active_slot]-25)
	if party_hp[active_slot]<=0:actor_down()
	else:call_deferred("load_room",checkpoint_room,checkpoint_pos);toast("坠落受伤 · 返回休息灯")

func damage_player(amount: float, facing: float, source: Node) -> void:player.receive_damage(amount,facing,source)

func selected_anchor() -> Variant:
	var best: Variant=null;var distance := 12.0
	for a in rooms[room].get("anchors",[]):
		var p := vector(a);var d := player.position.distance_to(p)
		if d<distance:
			var query := PhysicsRayQueryParameters3D.create(player.position+Vector3(0,1,0),p+Vector3(0,.25,0),1)
			if get_world_3d().direct_space_state.intersect_ray(query).is_empty():best=p;distance=d
	return best

func learn_skill(slot: int) -> void:
	var id := "%d_%d"%[active_slot,slot]
	if learned.has(id):toast("招式已学会");return
	if skill_points<=0:toast("技能点不足");return
	learned[id]=true;skill_points-=1;save_game();ui.rebuild_buttons();toast("招式已学会 · Ctrl + J / K")

func toast(value: String, duration: float = 2.5) -> void:status=value;toast_clock=duration
func show_story(value: String, _unused: bool = false) -> void:story=value;set_screen("story")

func save_game() -> bool:
	var payload := {"schema":1,"room":checkpoint_room,"p":[checkpoint_pos.x,checkpoint_pos.y,checkpoint_pos.z],"flags":flags,"visited":visited,"defeated":defeated,"opened":opened,"party_hp":party_hp,"active":active_slot,"magic":magic,"scrap":scrap,"weapon_rank":weapon_rank,"skill_points":skill_points,"learned":learned,"potion":potion,"gear":gear,"water":water}
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
	checkpoint_room=int(saved.room);checkpoint_pos=vector(saved.p);set_screen("play");load_room(checkpoint_room,checkpoint_pos);return true

func sound(kind: String) -> void:
	var wav := AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=22050
	var bytes := PackedByteArray();bytes.resize(6600)
	for i in range(3300):
		var t := float(i)/22050;var f := 130 if kind in ["step","hammer"] else 480 if kind=="arc" else 240
		var sample := (randf_range(-1,1)*(.5 if kind in ["hit","metal","swing"] else .2)+sin(t*TAU*f)*.35)*exp(-t*(35 if kind=="hammer" else 50))
		bytes.encode_s16(i*2,int(sample*14000))
	wav.data=bytes;audio.stream=wav;audio.play()

func footstep() -> void:sound("step")
func spawn_dust(pos: Vector3, force: float) -> void:particles(pos,force,Color(.43,.37,.29,.24))
func spawn_sparks(pos: Vector3, metal: bool) -> void:particles(pos,2,Color(1,.43,.05) if metal else Color(.8,.14,.07))
func particles(pos: Vector3, force: float, col: Color) -> void:
	for i in range(7):
		var n := MeshInstance3D.new();var m := SphereMesh.new();m.radius=.045;m.height=.09;m.radial_segments=6;m.rings=3;n.mesh=m
		var material := StandardMaterial3D.new();material.albedo_color=col;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;n.material_override=material
		world.add_child(n);n.position=pos;dusts.append({"node":n,"mat":material,"life":.45,"velocity":Vector3(randf_range(-1.5,1.5)*force,randf_range(.5,2),0)})

func run_qa() -> void:
	await preload("res://scripts/qa.gd").new().run(self,capture_dir)
