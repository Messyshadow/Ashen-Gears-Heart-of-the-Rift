extends RefCounted
var builder_ref: WeakRef
var builder: RefCounted:
	get:return builder_ref.get_ref()
var spec: Dictionary
var animated: Array=[]
var floats: Array=[]
var vents: Array=[]
var phase_walls: Array=[]
var pendulums: Array=[]
var indicators: Array=[]
var root: AnimatableBody3D
var elapsed := 0.0

func build(b: RefCounted, room_spec: Dictionary, top: float) -> void:
	builder_ref=weakref(b);spec=room_spec
	var g: Node3D=b.game
	var regional: Dictionary=g.kit_parts("regional_kit_v06")
	b.parts.merge(regional)
	var region: int=int(spec.region)
	var variant: int=int(spec.id.right(2))-1
	for column in range(6):
		var x: float=-20+column*8+sin(column+variant)*1.2
		var p:=Vector3(x,0,-5.5-(variant%3)*.7)
		if region==3:
			b.part("WaterPipe",p,Vector3(1,maxf(1,top/7),1))
			b.part("WaterTank" if column%2==variant%2 else "WaterWheel",p+Vector3(2,1,-3),Vector3(1,1.2+(variant%3)*.4,1))
		elif region==4:
			b.part("IronTree",p,Vector3(1.4,1.2+(variant%3)*.3,1.5))
			b.part("RootVine",p+Vector3(0,0,2),Vector3(1.5,1.5,1.5))
			b.part("SporeCluster",p+Vector3(2,1,-1),Vector3(1.5,1.5,1.5))
		elif region==5:
			b.part("GothicWindow",p,Vector3(1.6,1.5,1.2))
			b.part("Bookshelf",p+Vector3(3,0,-2),Vector3(1,1.5+(variant%2)*.5,1))
			b.part("BloodVessel",p+Vector3(-2,1,1))
		else:
			b.part("LabTank",p,Vector3(1,1.6,1))
			b.part("Terminal",p+Vector3(2,0,1))
			b.part("CircuitPylon",p+Vector3(-2,1,-3),Vector3(1,2,1))
		b.part("Arch",p+Vector3(0,0,-7),Vector3(1.2,2.2,1.5))
		b.part("Lantern",p+Vector3(1.8,3,2))
		var light:=OmniLight3D.new();g.world.add_child(light);light.position=p+Vector3(1.8,3,3)
		light.light_color=[Color(.18,.62,.75),Color(.42,.76,.32),Color(.88,.19,.32),Color(.27,.62,1)][region-3]
		light.light_energy=2;light.omni_range=7;b.lights.append(light)
	for x in [-23.0,23.0]:
		var shape:=BoxShape3D.new();shape.size=Vector3(.5,top+7,5);g.body(shape,Vector3(x,top*.5,0))
	var key: String="WaterWheel" if region==3 else "ClockFace" if region==5 else "HologramRing" if region==6 else "GlassDome"
	for x in ([-10,10] if region!=4 else [0]):
		var n: MeshInstance3D=b.part(key,Vector3(x,5+(variant%3),-7),Vector3(1.5,1.5,1.5));n.set_meta("static_part",false);animated.append(n)
	if variant==6:
		b.part(["WaterTank","IronTree","ClockFace","HologramRing"][region-3],Vector3(0,1 if region in [3,4] else 6,-6),Vector3(2.5,2.5,2.5))
	if region==3:
		var pool:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(46,7);pool.mesh=plane;g.world.add_child(pool);pool.position=Vector3(0,-1.25,-2)
		var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.05,.27,.31);mat.metallic=.6;mat.roughness=.18;pool.material_override=mat
	for x in [-13,0,13]:
		var particles:=CPUParticles3D.new();g.world.add_child(particles);particles.position=Vector3(x,1,-3)
		particles.amount=12;particles.lifetime=4;particles.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;particles.emission_box_extents=Vector3(2,.1,1)
		particles.direction=Vector3(0,1,0);particles.initial_velocity_min=.3;particles.initial_velocity_max=.7;particles.gravity=Vector3.ZERO
		var mesh:=SphereMesh.new();mesh.radius=.06 if region==4 else .14;mesh.height=mesh.radius*2;mesh.radial_segments=6;mesh.rings=3
		var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_color=Color(.42,.7,.3,.3) if region==4 else Color(.35,.56,.65,.13)
		mesh.material=mat;particles.mesh=mesh
	for f in spec.get("floats",[]):
		var body:=deck(Vector3(f.x,f.low-.18,0),f.width);floats.append({"body":body,"spec":f})
	if spec.has("root_bridge"):
		var f: Dictionary=spec.root_bridge;root=deck(Vector3(f.high if g.flags.get("root_bridge",false) else f.low,f.y-.18,0),f.width)
		var crown: MeshInstance3D=b.part("IronTree",Vector3.ZERO,Vector3(.65,.65,.65));crown.reparent(root,false);crown.position=Vector3(0,.18,-2.2);crown.set_meta("static_part",false)
	for prop in spec.props:
		if prop.kind not in ["root_light","root_lock","mirror_a","mirror_b","scan","copy","plate_left","plate_right","power","split","coolant","door_link","insulate"]:continue
		var indicator:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.10;sphere.height=.20;sphere.radial_segments=8;sphere.rings=4;indicator.mesh=sphere
		var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.emission_enabled=true;indicator.material_override=mat;g.world.add_child(indicator);indicator.position=g.vector(prop.p)+Vector3(0,1.8,-.35)
		indicators.append({"node":indicator,"mat":mat,"flag":"route_power" if prop.kind=="power" else "root_bridge" if prop.kind=="root_lock" else prop.kind})
	for v in spec.get("vents",[]):
		var n: MeshInstance3D=b.part("SteamVent",Vector3(v.x,v.y,0));n.set_meta("static_part",false)
		var label: Label3D=g.marker("毒雾预警" if region==4 else "蒸汽预警",Color(1,.5,.15));g.world.add_child(label);label.position=Vector3(v.x,v.y+2.2,0);label.visible=false
		var jet:=CPUParticles3D.new();g.world.add_child(jet);jet.position=Vector3(v.x,v.y+.4,0);jet.amount=14;jet.lifetime=.5;jet.direction=Vector3.UP;jet.initial_velocity_min=2;jet.initial_velocity_max=4;jet.gravity=Vector3.ZERO;jet.emitting=false
		var mesh:=SphereMesh.new();mesh.radius=.12;mesh.height=.24;mesh.radial_segments=6;mesh.rings=3;var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.45,.75,.1,.45) if region==4 else Color(.55,.73,.8,.35);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mesh.material=mat;jet.mesh=mesh
		vents.append({"node":n,"v":v,"cd":0.0,"label":label,"jet":jet,"warning":false})
	for h in spec.get("pendulums",[]):
		var n: MeshInstance3D=b.part("Gear",Vector3(h.x,h.y+1,0),Vector3(.45,.45,.45));n.set_meta("static_part",false)
		pendulums.append({"node":n,"h":h})
	for wall in spec.get("phase_walls",[]):
		var shape:=BoxShape3D.new();shape.size=Vector3(.45,wall.height,3);var body: StaticBody3D=g.body(shape,Vector3(wall.x,wall.y+wall.height*.5,0));body.set_meta("phase_wall",true);phase_walls.append(body)
		b.part("WallPanel",Vector3(wall.x,wall.y,0),Vector3(.12,wall.height/3,1))
		var label: Label3D=g.marker("G · 薄壁相移",Color(.65,.28,.82));g.world.add_child(label);label.position=Vector3(wall.x,wall.y+wall.height+.4,0)

