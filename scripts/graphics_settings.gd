extends Node
const RESOLUTIONS = [Vector2i.ZERO,Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160)]
const FPS_LIMITS = [30,60,90,120,144,165,240,0]
var game: Node3D
var settings: Dictionary={}
var previous: Dictionary={}
var config_path := "user://graphics_settings.cfg"
var confirmation_time := 0.0
var return_screen := "pause"
var light_clock := 0.0
func defaults() -> Dictionary:
	var gpu:=RenderingServer.get_video_adapter_name().to_lower()
	var quality: String="low" if "intel" in gpu or "uhd" in gpu or "iris" in gpu or "radeon graphics" in gpu else "high" if "rtx 50" in gpu or "rtx 40" in gpu or "rtx 30" in gpu else "medium"
	return {"quality":quality,"resolution":0,"mode":1,"fps":60,"vsync":true,"scale":.67 if quality=="low" else .85 if quality=="medium" else 1.0,"shadows":quality!="low","show_fps":false,"fog":true,"glow":true,"brightness":1.0}
func _ready() -> void:
	if game.qa_mode:config_path="user://qa_graphics_settings.cfg"
	settings=defaults();load_settings()
	for arg in OS.get_cmdline_user_args():
		if arg=="--graphics-low":settings.merge({"quality":"low","scale":.67,"shadows":false},true)
	apply_settings(not game.qa_mode)
func load_settings() -> void:
	var cfg:=ConfigFile.new()
	if cfg.load(config_path)==OK:
		for key in settings:settings[key]=cfg.get_value("graphics",key,settings[key])
	sanitize()
func sanitize() -> void:
	if str(settings.quality) not in ["low","medium","high"]:settings.quality="medium"
	settings.resolution=clampi(int(settings.resolution),0,RESOLUTIONS.size()-1);settings.mode=clampi(int(settings.mode),0,1)
	if int(settings.fps) not in FPS_LIMITS:settings.fps=60
	settings.scale=clampf(float(settings.scale),.5,1);settings.vsync=bool(settings.vsync);settings.shadows=bool(settings.shadows);settings.show_fps=bool(settings.show_fps);settings.fog=bool(settings.get("fog",true));settings.glow=bool(settings.get("glow",true));settings.brightness=clampf(float(settings.get("brightness",1)),.75,1.5)
func save_settings() -> void:
	var cfg:=ConfigFile.new()
	for key in settings:cfg.set_value("graphics",key,settings[key])
	cfg.save(config_path)
func native_size() -> Vector2i:return DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
func apply_settings(window: bool=true) -> void:
	sanitize();Engine.max_fps=settings.fps
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED)
	if window:
		var output: Vector2i=native_size() if settings.resolution==0 else RESOLUTIONS[settings.resolution]
		if settings.mode==1:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var usable:=DisplayServer.screen_get_usable_rect();output=output.min(usable.size-Vector2i(32,64)).max(Vector2i(960,540));DisplayServer.window_set_size(output);DisplayServer.window_set_position(usable.position+(usable.size-output)/2)
	var view:=game.get_viewport();var native:=native_size();var resolution: Vector2i=RESOLUTIONS[settings.resolution]
	var ratio:=1.0
	if settings.mode==1 and resolution!=Vector2i.ZERO:ratio=minf(1,minf(float(resolution.x)/native.x,float(resolution.y)/native.y))
	view.scaling_3d_scale=clampf(float(settings.scale)*ratio,.25,1);view.scaling_3d_mode=Viewport.SCALING_3D_MODE_BILINEAR
	view.msaa_3d=Viewport.MSAA_4X if settings.quality=="high" else Viewport.MSAA_DISABLED
	view.screen_space_aa=Viewport.SCREEN_SPACE_AA_FXAA if settings.quality!="low" and RenderingServer.get_current_rendering_method()!="gl_compatibility" else Viewport.SCREEN_SPACE_AA_DISABLED
	var forward: bool=RenderingServer.get_current_rendering_method()=="forward_plus"
	game.environment.fog_enabled=settings.fog;game.environment.ambient_light_energy=.56*float(settings.brightness)
	game.environment.glow_enabled=forward and settings.quality=="high" and settings.glow;game.environment.ssao_enabled=forward and settings.quality=="high"
	game.sun.shadow_enabled=settings.shadows;game.sun.directional_shadow_max_distance=70 if settings.quality=="high" else 42;game.sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if settings.quality=="high" else DirectionalLight3D.SHADOW_ORTHOGONAL
	game.get_viewport().positional_shadow_atlas_size=1024 if settings.quality=="low" else 2048
	apply_world_quality();light_clock=0
func set_quality(value: String,save: bool=true) -> void:
	settings.quality=value;settings.scale=.67 if value=="low" else .85 if value=="medium" else 1.0;settings.shadows=value!="low";apply_settings(false)
	if save:save_settings()
func apply_world_quality() -> void:
	if not is_instance_valid(game.world):return
	for mesh in game.world.find_children("*","GeometryInstance3D",true,false):
		if mesh.get_meta("distant_decor",false):mesh.visible=true
	for mat in game.atmosphere_materials.values():
		mat.set_shader_parameter("detail_normal",true);mat.set_shader_parameter("detail_rough",true)
func _process(dt: float) -> void:
	if confirmation_time>0:
		confirmation_time=maxf(0,confirmation_time-dt)
		if confirmation_time==0:revert()
	light_clock-=dt
	if light_clock>0 or not is_instance_valid(game.player) or game.world_builder==null:return
	light_clock=.2;var lights: Array=game.world_builder.lights.duplicate();var origin: Vector3=game.player.position
	lights.sort_custom(func(a,b):return a.position.distance_squared_to(origin)<b.position.distance_squared_to(origin))
	var budget: int=4 if settings.quality=="low" else 8 if settings.quality=="medium" else 14
	for i in range(lights.size()):lights[i].visible=i<budget
func begin_apply(values: Dictionary) -> void:
	previous=settings.duplicate(true);settings=values.duplicate(true);apply_settings();confirmation_time=15;game.set_screen("graphics_confirm")
func confirm() -> void:
	confirmation_time=0;previous.clear();save_settings();game.set_screen("graphics")
func revert() -> void:
	if previous.is_empty():return
	settings=previous.duplicate(true);previous.clear();confirmation_time=0;apply_settings();game.set_screen("graphics")
