extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var g: Node3D=load("res://scenes/main.tscn").instantiate();g.qa_mode=true;g.external_qa=true;g.save_path="user://combat102.json";root.add_child(g)
 var checks: Array=await preload("res://scripts/qa_actions.gd").new().run(g,"res://qa/action_screenshots")
 checks.append_array(await preload("res://scripts/qa_impact_v101.gd").new().run(g,"res://qa/action_screenshots"))
 checks.append_array(await preload("res://scripts/qa_combat_v102.gd").new().run(g))
 var failures:=0
 for c in checks:
  if not c.pass:failures+=1
 var f:=FileAccess.open("res://qa/combat_editor_v102.json",FileAccess.WRITE);f.store_string(JSON.stringify({"version":g.Content.VERSION,"checks":checks,"failures":failures},"  "));f.close()
 print("COMBAT_102_FINISHED ",checks.size()," ",failures);g.audio_system.halt();await create_timer(.15).timeout;quit(failures)
