extends Control
var game: Node3D
var buttons: Array[Button]=[]
var font: Font
var preview: SubViewportContainer
var preview_slot := 0
var audio_controls: Array[Control]=[]
var graphics_controls: Array[Control]=[]
var graphics_draft: Dictionary={}
const GOLD=Color(.88,.68,.36)
const TEXT=Color(.89,.87,.81)
const MUTED=Color(.58,.67,.71)
const DARK=Color(.024,.037,.047,.94)

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	font=ThemeDB.fallback_font
	resized.connect(func():call_deferred("rebuild_buttons"))

func text_at(pos: Vector2, value: String, size_value: int = 22, col: Color = TEXT) -> void:
	draw_string(font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,col)

func bar(pos: Vector2, width: float, value: float, max_value: float, col: Color) -> void:
	draw_rect(Rect2(pos,Vector2(width,7)),Color(.11,.16,.19))
	draw_rect(Rect2(pos,Vector2(width*clampf(value/max_value,0,1),7)),col)

func _draw() -> void:
	if not game or not font or not is_instance_valid(game.player):return
	var w := size.x;var h := size.y
	draw_rect(Rect2(24,22,350,120),DARK)
	draw_line(Vector2(24,22),Vector2(374,22),GOLD,2)
	text_at(Vector2(42,55),["凯恩 · "+game.weapon_name(),"洛铆 · 机械师","伊瑟 · 矿族游侠"][game.active_slot],22)
	text_at(Vector2(42,83),"%d / %d"%[game.party_hp[game.active_slot],game.max_hp()],16,MUTED)
	bar(Vector2(142,72),208,game.party_hp[game.active_slot],game.max_hp(),Color(.67,.21,.15))
	bar(Vector2(42,99),308,game.player.stamina,100,Color(.72,.56,.28))
	bar(Vector2(42,118),308,game.magic,100,Color(.16,.48,.67))
	draw_rect(Rect2(w-390,22,366,108),DARK)
	text_at(Vector2(w-368,53),game.rooms[game.room].name,24,GOLD)
	text_at(Vector2(w-368,80),game.rooms[game.room].id+"  /  v0.4.3",16,MUTED)
	text_at(Vector2(w-368,107),"铁屑 %d    药剂 %d    技能点 %d"%[game.scrap,game.potion,game.skill_points],17)
	if game.flags.get("rescued",false):
		text_at(Vector2(42,170),"1 凯恩  2 洛铆"+("  3 伊瑟" if game.flags.get("ranger",false) else "")+"  /  F 切换",17,MUTED)
	draw_rect(Rect2(0,h-72,w,72),DARK)
	text_at(Vector2(28,h-43),game.rooms[game.room].hint,17,TEXT)
	text_at(Vector2(28,h-16),"摇杆 移动  A 二段跳  X/Y 攻击  B 闪避  LB 格挡  ↑ 交互  LT 钩索  RT 切人  右摇杆按下 换武器" if game.pad>=0 else "A/D 移动  W/S 攀梯  Alt 冲跑  Space 二段跳  J/K 攻击  Shift 翻滚  L 弹反  E 交互  V 换武器  Q 钩索  Tab 总览  M 地图  T 技能",15,MUTED)
	if game.graphics.settings.show_fps:
		text_at(Vector2(w*.46,30),"%d FPS"%Engine.get_frames_per_second(),16,MUTED)
	if game.screen=="play":
		if not game.nearest.is_empty():
			var value: String=game.nearest.text
			if game.nearest.kind!="assassinate":value="E  "+value
			var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x+50
			draw_rect(Rect2((w-width)/2,h-140,width,44),DARK)
			text_at(Vector2((w-width)/2+25,h-112),value,21,GOLD)
		if game.toast_clock>0:
			var tw := font.get_string_size(game.status,HORIZONTAL_ALIGNMENT_LEFT,-1,19).x
			text_at(Vector2((w-tw)/2,155),game.status,19,GOLD)
		if Input.is_action_pressed("grapple") and game.flags.get("grapple",false):
			var a: Variant=game.selected_anchor()
			if a!=null:
				var p: Vector2=game.camera.unproject_position(a+Vector3(0,.4,0))
				draw_arc(p,21,0,TAU,36,Color(.23,.7,1),2)
				draw_line(game.camera.unproject_position(game.player.position+Vector3(0,1,0)),p,Color(.23,.7,1,.55),1)
		for enemy in game.enemies:
			if not is_instance_valid(enemy):continue
			var p: Vector2=game.camera.unproject_position(enemy.position+Vector3(0,3.7 if enemy.boss() else 2.1,0))
			bar(p-Vector2(30,0),60,enemy.hp,enemy.max_hp,Color(.75,.24,.1))
			if enemy.state=="windup":text_at(p+Vector2(-40,-12),enemy.pattern+"！",19,GOLD)
		if game.room==9:
			text_at(Vector2(w/2-170,200),"锁销 %s  /  惰轮 %s  /  离合 %s"%["固定" if game.gear[0] else "拔出","接入" if game.gear[1] else "移开","合上" if game.gear[2] else "断开"],18,GOLD)
		var alive:=0
		for enemy in game.enemies:
			if is_instance_valid(enemy) and enemy.hp>0:alive+=1
		text_at(Vector2(w-368,153),"本室敌人 %d   /   Tab 查看完整路线"%alive,16,GOLD)
		return
	draw_rect(Rect2(Vector2.ZERO,size),Color(.008,.016,.024,.82))
	if game.screen=="title":
		text_at(Vector2(w*.13,h*.29),"灰烬齿轮",64,GOLD)
		text_at(Vector2(w*.13,h*.37),"裂界之心",38,TEXT)
		text_at(Vector2(w*.13,h*.43),"ASHEN GEARS  /  HEART OF THE RIFT",18,MUTED)
		text_at(Vector2(w*.13,h*.51),"一座以记忆为燃料的城。一份被伪造的名字。",23,TEXT)
		text_at(Vector2(w*.13,h*.89),"灰闸囚厂 × 锈脊齿轮井   /   18 房间 · v0.4.3",17,MUTED)
	elif game.screen=="story":
		var lines: PackedStringArray=game.story.split("\n")
		var top := h*.35
		draw_line(Vector2(w*.20,top-45),Vector2(w*.80,top-45),GOLD,1)
		for i in lines.size():text_at(Vector2(w*.20,top+i*39),lines[i],24,TEXT)
		text_at(Vector2(w*.20,top+lines.size()*39+35),"E / Enter 继续",18,GOLD)
	elif game.screen=="pause":
		text_at(Vector2(w*.35,h*.30),"回声暂歇",42,GOLD)
		text_at(Vector2(w*.35,h*.38),"进度在休息灯保存；独特奖励即时记录。",20,MUTED)
	elif game.screen=="audio":
		text_at(Vector2(w*.23,h*.20),"声音设置",40,GOLD)
		text_at(Vector2(w*.23,h*.28),"总音量、动作音效、环境与音乐分别调整，自动保存。",20,MUTED)
		for i in range(4):text_at(Vector2(w*.23,h*(.38+i*.09)),["总音量","动作 / 战斗音效","背景音乐","环境 / 机械底噪"][i],21,TEXT)
		text_at(Vector2(w*.23,h*.91),"试听：攻击、命中、突进、跳跃落地与机关声音。",18,MUTED)
	elif game.screen=="graphics":
		text_at(Vector2(w*.20,h*.14),"画面设置",38,GOLD)
		text_at(Vector2(w*.20,h*.21),"高 / 中 / 低画质；默认使用当前屏幕分辨率。",20,MUTED)
		for i in range(8):text_at(Vector2(w*.20,h*(.285+i*.06)),["画面档位","分辨率","显示模式","帧率上限","垂直同步","3D 渲染比例","动态阴影","显示帧率"][i],20,TEXT)
		text_at(Vector2(w*.20,h*.81),"全屏保持屏幕大小；分辨率与渲染比例控制 3D 清晰度，界面保持清晰。",17,MUTED)
	elif game.screen=="graphics_confirm":
		text_at(Vector2(w*.24,h*.35),"保留这组画面设置？",36,GOLD)
		text_at(Vector2(w*.24,h*.44),"%d 秒内确认，超时或 Esc 自动恢复。"%ceil(game.graphics.confirmation_time),22,TEXT)
	elif game.screen=="chapter_complete":
		text_at(Vector2(w*.20,h*.24),"R01 / R02 · 章节完成",38,GOLD)
		text_at(Vector2(w*.20,h*.34),"总井恢复运转，幸存者已回到维修所。",23,TEXT)
		text_at(Vector2(w*.20,h*.41),"已完成两个区域；第三章「雾肺水务区」尚未开放。",21,MUTED)
		text_at(Vector2(w*.20,h*.48),"以下入口用于回访与整备，不会重置 Boss、奖励或同伴进度。",20,MUTED)
		text_at(Vector2(w*.20,h*.55),"伊瑟救援："+("已完成" if game.flags.get("ranger",false) else "可回轴承台中层侧门完成"),20,GOLD)
	elif game.screen=="skills":
		text_at(Vector2(w*.18,h*.22),"招式工坊",40,GOLD)
		text_at(Vector2(w*.18,h*.29),["凯恩 · "+game.weapon_name(),"洛铆 · 机械重击","伊瑟 · 弓箭"][game.active_slot],24,TEXT)
		text_at(Vector2(w*.18,h*.35),"技能点 %d / 每招 1 点。Ctrl + J / K 攻击，Ctrl + Space 空中冲刺。"%game.skill_points,20,MUTED)
		text_at(Vector2(w*.18,h*.70),"太刀 J 三连斩 / K 重劈；匕首快速连击；V 换武器。",21,TEXT)
		text_at(Vector2(w*.18,h*.76),"初始 Space 二段跳；空中 K 下砸；蓝纹墙 + Space 蹬墙。",18,MUTED)
	elif game.screen=="map":
		text_at(Vector2(w*.14,h*.19),"灰炉城 · 已探索通道",38,GOLD)
		for i in range(game.rooms.size()):
			var col := i%5;var row := i/5
			var p := Vector2(w*.14+col*w*.15,h*.27+row*82)
			var known: bool=game.visited.has(game.rooms[i].id)
			draw_rect(Rect2(p,Vector2(w*.14,72)),Color(.12,.16,.19) if known else Color(.05,.07,.08))
			draw_rect(Rect2(p,Vector2(w*.14,72)),GOLD if i==game.room else Color(.30,.38,.41),false,2)
			text_at(p+Vector2(13,28),game.rooms[i].id,16,MUTED)
			text_at(p+Vector2(13,55),game.rooms[i].name if known else "未探索",17,TEXT if known else MUTED)

		text_at(Vector2(w*.14,h*.78),"主线：R01-01 → 08 → R02-01 → 08（本章终点）；维修所和矿牢为回访支线。",18,MUTED)
		text_at(Vector2(w*.14,h*.84),"维修所："+("已发现" if game.visited.has("R00-01") else "未发现")+"     /     M 或 Esc 返回",18,GOLD)

