extends CharacterBody3D
var game: Node3D
var visual: Node3D
var animator: AnimationPlayer
var current_clip := "PassageIdle"
var facing := 1.0
var motion := "ground"
var stamina := 100.0
var stamina_delay := 0.0
var invulnerable := 0.0
var hurt_clock := 0.0
var attack_clock := 0.0
var attack_total := 0.0
var hit_at := 0.0
var attack_power := 0.0
var attack_reach := 1.9
var attack_clip := "Dagger1"
var attack_hit := false
var combo := 0
var combo_clock := 0.0
var queued_attack := false
var guarding := false
var guard_clock := 0.0
var crouching := false
var coyote := 0.0
var buffer := 0.0
var air_dash_used := false
var air_jump_used := false
var double_jump_clock := 0.0
var double_jumps := 0
var dash_clock := 0.0
var dodge_clock := 0.0
var dodge_elapsed := 0.0
var wall_clock := 0.0
var wall_lock := 0.0
var wall_jumps := 0
var vault_clock := 0.0
var vault_from := Vector3.ZERO
var vault_to := Vector3.ZERO
var vaults := 0
var slamming := false
var grapple_target := Vector3.ZERO
var grappling := false
var grapple_clock := 0.0
var route: Dictionary={}
var detach_clock := 0.0
var ladder_travel := 0.0
var steps := 0
var distance_clock := 0.0
var ladder_sound_clock := 0.0
var wall_sound_clock := 0.0
var capsule: CapsuleShape3D
var collider: CollisionShape3D

func _ready() -> void:
	collision_layer=2;collision_mask=1;floor_snap_length=.3;floor_max_angle=deg_to_rad(50);floor_constant_speed=true
	collider=CollisionShape3D.new();capsule=CapsuleShape3D.new();capsule.radius=.26;capsule.height=1.7;collider.shape=capsule;collider.position.y=.86;add_child(collider)
	set_actor(game.active_slot)
	var light:=OmniLight3D.new();add_child(light);light.position=Vector3(0,2,2);light.light_color=Color(1,.86,.7);light.light_energy=.6;light.omni_range=5

func set_actor(slot: int) -> void:
	if is_instance_valid(visual):remove_child(visual);visual.queue_free()
	visual=load("res://assets/models/"+game.actor_model(slot)+".glb").instantiate();add_child(visual)
	visual.scale=Vector3.ONE*(1.1 if slot==1 else 1);animator=visual.find_child("AnimationPlayer",true,false)
	for name in ["PassageIdle","PassageWalk","Run","Crouch","LadderUp","LadderDown","LadderIdle","WallHold","HookPull","StairUp","StairDown"]:
		if animator.has_animation(name):animator.get_animation(name).loop_mode=Animation.LOOP_LINEAR
	if not animator.has_animation(current_clip):current_clip="PassageIdle"
	visual.rotation.y=facing*PI/2;animator.play(current_clip);set_animation_paused(game.paused)
func set_animation_paused(value: bool) -> void:animator.speed_scale=0 if value else 1
func clip(name: String, rate: float=1) -> void:
	if not animator.has_animation(name):name="PassageIdle"
	if current_clip!=name:current_clip=name;animator.play(name,.09,rate)
	else:animator.speed_scale=rate if not game.paused else 0
func move_axis() -> float:
	var axis:=Input.get_axis("left","right")
	if game.pad>=0:axis+=Input.get_joy_axis(game.pad,JOY_AXIS_LEFT_X)
	return 0 if absf(axis)<.18 else clampf(axis,-1,1)
func vertical_axis() -> float:
	var axis:=Input.get_axis("down","up")
	if game.pad>=0:axis-=Input.get_joy_axis(game.pad,JOY_AXIS_LEFT_Y)
	return 0 if absf(axis)<.24 else clampf(axis,-1,1)

