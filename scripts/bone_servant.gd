extends Node3D
var game: Node3D
var life := 4.0
var clock := 0.0
func _ready() -> void:
 var model: Node3D=game.instantiate_model("specter_v10");add_child(model);model.scale=Vector3.ONE*.6
func _physics_process(dt: float) -> void:
 if game.paused:return
 life-=dt;clock-=dt
 if life<=0:queue_free();return
 position=position.lerp(game.player.position+Vector3(-game.player.facing*.8,1.8,0),dt*4)
 if clock>0:return
 clock=.8
 var target: Node=null;var distance:=9.0
 for e in game.enemies:
  if is_instance_valid(e) and e.hp>0 and e.position.distance_to(position)<distance:target=e;distance=e.position.distance_to(position)
 if target==null:return
 var ray:=PhysicsRayQueryParameters3D.create(position,target.position+Vector3.UP,1)
 if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():target.hurt(12,signf(target.position.x-position.x),8);game.spawn_sparks(target.position+Vector3.UP,false)
