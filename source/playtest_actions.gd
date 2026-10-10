extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game: Node3D=load("res://scenes/main.tscn").instantiate();game.save_path="user://action_playtest.json";root.add_child(game);game.qa_mode=true
	var checks: Array=await preload("res://scripts/qa_actions.gd").new().run(game,"res://qa/action_screenshots")
	var failures:=0
	for item in checks:
		if not item.pass:failures+=1
	print("ACTION_QA_FINISHED ",checks.size()," checks, ",failures," failures")
	game.audio_system.halt();await create_timer(.15).timeout;quit(1 if failures else 0)