func add_button(value: String, pos: Vector2, action: Callable, width: float = 300) -> void:
	var b := Button.new();add_child(b);buttons.append(b);b.text=value;b.position=pos;b.size=Vector2(width,48)
	b.add_theme_font_size_override("font_size",21)
	var s := StyleBoxFlat.new();s.bg_color=Color(.075,.105,.12);s.border_color=Color(.36,.39,.36);s.set_border_width_all(1);s.content_margin_left=18
	b.add_theme_stylebox_override("normal",s)
	var hover := s.duplicate();hover.bg_color=Color(.20,.16,.10);hover.border_color=GOLD;b.add_theme_stylebox_override("hover",hover);b.add_theme_stylebox_override("focus",hover)
	b.pressed.connect(func():game.sound("ui"));b.pressed.connect(action)

func rebuild_buttons() -> void:
	for control in graphics_controls:remove_child(control);control.queue_free()
	graphics_controls.clear()
	for control in audio_controls:remove_child(control);control.queue_free()
	audio_controls.clear()
	if is_instance_valid(preview):remove_child(preview);preview.queue_free()
	for b in buttons:remove_child(b);b.queue_free()
	buttons.clear()
	var w := get_viewport_rect().size.x;var h := get_viewport_rect().size.y
	if game.screen=="title":
		add_button("开始新的旅程",Vector2(w*.13,h*.59),game.new_game)
		if FileAccess.file_exists(game.save_path):add_button("继续休息灯存档",Vector2(w*.13,h*.66),game.load_game)
		add_button("画面设置",Vector2(w*.13,h*.73),game.open_graphics)
		add_button("离开灰炉城",Vector2(w*.13,h*.80),game.request_quit)
	if game.screen=="pause":
		add_button("继续",Vector2(w*.35,h*.46),func():game.set_screen("play"))
		add_button("查看地图",Vector2(w*.35,h*.54),func():game.set_screen("map"))
		add_button("招式工坊",Vector2(w*.35,h*.62),func():game.set_screen("skills"))
		add_button("声音设置",Vector2(w*.35,h*.70),func():game.set_screen("audio"))
		add_button("画面设置",Vector2(w*.35,h*.78),game.open_graphics)
		add_button("返回标题",Vector2(w*.35,h*.86),func():game.set_screen("title"))
	if game.screen=="graphics":build_graphics()
	if game.screen=="graphics_confirm":
		add_button("保留设置",Vector2(w*.24,h*.56),game.graphics.confirm,240)
		add_button("恢复原设置",Vector2(w*.48,h*.56),game.graphics.revert,240)
	if game.screen=="chapter_complete":
		add_button("前往维修所整备",Vector2(w*.20,h*.65),game.chapter_return.bind(11),340)
		add_button("回访锈井入口",Vector2(w*.52,h*.65),game.chapter_return.bind(8),340)
		add_button("回访灰闸囚厂",Vector2(w*.20,h*.74),game.chapter_return.bind(0),340)
		add_button("返回标题",Vector2(w*.52,h*.74),func():game.set_screen("title"),340)
	if game.screen=="audio":
		for i in range(4):
			var bus: String=["Master","SFX","Music","Ambient"][i]
			var slider:=HSlider.new();add_child(slider);audio_controls.append(slider);slider.position=Vector2(w*.46,h*(.36+i*.09));slider.size=Vector2(w*.26,30);slider.min_value=0;slider.max_value=100;slider.step=1;slider.value=game.audio_system.settings[bus]*100
			var label:=Label.new();add_child(label);audio_controls.append(label);label.position=Vector2(w*.74,h*(.36+i*.09));label.text="%d%%"%slider.value;label.add_theme_font_size_override("font_size",21)
			slider.value_changed.connect(func(value):game.audio_system.set_volume(bus,value/100);label.text="%d%%"%value)
		add_button("试听音效",Vector2(w*.23,h*.76),game.preview_audio,200)
		add_button("恢复默认",Vector2(w*.41,h*.76),func():game.audio_system.reset_defaults();rebuild_buttons(),200)
		add_button("返回",Vector2(w*.59,h*.76),func():game.set_screen("pause"),200)
	if game.screen=="skills":
		for i in range(3):
			var learned: bool=game.learned.has("%d_%d"%[game.active_slot,i])
			var names: Array = [["裂影刺","齿刃旋舞","裂影空冲"],["铜核修补击","齿轮过载","机械推进"],["穿甲射击","裂界强弓","游侠空冲"]][game.active_slot]
			add_button(("预览 · " if learned else "学习 · ")+names[i],Vector2(w*.12+i*w*.27,h*.44),choose_skill.bind(i),w*.25)
		for slot in game.available_slots():add_button(["凯恩","洛铆","伊瑟"][slot],Vector2(w*.18+slot*160,h*.58),game.menu_actor.bind(slot),140)
		add_button("返回",Vector2(w*.18,h*.84),func():game.set_screen("play"))
		build_preview(Vector2(w*.66,h*.56),Vector2(w*.22,h*.28))

