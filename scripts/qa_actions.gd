extends RefCounted
var game: Node3D
var checks: Array=[]
func wait(seconds: float) -> void:await game.get_tree().create_timer(seconds).timeout
func step() -> void:await game.get_tree().physics_frame;await game.get_tree().process_frame
func check(ok: bool,label: String,detail: Variant=null) -> void:
	checks.append({"pass":ok,"check":label,"detail":detail});print("PASS " if ok else "FAIL ",label," ",detail)
func release_all() -> void:
	for action in ["left","right","up","down","jump","light","heavy","dodge","guard","modifier"]:Input.action_release(action)
func target(kind: String="human",p: Vector3=Vector3(8,0,0)) -> Node:
	var enemy: Node=game.Enemy.new();enemy.game=game;enemy.kind=kind;enemy.position=p;game.world.add_child(enemy);game.enemies.append(enemy);enemy.hp=1000;enemy.max_hp=1000;enemy.state="recover";enemy.clock=-20;return enemy
func idle(p: Vector3=Vector3(-12,.04,0)) -> void:
	release_all();game.player.position=p;game.player.velocity=Vector3.ZERO;game.player.attack_clock=0;game.player.hurt_clock=0;game.player.hit_pause=0;game.player.stamina=100;game.player.clear_action_buffer();game.player.buffer=0;game.player.dodge_clock=0;game.player.dash_clock=0;game.player.slamming=false;game.player.motion="ground";game.player.air_jump_used=false;game.player.coyote=0;game.player.combo=0;game.player.combo_clock=0;game.player.guarding=false
func press(action: String,seconds: float=.03) -> void:Input.action_press(action);await wait(seconds);Input.action_release(action)
func jump_apex(held: float) -> float:
	idle();await wait(.12);Input.action_press("jump");var began: float=game.main_clock;var apex:=0.0
	while game.main_clock-began<.9:
		if game.main_clock-began>=held:Input.action_release("jump")
		apex=maxf(apex,game.player.position.y);await step()
	Input.action_release("jump");return apex
