extends Node
const Tuning=preload("res://scripts/action_tuning.gd")
var game: Node3D
var targets: Dictionary={}
var trauma := 0.0
var phase := 0.0
var last_event: Dictionary={}
func reset() -> void:
	for item in targets.values():clear_visual(item)
	targets.clear();trauma=0;phase=0
func clear_visual(item: Dictionary) -> void:
	var visual: Node3D=item.visual.get_ref()
	if is_instance_valid(visual):visual.position=item.base
	for reference in item.meshes:
		var mesh: MeshInstance3D=reference.get_ref()
		if is_instance_valid(mesh) and mesh.material_overlay==item.material:mesh.material_overlay=null
func prepare(victim: Node) -> Dictionary:
	if not is_instance_valid(victim) or not is_instance_valid(victim.visual):return {}
	var id: int=victim.get_instance_id();var item: Dictionary=targets.get(id,{})
	if not item.is_empty() and item.visual.get_ref()!=victim.visual:clear_visual(item);item={}
	if item.is_empty():
		var material:=ShaderMaterial.new();material.shader=preload("res://scripts/hit_flash.gdshader")
		var meshes: Array=[]
		for mesh in victim.visual.find_children("*","MeshInstance3D",true,false):meshes.append(weakref(mesh))
		item={"actor":weakref(victim),"visual":weakref(victim.visual),"base":victim.visual.position,"material":material,"meshes":meshes,"last":-10.0,"chain":0,"flash":0.0,"shake_time":0.0,"shake":0.0,"warm":.04}
		material.set_shader_parameter("strength",.001)
		for reference in meshes:
			var mesh: MeshInstance3D=reference.get_ref()
			if is_instance_valid(mesh):mesh.material_overlay=material
		targets[id]=item
	return item
func impact(victim: Node,direction: float,tier: String,attacker: Node=null,play_sound: bool=true) -> Dictionary:
	var item: Dictionary=prepare(victim)
	if item.is_empty():return {}
	var id: int=victim.get_instance_id();var profile: Dictionary=Tuning.IMPACT.get(tier,Tuning.IMPACT.light)
	item.warm=0
	item.chain=mini(int(item.chain)+1,3) if game.main_clock-float(item.last)<.5 else 0
	item.last=game.main_clock
	var duration: float=float(profile.stop)*maxf(.55,1-float(item.chain)*.2)
	victim.hit_pause=maxf(victim.hit_pause,duration)
	if victim.animator:victim.animator.speed_scale=0
	if is_instance_valid(attacker):
		attacker.hit_pause=maxf(attacker.hit_pause,duration)
		if attacker.animator:attacker.animator.speed_scale=0
	item.flash=float(profile.flash);item.shake_time=duration+.05;item.shake=float(profile.shake);item.direction=direction
	item.material.set_shader_parameter("strength",.8);item.material.set_shader_parameter("tint",Vector3(.35,.8,1) if tier=="parry" else Vector3(1,.72,.3) if tier=="block" else Vector3.ONE)
	for reference in item.meshes:
		var mesh: MeshInstance3D=reference.get_ref()
		if is_instance_valid(mesh):mesh.material_overlay=item.material
	targets[id]=item;trauma=minf(Tuning.CAMERA.max_trauma,maxf(trauma,float(profile.trauma))+float(profile.trauma)*.08)
	var point: Vector3=victim.position+Vector3(0,1,0)
	game.particles(point,2,Color(.2,.75,1) if tier=="parry" else Color(1,.6,.15) if tier=="block" else Color(1,.43,.05) if victim!=game.player and not victim.definition.get("human",false) else Color(.8,.14,.07),direction,int(profile.particles))
	if play_sound:
		game.sound("parry" if tier=="parry" else "guard" if tier=="block" else "hit" if victim==game.player else "hit_flesh_%d"%randi_range(1,2) if victim.definition.get("human",false) else "hit_metal_%d"%randi_range(1,2),point)
	last_event={"tier":tier,"duration":duration,"victim":id,"attacker":attacker.get_instance_id() if is_instance_valid(attacker) else 0,"time_usec":Time.get_ticks_usec(),"particles":int(profile.particles)}
	return profile
func _process(dt: float) -> void:
	if not game.paused:phase+=dt*Tuning.CAMERA.frequency;trauma=move_toward(trauma,0,dt*Tuning.CAMERA.decay_per_second)
	for id in targets.keys():
		var item: Dictionary=targets[id];var actor: Node=item.actor.get_ref();var visual: Node3D=item.visual.get_ref()
		if not is_instance_valid(actor) or not is_instance_valid(visual) or actor.visual!=visual:clear_visual(item);targets.erase(id);continue
		if float(item.warm)>0:item.warm=maxf(0,float(item.warm)-dt);continue
		if game.paused and float(item.flash)>0:continue
		item.flash=maxf(0,float(item.flash)-dt);item.shake_time=maxf(0,float(item.shake_time)-dt)
		if float(item.flash)>0:item.material.set_shader_parameter("strength",minf(.8,float(item.flash)*18))
		else:
			for reference in item.meshes:
				var mesh: MeshInstance3D=reference.get_ref()
				if is_instance_valid(mesh) and mesh.material_overlay==item.material:mesh.material_overlay=null
		visual.position=item.base+Vector3(sin(game.main_clock*120)*float(item.shake),cos(game.main_clock*145)*float(item.shake)*.35,0) if float(item.shake_time)>0 else item.base
func camera_offset() -> Vector3:
	var weight: float=trauma*trauma
	return Vector3((sin(phase)+.35*sin(phase*1.73))*Tuning.CAMERA.horizontal_metres*weight,cos(phase*1.37)*Tuning.CAMERA.vertical_metres*weight,0)
func zoom_factor() -> float:return 1-Tuning.CAMERA.zoom_fraction*trauma*trauma
