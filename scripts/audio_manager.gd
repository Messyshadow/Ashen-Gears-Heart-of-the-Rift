extends Node
const CUE_NAMES = ["foot_stone_1", "foot_stone_2", "foot_stone_3", "foot_metal_1", "foot_metal_2", "foot_metal_3", "ladder_1", "hit_metal_1", "hit_flesh_1", "whoosh_light_1", "ladder_2", "hit_metal_2", "hit_flesh_2", "whoosh_light_2", "jump", "dash", "roll", "wall_jump", "vault", "whoosh_heavy", "boss_charge", "land_soft", "land_heavy", "player_hurt", "guard", "grapple_attach", "elevator_stop", "gear_latch", "press_hit", "boss_smash", "shockwave", "bow_fire", "grapple_launch", "skill", "parry", "enemy_fire", "enemy_windup", "press_warning", "boss_roar", "elevator_start", "gear_start", "chest", "save", "switch", "door", "ui", "amb_furnace", "amb_wind", "amb_gears", "amb_workshop", "music_explore", "music_combat", "music_boss","amb_water","amb_garden","amb_castle","amb_lab"]
var game: Node3D
var streams: Dictionary={}
var voices: Array[AudioStreamPlayer]=[]
var beds: Dictionary={}
var gains: Dictionary={}
var targets: Dictionary={}
var events: Dictionary={}
var settings: Dictionary={"Master":.85,"SFX":.9,"Music":.55,"Ambient":.65}
var ambient_name := "amb_furnace"
var combat_mode := "explore"
var combat_hold := 0.0
var combat_scan := 0.0
var config_path := "user://audio_settings.cfg"

func _ready() -> void:
	if game.qa_mode:config_path="user://qa_audio_settings.cfg"
	for bus in ["SFX","Music","Ambient","UI"]:
		if AudioServer.get_bus_index(bus)<0:AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
		AudioServer.set_bus_send(AudioServer.get_bus_index(bus),"Master")
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus),false)
	var master: int=AudioServer.get_bus_index("Master")
	var limiter:=AudioEffectLimiter.new();limiter.ceiling_db=-.8;limiter.threshold_db=-3;AudioServer.add_bus_effect(master,limiter)
	# Imported filenames differ inside PCKs; use stable logical resource paths.
	for cue in CUE_NAMES:
		var extension: String=".ogg" if cue.begins_with("amb_") or cue.begins_with("music_") else ".wav"
		var path: String="res://assets/audio/"+cue+extension
		if ResourceLoader.exists(path):streams[cue]=load(path)
		else:push_error("Missing packaged audio resource: "+path)
	for i in range(20):
		var voice:=AudioStreamPlayer.new();add_child(voice);voice.bus="SFX";voice.set_meta("priority",0);voice.set_meta("started",0);voices.append(voice)
	for name in ["amb_furnace","amb_wind","amb_gears","amb_workshop","music_explore","music_combat","music_boss","amb_water","amb_garden","amb_castle","amb_lab"]:
		var voice:=AudioStreamPlayer.new();add_child(voice);voice.bus="Music" if name.begins_with("music") else "Ambient";voice.stream=streams[name]
		if voice.stream is AudioStreamOggVorbis:voice.stream.loop=true
		voice.volume_db=-80;voice.play();beds[name]=voice;gains[name]=0.0;targets[name]=0.0
	load_settings();set_room("coal");update_targets()

func load_settings() -> void:
	var config:=ConfigFile.new()
	if config.load(config_path)==OK:
		for bus in settings:settings[bus]=clampf(float(config.get_value("volume",bus,settings[bus])),0,1)
	apply_settings()

