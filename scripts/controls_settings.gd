extends Node
const LABELS={"left":"向左","right":"向右","up":"上攀梯","down":"蹲行 / 下攀梯","jump":"跳跃 / 二段跳","light":"轻攻击","heavy":"重攻击","dodge":"翻滚","guard":"格挡 / 弹反","modifier":"技能修饰键","grapple":"钩索","interact":"交互","switch":"切换同伴","weapon":"切换武器","item":"使用药剂","map":"地图","skills":"招式工坊","run":"冲跑","overview":"场景总览","roster":"同伴名册","journal":"任务记录","phase":"薄壁相移","inventory":"背包","equipment":"装备","transform":"共鸣形态"}
var game: Node3D
var defaults: Dictionary={}
var keys: Dictionary={}
var capturing := ""
var page := 0
var config_path := "user://controls_settings.cfg"
func _ready() -> void:
	if game.qa_mode:config_path="user://qa_controls_settings.cfg"
	for action in LABELS:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:defaults[action]=event.physical_keycode;break
	keys=defaults.duplicate();var cfg:=ConfigFile.new()
	if cfg.load(config_path)==OK:
		for action in defaults:
			var candidate: int=int(cfg.get_value("keys",action,defaults[action]))
			if candidate>0 and candidate not in [KEY_ESCAPE,KEY_ENTER,KEY_F11,KEY_1,KEY_2,KEY_3]:keys[action]=candidate
	# Invalid duplicate bindings recover to defaults rather than leave actions unreachable.
	var used: Dictionary={}
	for action in keys:
		if used.has(keys[action]):keys=defaults.duplicate();break
		used[keys[action]]=true
	apply()
func apply() -> void:
	for action in keys:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:InputMap.action_erase_event(action,event)
		var key:=InputEventKey.new();key.physical_keycode=keys[action];InputMap.action_add_event(action,key)
		if action in ["left","right","up","down"]:
			var arrow:=InputEventKey.new();arrow.physical_keycode={"left":KEY_LEFT,"right":KEY_RIGHT,"up":KEY_UP,"down":KEY_DOWN}[action];InputMap.action_add_event(action,arrow)
func bind_key(action: String, code: int) -> bool:
	if not defaults.has(action) or code<=0 or code in [KEY_ESCAPE,KEY_ENTER,KEY_F11,KEY_1,KEY_2,KEY_3,KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:return false
	for other in keys:
		if other!=action and keys[other]==code:return false
	keys[action]=code;apply();save();return true
func save() -> void:
	var cfg:=ConfigFile.new()
	for action in keys:cfg.set_value("keys",action,keys[action])
	cfg.save(config_path)
func reset() -> void:keys=defaults.duplicate();apply();save();capturing="";game.ui.rebuild_buttons()
func label(action: String) -> String:return OS.get_keycode_string(keys.get(action,KEY_ESCAPE))
func begin(action: String) -> void:capturing=action;game.ui.queue_redraw()
func _input(event: InputEvent) -> void:
	if capturing.is_empty() or not event is InputEventKey or not event.pressed or event.echo:return
	get_viewport().set_input_as_handled()
	if event.physical_keycode==KEY_ESCAPE:capturing="";game.ui.rebuild_buttons();return
	if bind_key(capturing,event.physical_keycode):capturing="";game.ui.rebuild_buttons()
	else:game.toast("该按键已占用或为系统保留，请选择其他键")
