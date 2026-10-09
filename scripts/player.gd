extends CharacterBody3D

var game: Node3D
var visual: Node3D
var tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var current_clip := "PassageIdle"
var facing := 1.0
var motion := "ground"
var phase_clock := 0.0
var ladder_direction := 0.0
var last_floor := true
var last_air_speed := 0.0
var coyote := 0.0
var buffer := 0.0
var land_clock := 0.0
var turn_clock := 0.0
var turn_from := Vector3.ZERO
var switch_lane := 0
var steps := 0
var distance_clock := 0.0
var transition_from := Vector3.ZERO
var transition_to := Vector3.ZERO
var transition_total := .30
var feet: SkeletonModifier3D
var max_transition_step := 0.0
var detach_clock := 0.0
var attack_clock := 0.0
var attack_total := 0.0
var hit_at := 0.0
var attack_power := 0.0
var attack_reach := 1.8
var attack_clip := "Dagger1"
var attack_hit := false
var combo := 0
var combo_clock := 0.0
var queued_attack := false
var invulnerable := 0.0
var dodge_clock := 0.0
var hurt_clock := 0.0
var stamina := 100.0
var stamina_delay := 0.0
var guarding := false
var guard_clock := 0.0
var crouching := false
var grapple_target := Vector3.ZERO
var grappling := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = .34
	floor_max_angle = deg_to_rad(50)
	floor_stop_on_slope = true
	floor_constant_speed = true
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = .24
	cap.height = 1.70
	shape.shape = cap
	shape.position.y = .87
	add_child(shape)
	visual = load("res://assets/models/ashen_actor.glb").instantiate()
	add_child(visual)
	var ap: AnimationPlayer = visual.find_child("AnimationPlayer", true, false)
	var state := AnimationNodeStateMachine.new()
	var loops := ["PassageIdle", "PassageWalk", "StairUp", "StairDown", "LadderUp", "LadderDown", "LadderIdle", "PassageFall", "PassageJump"]
	for name in ap.get_animation_list():
		if not name in loops + ["PassageLand", "LadderEnter", "LadderExit", "HatchEnter", "HatchExit", "Dagger1", "Dagger2", "Dagger3", "Heavy", "Guard", "Dodge", "Hurt", "Skill"]: continue
		if name in loops: ap.get_animation(name).loop_mode = Animation.LOOP_LINEAR
		var blend := AnimationNodeBlendTree.new()
		var anim := AnimationNodeAnimation.new()
		anim.animation = name
		blend.add_node("Clip", anim)
		blend.add_node("Rate", AnimationNodeTimeScale.new())
		blend.connect_node("Rate", 0, "Clip")
		blend.connect_node("output", 0, "Rate")
		state.add_node(name, blend)
	for a in state.get_node_list():
		for b in state.get_node_list():
			if a == b or a in ["Start", "End"] or b in ["Start", "End"]: continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = .11
			state.add_transition(a, b, transition)
	tree = AnimationTree.new()
	visual.add_child(tree)
	tree.tree_root = state
	tree.anim_player = tree.get_path_to(ap)
	tree.active = not game.paused
	playback = tree.get("parameters/playback")
	playback.start(current_clip)
	visual.rotation.y = PI / 2
	var bounce := SpotLight3D.new()
	add_child(bounce)
	bounce.position = Vector3(1.3,2.8,2.7)
	bounce.look_at_from_position(bounce.position,Vector3(0,1.0,0),Vector3.UP)
	bounce.light_color = Color(1.0,.89,.74)
	bounce.light_energy = .85
	bounce.spot_range = 6
	bounce.spot_angle = 25
	bounce.shadow_enabled = false
	var skeleton: Skeleton3D = visual.find_child("Skeleton3D",true,false)
	if not skeleton:
		var skeletons := visual.find_children("*","Skeleton3D",true,false)
		if not skeletons.is_empty(): skeleton = skeletons[0]
	if skeleton:
		feet = preload("res://scripts/stair_feet.gd").new()
		feet.actor = self
		skeleton.add_child(feet)

func clip(name: String, rate: float = 1.0) -> void:
	if current_clip != name:
		current_clip = name
		playback.travel(name)
	tree.set("parameters/" + name + "/Rate/scale", rate)

