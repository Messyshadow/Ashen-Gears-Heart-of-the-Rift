extends Node
const Tuning=preload("res://scripts/action_tuning.gd")
var game: Node3D
var targets: Dictionary={}
var trauma := 0.0
var phase := 0.0
var kick := Vector3.ZERO
var camera_window := -1.0
var camera_frame := -1
var weight_frame := -1
var cues: Array=[]
var cue_pool: Array=[]
var cue_meshes: Dictionary={}
var last_cue: Dictionary={}
var last_event: Dictionary={}
func reset() -> void:
	for item in targets.values():clear_visual(item)
	targets.clear();trauma=0;phase=0;kick=Vector3.ZERO;camera_window=-1;camera_frame=-1;weight_frame=-1
	for cue in cues:
		if is_instance_valid(cue.node):cue.node.queue_free()
	for node in cue_pool:
		if is_instance_valid(node):node.queue_free()
	cues.clear();cue_pool.clear()
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
func impact(victim: Node,direction: float,tier: String,attacker: Node=null,play_sound: bool=true,contact_point: Vector3=Vector3.INF) -> Dictionary:
	var item: Dictionary=prepare(victim)
	if item.is_empty():return {}
	var id: int=victim.get_instance_id();var profile: Dictionary=Tuning.IMPACT.get(tier,Tuning.IMPACT.light)
	item.warm=0
	item.chain=mini(int(item.chain)+1,3) if game.main_clock-float(item.last)<.5 else 0
	item.last=game.main_clock
	var stop: float=float(profile.stop)
	if attacker==game.player and is_instance_valid(attacker) and attacker.attack_clock>0 and attacker.attack_tier==tier:stop=float(Tuning.WEAPON_STOP.get(attacker.attack_clip,stop))
	var duration: float=stop*maxf(.55,1-float(item.chain)*.2)
	victim.hit_pause=maxf(victim.hit_pause,duration)
	if victim.animator:victim.animator.speed_scale=0
	if is_instance_valid(attacker):
		attacker.hit_pause=maxf(attacker.hit_pause,duration)
		if attacker.animator:attacker.animator.speed_scale=0
	item.flash=float(profile.flash);item.shake_time=duration+.05;item.shake=float(profile.shake);item.direction=direction
	item.material.set_shader_parameter("strength",.8*setting("flash"));item.material.set_shader_parameter("tint",Vector3(.35,.8,1) if tier=="parry" else Vector3(1,.72,.3) if tier=="block" else Vector3.ONE)
	for reference in item.meshes:
		var mesh: MeshInstance3D=reference.get_ref()
		if is_instance_valid(mesh):mesh.material_overlay=item.material
	targets[id]=item
	var point: Vector3=contact_point if contact_point.is_finite() else victim.position+Vector3(0,1,0)
	var material: String="flesh" if victim==game.player or victim.definition.get("human",false) else "soul" if victim.kind in ["wraith","specter","judge","elite6"] else "metal"
	var col:=Color(.25,.65,1) if tier=="parry" else Color(1,.72,.25) if tier=="block" else Color(.48,.35,1) if material=="soul" else Color(.8,.12,.10) if material=="flesh" and setting("blood")>0 else Color(1,.55,.18)
	var count: int=int(profile.particles)
	if material=="flesh":count=maxi(3,roundi(count*setting("blood")))
	game.particles(point,2,col,direction,count)
	contact_cue(point,direction,tier,col)
	var distance: float=point.distance_to(game.player.position)
	var attenuation: float=clampf(1-distance/16,0,1)
	var weight: float=float(profile.trauma)*attenuation
	var frame: int=Engine.get_physics_frames()
	if frame!=camera_frame and game.main_clock>camera_window:trauma=minf(Tuning.CAMERA.max_trauma,maxf(trauma,weight)+weight*.06);camera_window=game.main_clock+Tuning.CONTACT.camera_window_seconds
	else:trauma=maxf(trauma,weight)
	camera_frame=frame;kick.x=direction*minf(.055,float(profile.shake))*attenuation
	if play_sound:
		var cue: String="parry" if tier=="parry" else "guard" if tier=="block" else "hit" if victim==game.player else "skill" if material=="soul" else "hit_flesh_%d"%randi_range(1,2) if material=="flesh" else "hit_metal_%d"%randi_range(1,2)
		game.sound(cue,point)
		if tier in ["heavy","critical"] and frame!=weight_frame:game.audio_system.play_event("hit_weight",point,Tuning.CONTACT.heavy_layer_db);weight_frame=frame
	if game.pad>=0 and setting("rumble")>0:Input.start_joy_vibration(game.pad,.16*float(profile.trauma)*setting("rumble"),.40*float(profile.trauma)*setting("rumble"),minf(.13,duration+.04))
	last_event={"tier":tier,"duration":duration,"victim":id,"attacker":attacker.get_instance_id() if is_instance_valid(attacker) else 0,"time_usec":Time.get_ticks_usec(),"particles":count,"point":point,"material":material,"camera_frame":frame}
	return profile