func run(app: Node3D,directory: String="") -> Array:
	game=app;game.new_game();game.load_room(11);game.set_screen("play");game.overview=false;idle(Vector3(6.5,.04,0));await wait(.15)
	var enemy: Node=target();var bystander: Node=target("human",Vector3(16,0,0));await wait(.2)
	var shot: Node=preload("res://scripts/projectile.gd").new();shot.game=game;shot.position=Vector3(-15,2.5,0);shot.speed=2;game.world.add_child(shot)
	game.player.facing=1;game.player.begin_attack(false)
	var deadline: float=game.main_clock+.8
	while enemy.hp==1000 and game.main_clock<deadline:await step()
	var animation_before: float=game.player.animator.current_animation_position;var attack_before: float=game.player.attack_clock;var victim_clock: float=enemy.clock;var other_clock: float=bystander.clock;var shot_x: float=shot.position.x
	await step()
	check(enemy.hp<1000 and game.player.hit_pause>0 and enemy.hit_pause>0,"真实近战命中同时启动双方局部顿帧",game.feedback.last_event)
	check(is_equal_approx(game.player.attack_clock,attack_before) and absf(game.player.animator.current_animation_position-animation_before)<.001 and is_equal_approx(enemy.clock,victim_clock),"顿帧同时冻结攻击逻辑与骨骼动画")
	check(bystander.clock>other_clock and shot.position.x>shot_x and game.hitstop==0 and Engine.time_scale==1,"旁观敌人、弹道与全局时间持续推进")
	check(not enemy.visual.find_children("*","MeshInstance3D",true,false).filter(func(mesh):return mesh.material_overlay!=null).is_empty(),"闪白覆盖材质实际接入，原 PBR 材质保留")
	var body: Vector3=enemy.position;var visual_base: Vector3=game.feedback.targets[enemy.get_instance_id()].base;await game.get_tree().process_frame
	check(enemy.position==body and enemy.visual.position.distance_to(visual_base)>0,"受击微抖只影响模型，顿帧期间碰撞位置不动")
	await wait(.22)
	check(enemy.visual.find_children("*","MeshInstance3D",true,false).all(func(mesh):return mesh.material_overlay==null),"闪白结束恢复原材质，无残留覆盖")
	if not directory.is_empty():
		game.player.attack_clock=0;game.player.stamina=100;game.player.begin_attack(true);var old_hp: float=enemy.hp;deadline=game.main_clock+.9
		while enemy.hp==old_hp and game.main_clock<deadline:await step()
		DirAccess.make_dir_recursive_absolute(directory);await RenderingServer.frame_post_draw;game.get_viewport().get_texture().get_image().save_png(directory.path_join("00_local_hit.png"));await wait(.2)
	game.feedback.targets[enemy.get_instance_id()].last=-10
	game.feedback.impact(enemy,1,"light",game.player);var light_stop: float=game.feedback.last_event.duration
	game.feedback.targets[enemy.get_instance_id()].last=-10;game.feedback.impact(enemy,1,"heavy",game.player);var heavy_stop: float=game.feedback.last_event.duration
	check(heavy_stop>light_stop and game.feedback.last_event.particles>7,"重击相对轻击有更长顿帧及更多定向火花",{"light":light_stop,"heavy":heavy_stop})
	game.feedback.impact(enemy,1,"heavy",game.player);var repeated: float=game.feedback.last_event.duration
	check(repeated<heavy_stop and enemy.hit_pause<=.12,"连续命中缩短顿帧，时长取最大值不累加",repeated)
	for i in range(6):game.feedback.impact(enemy,1,"critical",game.player)
	check(game.feedback.trauma<=.8 and game.feedback.camera_offset().length()<.3 and game.feedback.zoom_factor()>.98,"叠加震屏与缩放受上限约束",game.feedback.trauma)
	check(game.dusts[-1].velocity.x>0 and game.dusts[-1].node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"火花沿实际攻击方向运动且不投影")
	await wait(.65);check(game.particle_pool.size()>0,"高频火花结束后进入复用池")
	var pool_size: int=game.particle_pool.size();game.spawn_sparks(Vector3.ZERO,true);check(game.particle_pool.size()==pool_size-7,"下一次命中复用已有七个粒子实例")
	enemy.position=Vector3(18,0,0);bystander.position=Vector3(19,0,0);idle();await wait(.15)
	game.player.begin_attack(true);await wait(.04);await press("light");await wait(1.05)
	check(game.player.attack_clock<=0 and game.player.pending_action.is_empty(),"过早输入超过缓冲有效期，不在重击结束后幽灵出刀")
	idle();await wait(.1);game.player.begin_attack(false);await wait(.11);game.player.hit_pause=.06;game.player.animator.speed_scale=0;await press("light");await wait(.2)
	check(game.player.attack_clip=="Dagger2" and game.player.attack_clock>0,"顿帧期间的真实轻击输入保留并在连招窗口衔接",game.player.snapshot())
	idle();await wait(.12);game.player.begin_attack(false);await wait(.025);await press("dodge");await wait(.2)
	check(game.player.dodge_clock<=0,"攻击前摇不能用翻滚取消尚未发生的命中")
	await wait(.2);idle();await wait(.1);game.player.begin_attack(false);await wait(.28);await press("dodge")
	check(game.player.dodge_clock>0 and game.player.attack_clock<=0,"轻击收招允许有限翻滚取消并关闭攻击状态")
	idle();await wait(.1);game.player.begin_attack(true);await press("light");game.player.invulnerable=0;game.player.receive_damage(14,-1,bystander);await wait(.55)
	check(game.player.attack_clock<=0 and game.player.pending_action.is_empty() and game.player.current_clip!="Dagger1","受击硬切动作并清掉旧连招，不补发攻击")
	idle();game.player.dash_clock=.19;game.player.extra_hits=[.3,.5];game.player.spell="bone";game.player.pending_action="heavy";game.player.pending_action_clock=.2;game.player.invulnerable=0;game.environment_damage(10)
	check(game.player.dash_clock<=0 and game.player.extra_hits.is_empty() and game.player.spell.is_empty() and game.player.pending_action.is_empty() and game.player.current_clip=="Hurt","环境受伤中断冲刺和多段招式，恢复后不会续冲或补发飞刃")
	await wait(.35)
	game.player.pending_action="light";game.player.pending_action_clock=.2;game.set_screen("pause");check(game.player.pending_action.is_empty(),"打开菜单清除待执行动作，恢复游戏不会幽灵出刀");game.set_screen("play")
	var short_apex: float=await jump_apex(.03);var held_apex: float=await jump_apex(.35)
	check(held_apex>short_apex+.3,"短按与长按跳跃产生不同实测高度",{"short":short_apex,"held":held_apex})
	idle(Vector3(-12,.18,0));game.player.velocity.y=-5;game.player.air_jump_used=true;game.player.move_and_slide();var double_before: int=game.player.double_jumps;await press("jump",.018);await wait(.09)
	check(game.player.velocity.y>4 and game.player.double_jumps==double_before,"提前落地按跳在接地后起跳，不额外刷新二段跳")
	await wait(1.0);idle()
	var floor:=StaticBody3D.new();floor.collision_layer=1;var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(2,.3,2);shape.shape=box;floor.add_child(shape);floor.position=Vector3(-18,3,0);game.world.add_child(floor)
	idle(Vector3(-17.3,3.2,0));await wait(.18);Input.action_press("right");var edge_deadline: float=game.main_clock+.6
	while game.player.is_on_floor() and game.main_clock<edge_deadline:await step()
	var edge_state: Dictionary=game.player.snapshot();edge_state.coyote=game.player.coyote
	await press("jump",.04);Input.action_release("right")
	check(not edge_state.floor and game.player.velocity.y>8 and not game.player.air_jump_used,"离开真实支撑台后土狼时间仍可起跳，并保留二段跳",{"edge":edge_state,"jump":game.player.snapshot()})
	floor.queue_free();idle();await wait(.15)
	var boss: Node=target("mother",Vector3(15,0,0));boss.state="windup";boss.clock=0;boss.hurt(5,1,12,"light",game.player)
	check(boss.state=="windup","首领低破势命中保留霸体与已承诺招式")
	boss.hurt(5,1,80,"heavy",game.player);check(boss.state=="stunned","足够破势可以打断首领并开放惩罚窗口")
	await wait(.25);idle();game.player.invulnerable=0;game.player.guarding=true;game.player.guard_clock=.05;game.player.facing=1;var hp: float=game.party_hp[0];game.player.receive_damage(20,-1,boss)
	check(game.party_hp[0]==hp and boss.state=="stunned" and game.feedback.last_event.tier=="parry","完美弹反无伤、中断、蓝色火花与独立反馈同步")
	game.load_room(11);game.set_screen("play");await wait(.15)
	check(game.feedback.targets.values().all(func(item):return is_instance_valid(item.actor.get_ref())),"换房清理反馈引用与粒子池，不持有旧角色")
	release_all()
	var failures:=0
	for item in checks:
		if not item.pass:failures+=1
	var out:=FileAccess.open("res://qa/actions_runtime_v061.json" if not OS.has_feature("standalone") else directory.get_base_dir().path_join("actions_runtime_v061.json"),FileAccess.WRITE)
	if out:out.store_string(JSON.stringify({"version":"0.6.1","checks":checks,"failures":failures,"input":"Real Godot input actions, fixed physics and rendered EXE; no human/controller playtest"},"  "));out.close()
	return checks