func move_axis() -> float:
	var axis := Input.get_axis("left", "right")
	if game.pad >= 0: axis = maxf(axis, 0) + minf(axis, 0) + Input.get_joy_axis(game.pad, JOY_AXIS_LEFT_X)
	return 0.0 if absf(axis) < .18 else clampf(axis, -1, 1)

func vertical_axis() -> float:
	var axis := Input.get_axis("down", "up")
	if game.pad >= 0: axis -= Input.get_joy_axis(game.pad, JOY_AXIS_LEFT_Y)
	return 0.0 if absf(axis) < .24 else clampf(axis, -1, 1)

func _physics_process(dt: float) -> void:
	if game.paused: return
	invulnerable=maxf(0,invulnerable-dt)
	stamina_delay=maxf(0,stamina_delay-dt)
	if stamina_delay<=0:stamina=minf(100,stamina+25*dt)
	combo_clock=maxf(0,combo_clock-dt)
	if combo_clock<=0:combo=0
	if hurt_clock>0:
		hurt_clock-=dt;velocity.y-=31.25*dt;move_and_slide();clip("Hurt");return
	if grappling:
		velocity=(grapple_target-position).normalized()*14
		var distance := position.distance_to(grapple_target)
		move_and_slide();clip("PassageJump")
		if distance<.45 or Input.is_action_just_pressed("jump"):
			grappling=false;motion="ground";velocity=Vector3(facing*2,3,0)
		return
	if dodge_clock>0:
		dodge_clock-=dt;velocity.x=facing*10.7;velocity.y-=31.25*dt
		move_and_slide();clip("Dodge",1.33);return
	if attack_clock>0:
		attack_clock-=dt
		if Input.is_action_just_pressed("light") and attack_clip.begins_with("Dagger"):queued_attack=true
		velocity.x=move_toward(velocity.x,0,dt*32);velocity.y-=31.25*dt;move_and_slide()
		clip(attack_clip)
		if not attack_hit and attack_total-attack_clock>=hit_at:
			attack_hit=true
			for enemy in game.enemies:
				if not is_instance_valid(enemy):continue
				var offset: Vector3 = enemy.position-position
				if absf(offset.x)<attack_reach and facing*offset.x>-.25 and absf(offset.y)<1.6 and absf(offset.z)<2.0:
					enemy.hurt(attack_power*(1+.15*game.weapon_rank),facing,30 if attack_clip=="Heavy" else 12)
		if attack_clock<=0 and queued_attack:
			queued_attack=false;begin_attack(false)
		return
	guarding=Input.is_action_pressed("guard") and motion=="ground" and is_on_floor() and stamina>0
	guard_clock=guard_clock+dt if guarding else 0.0
	if guarding:
		stamina=maxf(0,stamina-dt*8);stamina_delay=.55
		velocity.x=move_toward(velocity.x,0,dt*30);velocity.y-=31.25*dt;move_and_slide();clip("Guard");return
	if Input.is_action_just_pressed("dodge") and motion=="ground" and stamina>=20:
		stamina-=20;stamina_delay=.55;dodge_clock=.30;invulnerable=.19;return
	if motion=="ground":
		if Input.is_action_just_pressed("light"):
			if Input.is_action_pressed("modifier"):begin_skill(0)
			else:begin_attack(false)
			return
		if Input.is_action_just_pressed("heavy"):
			if Input.is_action_pressed("modifier"):begin_skill(1)
			else:begin_attack(true)
			return
	if Input.is_action_just_released("grapple") and game.flags.get("grapple",false) and motion=="ground":
		var anchor: Variant = game.selected_anchor()
		if anchor!=null:grapple_target=anchor+Vector3(-.3,.15,0);grappling=true;return
	crouching=Input.is_action_pressed("down") and is_on_floor() and motion=="ground"
	var before := position
	var transitioning := motion in ["enter","exit","turn"]
	advance_motion(dt)
	if transitioning: max_transition_step = maxf(max_transition_step,before.distance_to(position))

