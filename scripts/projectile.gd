extends Node3D
var game: Node3D
var direction := 1.0
var damage := 15.0
var friendly := false
var source: Node
var life := 2.0
var speed := 14.0
var travel := Vector3.RIGHT
func _ready() -> void:
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.5,.055,.055);mesh.mesh=box
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color(.2,.75,1) if friendly else Color(1,.4,.04);mat.emission_enabled=true;mat.emission=mat.albedo_color*2;mesh.material_override=mat;add_child(mesh)
func _physics_process(dt: float) -> void:
	if game.paused or game.hitstop>0:return
	life-=dt
	if life<=0:queue_free();return
	var next:=global_position+travel*speed*dt;var query:=PhysicsRayQueryParameters3D.create(global_position,next,5 if friendly else 3)
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var target: Object=hit.collider
		if friendly and target.has_method("hurt"):target.hurt(damage,direction,14)
		elif not friendly and target==game.player:game.damage_player(damage,direction,source if is_instance_valid(source) else null)
		game.spawn_sparks(hit.position,true);queue_free();return
	global_position=next