func choose_skill(slot: int) -> void:
	preview_slot=slot;game.learn_skill(slot);rebuild_buttons()

func build_preview(pos: Vector2,dimensions: Vector2) -> void:
	preview=SubViewportContainer.new();add_child(preview);preview.position=pos;preview.size=dimensions;preview.stretch=true;preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var viewport:=SubViewport.new();viewport.size=Vector2i(dimensions);viewport.world_3d=World3D.new();viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;preview.add_child(viewport)
	var scene:=Node3D.new();viewport.add_child(scene)
	var env:=WorldEnvironment.new();scene.add_child(env);env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.035,.055,.065);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.8
	var light:=DirectionalLight3D.new();scene.add_child(light);light.rotation_degrees=Vector3(-30,-35,0);light.light_energy=2
	var camera:=Camera3D.new();scene.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.6;camera.position=Vector3(1.8,1.2,4);camera.look_at(Vector3(0,1,0));camera.current=true
	var actor: Node3D=load("res://assets/models/"+game.actor_model(game.active_slot)+".glb").instantiate();scene.add_child(actor)
	var animator: AnimationPlayer=actor.find_child("AnimationPlayer",true,false)
	var clip: String="AirDash" if preview_slot==2 else "BowShot" if game.active_slot==2 else "MechLight" if game.active_slot==1 and preview_slot==0 else "MechHeavy" if game.active_slot==1 else "Dagger3" if preview_slot==0 else "Skill"
	if game.active_slot==0 and game.equipped_weapon=="katana" and preview_slot!=2:clip="Katana3" if preview_slot==0 else "KatanaHeavy"
	var anim: Animation=animator.get_animation(clip).duplicate();anim.loop_mode=Animation.LOOP_LINEAR;var library:=AnimationLibrary.new();library.add_animation("action",anim);animator.add_animation_library("preview",library);animator.play("preview/action")

