extends CharacterBody3D
var game: Node3D
var kind := "human"
var uid := ""
var hp := 65.0
var max_hp := 65.0
var facing := 1.0
var origin := Vector3.ZERO
var state := "patrol"
var clock := 0.0
var cooldown := 0.0
var visual: Node3D
var animator: AnimationPlayer
var hit_flash := 0.0
var posture := 0.0
var attack_done := false
var swing_phase := 0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	max_hp = 360 if kind == "boss" else 90 if kind == "hound" else 65
	hp = max_hp
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = .65 if kind == "boss" else .3
	shape.height = 3.4 if kind == "boss" else 1.7 if kind == "human" else 1.05
	cs.shape = shape
	cs.position.y = shape.height * .5
	add_child(cs)
	visual = load("res://assets/models/" + ("ashen_actor" if kind == "human" else "execution_machine" if kind == "boss" else "mechanical_hound") + ".glb").instantiate()
	add_child(visual)
	if kind == "human":
		animator = visual.find_child("AnimationPlayer",true,false)
		animator.get_animation("PassageWalk").loop_mode = Animation.LOOP_LINEAR
		animator.play("PassageWalk")
		var badge: Label3D = game.marker("守军",Color(.86,.44,.23))
		add_child(badge);badge.position.y = 2.2
	origin = position

func _physics_process(dt: float) -> void:
	if game.paused or hp <= 0: return
	clock += dt
	cooldown = maxf(0,cooldown-dt)
	hit_flash = maxf(0,hit_flash-dt)
	var p: CharacterBody3D = game.player
	var diff := p.position-position
	var same_level := absf(diff.y)<1.4 and absf(diff.z)<2.0
	var sees := false
	if same_level and absf(diff.x)<(13 if kind=="boss" else 7):
		var query := PhysicsRayQueryParameters3D.create(global_position+Vector3(0,1,0),p.global_position+Vector3(0,1,0),1)
		sees = get_world_3d().direct_space_state.intersect_ray(query).is_empty() and (kind!="human" or facing*diff.x>0 or absf(diff.x)<(1.2 if p.crouching else 2.7))
	if state == "patrol" and sees:
		state = "chase"
		game.toast("典刑机已启动" if kind=="boss" else "守卫警觉" if kind=="human" else "机械犬锁定目标",1.4)
	velocity.y -= 30*dt
	if state == "stunned":
		velocity.x = move_toward(velocity.x,0,dt*15)
		if clock>.7: state="chase";clock=0
	elif state == "windup":
		velocity.x = 0
		var windup := .85 if kind=="boss" else .50 if kind=="hound" else .38
		visual.rotation.z = -.14*facing*sin(minf(clock/windup,1)*PI/2)
		if clock>=windup:
			state="strike";clock=0;attack_done=false
	elif state == "strike":
		velocity.x = facing*(7 if kind=="hound" else 1.5)
		visual.rotation.z = facing*.22*sin(minf(clock/.3,1)*PI)
		if not attack_done and clock>.09:
			attack_done=true
			if same_level and absf(diff.x)<(3.4 if kind=="boss" else 1.9):
				game.damage_player(26 if kind=="boss" else 14 if kind=="hound" else 11,facing,self)
			if kind=="boss": game.spawn_dust(position+Vector3(facing*1.5,0,0),2);game.sound("hammer")
		if clock>.30:
			state="recover";clock=0
	elif state == "recover":
		velocity.x=0
		if clock>(.9 if kind=="boss" else .4):
			state="chase";clock=0;cooldown=.45
	elif state == "chase":
		if same_level:
			facing=signf(diff.x) if absf(diff.x)>.1 else facing
			var reach := 2.9 if kind=="boss" else 1.6
			velocity.x = facing*(2.1 if kind=="boss" else 3.1) if absf(diff.x)>reach else 0.0
			if absf(diff.x)<=reach and cooldown<=0:
				state="windup";clock=0
		else: velocity.x=0
	elif state == "patrol":
		if absf(position.x-origin.x)>2.2:facing=-signf(position.x-origin.x)
		velocity.x=facing*.85
	move_and_slide()
	if kind=="human":
		visual.rotation.y=facing*PI/2
		if state=="windup": animator.play("Heavy")
		elif state=="stunned":animator.play("Hurt")
		elif animator.current_animation!="PassageWalk":animator.play("PassageWalk")
	else:
		visual.rotation.y=0 if facing>0 else PI
		visual.position.y=.03*sin(clock*9) if state in ["patrol","chase"] else 0.0
	visual.scale=Vector3.ONE*(1.025 if hit_flash>0 else 1.0)

func can_assassinate() -> bool:
	var p: CharacterBody3D = game.player
	return kind=="human" and hp>0 and state=="patrol" and absf(p.position.x-position.x)<=1.3 and (p.position.x-position.x)*facing<0 and absf(p.position.y-position.y)<.4 and absf(p.position.z-position.z)<1.1

func hurt(amount: float, force: float, break_power: float = 10) -> void:
	if hp<=0:return
	hp=maxf(0,hp-amount);posture+=break_power;hit_flash=.15
	game.spawn_sparks(position+Vector3(0,1.2,0),kind!="human")
	game.camera_impact=.1
	game.sound("metal" if kind!="human" else "hit")
	if hp<=0:
		game.defeated[uid]=true
		game.scrap+=40 if kind=="boss" else 8
		if kind=="boss":
			game.flags.boss=true;game.skill_points+=2
			game.show_story("典刑机的链条停了。\n洛铆：囚车还在……先去拿转运表。",false)
		game.save_game()
		queue_free()
	elif kind!="boss" or posture>=75:
		posture=0;state="stunned";clock=0;velocity.x=force*3