func advance_motion(dt: float) -> void:
	if game.paused: return
	var dx := move_axis()
	var dy := vertical_axis()
	var jump := Input.is_action_just_pressed("jump")
	phase_clock = maxf(phase_clock - dt, 0)
	land_clock = maxf(land_clock - dt, 0)
	detach_clock = maxf(detach_clock - dt, 0)
	buffer = .14 if jump else maxf(buffer - dt, 0)
	coyote = .12 if is_on_floor() else maxf(coyote - dt, 0)
	if motion == "turn":
		turn_clock += dt
		var t := smoothstep(0, 1, minf(turn_clock / .48, 1))
		position.z = lerpf(turn_from.z, 1.05 if switch_lane == 1 else -.6, t)
		visual.rotation.y = lerp_angle(visual.rotation.y, facing * PI/2, dt * 12)
		clip("PassageWalk", .65)
		if t >= 1:
			motion = "ground"
			phase_clock = .85
		return
	if motion == "enter" or motion == "exit":
		velocity = Vector3.ZERO
		var t := smoothstep(0, 1, clampf(1 - phase_clock / transition_total, 0, 1))
		position = transition_from.lerp(transition_to, t)
		if motion == "exit": position.y += sin(t * PI) * .12
		visual.rotation.y = lerp_angle(visual.rotation.y, PI if motion == "enter" else facing * PI / 2, dt * 14)
		if phase_clock <= 0:
			if motion == "exit": motion = "ground"
			else: motion = "ladder"
		return
	if motion == "ladder":
		var route: Dictionary = game.data.ladder
		if jump:
			motion = "ground"
			velocity = Vector3(facing * 3.4, 7.2, 0)
			detach_clock = .22
			phase_clock = .30
			coyote = 0
			buffer = 0
			last_floor = false
			clip("PassageJump")
			game.status = "离梯跳跃 · 保留惯性与重力"
			return
		position.x = float(route.x)
		position.z = float(route.z) + .26
		position.y += dy * 1.95 * dt
		velocity = Vector3.ZERO
		visual.rotation.y = lerp_angle(visual.rotation.y, PI, dt * 15)
		clip("LadderIdle" if dy == 0 else "LadderUp" if dy > 0 else "LadderDown", 1 if dy == 0 else absf(dy)*2.56)
		if position.y >= float(route.high) + .06 or position.y <= float(route.low) - .025:
			var high := position.y > float(route.low) + 1
			transition_from = position
			transition_to = Vector3(float(route.x) - 1.32, float(route.high) if high else float(route.low), float(route.z))
			transition_total = .42
			motion = "exit"
			phase_clock = transition_total
			clip("HatchExit" if route.hatch else "LadderExit", 3.0)
			game.status = "爬出井口" if route.hatch else "离开梯子 · 上层 / 下层接地"
		return
	if phase_clock == 0 and game.data.has("ladder") and dy != 0:
		var route: Dictionary = game.data.ladder
		var near_low := absf(position.y - float(route.low)) < .40
		var near_high := absf(position.y - float(route.high)) < .55
		if absf(position.x - float(route.x)) < 1.4 and ((near_low and dy > 0) or (near_high and dy < 0)):
			motion = "enter"
			phase_clock = .45 if route.hatch else .27
			transition_total = phase_clock
			transition_from = position
			transition_to = Vector3(float(route.x),float(route.high)-.06 if near_high else float(route.low)+.08,float(route.z)+.26)
			velocity = Vector3.ZERO
			clip("HatchEnter" if route.hatch else "LadderEnter", 2.2 if route.hatch else 3.3)
			if route.hatch: game.open_hatch()
			game.status = "开盖 · 进入井内竖梯" if route.hatch else "握住梯子 · 手脚交替攀爬"
			return
	# The two flights meet at a true depth-separated landing. Walk to the
	# right-hand turning pad, reverse direction, then cross the pad smoothly.
	if phase_clock == 0 and game.data.has("switchback") and absf(position.y - 4) < .34 and is_on_floor():
		if position.x > 2.1 and ((switch_lane == 0 and dx < -.2) or (switch_lane == 1 and dx > .2)):
			switch_lane = 1 - switch_lane
			motion = "turn"
			turn_from = position
			turn_clock = 0
			facing = -1 if switch_lane == 1 else 1
			game.status = "折返平台转身 · 下段向左 / 上段向右"
			return
	var grounded := is_on_floor()
	var desired := dx * (2.2 if crouching else 5.8)
	if game.index==3 and grounded:
		if absf(get_floor_normal().x)>.09:desired=dx*4.4
		if switch_lane==0 and absf(position.y-4)<.34 and position.x>3.35 and dx>0:desired=0
	if detach_clock > 0 and absf(dx) < .18: desired = facing * 3.4
	velocity.x = move_toward(velocity.x, desired, (28 if grounded else 13) * dt)
	velocity.z = 0
	if buffer > 0 and coyote > 0 and land_clock < .18:
		velocity.y = 12.5
		buffer = 0
		coyote = 0
		clip("PassageJump")
	else:
		velocity.y -= (42.2 if velocity.y < 0 else 31.25) * dt
		if not Input.is_action_pressed("jump") and velocity.y > 3: velocity.y -= 20 * dt
	last_air_speed = velocity.y
	move_and_slide()
	if is_on_floor() and not last_floor:
		land_clock = .32 if last_air_speed < -9 else .19
		game.landing_count += 1
		game.spawn_dust(position, clampf(-last_air_speed / 13, .3, 1.5))
		game.camera_impact = clampf(-last_air_speed * .012, 0, .16)
	if dx != 0: facing = signf(dx)
	visual.rotation.y = lerp_angle(visual.rotation.y, facing * PI/2, dt * 16)
	if land_clock > 0:
		clip("PassageLand", 3.1)
	elif not is_on_floor():
		clip("PassageJump" if velocity.y > 1 else "PassageFall")
	elif absf(velocity.x) > .14:
		var normal := get_floor_normal()
		var slope := absf(normal.x) > .09
		var rising := velocity.x * (-normal.x) > 0
		clip(("StairUp" if rising else "StairDown") if slope and game.index == 3 else "PassageWalk", maxf(absf(velocity.x) / (1.25 if slope else 1.30), .2))
		distance_clock += absf(velocity.x) * dt
		if distance_clock > .65:
			distance_clock -= .65
			steps += 1
			game.footstep()
	else:
		clip("PassageIdle")
	last_floor = is_on_floor()
	if position.y < -3.5: game.reset_player()
	if game.flags.get("wall",false) and is_on_wall() and velocity.y<0 and Input.is_action_just_pressed("jump"):
		velocity=Vector3(-facing*6,11,0)