func apply_settings() -> void:
	for bus in settings:AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus),linear_to_db(maxf(settings[bus],.00001)));AudioServer.set_bus_mute(AudioServer.get_bus_index(bus),settings[bus]<=0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"),linear_to_db(maxf(settings.SFX,.00001)));AudioServer.set_bus_mute(AudioServer.get_bus_index("UI"),settings.SFX<=0)

func set_volume(bus: String,value: float,save: bool=true) -> void:
	settings[bus]=clampf(value,0,1);apply_settings()
	if save:
		var config:=ConfigFile.new()
		for key in settings:config.set_value("volume",key,settings[key])
		config.save(config_path)

func reset_defaults(save: bool=true) -> void:
	for pair in [["Master",.85],["SFX",.9],["Music",.55],["Ambient",.65]]:set_volume(pair[0],pair[1],save)

func set_room(style: String) -> void:
	ambient_name="amb_gears" if style in ["gears","bearing","lift","conveyor"] else "amb_wind" if style in ["grapple","wall","mine","barrage"] else "amb_workshop" if style in ["hub","workshop"] else "amb_furnace"
	if style in ["water","garden","castle","lab"]:ambient_name="amb_"+style
	if style=="laboratory":ambient_name="amb_lab"
	combat_hold=0;combat_mode="explore";update_targets()

func update_targets() -> void:
	for name in targets:targets[name]=0.0
	targets[ambient_name]=1.0;targets["music_"+combat_mode]=.55 if game.paused else 1.0

func _process(dt: float) -> void:
	combat_scan-=dt
	if combat_scan<=0:
		combat_scan=.15;var mode: String="explore"
		if not game.paused and is_instance_valid(game.player):
			for enemy in game.enemies:
				if not is_instance_valid(enemy) or enemy.hp<=0:continue
				var distance: float=enemy.position.distance_to(game.player.position)
				if enemy.boss() and distance<15:mode="boss";break
				if enemy.state in ["chase","windup","strike","recover","stunned"] and distance<15:mode="combat"
		if mode!="explore":combat_mode=mode;combat_hold=2.5
		elif combat_hold<=0 or game.paused:combat_mode="explore"
		update_targets()
	combat_hold=maxf(0,combat_hold-dt)
	for name in beds:
		var voice: AudioStreamPlayer=beds[name]
		gains[name]=move_toward(float(gains[name]),float(targets[name]),dt*1.6)
		voice.volume_db=linear_to_db(maxf(gains[name],.00001))+(-9 if name.begins_with("music") else -10)
		var audible: bool=float(gains[name])>.0001 or float(targets[name])>.0001
		voice.stream_paused=not audible
		if audible and not voice.playing:voice.play()
		# Vorbis loops keep the room beds continuous. No per-action PCM allocation.

func play_event(kind: String,pos: Vector3=Vector3.INF) -> void:
	var priority: int=0 if kind.begins_with("foot") or kind.begins_with("ladder") else 3 if kind in ["parry","boss_smash","press_hit","land_heavy"] else 2
	if not streams.has(kind):push_error("Missing audio cue: "+kind);return
	var chosen: AudioStreamPlayer=null;var oldest:=INF
	for voice in voices:
		if not voice.playing:chosen=voice;break
		var rank: int=voice.get_meta("priority",0)
		var age: float=voice.get_meta("started",0)
		if rank<=priority and age<oldest:oldest=age;chosen=voice
	if chosen==null:return
	chosen.bus="UI" if kind=="ui" else "SFX";chosen.stream=streams[kind];chosen.pitch_scale=randf_range(.95,1.05) if priority<3 else 1.0
	var gain: float=-8 if priority==0 else -7 if kind=="ui" else -2
	if pos.is_finite() and is_instance_valid(game.player):gain+=linear_to_db(clampf(1-pos.distance_to(game.player.position)/28,.08,1))
	chosen.volume_db=gain;chosen.set_meta("priority",priority);chosen.set_meta("started",Time.get_ticks_usec());chosen.play()
	if game.qa_mode:events[kind]=int(events.get(kind,0))+1

func halt() -> void:
	set_process(false)
	for voice in voices:voice.stop();voice.stream=null
	for voice in beds.values():voice.stop();voice.stream=null

func _exit_tree() -> void:
	halt()