func deck(pos: Vector3, width: float) -> AnimatableBody3D:
	var body:=AnimatableBody3D.new();body.sync_to_physics=false;builder.game.world.add_child(body);body.position=pos
	var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(width,.36,3);collision.shape=box;body.add_child(collision)
	var n: MeshInstance3D=builder.part("Platform",Vector3.ZERO,Vector3(width/4,.45,1));n.reparent(body,false);n.position=Vector3(0,.18,0);n.set_meta("static_part",false)
	return body

func tick(dt: float) -> void:
	elapsed+=dt;var g: Node3D=builder.game
	for i in indicators:
		var col:=Color(.15,.85,.55) if g.flags.get(i.flag,false) else Color(.9,.27,.12)
		i.mat.albedo_color=col;i.mat.emission=col
	for node in animated:
		if spec.region==4:node.rotation.z=sin(elapsed*.35)*.015
		else:node.rotation.z+=dt*.3
	for f in floats:
		var before: Vector3=f.body.position
		f.body.position.y=move_toward(before.y,lerpf(f.spec.low,f.spec.high,clampf(float(g.water[2])/2,0,1))-.18,dt*.8)
		carry(f.body,before,f.spec.width)
	if is_instance_valid(root):
		var before:=root.position;var f: Dictionary=spec.root_bridge
		root.position.x=move_toward(root.position.x,f.high if g.flags.get("root_light",false) or g.flags.get("root_bridge",false) else f.low,dt*1.5);carry(root,before,f.width)
	for h in vents:
		h.cd=maxf(0,h.cd-dt);var v: Dictionary=h.v;var phase: float=fmod(elapsed+float(v.get("phase",0)),v.period)
		h.node.scale=Vector3(1,1.2 if phase>float(v.period)-1 else 1,1)
		var danger: bool=phase>float(v.period)-.65
		var warning: bool=phase>float(v.period)-1.2;h.label.visible=warning;h.jet.emitting=danger
		if warning and not h.warning:g.sound("press_warning",h.node.position)
		h.warning=warning
		if danger and h.cd<=0 and absf(g.player.position.x-v.x)<1.1 and absf(g.player.position.y-v.y)<1.3:
			h.cd=1;g.environment_damage(14);g.sound("press_warning",g.player.position);g.toast("管口喷发 · 跳跃或观察周期绕开")
	for p in pendulums:
		var h: Dictionary=p.h;var angle: float=sin(elapsed*TAU/float(h.period))*.85
		p.node.position=Vector3(h.x+sin(angle)*4,h.y+4.4-cos(angle)*4,0);p.node.rotation.z=angle
		if g.player.invulnerable<=0 and p.node.position.distance_to(g.player.position+Vector3(0,.9,0))<1.0:g.environment_damage(12);g.sound("hit_metal_1",p.node.position)

func carry(body: AnimatableBody3D, before: Vector3, width: float) -> void:
	var p: CharacterBody3D=builder.game.player
	if absf(p.position.x-before.x)<width*.5 and absf(p.position.y-before.y-.18)<.22 and p.velocity.y<=.1:p.position+=body.position-before
