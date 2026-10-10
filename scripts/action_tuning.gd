extends RefCounted
# Seconds and metres. Animation clips stay in the existing Blender assets.
const MOVEMENT={"coyote_seconds":.10,"jump_buffer_seconds":.12,"jump_speed":12.5,"double_jump_speed":11.8,"gravity_up":31.25,"gravity_down":42.2,"jump_release_gravity":20.0,"ground_acceleration":30.0,"air_acceleration":15.0}
const INPUT={"attack_buffer_seconds":.22,"dodge_buffer_seconds":.12,"combo_cancel_fraction":.72,"dodge_cancel_fraction":.80}
const IMPACT={
	"light":{"stop":.05,"flash":.04,"shake":.025,"trauma":.24,"stun":.22,"knockback":2.0,"particles":7},
	"medium":{"stop":.075,"flash":.055,"shake":.04,"trauma":.40,"stun":.30,"knockback":2.7,"particles":11},
	"heavy":{"stop":.11,"flash":.07,"shake":.06,"trauma":.58,"stun":.38,"knockback":3.5,"particles":15},
	"critical":{"stop":.12,"flash":.08,"shake":.07,"trauma":.68,"stun":.42,"knockback":4.0,"particles":18},
	"parry":{"stop":.08,"flash":.06,"shake":.04,"trauma":.42,"stun":.45,"knockback":0.0,"particles":11},
	"block":{"stop":.025,"flash":.025,"shake":.015,"trauma":.12,"stun":.10,"knockback":0.0,"particles":7}
}
const CAMERA={"decay_per_second":1.65,"max_trauma":.8,"horizontal_metres":.25,"vertical_metres":.15,"frequency":34.0,"zoom_fraction":.018}
# Active windows follow startup; the remainder is recovery. Multi-hit skills
# extend their cancellation boundary through their final authored contact.
const ACTIVE_SECONDS={"Dagger1":.065,"Dagger2":.065,"Dagger3":.065,"Katana1":.075,"Katana2":.075,"Katana3":.085,"KatanaHeavy":.10,"MechLight":.08,"MechHeavy":.10,"Heavy":.08,"BoneSlash":.08,"BoneThrust":.09,"ShadowStrike":.05,"ShadowBind":.08,"RapierThrust":.06,"BloodCast":.08,"ElectricPunch":.06,"ElectricBurst":.10,"BowShot":.04,"Skill":.08}
# [total seconds, startup seconds]; recovery = total - startup - active.
const ATTACK_TIMINGS={"Dagger1":[.34,.10],"Dagger2":[.34,.10],"Dagger3":[.34,.10],"Heavy":[.86,.36],"MechLight":[.34,.10],"MechHeavy":[.86,.36],"BowShot":[.34,.10],"BowShotHeavy":[.86,.36],"Katana1":[.50,.19],"Katana2":[.54,.21],"Katana3":[.65,.26],"KatanaHeavy":[1.0,.48],"BoneSlash":[.46,.18],"BoneThrust":[.8,.32],"ShadowStrike":[.27,.1],"ShadowBind":[.62,.25],"RapierThrust":[.4,.16],"BloodCast":[.75,.3],"ElectricPunch":[.36,.13],"ElectricBurst":[.8,.32]}
const SKILL_TIMINGS={"3_0":[.7,.22],"3_1":[.8,.16],"4_0":[.65,.24],"4_1":[.5,.18],"5_0":[.8,.28],"5_1":[.8,.28],"6_0":[.8,.3],"6_1":[.65,.25]}
static func tier_for_damage(amount: float) -> String:return "critical" if amount>=90 else "heavy" if amount>=45 else "medium" if amount>=30 else "light"
