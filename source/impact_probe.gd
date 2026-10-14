extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var report: String="res://qa/impact_before_v101.json"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
 var g: Node3D=load("res://scenes/main.tscn").instantiate();g.qa_mode=true;g.external_qa=true;g.save_path="user://impact_probe.json";root.add_child(g)
 g.new_game();g.load_room(11);g.set_screen("play");g.player.position=Vector3(6.5,.04,0);g.player.velocity=Vector3.ZERO;g.player.facing=1
 var enemy: Node=g.Enemy.new();enemy.game=g;enemy.kind="human";enemy.position=Vector3(8,0,0);enemy.uid="probe";g.world.add_child(enemy);g.enemies.append(enemy);enemy.hp=1000;enemy.max_hp=1000;enemy.state="recover";enemy.clock=-20
 await create_timer(.2).timeout;g.player.begin_attack(false)
 var deadline:=Time.get_ticks_msec()+1000
 while enemy.hp==1000 and Time.get_ticks_msec()<deadline:await physics_frame;await process_frame
 var result: Dictionary={"version":g.Content.VERSION,"hit":enemy.hp<1000,"logical_contact_seconds":g.player.attack_total-g.player.attack_clock,"animation_contact_fraction":g.player.animator.current_animation_position/g.player.animator.get_animation(g.player.attack_clip).length}
 await create_timer(.5).timeout
 enemy.position=Vector3(8,0,0);enemy.hit_pause=0;enemy.hurt(50,1,35,"heavy",g.player);var start: float=enemy.position.x
 await create_timer(.55).timeout;result.heavy_displacement=enemy.position.x-start
 enemy.hurt(9999,1,90,"critical",g.player);await process_frame;await process_frame;result.kill_visual_visible=is_instance_valid(enemy) and enemy.is_visible_in_tree()
 var file:=FileAccess.open(report,FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close();print("IMPACT_PROBE ",result)
 g.audio_system.halt();await create_timer(.15).timeout;quit()