func _physics_process(dt: float) -> void:
	if game.paused or game.hitstop>0:return
	double_jump_clock=maxf(0,double_jump_clock-dt)
	invulnerable=maxf(0,invulnerable-dt);stamina_delay=maxf(0,stamina_delay-dt);wall_sound_clock=maxf(0,wall_sound_clock-dt);wall_lock=maxf(0,wall_lock-dt);detach_clock=maxf(0,detach_clock-dt)
	if stamina_delay<=0:stamina=minf(100,stamina+25*dt)
	combo_clock=maxf(0,combo_clock-dt)
	if combo_clock<=0:combo=0
	if position.y < -3 or absf(position.x)>25:game.reset_player();return
	var dx:=move_axis();var dy:=vertical_axis();var jump:=Input.is_action_just_pressed("jump")
	if hurt_clock>0:hurt_clock-=dt;velocity.y-=31.25*dt;move_with_sound();clip("Hurt");return
	if vault_clock>0:
		vault_clock=maxf(0,vault_clock-dt);var t:=1-vault_clock/.4
		position=vault_from.lerp(vault_to,t)+Vector3(0,sin(t*PI)*.55,0);clip("Vault",1.5)
		if vault_clock==0:motion="ground";velocity=Vector3(facing*3,0,0)
		return
	if grappling:
		grapple_clock+=dt;velocity=(grapple_target-position).normalized()*14;move_with_sound();clip("HookPull",1.3)
		if position.distance_to(grapple_target)<.4 or jump or grapple_clock>2.2:game.sound("grapple_attach",position);grappling=false;motion="ground";velocity=Vector3(facing*2,3,0)
		return
	if motion=="ladder":
		if jump:motion="ground";detach_clock=.35;velocity=Vector3(facing*4,9,0);game.sound("jump",position);clip("PassageJump");return
		var delta:=dy*2.8*dt;position.y=clampf(position.y+delta,float(route.low),float(route.high));position.x=route.x;position.z=.06;velocity=Vector3.ZERO;ladder_travel+=absf(delta)
		ladder_sound_clock+=absf(delta)
		if ladder_sound_clock>.48:ladder_sound_clock=0;game.sound("ladder_%d"%randi_range(1,2),position)
		visual.rotation.y=PI;clip("LadderIdle" if dy==0 else "LadderUp" if dy>0 else "LadderDown",2.9 if dy!=0 else 1)
		if (position.y>=float(route.high)-.02 and dy>0) or (position.y<=float(route.low)+.02 and dy<0):position.x-=1.05;position.z=0;motion="ground";detach_clock=.45;clip("LadderExit",2)
		if Input.is_action_just_pressed("interact"):
			for platform in game.rooms[game.room].platforms:
				if absf(position.y-platform[2])<.45 and position.x>platform[0]+1 and position.x<platform[1]:position.x-=1.0;position.y=platform[2]+.04;motion="ground";detach_clock=.4;break
		return
	if dash_clock>0:dash_clock-=dt;velocity=Vector3(facing*17,0,0);move_with_sound();clip("AirDash",1.5);return
	if dodge_clock>0:dodge_clock-=dt;dodge_elapsed+=dt;velocity.x=facing*10.7;velocity.y-=31.25*dt;move_with_sound();clip("Roll",2);return
	if slamming:
		velocity.x=dx*2;velocity.y=-22;move_with_sound();clip("Slam",1.3)
		if is_on_floor():slamming=false;game.melee_hit(42,4.0,facing,true);game.spawn_dust(position,2);game.camera_impact=.2;game.sound("land_heavy",position)
		return
	if attack_clock>0:
		attack_clock-=dt
		if Input.is_action_just_pressed("light") and (attack_clip.begins_with("Dagger") or (attack_clip.begins_with("Katana") and attack_clip!="KatanaHeavy")):queued_attack=true
		velocity.x=move_toward(velocity.x,0,32*dt);velocity.y-=31.25*dt;move_with_sound()
		clip(attack_clip,animator.get_animation(attack_clip).length/attack_total if attack_clip.begins_with("Katana") else 1.0)
		if not attack_hit and attack_total-attack_clock>=hit_at:
			attack_hit=true
			if game.active_slot==2:game.fire_projectile(position+Vector3(facing*.6,1,0),facing,attack_power,true,null)
			else:game.melee_hit(attack_power*(1+.15*game.weapon_rank),attack_reach,facing,false)
		if attack_clock<=0 and queued_attack:queued_attack=false;begin_attack(false)
		return
	guarding=Input.is_action_pressed("guard") and is_on_floor() and stamina>0;guard_clock=guard_clock+dt if guarding else 0
	if guarding:stamina=maxf(0,stamina-dt*8);stamina_delay=.55;velocity.x=0;velocity.y-=31.25*dt;move_with_sound();clip("Guard");return
	if Input.is_action_pressed("modifier") and jump:begin_skill(2);return
	if Input.is_action_just_pressed("dodge") and stamina>=20:
		if is_on_floor():stamina-=20;stamina_delay=.55;dodge_clock=.3;dodge_elapsed=0;game.sound("roll",position);clip("Roll");return
		elif game.learned.has("%d_2"%game.active_slot) and not air_dash_used:begin_skill(2);return
	if Input.is_action_just_pressed("light"):
		if Input.is_action_pressed("modifier"):begin_skill(0)
		else:begin_attack(false)
		return
	if Input.is_action_just_pressed("heavy"):
		if Input.is_action_pressed("modifier"):begin_skill(1)
		elif not is_on_floor():slamming=true;clip("Slam")
		else:begin_attack(true)
		return
	if Input.is_action_just_released("grapple") and game.flags.get("grapple",false):
		var a: Variant=game.selected_anchor()
		if a!=null:grapple_target=a+Vector3(-.15,.08,0);grappling=true;grapple_clock=0;game.sound("grapple_launch",position);return
	if dy!=0 and detach_clock<=0:
		for ladder in game.rooms[game.room].ladders:
			if absf(position.x-ladder.x)<1.0 and position.y>=float(ladder.low)-.3 and position.y<=float(ladder.high)+.25:
				if (dy>0 and position.y<float(ladder.high)-.1) or (dy<0 and position.y>float(ladder.low)+.1):route=ladder;motion="ladder";position.x=ladder.x;velocity=Vector3.ZERO;return
	var grounded:=is_on_floor()
	if grounded:air_dash_used=false;air_jump_used=false;double_jump_clock=0;wall_clock=0
	coyote=.1 if grounded else maxf(0,coyote-dt);buffer=.12 if jump else maxf(0,buffer-dt)
	crouching=Input.is_action_pressed("down") and grounded;capsule.height=1.1 if crouching else 1.7;collider.position.y=.56 if crouching else .86
	var wall_contact:=false
	if game.flags.get("wall",false) and is_on_wall() and not grounded and dx!=0 and wall_lock<=0:
		for i in get_slide_collision_count():
			var body: Object=get_slide_collision(i).get_collider()
			if body is Node and body.get_meta("climbable",false):wall_contact=true
	if wall_contact and wall_clock<.65:
		if wall_sound_clock<=0:game.sound("grapple_attach",position);wall_sound_clock=.5
		wall_clock+=dt;velocity.y=maxf(velocity.y,-1.7);clip("WallHold")
		if jump:velocity=Vector3(-dx*7,11.8,0);facing=-dx;wall_lock=.25;wall_jumps+=1;game.sound("wall_jump",position);buffer=0;clip("WallKick");move_with_sound();return
	if buffer>0 and coyote>0:
		if try_vault():return
		game.sound("jump",position);velocity.y=12.5;buffer=0;coyote=0;clip("PassageJump")
	elif jump and not grounded and not air_jump_used:
		air_jump_used=true;double_jumps+=1;double_jump_clock=.5;velocity.y=11.8;buffer=0;coyote=0
		game.sound("jump",position);game.spawn_dust(position+Vector3(0,.3,0),.7);clip("DoubleJump")
	else:
		velocity.y-=(42.2 if velocity.y<0 else 31.25)*dt
		if not Input.is_action_pressed("jump") and velocity.y>3:velocity.y-=20*dt
	var speed:=2.2 if crouching else 7.8 if Input.is_action_pressed("run") else 5.8
	if grounded and absf(get_floor_normal().x)>.08:speed=4.4
	if wall_lock<=0:velocity.x=move_toward(velocity.x,dx*speed+game.world_builder.conveyor_speed(position),dt*(30 if grounded else 15))
	velocity.z=0;var was_floor:=grounded;move_with_sound()
	if dx!=0 and wall_lock<=0:facing=signf(dx)
	visual.rotation.y=lerp_angle(visual.rotation.y,facing*PI/2,dt*16)
	if not was_floor and is_on_floor():game.landing_count+=1;game.spawn_dust(position,1);clip("PassageLand",2.5)
	elif wall_contact and wall_clock<.65:clip("WallHold")
	elif not is_on_floor():clip("DoubleJump" if double_jump_clock>0 else "PassageJump" if velocity.y>1 else "PassageFall")
	elif absf(velocity.x)>.2:
		var slope:=absf(get_floor_normal().x)>.08
		clip("StairUp" if slope and velocity.x*(-get_floor_normal().x)>0 else "StairDown" if slope else "Crouch" if crouching else "Run" if speed>6 else "PassageWalk",maxf(absf(velocity.x)/2.2,.5))
		distance_clock+=absf(velocity.x)*dt
		if distance_clock>.75:distance_clock-=.75;steps+=1;game.footstep()
	else:clip("Crouch" if crouching else "PassageIdle",.4 if crouching else 1)

