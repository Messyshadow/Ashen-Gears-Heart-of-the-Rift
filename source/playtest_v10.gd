extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game: Node3D=load("res://scenes/main.tscn").instantiate();game.qa_mode=true;game.external_qa=true;game.save_path="user://v10_isolated.json";root.add_child(game)
 await create_timer(.5).timeout
 var checks: Array=await preload("res://scripts/qa_v10.gd").new().run(game,"res://qa/v10_screenshots")
 var failures:=0
 for c in checks:
  if not c.pass:failures+=1
 var file:=FileAccess.open("res://qa/v10_editor_runtime.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "));file.close()
 print("V10_QUICK_FINISHED ",checks.size()," ",failures);game.audio_system.halt();await create_timer(.2).timeout;quit(failures)
