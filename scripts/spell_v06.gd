extends Node3D
var game: Node3D
var direction := 1.0
var damage := 35.0
var kind := "bone"
var owner_slot := 3
var elapsed := 0.0
var hit_targets: Dictionary={}
var healed := false
func _ready() -> void:
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.7,.12,.12);mesh.mesh=box
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color(.85,.8,.55) if kind=="bone" else Color(.9,.08,.2);mat.emission_enabled=true;mat.emission=mat.albedo_color;mesh.material_override=mat;add_child(mesh)
func _physics_process(dt: float) -> void:
	if game.paused or game.hitstop>0:return
	var previous:=elapsed;elapsed+=dt
	if elapsed>1.4:queue_free();return
	if kind=="bone" and elapsed>.7 and previous<=.7:direction=-direction;hit_targets.clear()
	var next:=position+Vector3(direction*12*dt,0,0)
	var query:=PhysicsRayQueryParameters3D.create(global_position,next,1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():game.spawn_sparks(position,true);queue_free();return
	for enemy in game.enemies:
		if not is_instance_valid(enemy) or hit_targets.has(enemy.get_instance_id()):continue
		if absf(enemy.position.x-next.x)>.65 or absf(enemy.position.y+1-next.y)>1.25:continue
		var uid: int=enemy.get_instance_id();hit_targets[uid]=true;enemy.hurt(damage,direction,20)
		if kind=="leech" and not healed:game.party_hp[owner_slot]=minf(game.Content.ROSTER[owner_slot].hp,game.party_hp[owner_slot]+8);healed=true;game.toast("血瓶命中 · 恢复 8 生命")
		if kind=="blood_burst":
			for other in game.enemies:
				if is_instance_valid(other) and other!=enemy and other.position.distance_to(enemy.position)<2.6:
					var ray:=PhysicsRayQueryParameters3D.create(next,other.position+Vector3(0,1,0),1)
					if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():other.hurt(damage*.6,direction,25)
		if kind!="bone":game.spawn_sparks(next,false);queue_free();return
	position=next