func graphics_option(items: Array, row: int, selected: int, changed: Callable) -> OptionButton:
	var option:=OptionButton.new();add_child(option);graphics_controls.append(option);option.position=Vector2(size.x*.49,size.y*(.259+row*.06));option.size=Vector2(size.x*.31,36)
	option.add_theme_font_size_override("font_size",20)
	for item in items:option.add_item(str(item))
	option.select(selected);option.item_selected.connect(changed);return option
func build_graphics() -> void:
	graphics_draft=game.graphics.settings.duplicate(true)
	var native: Vector2i=game.graphics.native_size();var resolution_names: Array=["屏幕原生 %d × %d"%[native.x,native.y]]
	for resolution in game.graphics.RESOLUTIONS.slice(1):resolution_names.append("%d × %d"%[resolution.x,resolution.y])
	var quality:=graphics_option(["低 · 核显 / 节能","中 · 均衡","高 · 阴影 / SSAO / 辉光"],0,["low","medium","high"].find(graphics_draft.quality),func(i):graphics_draft.quality=["low","medium","high"][i])
	graphics_option(resolution_names,1,graphics_draft.resolution,func(i):graphics_draft.resolution=i)
	graphics_option(["窗口","全屏"],2,graphics_draft.mode,func(i):graphics_draft.mode=i)
	graphics_option(["30 FPS","60 FPS","90 FPS","120 FPS","144 FPS","165 FPS","240 FPS","不限"],3,game.graphics.FPS_LIMITS.find(graphics_draft.fps),func(i):graphics_draft.fps=game.graphics.FPS_LIMITS[i])
	graphics_option(["关闭","开启"],4,int(graphics_draft.vsync),func(i):graphics_draft.vsync=i==1)
	var scales: Array=[.5,.67,.85,1.0];var scale_index:=0
	for i in range(scales.size()):
		if absf(scales[i]-float(graphics_draft.scale))<.02:scale_index=i
	var scale:=graphics_option(["50%","67%","85%","100%"],5,scale_index,func(i):graphics_draft.scale=scales[i])
	var shadow:=graphics_option(["关闭","开启"],6,int(graphics_draft.shadows),func(i):graphics_draft.shadows=i==1)
	graphics_option(["关闭","开启"],7,int(graphics_draft.show_fps),func(i):graphics_draft.show_fps=i==1)
	quality.item_selected.connect(func(i):graphics_draft.scale=scales[i+1];graphics_draft.shadows=i!=0;scale.select(i+1);shadow.select(int(i!=0)))
	add_button("应用",Vector2(size.x*.20,size.y*.86),func():game.graphics.begin_apply(graphics_draft),200)
	add_button("恢复推荐",Vector2(size.x*.40,size.y*.86),func():game.graphics.begin_apply(game.graphics.defaults()),220)
	add_button("返回",Vector2(size.x*.62,size.y*.86),func():game.set_screen(game.graphics.return_screen),200)
