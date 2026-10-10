extends CharacterBody3D
const Content=preload("res://scripts/content_v06.gd")
const Tuning=preload("res://scripts/action_tuning.gd")
var hit_pause := 0.0
var stun_duration := .45
var definition: Dictionary
var sense_clock := 0.0
var line_clear := true
var edge_clock := 0.0
var edge_safe := true
var last_pattern := ""
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
var posture := 0.0
var visual: Node3D
var animator: AnimationPlayer
var hit_flash := 0.0
var attack_done := false
var pattern := "近击"
var attacks := 0
var phase_two := false
var windup := .6
var legs: Array=[]

func boss() -> bool:return Content.ENEMIES.get(kind,{}).get("boss",false)
func ranged() -> bool:return Content.ENEMIES.get(kind,{}).get("ranged",false)
func flying() -> bool:return Content.ENEMIES.get(kind,{}).get("flying",false)
func _ready() -> void:
	collision_layer=4;collision_mask=1
	definition=Content.ENEMIES[kind];max_hp=float(definition.hp);hp=max_hp
	var shape:=CollisionShape3D.new();var cap:=CapsuleShape3D.new();cap.radius=.65 if boss() else .3;cap.height=3.6 if boss() else 1.7 if definition.get("human",false) else 1.05;shape.shape=cap;shape.position.y=cap.height*.5;add_child(shape)
	visual=game.instantiate_model(definition.model);add_child(visual)
	animator=visual.find_child("AnimationPlayer",true,false)
	if animator:
		animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
		animator.get_animation("PassageWalk").loop_mode=Animation.LOOP_LINEAR;animator.play("PassageWalk")
	var label: Label3D=game.marker(definition.get("name",{"human":"守军","ranged":"弩手","wraith":"管魂","thorn":"铁棘爬行兽","blood_guard":"血堡侍卫","scribe":"绘笔守卫","mother":"管喉之母","witch":"迁木女巫","lord":"血契侯爵","editor":"校稿者"}.get(kind,"")),Color(.9,.3,.16));add_child(label);label.position.y=4.0 if boss() else 2.1
	legs=visual.find_children("Leg*","MeshInstance3D",true,false);origin=position
	game.feedback.prepare(self)

