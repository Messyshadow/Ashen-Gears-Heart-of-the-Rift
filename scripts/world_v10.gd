extends RefCounted
var builder_ref: WeakRef
var spec: Dictionary
var animated: Array=[]
var platforms: Array=[]
var elapsed := 0.0
func build(b: RefCounted,r: Dictionary,top: float) -> void:
 builder_ref=weakref(b);spec=r;b.parts.merge(b.game.kit_parts("late_kit_v10"))
 var region: int=int(r.region);var variant: int=int(r.id.right(2)) if not "H" in r.id else 9
 var colors: Array=[Color(1,.31,.08),Color(.61,.65,.80),Color(.52,.28,.75),Color(.22,.5,1),Color(.58,.15,.93),Color(1,.63,.17)]
 for i in range(5):
  var p:=Vector3(-19+i*9+sin(variant+i),0,-6-(i%2)*2)
  match region:
   7:
    b.part("FurnaceTower",p,Vector3(1,1+(variant%3)*.4,1));b.part("Pipe",p+Vector3(-2,0,1),Vector3(1,2.5,1));b.part("Gear",p+Vector3(3,3,-3),Vector3(1.5,1.5,1.5))
   8:
    b.part("EasternRoof",p,Vector3(1.6,1.4,1.4));b.part("BoneLantern",p+Vector3(3,0,1),Vector3(1.5,1.5,1.5));b.part("Crate",p+Vector3(-2,0,-2))
   9:
    b.part("ArchiveShelf",p,Vector3(1.7,1.6,1.5));b.part("BoneLantern",p+Vector3(-2,4,1));b.part("ClockFace",p+Vector3(2,7,-2))
   10:
    b.part("MagneticCoil",p,Vector3(1.8,2,1.5));b.part("MagneticRail",p+Vector3(0,3,-2),Vector3(1.4,1.4,1.4));b.part("TrainCar",p+Vector3(2,0,-3))
   11:
    b.part("RiftShard",p,Vector3(2,2.2,2));b.part("RiftPortal",p+Vector3(3,2,-4));var roof: MeshInstance3D=b.part("EasternRoof",p+Vector3(0,10,-2),Vector3(1.5,1.5,1.5));roof.rotation.z=PI
   12:
    b.part("FurnaceTower",p,Vector3(1.5,2,1.5));b.part("GothicWindow",p+Vector3(3,0,-2),Vector3(1.5,2,1.5));b.part("CrownThrone",p+Vector3(0,5,-3))
  b.part("Arch",p+Vector3(0,0,-6),Vector3(1.4,2.2,1.6));b.part("Lantern",p+Vector3(2,3,2))
  var light:=OmniLight3D.new();b.game.world.add_child(light);light.position=p+Vector3(2,4,3);light.light_color=colors[region-7];light.light_energy=2.2;light.omni_range=8;b.lights.append(light)
 var key: String="FurnaceTower" if region==7 else "RiftPortal" if region in [11,12] else "ClockFace" if region==9 else "MagneticCoil" if region==10 else "BoneLantern"
 var feature: MeshInstance3D=b.part(key,Vector3(0,4+(variant%3),-9),Vector3(2,2,2));feature.set_meta("static_part",false);animated.append(feature)
 for x in [-23.0,23.0]:
  var shape:=BoxShape3D.new();shape.size=Vector3(.5,top+7,5);b.game.body(shape,Vector3(x,top*.5,0))
 if region in [7,11,12]:
  var sheet:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(48,9);sheet.mesh=plane;b.game.world.add_child(sheet);sheet.position=Vector3(0,-1.6,-3)
  var mat:=ShaderMaterial.new();mat.shader=preload("res://scripts/lava.gdshader");sheet.material_override=mat
 for i in range(3):
  var sparks:=CPUParticles3D.new();b.game.world.add_child(sparks);sparks.position=Vector3(-14+i*14,0,-3);sparks.amount=14;sparks.lifetime=4;sparks.direction=Vector3.UP;sparks.initial_velocity_min=.3;sparks.initial_velocity_max=.8;sparks.gravity=Vector3.ZERO;sparks.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;sparks.emission_box_extents=Vector3(4,.2,2)
  var mesh:=SphereMesh.new();mesh.radius=.045;mesh.height=.09;mesh.radial_segments=6;mesh.rings=3;var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=colors[region-7];mesh.material=mat;sparks.mesh=mesh
 for f in r.get("floats",[]):
  var body: AnimatableBody3D=b.extension.deck(Vector3(f.x,f.low-.18,0),f.width);platforms.append({"body":body,"spec":f})
func tick(dt: float) -> void:
 elapsed+=dt
 for node in animated:node.rotation.z=sin(elapsed*.4)*.04 if spec.region in [7,8,12] else node.rotation.z+dt*.2
 var b: RefCounted=builder_ref.get_ref()
 for p in platforms:
  var before: Vector3=p.body.position;var goal: float=float(p.spec.high) if b.game.flags.get("gravity_high",false) else float(p.spec.low)
  p.body.position.y=move_toward(p.body.position.y,goal-.18,dt*1.5);b.extension.carry(p.body,before,p.spec.width)
