extends Control
var game: Node3D
var buttons: Array[Button]=[]
var font: Font
const GOLD=Color(.88,.68,.36)
const TEXT=Color(.89,.87,.81)
const MUTED=Color(.58,.67,.71)
const DARK=Color(.024,.037,.047,.94)

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	font=ThemeDB.fallback_font

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
	text_at(Vector2(42,55),"凯恩 · 裂影匕首" if game.active_slot==0 else "洛铆 · 机械师",22)
	text_at(Vector2(42,83),"%d / %d"%[game.party_hp[game.active_slot],game.max_hp()],16,MUTED)
	bar(Vector2(142,72),208,game.party_hp[game.active_slot],game.max_hp(),Color(.67,.21,.15))
	bar(Vector2(42,99),308,game.player.stamina,100,Color(.72,.56,.28))
	bar(Vector2(42,118),308,game.magic,100,Color(.16,.48,.67))
	draw_rect(Rect2(w-390,22,366,108),DARK)
	text_at(Vector2(w-368,53),game.rooms[game.room].name,24,GOLD)
	text_at(Vector2(w-368,80),game.rooms[game.room].id+"  /  断电之夜",16,MUTED)
	text_at(Vector2(w-368,107),"铁屑 %d    药剂 %d    技能点 %d"%[game.scrap,game.potion,game.skill_points],17)
	if game.flags.get("rescued",false):
		text_at(Vector2(42,170),"1 凯恩 %d%%     2 洛铆 %d%%     F 切换"%[roundi(game.party_hp[0]),roundi(game.party_hp[1]/1.1)],17,MUTED)
	draw_rect(Rect2(0,h-72,w,72),DARK)
	text_at(Vector2(28,h-43),game.rooms[game.room].hint,17,TEXT)
	text_at(Vector2(28,h-16),"摇杆 移动  A 跳跃  X/Y 攻击  B 闪避  LB 格挡  ↑ 交互  LT 钩索  RT 切换" if game.pad>=0 else "A/D 移动   W/S 攀梯   Space 跳跃   J/K 攻击   Shift 闪避   L 格挡   E 交互   Q 钩索   M 地图   T 技能   Esc 暂停",15,MUTED)
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
			var p: Vector2=game.camera.unproject_position(enemy.position+Vector3(0,3.7 if enemy.kind=="boss" else 2.1,0))
			bar(p-Vector2(30,0),60,enemy.hp,enemy.max_hp,Color(.75,.24,.1))
			if enemy.state=="windup":text_at(p+Vector2(-40,-12),"落锤！" if enemy.kind=="boss" else "!",19,GOLD)
		if game.room==9:
			text_at(Vector2(w/2-170,200),"锁销 %s  /  惰轮 %s  /  离合 %s"%["固定" if game.gear[0] else "拔出","接入" if game.gear[1] else "移开","合上" if game.gear[2] else "断开"],18,GOLD)
		if game.room==10:
			text_at(Vector2(w/2-160,200),"水位 %.1f / 2  ·  %s"%[game.water[2],"旁路开放" if game.water[3] else "蒸汽隔离"],18,GOLD)
		return
	draw_rect(Rect2(Vector2.ZERO,size),Color(.008,.016,.024,.82))
	if game.screen=="title":
		text_at(Vector2(w*.13,h*.29),"灰烬齿轮",64,GOLD)
		text_at(Vector2(w*.13,h*.37),"裂界之心",38,TEXT)
		text_at(Vector2(w*.13,h*.43),"ASHEN GEARS  /  HEART OF THE RIFT",18,MUTED)
		text_at(Vector2(w*.13,h*.51),"一座以记忆为燃料的城。一份被伪造的名字。",23,TEXT)
		text_at(Vector2(w*.13,h*.89),"序章 · 断电之夜     /     v0.1 可玩原型",17,MUTED)
	elif game.screen=="story":
		var lines: PackedStringArray=game.story.split("\n")
		var top := h*.35
		draw_line(Vector2(w*.20,top-45),Vector2(w*.80,top-45),GOLD,1)
		for i in lines.size():text_at(Vector2(w*.20,top+i*39),lines[i],24,TEXT)
		text_at(Vector2(w*.20,top+lines.size()*39+35),"E / Enter 继续",18,GOLD)
	elif game.screen=="pause":
		text_at(Vector2(w*.35,h*.30),"回声暂歇",42,GOLD)
		text_at(Vector2(w*.35,h*.38),"进度在休息灯保存；独特奖励即时记录。",20,MUTED)
	elif game.screen=="skills":
		text_at(Vector2(w*.18,h*.22),"招式工坊",40,GOLD)
		text_at(Vector2(w*.18,h*.29),"凯恩 · 匕首" if game.active_slot==0 else "洛铆 · 机械重击",24,TEXT)
		text_at(Vector2(w*.18,h*.35),"技能点 %d  /  每招 1 点。Ctrl + J / K，消耗 18 魔力。"%game.skill_points,20,MUTED)
		text_at(Vector2(w*.18,h*.70),"轻击 J 可接三连；重击 K 破势；完美格挡回复耐力。",21,TEXT)
		text_at(Vector2(w*.18,h*.76),"共鸣变身与其他同伴将在后续章节制作。",18,MUTED)
	elif game.screen=="map":
		text_at(Vector2(w*.14,h*.19),"灰炉城 · 已探索通道",38,GOLD)
		for i in range(11):
			var col := i%4;var row := i/4
			var p := Vector2(w*.14+col*w*.19,h*.28+row*125)
			var known: bool=game.visited.has(game.rooms[i].id)
			draw_rect(Rect2(p,Vector2(w*.16,88)),Color(.12,.16,.19) if known else Color(.05,.07,.08))
			draw_rect(Rect2(p,Vector2(w*.16,88)),GOLD if i==game.room else Color(.30,.38,.41),false,2)
			text_at(p+Vector2(13,28),game.rooms[i].id,16,MUTED)
			text_at(p+Vector2(13,60),game.rooms[i].name if known else "未探索",21,TEXT if known else MUTED)
			if col<3 and i<10:draw_line(p+Vector2(w*.16,44),p+Vector2(w*.19,44),MUTED,2)
		text_at(Vector2(w*.14,h*.78),"◇ 休息灯   /   蓝色 ◇ 钩索锚点   /   原路与囚厂回环可以再次探索",18,MUTED)
		text_at(Vector2(w*.14,h*.84),"维修所："+("已发现" if game.visited.has("R00-01") else "未发现")+"     /     M 或 Esc 返回",18,GOLD)

