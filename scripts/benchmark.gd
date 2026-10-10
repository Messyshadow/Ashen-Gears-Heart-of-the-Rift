extends SceneTree
var game: Node3D
var report_path := "res://qa/performance_baseline.json"
var profile := "baseline"
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):report_path=arg.trim_prefix("--report=")
		if arg.begins_with("--profile="):profile=arg.trim_prefix("--profile=")
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://benchmark_save.json";root.add_child(game)
	game.qa_mode=true;game.audio_system.config_path="user://benchmark_audio.cfg"
	if game.get("graphics")!=null:game.graphics.set_quality(profile if profile!="baseline" else "high",false)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED);DisplayServer.window_set_size(Vector2i(1920,1080));DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
	var records: Array=[]
	for room in [2,9,15,19,27,35,43,48,56,64,72,80,88,96]:
		var start:=Time.get_ticks_usec();game.load_room(room);game.set_screen("play");game.player.position=Vector3(-8,0,0)
		var load_ms: float=(Time.get_ticks_usec()-start)/1000.0
		await create_timer(1.5).timeout
		var frames: Array[float]=[];var draws: Array[float]=[];var objects: Array[float]=[];var previous:=Time.get_ticks_usec()
		Input.action_press("right")
		for i in range(240):
			await process_frame
			var now:=Time.get_ticks_usec();frames.append((now-previous)/1000.0);previous=now
			draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME));objects.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
			if i==90:Input.action_release("right");Input.action_press("left")
			if i==180:Input.action_release("left")
		Input.action_release("right");Input.action_release("left");frames.sort()
		var total:=0.0;var draw_total:=0.0;var object_total:=0.0
		for value in frames:total+=value
		for value in draws:draw_total+=value
		for value in objects:object_total+=value
		records.append({"room":room,"mean_frame_ms":total/frames.size(),"p95_frame_ms":frames[int(frames.size()*.95)],"average_fps":1000.0/(total/frames.size()),"draw_calls":draw_total/draws.size(),"visible_objects":object_total/objects.size(),"room_build_ms":load_ms,"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
		print("BENCH ",profile," ",records[-1])
	var report={"version":game.Content.VERSION,"profile":profile,"gpu":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"resolution":"1920x1080","vsync":false,"fps_limit":0,"frames_per_room":240,"records":records,"note":"Measured on this GPU; does not certify GTX 1060 or integrated GPU FPS. Room build includes instantiation, not all driver shader compilation."}
	var file:=FileAccess.open(report_path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	game.audio_system.halt();await create_timer(.15).timeout;quit()
