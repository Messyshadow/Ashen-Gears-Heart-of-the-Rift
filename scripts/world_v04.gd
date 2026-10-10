extends RefCounted
const KIT = preload("res://assets/models/industrial_kit_v04.glb")
var extension: RefCounted
var game: Node3D
var parts: Dictionary={}
var moving: Array=[]
var mechanisms: Array=[]
var hazards: Array=[]
var conveyors: Array=[]
var obstacles: Array=[]
var clock := 0.0
var lights: Array[OmniLight3D]=[]
var batched_instances := 0
var batches := 0

func build(g: Node3D, spec: Dictionary) -> void:
	game=g;clock=0
	parts=game.kit_parts("industrial_kit_v04").duplicate()
	var bounds: Array=spec.bounds
	for platform in spec.platforms:platform_segment(float(platform[0]),float(platform[1]),float(platform[2]))
	for stair in spec.slopes:
		var a:=Vector2(stair.a[0],stair.a[1]);var b:=Vector2(stair.b[0],stair.b[1]);var count:=int(ceil(absf(b.x-a.x)/.55))
		for i in range(count):
			var t:=float(i)/count;var u:=float(i+1)/count
			var x:=lerpf(a.x,b.x,t);var next:=lerpf(a.x,b.x,u);var y:=lerpf(a.y,b.y,u)
			part("Platform",Vector3((x+next)*.5,y,0),Vector3(absf(next-x)/4,1,1))
		var pts:=PackedVector3Array()
		for end in [stair.a,stair.b]:
			for z in [-1.5,1.5]:
				for depth in [0,-.3]:pts.append(Vector3(end[0],end[1]+depth,z))
		var shape:=ConvexPolygonShape3D.new();shape.points=pts;game.body(shape,Vector3.ZERO)
	for route in spec.ladders:
		var length: float=route.high-route.low
		part("Ladder",Vector3(route.x,route.low,-.35),Vector3(1,length/4,1))
		var label: Label3D=game.marker("⇅",Color(.3,.7,1));game.world.add_child(label);label.position=Vector3(route.x,route.high+.5,0)
	for wall in spec.get("walls",[]):
		var shape:=BoxShape3D.new();shape.size=Vector3(.42,wall[2]-wall[1],3)
		var body: StaticBody3D=game.body(shape,Vector3(wall[0],(wall[1]+wall[2])*.5,0));body.set_meta("climbable",true)
		part("Pipe",Vector3(wall[0],wall[1],0),Vector3(1,(wall[2]-wall[1])/4,3))
		part("Coil",Vector3(wall[0],wall[1],1.7),Vector3(.24,(wall[2]-wall[1])/3,.24))
	var style: String=spec.style
	var top: float=float(bounds[3])
	if int(spec.get("region",1))>=3:
		extension=preload("res://scripts/world_extension.gd").new();extension.build(self,spec,top)
	else:build_legacy(spec,top)
	for anchor in spec.get("anchors",[]):part("Coil",game.vector(anchor)+Vector3(0,-.25,-.2),Vector3(.22,.22,.22))
	for deck in spec.get("elevators",[]):
		var body:=AnimatableBody3D.new();body.sync_to_physics=false;game.world.add_child(body);body.position=Vector3(deck.x,deck.low-.18,0)
		var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(deck.width,.36,3);shape.shape=box;body.add_child(shape)
		var visible:=part("Platform",Vector3.ZERO,Vector3(deck.width/4,.45,1));game.world.remove_child(visible);body.add_child(visible);visible.position=Vector3(0,.18,0)
		part("Pipe",Vector3(deck.x-2.5,deck.low,-1.5),Vector3(1,(deck.high-deck.low+2)/4,1))
		part("Pipe",Vector3(deck.x+2.5,deck.low,-1.5),Vector3(1,(deck.high-deck.low+2)/4,1))
		moving.append({"body":body,"low":float(deck.low)-.18,"high":float(deck.high)-.18,"target":float(deck.low)-.18,"width":float(deck.width)})
	for hazard in spec.get("hazards",[]):
		var press:=part("Platform",game.vector(hazard.p)+Vector3(0,5,0),Vector3(.7,1.8,1));press.set_meta("static_part",false);hazards.append({"node":press,"p":game.vector(hazard.p),"period":float(hazard.period),"damage_clock":0.0,"last_phase":0.0})
		part("Pipe",game.vector(hazard.p)+Vector3(0,5,-.8),Vector3(1,1.5,1))
	conveyors=spec.get("conveyors",[])
	for conveyor in conveyors:
		for x in range(int(conveyor[0]),int(conveyor[1]),2):part("Gear",Vector3(x,-.3,1.7),Vector3(.2,.2,.2))
	# Real low obstacles for vaulting, kept off mandatory door approaches.
	if style in ["conveyor","cargo","stock"]:
		var ob:=BoxShape3D.new();ob.size=Vector3(.8,.85,2.8)
		game.body(ob,Vector3(-1,.425,0));part("Crate",Vector3(-1,0,0),Vector3(.8,1,3.5));obstacles.append(Vector3(-1,.85,0))