func add_button(value: String, pos: Vector2, action: Callable, width: float = 300) -> void:
	var b := Button.new();add_child(b);buttons.append(b);b.text=value;b.position=pos;b.size=Vector2(width,48)
	b.add_theme_font_size_override("font_size",21)
	var s := StyleBoxFlat.new();s.bg_color=Color(.075,.105,.12);s.border_color=Color(.36,.39,.36);s.set_border_width_all(1);s.content_margin_left=18
	b.add_theme_stylebox_override("normal",s)
	var hover := s.duplicate();hover.bg_color=Color(.20,.16,.10);hover.border_color=GOLD;b.add_theme_stylebox_override("hover",hover);b.add_theme_stylebox_override("focus",hover)
	b.pressed.connect(action)

func rebuild_buttons() -> void:
	for b in buttons:remove_child(b);b.queue_free()
	buttons.clear()
	var w := get_viewport_rect().size.x;var h := get_viewport_rect().size.y
	if game.screen=="title":
		add_button("开始新的旅程",Vector2(w*.13,h*.59),game.new_game)
		if FileAccess.file_exists(game.save_path):add_button("继续休息灯存档",Vector2(w*.13,h*.66),game.load_game)
		add_button("离开灰炉城",Vector2(w*.13,h*.73),func():get_tree().quit())
	if game.screen=="pause":
		add_button("继续",Vector2(w*.35,h*.46),func():game.set_screen("play"))
		add_button("查看地图",Vector2(w*.35,h*.54),func():game.set_screen("map"))
		add_button("招式工坊",Vector2(w*.35,h*.62),func():game.set_screen("skills"))
		add_button("返回标题",Vector2(w*.35,h*.70),func():game.set_screen("title"))
	if game.screen=="skills":
		for i in range(2):
			var learned: bool=game.learned.has("%d_%d"%[game.active_slot,i])
			var names := ["裂影刺","齿刃旋舞"] if game.active_slot==0 else ["铜核修补击","齿轮过载"]
			add_button(("已学会 · " if learned else "学习 · ")+names[i],Vector2(w*.18+i*350,h*.44),game.learn_skill.bind(i),320)
		add_button("返回",Vector2(w*.18,h*.57),func():game.set_screen("play"))