func _process(dt: float) -> void:
	if not game.paused:
		phase+=dt*Tuning.CAMERA.frequency;trauma=move_toward(trauma,0,dt*Tuning.CAMERA.decay_per_second);kick=kick.move_toward(Vector3.ZERO,dt*.9)
		tick_cues(dt)
	for id in targets.keys():
		var item: Dictionary=targets[id];var actor: Node=item.actor.get_ref();var visual: Node3D=item.visual.get_ref()
		if not is_instance_valid(actor) or not is_instance_valid(visual) or actor.visual!=visual:clear_visual(item);targets.erase(id);continue
		if float(item.warm)>0:item.warm=maxf(0,float(item.warm)-dt);continue
		if game.paused and float(item.flash)>0 and setting("flash")>0:continue
		item.flash=maxf(0,float(item.flash)-dt);item.shake_time=maxf(0,float(item.shake_time)-dt)
		if float(item.flash)>0 and setting("flash")>0:item.material.set_shader_parameter("strength",minf(.8,float(item.flash)*18)*setting("flash"))
		else:
			for reference in item.meshes:
				var mesh: MeshInstance3D=reference.get_ref()
				if is_instance_valid(mesh) and mesh.material_overlay==item.material:mesh.material_overlay=null
		if actor!=game.player and actor.hp<=0:continue
		visual.position=item.base+Vector3(sin(game.main_clock*120)*float(item.shake),cos(game.main_clock*145)*float(item.shake)*.35,0) if float(item.shake_time)>0 else item.base
func camera_offset() -> Vector3:
	var weight: float=trauma*trauma
	return (kick+Vector3((sin(phase)+.35*sin(phase*1.73))*Tuning.CAMERA.horizontal_metres*weight,cos(phase*1.37)*Tuning.CAMERA.vertical_metres*weight,0))*setting("shake")
func zoom_factor() -> float:return 1-Tuning.CAMERA.zoom_fraction*trauma*trauma*setting("zoom")

func setting(key: String) -> float:return float(game.graphics.settings.get(key,1)) if is_instance_valid(game.graphics) else 1.0
func cue_mesh(slash: bool) -> Mesh:
	if cue_meshes.has(slash):return cue_meshes[slash]
	var result: Mesh
	if slash:
		var arrays: Array=[];arrays.resize(Mesh.ARRAY_MAX);var vertices:=PackedVector3Array()
		for i in range(20):
			var a: float=lerpf(-1.05,1.10,i/20.0);var b: float=lerpf(-1.05,1.10,(i+1)/20.0)
			var p:=Vector3(cos(a),sin(a),0);var q:=Vector3(cos(b),sin(b),0)
			vertices.append_array(PackedVector3Array([p*.94,p,q,q,p*.94,q*.94]))
		arrays[Mesh.ARRAY_VERTEX]=vertices;var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);result=mesh
	else:
		var ring:=TorusMesh.new();ring.inner_radius=.22;ring.outer_radius=.26;ring.rings=20;ring.ring_segments=4;result=ring
	cue_meshes[slash]=result;return result
func spawn_cue(point: Vector3,col: Color,slash: bool,scale: Vector3,life: float) -> void:
	if cues.size()>=Tuning.CONTACT.cue_pool_limit:return
	var node: MeshInstance3D
	if not cue_pool.is_empty():node=cue_pool.pop_back()
	else:
		node=MeshInstance3D.new();game.world.add_child(node);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;node.material_override=mat
	node.mesh=cue_mesh(slash);node.position=point;node.rotation=Vector3.ZERO if slash else Vector3(PI/2,0,0);node.scale=scale;node.visible=true;node.material_override.albedo_color=col
	cues.append({"node":node,"color":col,"life":life,"total":life,"scale":scale,"slash":slash})
func contact_cue(point: Vector3,direction: float,tier: String,col: Color) -> void:
	var size: float=.65 if tier=="light" else 1.1 if tier in ["medium","block"] else 1.6
	spawn_cue(point,col,false,Vector3.ONE*size,.10 if tier=="light" else .16);last_cue={"point":point,"tier":tier,"color":col}
func swing(actor: Node,reach: float,clip_name: String) -> void:
	if clip_name in ["MechLight","MechHeavy","ElectricPunch","ElectricBurst"] or (game.active_slot>=7 and game.Content.ROSTER[game.active_slot].archetype in ["steam","healer"]):return
	var radius: float=clampf(reach*.68,.7,2.4)
	spawn_cue(actor.position+Vector3(0,1.0,.3),Color(.30,.73,1,.35) if clip_name.begins_with("Katana") else Color(1,.72,.35,.27),true,Vector3(actor.facing*radius,radius,1),.10)
func tick_cues(dt: float) -> void:
	for i in range(cues.size()-1,-1,-1):
		var cue: Dictionary=cues[i]
		if not is_instance_valid(cue.node):cues.remove_at(i);continue
		cue.life-=dt
		if cue.life<=0:cue.node.visible=false;cue_pool.append(cue.node);cues.remove_at(i);continue
		var color: Color=cue.color;color.a*=cue.life/cue.total;cue.node.material_override.albedo_color=color
		if not cue.slash:cue.node.scale=cue.scale*(1+(1-cue.life/cue.total)*.5)