func _physics_process(dt: float) -> void:
	if animator:animator.speed_scale=0 if game.paused or hit_pause>0 else 1
	if game.paused or hp<=0:return
	if boss() and hp<max_hp*.5 and not phase_two:phase_two=true;game.sound("boss_roar",position);game.toast("督工进入狂暴 · 连续冲锋" if kind=="minotaur" else "典刑机过载 · 链钩与冲击波" if kind=="boss" else "首领过载 · 连射与突进强化",3)
	if hit_pause>0:hit_pause=maxf(0,hit_pause-dt);return
	clock+=dt;cooldown=maxf(0,cooldown-dt);hit_flash=maxf(0,hit_flash-dt)
	var p: CharacterBody3D=game.player;var diff:=p.position-position;var same:=absf(diff.y)<1.6
	if flying():position.y=lerpf(position.y,origin.y+sin(clock*1.5)*.3,dt*4);velocity.y=0
	else:velocity.y-=30*dt
	sense_clock-=dt
	if sense_clock<=0:
		sense_clock=.12
		var query:=PhysicsRayQueryParameters3D.create(position+Vector3(0,1,0),p.position+Vector3(0,1,0),1)
		line_clear=get_world_3d().direct_space_state.intersect_ray(query).is_empty()
	var clear:=line_clear
	if state=="patrol" and absf(diff.x)<(14 if ranged() or boss() else 8) and (same or flying()) and clear and (kind!="human" or diff.x*facing>0 or absf(diff.x)<(1.1 if p.crouching else 2.7)):
		state="chase";clock=0
	if state=="stunned":
		velocity.x=move_toward(velocity.x,0,20*dt)
		if clock>stun_duration:state="chase";clock=0
	elif state=="windup":
		velocity.x=0;visual.rotation.z=-.12*facing*minf(clock/windup,1)
		if clock>=windup:state="strike";clock=0;attack_done=false;game.sound("boss_charge" if pattern=="冲锋" else "enemy_fire" if ranged() else "whoosh_heavy",position)
	elif state=="strike":
		velocity.x=facing*(10 if pattern in ["冲锋","复写突进"] else 7 if kind=="hound" else 0)
		visual.rotation.z=facing*.22*sin(minf(clock/.35,1)*PI)
		if not attack_done and clock>.1:
			attack_done=true
			if kind in ["mother","witch","lord","editor"] or definition.get("extended",false):strike_extended(diff,same)
			elif ranged() or pattern=="链钩":game.fire_projectile(position+Vector3(facing*.65,1.0,0),facing,18 if boss() else 12,false,self);game.sound("grapple_launch" if pattern=="链钩" else "enemy_fire",position)
			elif pattern=="震地":
				for direction in [-1.0,1.0]:game.fire_projectile(position+Vector3(direction*.8,.32,0),direction,22,false,self)
				game.sound("shockwave",position);game.spawn_dust(position,2.5);game.camera_impact=.2
			else:
				if boss():game.sound("boss_smash",position)
				if same and absf(diff.x)<(3.0 if boss() else 1.8):game.damage_player(26 if boss() else 14,facing,self)
		if pattern in ["冲锋","复写突进"] and same and absf(diff.x)<1.9:game.damage_player(24,facing,self)
		if clock>(.75 if pattern in ["冲锋","复写突进"] else .35):state="recover";clock=0
	elif state=="recover":
		velocity.x=0
		if clock>(.7 if boss() else .4):state="chase";clock=0;cooldown=.3 if phase_two else .6
	elif state=="chase":
		if same or ranged():
			facing=signf(diff.x) if absf(diff.x)>.1 else facing
			var reach:=11.0 if ranged() else 8.0 if kind=="boss" and (attacks+1)%3==1 else 8.0 if kind=="minotaur" and ((attacks+1)%3==0 or phase_two and (attacks+1)%2==0) else 9.0 if kind in ["mother","witch","lord","editor"] or definition.get("extended",false) else 3.0 if boss() else 1.6
			velocity.x=0 if ranged() else facing*(2.5 if boss() else 3.2) if absf(diff.x)>reach else 0
			if absf(diff.x)<reach and cooldown<=0 and clear:
				attacks+=1;pattern="弩射" if ranged() else "落锤" if boss() else "近击"
				if boss():pattern=["冲锋","落锤","震地"][attacks%3] if kind=="minotaur" else ["落锤","链钩","震地" if phase_two else "落锤"][attacks%3]
				if kind=="minotaur" and phase_two and attacks%2==0:pattern="冲锋"
				if kind in ["mother","witch","lord","editor"] or definition.get("extended",false):
					var choices: Array=definition.patterns.duplicate();choices.erase(last_pattern)
					pattern=choices[attacks%choices.size()];last_pattern=pattern
				windup=.9 if boss() else .65 if ranged() else .45;state="windup";clock=0;game.sound("enemy_windup",position)
		else:velocity.x=0
	else:
		if absf(position.x-origin.x)>2:facing=-signf(position.x-origin.x)
		velocity.x=facing*.8 if kind in ["human","hound","thorn","blood_guard"] else 0
	edge_clock-=dt
	if not flying() and is_on_floor() and absf(velocity.x)>.1:
		if edge_clock<=0:
			edge_clock=.12
			var next:=position+Vector3(signf(velocity.x)*.7,.3,0)
			var foot:=PhysicsRayQueryParameters3D.create(next,next+Vector3(0,-1.5,0),1)
			edge_safe=not get_world_3d().direct_space_state.intersect_ray(foot).is_empty()
		if not edge_safe:velocity.x=0;facing=-facing
	move_and_slide()
	if position.y < -3:position=origin;velocity=Vector3.ZERO
	if animator:
		visual.rotation.y=facing*PI/2
		var name: String="BowShot" if ranged() and state in ["windup","strike"] else "Heavy" if state in ["windup","strike"] else "Hurt" if state=="stunned" else "PassageWalk"
		if animator.current_animation!=name:animator.play(name,.1)
	else:visual.rotation.y=0 if facing>0 else PI
	for i in legs.size():legs[i].rotation.z=.18*sin(clock*12+i*PI) if absf(velocity.x)>.1 else 0
	visual.scale=Vector3.ONE*(1.03 if hit_flash>0 else 1)