func try_vault() -> bool:
	for p in game.world_builder.obstacles:
		if absf(p.x-position.x)<1.3 and (p.x-position.x)*facing>0 and absf(position.y)<.2:
			vault_from=position;vault_to=Vector3(p.x+facing*1.1,position.y,0);vault_clock=.4;motion="vault";game.sound("vault",position);vaults+=1;buffer=0;return true
	return false
func begin_attack(heavy: bool) -> void:
	var katana: bool=game.active_slot==0 and game.equipped_weapon=="katana"
	var cost: float=(24 if heavy else 8) if katana else 18 if heavy else 0
	if stamina<cost:return
	if cost>0:stamina-=cost;stamina_delay=.55
	combo=(combo%3)+1 if not heavy else 0;combo_clock=.85
	attack_clip=("KatanaHeavy" if heavy else "Katana%d"%combo) if katana else "BowShot" if game.active_slot==2 else ("MechHeavy" if heavy else "MechLight") if game.active_slot==1 else "Heavy" if heavy else "Dagger%d"%combo
	attack_total=.86 if heavy else .34;hit_at=.36 if heavy else .10;attack_clock=attack_total
	attack_power=(52 if game.active_slot==1 else 40) if heavy else 24 if game.active_slot==2 else 22;attack_reach=2.8 if heavy else 1.95;attack_hit=false
	if katana:
		attack_total=1.0 if heavy else [.50,.54,.65][combo-1];hit_at=.48 if heavy else [.19,.21,.26][combo-1]
		attack_power=56 if heavy else [28,30,36][combo-1];attack_reach=3.65 if heavy else [3.0,3.2,3.4][combo-1];attack_clock=attack_total
	animator.stop();clip(attack_clip);animator.play(attack_clip,.06,1);game.sound("bow_fire" if game.active_slot==2 else "whoosh_heavy" if heavy else "whoosh_light_%d"%randi_range(1,2),position)