func part(name: String, pos: Vector3, scale_value: Vector3=Vector3.ONE) -> MeshInstance3D:
	var n: MeshInstance3D=parts[name].duplicate();game.world.add_child(n);n.position=pos;n.scale=scale_value;n.set_meta("static_part",true);n.set_meta("distant_decor",pos.z < -12);return n

func platform_segment(a: float,b: float,y: float) -> void:
	var count:=int(ceil((b-a)/4))
	for i in range(count):
		var x:=lerpf(a,b,float(i)/count);var next:=lerpf(a,b,float(i+1)/count)
		part("Platform",Vector3((x+next)*.5,y,0),Vector3((next-x)/4,1,1))
	var shape:=BoxShape3D.new();shape.size=Vector3(b-a,.8,3.2);game.body(shape,Vector3((a+b)*.5,y-.4,0))
	for x in range(int(a)+1,int(b),3):part("Rail",Vector3(x,y,-1.5),Vector3(1.5,1,1))

func tick(dt: float) -> void:
	if game.paused:return
	clock+=dt
	if extension:extension.tick(dt)
	var p: CharacterBody3D=game.player
	for m in moving:
		var body: AnimatableBody3D=m.body
		var on_deck: bool=absf(p.position.x-body.position.x)<m.width*.5 and absf(p.position.y-(body.position.y+.18))<.2 and p.velocity.y<=.1
		var before: float=body.position.y
		body.position.y=move_toward(before,m.target,2.8*dt)
		if absf(body.position.y-m.target)<.01 and absf(before-m.target)>.01:game.sound("elevator_stop",body.position)
		if on_deck:p.position.y+=body.position.y-before
	for g in mechanisms:g.node.rotation.z+=dt*.35*(1 if game.flags.get("gear",false) else .2)
	for h in hazards:
		h.damage_clock=maxf(0,h.damage_clock-dt)
		var phase: float=fmod(clock,h.period)
		if phase>=2.25 and h.last_phase<2.25:game.sound("press_warning",h.p)
		if phase>=2.65 and h.last_phase<2.65:game.sound("press_hit",h.p)
		h.last_phase=phase
		h.node.position.y=h.p.y+(5 if phase<2.4 else lerpf(5,.25,clampf((phase-2.4)/.25,0,1)) if phase<2.65 else .25 if phase<3.2 else lerpf(.25,5,(phase-3.2)/.8))
		if phase>=2.65 and phase<3.2 and h.damage_clock<=0 and absf(p.position.x-h.p.x)<1.45 and p.position.y<h.p.y+1.4:
			h.damage_clock=1;game.environment_damage(18);game.toast("压锤命中 · 观察橙色预警")

func activate_deck() -> bool:
	for m in moving:
		if absf(game.player.position.x-m.body.position.x)<m.width*.5+1 and absf(game.player.position.y-m.body.position.y)<1.4:
			game.sound("elevator_start",m.body.position);m.target=m.high if absf(m.target-m.low)<.1 else m.low;game.toast("吊运台上行" if m.target==m.high else "吊运台下行");return true
	return false

func conveyor_speed(pos: Vector3) -> float:
	for c in conveyors:
		if pos.x>c[0] and pos.x<c[1] and absf(pos.y-c[2])<.2:return c[3]
	return 0

func batch_static_parts() -> void:
	var groups: Dictionary={}
	for node in game.world.get_children():
		if not node is MeshInstance3D or not node.get_meta("static_part",false):continue
		var key: String="%d:%d:%d"%[node.mesh.get_instance_id(),int(floor(node.position.x/8)),int(floor(node.position.z/8))]
		if not groups.has(key):groups[key]=[]
		groups[key].append(node)
	for group in groups.values():
		if group.size()<2:continue
		var mesh_id: int=group[0].mesh.get_instance_id()
		if not game.batched_meshes.has(mesh_id):
			var copy: Mesh=group[0].mesh.duplicate()
			for surface in copy.get_surface_count():
				var mat: Material=group[0].get_surface_override_material(surface)
				if mat:copy.surface_set_material(surface,mat)
			game.batched_meshes[mesh_id]=copy
		var mesh: Mesh=game.batched_meshes[mesh_id]
		var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=mesh;multi.instance_count=group.size()
		var batch:=MultiMeshInstance3D.new();batch.multimesh=multi;game.world.add_child(batch);batch.set_meta("distant_decor",group[0].get_meta("distant_decor",false))
		for i in range(group.size()):multi.set_instance_transform(i,group[i].transform);game.world.remove_child(group[i]);group[i].queue_free()
		batched_instances+=group.size();batches+=1