func can_assassinate() -> bool:
	var p: CharacterBody3D=game.player
	if not definition.get("human",false) or hp<=0 or state!="patrol":return false
	if absf(p.position.x-position.x)>1.3 or (p.position.x-position.x)*facing>=0 or absf(p.position.y-position.y)>.4:return false
	var ray:=PhysicsRayQueryParameters3D.create(p.position+Vector3(0,1,0),position+Vector3(0,1,0),1)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func hurt(amount: float,force: float,break_power: float=10,tier: String="",attacker: Node=null) -> void:
	if hp<=0:return
	if definition.get("shield",false) and force*facing<0 and state!="stunned" and amount<900:amount*=.30;game.sound("guard",position)
	if tier.is_empty():tier=Tuning.tier_for_damage(amount)
	hp=maxf(0,hp-amount);posture+=break_power;hit_flash=.15
	var profile: Dictionary=game.feedback.impact(self,force,tier,attacker)
	if hp<=0:
		game.inventory.loot(kind,uid)
		if not game.defeated.has(uid):
			game.scrap+=60 if boss() else 8
			game.flags.kill_progress=int(game.flags.get("kill_progress",0))+1
			if int(game.flags.kill_progress)%4==0:game.skill_points+=1
		game.defeated[uid]=true
		if boss():
			if not game.flags.get(definition.flag,false):game.skill_points+=3
			game.flags[definition.flag]=true
			game.show_story("牛头督工倒下，总井图纸的转运锁解除了。" if kind=="minotaur" else "典刑机的链条停了。去出货厅找转运表。" if kind=="boss" else "首领已击败，区域联锁解除。
继续沿右门前进；左门可返回寻找证物与同伴。")
		game.save_game();queue_free()
	elif not boss() or posture>=80:
		posture=0;enter_stun(float(profile.get("stun",.45)));velocity.x=force*float(profile.get("knockback",2.0))

func enter_stun(duration: float) -> void:
	state="stunned";clock=0;stun_duration=duration;velocity.x=0
	if animator and animator.has_animation("Hurt"):animator.play("Hurt",0);animator.advance(0)

func strike_extended(diff: Vector3, same: bool) -> void:
	if pattern in ["冲锋","复写突进"]:
		game.sound("boss_charge",position);return
	var wave: bool=pattern in ["震地","毒潮","血潮","裁稿波"]
	if wave:
		for direction in [-1.0,1.0]:game.fire_projectile(position+Vector3(direction*.8,.38,0),direction,24,false,self)
		game.sound("shockwave",position);game.spawn_dust(position,2.5);game.camera_impact=.18
	else:
		var shots: int=3 if phase_two else 1
		for i in range(shots):
			var shot:=preload("res://scripts/projectile.gd").new();shot.game=game;shot.position=position+Vector3(facing*.8,1.0,0);shot.direction=facing;shot.damage=20;shot.source=self
			shot.travel=(game.player.position+Vector3(0,.9,0)-shot.position).normalized().rotated(Vector3.FORWARD,(i-(shots-1)*.5)*.15);shot.speed=10;game.world.add_child(shot)
		game.sound("enemy_fire",position)
	if same and absf(diff.x)<2.5:game.damage_player(20,facing,self)
