extends RefCounted
var game: Node3D
var checks: Array=[]
func check(ok: bool,name: String) -> void:checks.append({"pass":ok,"check":name});print("PASS " if ok else "FAIL ",name)
func wait(t: float) -> void:await game.get_tree().create_timer(t).timeout
func capture(path: String,name: String) -> void:
	if path.is_empty():return
	await RenderingServer.frame_post_draw;game.get_viewport().get_texture().get_image().save_png(path.path_join(name+".png"))
func run(app: Node3D,path: String) -> Array:
	game=app;var gfx: Node=game.graphics;var original: Dictionary=gfx.settings.duplicate(true)
	check(gfx.defaults().resolution==0 and gfx.defaults().mode==1,"首次启动默认全屏原生分辨率")
	check(gfx.config_path.contains("qa_"),"画面验收使用独立设置文件")
	gfx.set_quality("high",false);await wait(.3)
	var forward: bool=RenderingServer.get_current_rendering_method()=="forward_plus"
	check(game.environment.glow_enabled==forward and game.environment.ssao_enabled==forward and game.sun.shadow_enabled and game.get_viewport().msaa_3d==Viewport.MSAA_4X,"高档保留阴影环境遮蔽辉光与4倍抗锯齿")
	check(game.world_builder.batched_instances>0 and game.world_builder.batches>0,"重复静态部件以 MultiMesh 合批")
	gfx.set_quality("low",false);check(not game.environment.ssao_enabled and not game.sun.shadow_enabled and game.get_viewport().scaling_3d_scale<=.671,"低档采用较低渲染比例与可选光影取舍")
	game.dusts.clear();game.particles(game.player.position,1,Color(.8,.1,.1));check(game.dusts.size()==7,"低档仍保留每次完整七粒战斗特效")
	var distant_visible:=true
	for node in game.world.get_children():
		if node is GeometryInstance3D and node.get_meta("distant_decor",false) and not node.visible:distant_visible=false
	check(distant_visible,"低档没有删除远景建筑或场景几何")
	gfx.set_quality("medium",false);check(game.get_viewport().msaa_3d==Viewport.MSAA_DISABLED and game.get_viewport().screen_space_aa==Viewport.SCREEN_SPACE_AA_FXAA and game.sun.shadow_enabled,"中档使用 FXAA 并保留动态阴影")
	var values: Dictionary=gfx.settings.duplicate(true);values.mode=0;values.resolution=1;values.fps=30;values.vsync=false
	gfx.begin_apply(values);await wait(.25);check(Engine.max_fps==30 and DisplayServer.window_get_vsync_mode()==DisplayServer.VSYNC_DISABLED and game.screen=="graphics_confirm","分辨率帧率与垂直同步应用进入确认画面")
	gfx.confirmation_time=.05;await wait(.2);check(game.screen=="graphics" and gfx.settings.fps!=30,"显示设置确认超时自动恢复")
	gfx.begin_apply(values);gfx.confirm();gfx.settings.fps=144;gfx.load_settings();check(gfx.settings.fps==30,"确认后的画面设置保存并恢复")
	gfx.settings=original.duplicate(true);gfx.settings.mode=0;gfx.settings.resolution=2;gfx.apply_settings();gfx.save_settings();game.open_graphics();await wait(.3)
	check(game.ui.graphics_controls.size()==8,"画面菜单显示八项可操作设置")
	await capture(path,"12_graphics")
	game.flags.boss2=true;game.load_room(16);game.set_screen("play");game.player.position=Vector3(19.4,4.02,0);game.player.velocity=Vector3.ZERO;await wait(.2)
	Input.action_press("right");await wait(.2);Input.action_release("right")
	check(game.room==16 and game.screen=="chapter_complete" and game.flags.get("slice_complete",false),"第二章终点显示完成界面且不自动回到原点")
	await capture(path,"13_chapter_complete")
	game.chapter_return(11);check(game.room==11 and game.screen=="play" and game.flags.get("boss2",false),"主动回维修所保留章节进度")
	check(game.rooms[11].next==8,"维修所回访门明确连接锈井入口")
	gfx.settings=original;gfx.apply_settings(false);gfx.save_settings();game.set_screen("play");return checks