func build_legacy(spec: Dictionary,top: float) -> void:
	# Distinct architectural composition and colour-coded industrial purpose.
	var style: String=spec.style
	for x in range(-21,23,7):
		var arch_height: float=5.0 if style in ["coal","cargo","hub"] else top+1
		part("Arch",Vector3(x,0,-4),Vector3(1.07,arch_height/6.8,1))
		part("Pipe",Vector3(x+2,0,-2.6),Vector3(1,maxf(top/4,1),1))
		for y in [2.0,minf(top-1,7.0)]:
			part("Lantern",Vector3(x+1.6,y,-2.15))
			var light:=OmniLight3D.new();game.world.add_child(light);light.position=Vector3(x+1.6,y,-1.4)
			light.light_color=Color(.3,.63,1) if spec.theme in ["blue","void"] else Color(.58,.92,.53) if spec.theme=="green" else Color(1,.52,.18)
			light.light_energy=2.0;light.omni_range=6.5;lights.append(light)
	for i in range(9):
		var x: float=-26+i*6
		part("Arch",Vector3(x,-2,-12-(i%3)*3),Vector3(1.3,1.5+(i%3)*.4,1.5))
	for xy in [[-18,0],[-9,3],[0,0],[9,6],[18,0]]:
		part("WallPanel",Vector3(xy[0],xy[1],-8),Vector3(1.2,1.4,1))
	for x in [-16.0,6.0,18.0]:
		part("Chain",Vector3(x,1,-1.8),Vector3(1,top/1.92,1))
	var heat:=MeshInstance3D.new();var pool:=PlaneMesh.new();pool.size=Vector2(48,5);heat.mesh=pool;game.world.add_child(heat);heat.position=Vector3(0,-1.6,-1)
	var shader:=ShaderMaterial.new();shader.shader=preload("res://scripts/lava.gdshader");heat.material_override=shader
	if spec.theme in ["blue","green","void"]:heat.visible=false
	for x in [-20.0,20.0]:
		var wallshape:=BoxShape3D.new();wallshape.size=Vector3(.5,top+7,5)
		# Side boundaries beyond actual door triggers stop accidental coal-room resets.
		game.body(wallshape,Vector3(x+3*signf(x),top*.5,0))
	if style in ["coal","stock"]:
		for x in [-17,-11,-3,9,16]:part("CoalPile",Vector3(x,0,-2.6),Vector3(1.4,1.6,1.4))
		for x in [-14,5,17]:part("Crate",Vector3(x,0,-2.6))
	elif style=="prison" or style=="mine":
		for x in [-17,-11,-5,5,11,17]:part("Cell",Vector3(x,0,-3.3))
		for x in [-12,12]:part("Banner",Vector3(x,3,-3))
	elif style in ["execution","minotaur"]:
		part("Boiler",Vector3(0,0,-5),Vector3(2,2.5,2))
		for x in [-15,15]:part("Coil",Vector3(x,0,-2.2),Vector3(1.2,2.0,1.2))
		for x in [-9,9]:part("Gear",Vector3(x,7,-7),Vector3(2,2,1))
	elif style in ["gears","bearing","lift"]:
		for xy in [[-14,7],[0,9],[14,4]]:
			var gear:=part("Gear",Vector3(xy[0],xy[1],-5),Vector3(1.4,1.4,1));mechanisms.append({"node":gear,"kind":"gear"});gear.set_meta("static_part",false)
		for x in [-18,18]:part("Boiler",Vector3(x,0,-5),Vector3(.8,1.7,.8))
	elif style in ["workshop","hub"]:
		for x in [-14,0,14]:part("Banner",Vector3(x,1.5,-3))
		for x in [-16,-10,9,15]:part("Crate",Vector3(x,0,-2.4))
		part("Boiler",Vector3(12,0,-5))
	elif style=="cargo" or style=="bridge":
		for x in [-18,-7,4,14]:
			part("Crate",Vector3(x,0,-3),Vector3(2,2,2))
			part("Rail",Vector3(x,9,-3),Vector3(2,1,1))
	else:
		for x in [-15,0,15]:part("Boiler",Vector3(x,0,-5),Vector3(1,1.7,1))