func begin_skill(slot: int) -> void:
	if not game.learned.has("%d_%d"%[game.active_slot,slot]):game.toast("T 学习对应招式与身法");return
	if game.magic<16 or game.skill_cooldown>0:game.toast("魔力不足或尚未冷却");return
	if slot==2:
		if air_dash_used:return
		game.magic-=16;dash_clock=.19;air_dash_used=true;game.skill_cooldown=1;game.sound("dash",position);clip("AirDash");return
	game.magic-=18;game.skill_cooldown=4
	if game.active_slot==1 and slot==0:game.party_hp[1]=minf(110,game.party_hp[1]+12)
	attack_clip="BowShot" if game.active_slot==2 else "MechHeavy" if game.active_slot==1 else "Skill";attack_total=.7;attack_clock=.7;hit_at=.26;attack_power=55 if slot==0 else 42;attack_reach=3.2 if slot==0 else 4.4;attack_hit=false
	if game.active_slot==0 and game.equipped_weapon=="katana":attack_clip="Katana3" if slot==0 else "KatanaHeavy"
	animator.stop();clip(attack_clip);animator.play(attack_clip);game.sound("arc")
func receive_damage(amount: float,direction: float,source: Node) -> void:
	if invulnerable>0 or (dodge_clock>0 and dodge_elapsed>=.06 and dodge_elapsed<=.19):return
	if guarding and facing*direction<0:
		if guard_clock<=.10:
			stamina=minf(100,stamina+10)
			if is_instance_valid(source):source.posture+=50;source.state="stunned";source.clock=0
			game.toast("完美弹反");game.sound("parry",position);return
		game.sound("guard",position);stamina=maxf(0,stamina-amount);amount*=.25
	game.party_hp[game.active_slot]=maxf(0,game.party_hp[game.active_slot]-amount);invulnerable=.55;hurt_clock=.23;attack_clock=0;grappling=false;slamming=false;velocity.x=direction*4;game.camera_impact=.16;game.sound("hit")
	if game.party_hp[game.active_slot]<=0:game.actor_down()
func snapshot() -> Dictionary:
	return {"p":[position.x,position.y,position.z],"velocity":[velocity.x,velocity.y,velocity.z],"floor":is_on_floor(),"motion":motion,"clip":current_clip,"wall_jumps":wall_jumps,"vaults":vaults,"air_dash_used":air_dash_used,"air_jump_used":air_jump_used,"double_jumps":double_jumps,"weapon":game.equipped_weapon,"ladder_travel":ladder_travel}

func move_with_sound() -> void:
	var on_ground:=is_on_floor();var fall_speed:=velocity.y
	move_and_slide()
	if is_on_floor():air_jump_used=false;double_jump_clock=0
	if not on_ground and is_on_floor() and fall_speed < -2 and not slamming:game.sound("land_heavy" if fall_speed < -16 else "land_soft",position)
