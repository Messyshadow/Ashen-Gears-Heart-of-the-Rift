extends RefCounted
static func attack(p: CharacterBody3D,heavy: bool) -> void:
 var g: Node3D=p.game;var kind: String=g.Content.ROSTER[g.active_slot].archetype
 p.spell="";p.attack_area=false
 var speed: float=.33 if kind=="ninja" else .65 if kind=="steam" else .46
 var power: float=20 if kind=="ninja" else 36 if kind=="steam" else 28
 var reach: float=3.6 if kind in ["light","dragon"] else 2.6
 if kind in ["ink","cannon","rifle","star","necromancer"]:p.spell=kind
 if heavy:p.attack_area=kind in ["steam","light"];power*=1.65;speed+=.30
 p.start_companion("RoleHeavy" if heavy else "RoleLight",speed,power,reach,.3 if heavy else .15)
static func skill(p: CharacterBody3D,slot: int) -> void:
 var g: Node3D=p.game;var kind: String=g.Content.ROSTER[g.active_slot].archetype
 p.attack_area=false;p.spell="";p.extra_hits=[]
 var power: float=50 if slot==0 else 62
 var duration:=.85;var reach:=3.8
 match kind:
  "ninja":
   p.extra_hits=[.39,.57] if slot==1 else [.38];power=25;g.snare_nearby(3.6)
  "ink":p.spell="ink";power=60 if slot==1 else 42;g.snare_nearby(4)
  "steam":p.attack_area=true;p.shield_clock=3 if slot==1 else 0;power=70;reach=4.6
  "dragon":
   if slot==0:p.spell="flame"
   else:p.attack_area=true;p.extra_hits=[.48];power=34;reach=4.2
  "light":p.extra_hits=[.46] if slot==1 else [];p.attack_area=slot==1;power=40 if slot==1 else 58
  "cannon":p.spell="cannon";power=75 if slot==1 else 62;p.extra_hits=[.45] if slot==1 else []
  "necromancer":
   p.spell="soul";g.snare_nearby(4 if slot==1 else 2.5)
   if slot==0:
    var servants: Array=g.world.find_children("BoneServant*","Node3D",false,false)
    if servants.size()<2:
     var servant:=preload("res://scripts/bone_servant.gd").new();servant.game=g;servant.name="BoneServant";servant.position=p.position+Vector3(0,1.7,0);g.world.add_child(servant)
  "healer":
   p.attack_area=true;reach=4;power=35
   if slot==1:
    for actor in g.field_slots():g.party_hp[actor]=minf(g.actor_hp(actor),g.party_hp[actor]+18)
   else:p.shield_clock=1.5
  "rifle":p.spell="rifle";p.extra_hits=[.43,.65] if slot==1 else [];power=38 if slot==1 else 70
  "star":p.spell="star";p.extra_hits=[.42,.62] if slot==1 else [];power=36 if slot==1 else 60
 p.start_companion("RoleSkill",duration,power,reach,.24)