func begin_attack(heavy: bool) -> void:
	if heavy and stamina<18:return
	if heavy:stamina-=18;stamina_delay=.55
	combo=(combo%3)+1 if not heavy else 0
	combo_clock=.85
	attack_clip="Heavy" if heavy else "Dagger%d"%combo
	attack_total=.90 if heavy else [.31,.36,.49][combo-1]
	hit_at=.38 if heavy else [.09,.11,.16][combo-1]
	attack_clock=attack_total
	attack_power=(46 if game.active_slot==1 else 36) if heavy else (18 if game.active_slot==1 else 22)*[1.0,1.1,1.4][combo-1]
	attack_reach=2.5 if heavy else 1.85
	attack_hit=false
	clip(attack_clip)
	if playback:playback.start(attack_clip)
	game.sound("swing")

func begin_skill(slot: int) -> void:
	var id := "%d_%d"%[game.active_slot,slot]
	if not game.learned.has(id):game.toast("先在技能界面 T 学习此招式");return
	if game.magic<18 or game.skill_cooldown>0:game.toast("魔力不足或技能尚未冷却");return
	game.magic-=18;game.skill_cooldown=4
	if game.active_slot==1 and slot==0:game.party_hp[1]=minf(110,game.party_hp[1]+12)
	attack_clip="Skill";attack_total=.8;attack_clock=.8;hit_at=.30;attack_power=52 if slot==0 else 38;attack_reach=3.3 if slot==0 else 4.5;attack_hit=false
	clip("Skill");playback.start("Skill");game.sound("arc")

func receive_damage(amount: float, direction: float, source: Node) -> void:
	if invulnerable>0:return
	if guarding and facing*direction<0:
		if guard_clock<=.10:
			stamina=minf(100,stamina+10);source.posture+=50;source.state="stunned";source.clock=0
			game.toast("完美弹反");game.sound("arc");return
		stamina=maxf(0,stamina-amount);amount*=.25
		if stamina<=0:hurt_clock=.6
	game.party_hp[game.active_slot]=maxf(0,game.party_hp[game.active_slot]-amount)
	invulnerable=.55;hurt_clock=maxf(.23,hurt_clock);attack_clock=0;grappling=false
	velocity.x=direction*4;game.camera_impact=.17;game.sound("hit")
	if game.party_hp[game.active_slot]<=0:game.actor_down()

func snapshot() -> Dictionary:
	return {"p": [position.x, position.y, position.z], "velocity": [velocity.x, velocity.y, velocity.z], "motion": motion, "clip": current_clip, "floor": is_on_floor(), "lane": switch_lane,"transition_max":max_transition_step}
