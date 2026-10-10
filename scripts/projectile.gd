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
	add_child(game.projectile_visual(friendly))
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
		else:game.sound("hit_metal_1",hit.position)
		game.spawn_sparks(hit.position,true);queue_free();return
	global_position=next
