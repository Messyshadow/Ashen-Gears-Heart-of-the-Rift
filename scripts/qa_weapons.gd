extends RefCounted
var game: Node3D
var checks: Array=[]
func check(ok: bool,name: String) -> void:
	checks.append({"pass":ok,"check":name,"state":game.player.snapshot()});print("PASS " if ok else "FAIL ",name)
func wait(t: float) -> void:await game.get_tree().create_timer(t).timeout
func drive(action: String,t: float=.03) -> void:
	Input.action_press(action);await wait(t);Input.action_release(action);await game.get_tree().physics_frame
func weapon_key() -> void:
	var event:=InputEventKey.new();event.physical_keycode=KEY_V;event.keycode=KEY_V;event.pressed=true
	Input.parse_input_event(event);await wait(.03);event.pressed=false;Input.parse_input_event(event);await wait(.03)
func capture(path: String,name: String) -> void:
	if path.is_empty():return
	await RenderingServer.frame_post_draw;game.get_viewport().get_texture().get_image().save_png(path.path_join(name+".png"))
func idle() -> void:
	game.player.attack_clock=0;game.player.hurt_clock=0;game.player.combo=0;game.player.combo_clock=0;game.player.queued_attack=false;game.player.stamina=100;game.hitstop=0
func run(app: Node3D,path: String) -> Array:
	game=app;game.new_game();game.set_screen("play");await wait(.2)
	check(game.weapons=={"dagger":true} and game.equipped_weapon=="dagger" and game.player.visual.name!="","新游戏只持有开局匕首")
	var chest: Dictionary={}
	for prop in game.props:
		if prop.kind=="katana_chest":chest=prop
	check(not chest.is_empty() and chest.p.y==0 and chest.p.x < -10,"太刀补给宝箱位于煤仓地面安全入口")
	game.player.position=chest.p+Vector3(-.6,0,0);await wait(.2);game.update_nearest()
	check(game.nearest.get("kind","")=="katana_chest","入口宝箱进入真实交互范围")
	game.interact();await wait(.1)
	check(game.weapons.get("katana",false) and game.equipped_weapon=="katana" and game.opened.has(chest.uid),"E 开箱获得并装备太刀且即时记录")
	check(game.player.visual.find_child("Grey_steel_katana_blade",true,false)!=null or game.player.visual.find_child("Grey steel katana blade",true,false)!=null,"Blender 太刀模型作为骨骼装备载入")
	game.overview=false;await wait(.3);await capture(path,"14_katana")
	var opened: Dictionary=game.opened.duplicate();var scrap: int=game.scrap;game.nearest=chest;game.interact()
	check(game.opened==opened and game.scrap==scrap,"太刀宝箱不可重复领取")
	game.load_room(0);game.set_screen("play");await wait(.2)
	var found:=false
	for prop in game.props:
		if prop.kind=="katana_chest":found=true
	check(not found and game.equipped_weapon=="katana","重访不刷新已领太刀宝箱")
	await weapon_key();check(game.equipped_weapon=="dagger","V 真实键盘事件切回匕首")
	await weapon_key();check(game.equipped_weapon=="katana","V 切回太刀保留所有权")
	var enemy: Node=game.enemies[0];enemy.set_physics_process(false);enemy.hp=500;enemy.max_hp=500;enemy.position=Vector3(12.7,0,0)
	game.player.position=Vector3(10,0,0);game.player.velocity=Vector3.ZERO;game.player.facing=1;await wait(.2)
	game.equip_weapon("dagger");idle();await drive("light");var dagger_total: float=game.player.attack_total;await wait(.4)
	check(enemy.hp==500,"匕首短距离无法命中 2.7 米处目标")
	game.equip_weapon("katana");idle();await drive("light");await wait(.07)
	check(game.player.attack_clip=="Katana1" and enemy.hp==500 and game.player.attack_total>dagger_total,"太刀独立首斩更慢且前摇不提前造成伤害")
	await wait(.2);check(enemy.hp==472,"太刀有效帧实际命中更远目标并造成首斩伤害")
	await drive("light");await wait(.3)
	check(game.player.attack_clip=="Katana2","太刀轻击缓冲衔接第二段上挑")
	await drive("light");await wait(.55)
	check(game.player.attack_clip=="Katana3","太刀轻击缓冲衔接第三段重斩")
	await wait(.7);idle();await drive("heavy");await wait(.1)
	check(game.player.attack_clip=="KatanaHeavy" and game.player.attack_reach>3.6 and game.player.stamina<=76,"太刀独立重劈、长攻击距离与 24 耐力消耗")
	var weapon: String=game.equipped_weapon;await weapon_key();check(game.equipped_weapon==weapon,"攻击收招前禁止换武器取消硬直")
	await wait(.5);check(enemy.hp<408,"太刀重劈有效帧造成实际伤害")
	await wait(.5);idle();game.player.stamina=7;await drive("light");check(game.player.attack_clock<=0,"太刀耐力不足不会出刀或排入连击")
	idle();enemy.position=Vector3(-8,0,0);game.player.position=Vector3(10,0,0);game.player.velocity=Vector3.ZERO;await wait(.25)
	var points: int=game.skill_points;var mp: float=game.magic
	await drive("jump",.08);await wait(.2);var first_speed: float=game.player.velocity.y
	await drive("jump");await wait(.05)
	check(game.player.double_jumps==1 and game.player.air_jump_used and game.player.velocity.y>first_speed+4 and game.player.velocity.y>5 and game.player.current_clip=="DoubleJump","初始二段跳真实第二次输入抬升并播放独立动作")
	check(game.skill_points==points and game.magic==mp and game.learned.is_empty(),"二段跳无需学习且不消耗技能点或魔力")
	await capture(path,"15_double_jump")
	var jumps: int=game.player.double_jumps;await weapon_key();check(game.player.air_jump_used and game.player.double_jumps==jumps,"空中换武器保留二段跳使用状态")
	game.flags.rescued=true;game.switch_cooldown=0;game.switch_actor(1)
	check(game.active_slot==1 and game.player.air_jump_used and game.player.animator.has_animation("DoubleJump"),"空中切角色不刷新二段跳且同伴具有该动作")
	await drive("jump");check(game.player.double_jumps==jumps,"第三次空中跳跃输入不会产生无限跳")
	await wait(1.4);check(game.player.is_on_floor() and not game.player.air_jump_used,"真实落地恢复一次额外空中跳跃")
	await drive("jump",.06);await wait(.06);await drive("jump");check(game.player.double_jumps==jumps+1,"落地后的同伴再次正常使用二段跳")
	await wait(1.5);game.switch_cooldown=0;game.switch_actor(0);game.equip_weapon("katana");game.save_game()
	game.equip_weapon("dagger");game.weapons={"dagger":true};game.load_game();game.set_screen("play")
	check(game.weapons.get("katana",false) and game.equipped_weapon=="katana" and game.flags.get("rescued",false),"继续游戏恢复太刀、装备选择与旧同伴进度")
	# Simulate a schema-1 save from 0.4.2: no weapon fields, upper iron chest already claimed.
	var legacy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	legacy.erase("weapons");legacy.erase("equipped_weapon");legacy.opened.erase("R01-01:katana_chest");legacy.opened["R01-01:chest"]=true
	legacy.erase("party");legacy.party_hp=legacy.party_hp.slice(0,3)
	legacy.flags.boss2=true;var file:=FileAccess.open(game.save_path,FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
	game.load_game();game.set_screen("play");await wait(.2);found=false
	for prop in game.props:
		if prop.kind=="katana_chest":found=true
	check(game.equipped_weapon=="dagger" and game.weapons.get("dagger",false) and game.flags.get("boss2",false) and found,"旧存档默认匕首、保留 Boss 进度并可补领新太刀宝箱")
	check(game.player.animator.has_animation("DoubleJump"),"旧存档无需重开就具有初始二段跳")
	check(game.party_hp.size()==17 and game.party==[0,1],"旧三人 HP 存档兼容升级到完整名册")
	var clips_ok:=true
	for clip in ["Katana1","Katana2","Katana3","KatanaHeavy"]:
		if not game.player.animator.has_animation(clip):clips_ok=false
	check(clips_ok,"四个太刀动作均为 Blender 导出的独立骨骼动画")
	var report:=FileAccess.open(path.get_base_dir().path_join("weapons_runtime.json") if not path.is_empty() else "user://weapons_runtime.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"version":"0.4.3","checks":checks},"  "));report.close()
	return checks
