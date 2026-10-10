extends Node3D
# Five-second isolated demonstration. No input, save or gameplay side effects.
var actor: Node3D
var dummy: Node3D
var clip := "Skill"
var node_id := "C1"
var clock := 0.0
var animator: AnimationPlayer
var target_animator: AnimationPlayer
var struck := false
func _ready() -> void:
 animator=actor.find_child("AnimationPlayer",true,false);target_animator=dummy.find_child("AnimationPlayer",true,false)
 actor.rotation.y=PI/2;target_animator.play("PassageIdle");animator.play("PassageIdle")
func _process(dt: float) -> void:
 var previous: float=clock;clock=fmod(clock+dt,5.5)
 if clock<previous:struck=false;actor.position=Vector3.ZERO;dummy.position=Vector3(1.2,0,0);animator.play("PassageIdle");target_animator.play("PassageIdle")
 if previous<1 and clock>=1:animator.play(clip,.06)
 if clock>1.3 and clock<2.0 and not struck:
  struck=true
  if node_id.begins_with("C") or node_id=="T3":target_animator.play("Hurt",0)
 if clock>2.7 and animator.current_animation!="PassageIdle":animator.play("PassageIdle",.12)
 if node_id=="M2" and clock>1 and clock<1.5:actor.position=Vector3(sin((clock-1)*TAU)*.3,sin((clock-1)*TAU)*.45,0)
 elif node_id=="M3" and clock>1 and clock<1.7:actor.position.y=maxf(0,sin((clock-1)/.7*PI)*.7)
 elif node_id.begins_with("T"):actor.scale=Vector3.ONE*(1.08 if clock>1 and clock<2.7 else 1)
