extends RefCounted
var game: Node3D
var checks: Array=[]
var recorder: AudioEffectCapture
var recorded:=PackedVector2Array()
var master := 0
func check(ok: bool,name: String,detail: Dictionary={}) -> void:
	checks.append({"pass":ok,"check":name,"detail":detail});print("PASS " if ok else "FAIL ",name," ",detail)
func wait(t: float) -> void:await game.get_tree().create_timer(t).timeout
func counts(prefix: String) -> int:
	var count:=0
	for name in game.audio_system.events:
		if name.begins_with(prefix):count+=game.audio_system.events[name]
	return count
func measure() -> Dictionary:
	var data: PackedVector2Array=recorder.get_buffer(recorder.get_frames_available());recorded.append_array(data)
	var energy:=0.0;var peak:=0.0
	for frame in data:energy+=frame.length_squared();peak=maxf(peak,maxf(absf(frame.x),absf(frame.y)))
	return {"frames":data.size(),"rms":sqrt(energy/maxi(data.size()*2,1)),"peak":peak}
func run(g: Node3D,path: String) -> Array:
	game=g;var audio: Node=game.audio_system;audio.reset_defaults(false)
	master=AudioServer.get_bus_index("Master");recorder=AudioEffectCapture.new();recorder.buffer_length=1;AudioServer.add_bus_effect(master,recorder)
	check(audio.streams.size()==63 and audio.voices.size()==20,"63 个声音资源加载，20 路并发播放器")
	await wait(.5);var mix:=measure();check(mix.rms>.002,"探索音乐与环境实际混音非静音",mix)
	audio.set_volume("Music",0,false);audio.set_volume("Ambient",0,false)
	for voice in audio.voices:voice.stop()
	await wait(.3);recorder.clear_buffer();game.sound("whoosh_heavy");game.sound("hit_metal_1");game.sound("dash")
	var voices:=0
	for voice in audio.voices:
		if voice.playing:voices+=1
	await wait(.2);mix=measure();check(voices>=3 and mix.rms>.01 and mix.peak<.999,"攻击命中突进同时播放，有混音信号且不削波",mix)
	game.load_room(11);game.set_screen("play");game.player.position=Vector3(-8,0,0);game.player.velocity=Vector3.ZERO;await wait(.3)
	var before: int=counts("jump");recorder.clear_buffer();Input.action_press("jump");await wait(.18);Input.action_release("jump");mix=measure()
	check(counts("jump")>before and mix.rms>.004,"实际跳跃输入触发可测起跳音效",mix)
	game.learned["%d_2"%game.active_slot]=true;game.skill_cooldown=0;before=counts("dash");recorder.clear_buffer();Input.action_press("modifier");Input.action_press("jump");await wait(.10);Input.action_release("jump");Input.action_release("modifier");await wait(.08);mix=measure()
	check(counts("dash")>before and mix.rms>.004,"实际空冲输入触发可测突进音效",mix)
	before=counts("land_");await wait(.8);mix=measure();check(counts("land_")>before,"跳跃及突进后的接地触发物理落地音效",mix)
	before=counts("roll");await wait(.2);Input.action_press("dodge");await wait(.1);Input.action_release("dodge");check(counts("roll")>before,"实际翻滚输入触发身法音效")
	check(counts("foot_")>0 and counts("ladder_")>0 and counts("grapple_launch")>0 and counts("grapple_attach")>0,"主线真实输入触发脚步攀梯钩索声音")
	check(counts("whoosh_heavy")>0 and counts("hit_metal_")>0 and counts("hit_flesh_")>0 and counts("parry")>0 and counts("bow_fire")>0,"战斗有效事件触发挥击命中弹反与弓弦声音")
	check(counts("elevator_start")>0 and counts("elevator_stop")>0 and counts("gear_latch")>0,"升降起停与齿轮操作触发机械音效")
	audio.reset_defaults(false);game.load_room(0);game.set_screen("play");game.player.position=Vector3(-4,0,0);var enemy: Node=game.enemies[0];enemy.state="recover";enemy.clock=-10;await wait(.5)
	mix=measure();check(audio.combat_mode=="combat" and audio.gains.music_combat>.3 and mix.rms>.002,"附近战斗切入战斗音乐",mix)
	var completed: bool=game.flags.get("boss",false);game.flags.boss=false;game.load_room(6);game.set_screen("play");game.player.position=Vector3(0,0,0);await wait(.6)
	check(audio.combat_mode=="boss" and audio.gains.music_boss>.5,"Boss 遭遇切入 Boss 音乐")
	game.flags.boss=completed;game.load_room(2);game.set_screen("play");before=counts("press_hit");await wait(3);measure()
	check(counts("press_hit")>before and counts("press_warning")>0,"周期压锤真实运动触发预警与碰撞音效")
	game.load_room(8);game.set_screen("play");await wait(.5);check(audio.ambient_name=="amb_gears" and audio.gains.amb_gears>.5,"换房交叉淡入对应机械环境底噪")
	audio.set_volume("SFX",.42,true);audio.settings.SFX=.9;audio.load_settings();check(absf(audio.settings.SFX-.42)<.001,"独立音量设置保存并恢复")
	audio.reset_defaults(true);game.set_screen("audio");await wait(.2)
	check(game.ui.audio_controls.size()==8,"声音菜单显示四组音量滑杆和数值")
	if not path.is_empty():
		await RenderingServer.frame_post_draw;game.get_viewport().get_texture().get_image().save_png(path.path_join("11_audio.png"))
		var wav:=AudioStreamWAV.new();wav.mix_rate=int(AudioServer.get_mix_rate());wav.stereo=true;wav.format=AudioStreamWAV.FORMAT_16_BITS
		var bytes:=PackedByteArray();bytes.resize(recorded.size()*4)
		for i in recorded.size():bytes.encode_s16(i*4,int(clampf(recorded[i].x,-1,1)*32767));bytes.encode_s16(i*4+2,int(clampf(recorded[i].y,-1,1)*32767))
		wav.data=bytes;wav.save_to_wav(path.get_base_dir().path_join("audio_mix_preview.wav"))
	AudioServer.remove_bus_effect(master,AudioServer.get_bus_effect_count(master)-1)
	var out:=FileAccess.open(path.get_base_dir().path_join("audio_runtime.json") if not path.is_empty() else "user://audio_runtime.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"driver":AudioServer.get_driver_name(),"output_device":AudioServer.output_device,"sample_rate":AudioServer.get_mix_rate(),"checks":checks,"events":audio.events,"notes":"Captured game mixer PCM; physical speaker listening and Windows per-app mixer were not verified."},"  "));out.close()
	game.set_screen("play");return checks
