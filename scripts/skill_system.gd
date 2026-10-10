extends RefCounted
var game: Node3D
var actor := 0
var selected := "C1"
var levels: Dictionary={}
var definitions: Dictionary={}
const NODES=["C1","C2","C3","M1","M2","M3","T1","T2","T3"]

func catalog(slot: int) -> Dictionary:
 if definitions.is_empty():definitions=JSON.parse_string(FileAccess.get_file_as_string("res://data/skills.json"))
 return definitions.get(str(slot),{})
func key(slot: int,node: String) -> String:return "%d:%s"%[slot,node]
func level(slot: int,node: String) -> int:
 var result: int=int(levels.get(key(slot,node),0))
 var legacy: int={"C1":0,"C2":1,"M2":2,"C3":3}.get(node,-1)
 if legacy>=0 and game.learned.has("%d_%d"%[slot,legacy]):result=maxi(1,result)
 return result
func restore(saved: Dictionary) -> void:
 levels={}
 for id in saved:
  var bits: PackedStringArray=str(id).split(":")
  if bits.size()==2 and int(bits[0])>=0 and int(bits[0])<game.Content.ROSTER.size() and bits[1] in NODES:levels[id]=clampi(int(saved[id]),0,3)
func requirement(slot: int,node: String) -> String:
 if slot not in game.available_slots():return "先招募这位同伴，可预览全部招式"
 if level(slot,node)>=3:return "已达最高等级"
 var previous: String=node.left(1)+str(int(node.right(1))-1)
 if node.right(1)!="1" and level(slot,previous)<=0:return "前置："+str(catalog(slot)[previous].name)
 if node.begins_with("T") and not game.flags.get("boss5",false):return "击败血契侯爵后开放共鸣"
 var cost: int=point_cost(slot,node)
 if game.skill_points<cost:return "需要 %d 技能点"%cost
 var material: int=level(slot,node)
 if game.inventory.owned("gear_core")<material:return "需要 %d 齿芯"%material
 return ""
func point_cost(slot: int,node: String) -> int:return int(node.right(1))+(1 if node=="T1" else 0)+level(slot,node)
func upgrade(slot: int,node: String) -> bool:
 var reason: String=requirement(slot,node)
 if not reason.is_empty():game.toast(reason);return false
 var old: int=level(slot,node);game.skill_points-=point_cost(slot,node)
 game.inventory.items.gear_core=game.inventory.owned("gear_core")-old
 levels[key(slot,node)]=old+1
 var legacy: int={"C1":0,"C2":1,"M2":2,"C3":3}.get(node,-1)
 if legacy>=0:game.learned["%d_%d"%[slot,legacy]]=true
 game.sound("skill");game.save_game();game.ui.rebuild_buttons();return true
func bonus(slot: int,stat: String) -> float:
 if stat=="hp":return level(slot,"M1")*5.0
 if stat=="defense":return level(slot,"M3")*.02
 if stat=="stamina":return level(slot,"M1")*.08
 if stat=="damage":return (level(slot,"C1")+level(slot,"C2")+level(slot,"C3"))*.035
 return 0
func choose_actor(slot: int) -> void:
 actor=clampi(slot,0,game.Content.ROSTER.size()-1);selected="C1";game.set_screen("skills")
func animation(slot: int,node: String) -> String:
 if node=="M1":return "Roll"
 if node=="M2":return "AirDash"
 if node=="M3":return "WallKick"
 if node=="T1":return "Guard"
 if node=="T2":return "Run"
 if node=="T3":return "Skill"
 if slot>=7:return ["RoleLight","RoleSkill","RoleHeavy"][int(node.right(1))-1]
 if slot==0:return ["Dagger3","Skill","Heavy"][int(node.right(1))-1]
 if slot==1:return ["MechLight","MechHeavy","Skill"][int(node.right(1))-1]
 if slot==2:return ["BowShot","Skill","Heavy"][int(node.right(1))-1]
 return [["BoneThrust","BoneSlash","Skill"],["ShadowBind","ShadowStrike","Skill"],["BloodCast","RapierThrust","Skill"],["ElectricPunch","ElectricBurst","Skill"]][slot-3][int(node.right(1))-1]
