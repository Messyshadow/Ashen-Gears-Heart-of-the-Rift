extends SkeletonModifier3D
## Two-link foot support after AnimationTree sampling. Only case 03 stairs.
## Uses exact visible tread heights, never moves the collision body/root.
var actor: CharacterBody3D
var locks: Dictionary = {}
var offsets: Dictionary = {}
var corrected_frames := 0
var max_correction := 0.0

func _process_modification() -> void:
	var s := get_skeleton()
	if not actor or not s: return
	if actor.game.index != 3 or actor.motion != "ground" or not actor.is_on_floor() or not actor.current_clip in ["StairUp","StairDown"]:
		locks.clear()
		return
	for side in ["L","R"]:
		var thigh := s.find_bone("thigh"+side)
		var shin := s.find_bone("shin"+side)
		var foot := s.find_bone("foot"+side)
		if thigh < 0 or shin < 0 or foot < 0: continue
		var hip_pose := s.get_bone_global_pose(thigh)
		var knee_pose := s.get_bone_global_pose(shin)
		var ankle_pose := s.get_bone_global_pose(foot)
		var world_ankle := s.to_global(ankle_pose.origin)
		if not offsets.has(side): offsets[side] = (s.global_basis * s.get_bone_global_rest(foot).origin).y
		var lift: float = world_ankle.y - actor.global_position.y - float(offsets[side])
		var planted := lift < .045
		var target_world := world_ankle
		if planted:
			if not locks.has(side): locks[side] = world_ankle
			target_world.x = float(locks[side].x)
		else: locks.erase(side)
		var lower: bool = actor.switch_lane == 1
		var a := Vector2(1,4) if lower else Vector2(-12,8)
		var b := Vector2(-12,0) if lower else Vector2(1,4)
		var t := clampf((target_world.x-a.x)/(b.x-a.x),0,1)
		var step := minf(floorf(t*20)+1,20)
		var surface_y := lerpf(a.y,b.y,step/20)
		target_world.y = surface_y + float(offsets[side]) + maxf(lift,0)
		var correction := target_world - world_ankle
		correction = correction.limit_length(.24)
		max_correction = maxf(max_correction,correction.length())
		var target_local := s.to_local(world_ankle+correction)
		var h := hip_pose.origin
		var k := knee_pose.origin
		var e := ankle_pose.origin
		var length_a := h.distance_to(k)
		var length_b := k.distance_to(e)
		var direction := target_local-h
		var distance := clampf(direction.length(),absf(length_a-length_b)+.001,length_a+length_b-.002)
		direction = direction.normalized()
		var along := (length_a*length_a-length_b*length_b+distance*distance)/(2*distance)
		var perpendicular := sqrt(maxf(0,length_a*length_a-along*along))
		var pole := k-h-direction*((k-h).dot(direction))
		if pole.length() < .001: pole = s.global_basis.inverse()*Vector3(actor.facing,0,0)
		pole = pole.normalized()
		var wanted_knee := h+direction*along+pole*perpendicular
		var wanted_ankle := h+direction*distance
		hip_pose.basis = Basis(Quaternion((k-h).normalized(),(wanted_knee-h).normalized()))*hip_pose.basis
		knee_pose.basis = Basis(Quaternion((e-k).normalized(),(wanted_ankle-wanted_knee).normalized()))*knee_pose.basis
		knee_pose.origin = wanted_knee
		ankle_pose.origin = wanted_ankle
		s.set_bone_global_pose(thigh,hip_pose)
		s.set_bone_global_pose(shin,knee_pose)
		s.set_bone_global_pose(foot,ankle_pose)
		corrected_frames += 1
