extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var report: String="res://qa/window_after_v102.json"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
 var g: Node3D=load("res://scenes/main.tscn").instantiate();g.qa_mode=true;g.external_qa=true;g.save_path="user://window_probe.json";root.add_child(g);g.new_game();g.load_room(11);g.set_screen("play")
 g.player.position=Vector3(6.5,.04,0);g.player.velocity=Vector3.ZERO;g.player.facing=1
 var e: Node=g.Enemy.new();e.game=g;e.kind="human";e.position=Vector3(10,0,0);g.world.add_child(e);g.enemies.append(e);e.set_physics_process(false);e.hp=1000;e.max_hp=1000
 await create_timer(.15).timeout;g.player.begin_attack(false)
 while not g.player.attack_hit:await physics_frame
 var before: float=e.hp;e.position=Vector3(7.7,0,0);await create_timer(.30).timeout
 var result: Dictionary={"version":g.Content.VERSION,"late_entry_damage":before-e.hp,"late_entry_during_active_window":true}
 var f:=FileAccess.open(report,FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close();print("WINDOW_PROBE ",result)
 g.audio_system.halt();await create_timer(.15).timeout;quit()
