"""Apply audited integration seams once, keeping existing controllers and saves."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def edit(path, changes):
 p=ROOT/path;s=p.read_text(encoding='utf-8')
 for old,new in changes:
  if old not in s:raise RuntimeError((path,old[:80]))
  s=s.replace(old,new,1)
 p.write_text(s,encoding='utf-8')
edit('scripts/game.gd',[
 ('var progression: RefCounted','var inventory: RefCounted\nvar skills: RefCounted\nvar heat := 0.0\nvar map_marks: Dictionary={}\nvar progression: RefCounted'),
 ('setup_input();setup_environment()','inventory=preload("res://scripts/inventory.gd").new();inventory.game=self;inventory.reset()\n\tskills=preload("res://scripts/skill_system.gd").new();skills.game=self\n\tparty_hp=full_health()\n\tsetup_input();setup_environment()'),
 ('"phase":[KEY_G]}','"phase":[KEY_G],"inventory":[KEY_I],"equipment":[KEY_O]}'),
 ('["pause","map","skills","roster","journal","travel","rest"]','["pause","map","skills","roster","journal","travel","rest","inventory","equipment","shop","craft","ending"]'),
 ('if screen in ["play","map","skills","roster","journal"]:', 'if screen in ["play","map","skills","roster","journal","inventory","equipment"]:\n\t\tif event.is_action_pressed("inventory"):set_screen("play" if screen=="inventory" else "inventory");return\n\t\tif event.is_action_pressed("equipment"):set_screen("play" if screen=="equipment" else "equipment");return'),
 ('flags={};visited={};defeated={};opened={};party_hp=full_health();','flags={};visited={};defeated={};opened={};inventory.reset();skills.levels={};map_marks={};heat=0;party_hp=full_health();'),
 ('func max_hp() -> float:return Content.ROSTER[active_slot].hp','func actor_hp(slot: int) -> float:return float(Content.ROSTER[slot].hp)+float(inventory.stats(slot).get("hp",0))+skills.bonus(slot,"hp")\nfunc max_hp() -> float:return actor_hp(active_slot)\nfunc damage_multiplier() -> float:return 1.0+float(inventory.stats(active_slot).get("damage",0))+skills.bonus(active_slot,"damage")\nfunc defense_multiplier() -> float:return 1.0-minf(.65,float(inventory.stats(active_slot).get("defense",0))+skills.bonus(active_slot,"defense"))'),
 ('for actor in Content.ROSTER:values.append(float(actor.hp))','for slot in Content.ROSTER.size():values.append(actor_hp(slot))'),
 ('weapons.katana=true;equip_weapon("katana");','weapons.katana=true;inventory.grant("katana");inventory.equipment["0"]["weapon"]="katana";equip_weapon("katana");'),
 ('if kind=="chest":scrap+=20;toast(nearest.text);sound("chest")','if kind=="chest":scrap+=20;inventory.grant("gear_core",2);toast(nearest.text);sound("chest")'),
 ('func equip_weapon(value: String) -> void:\n\tequipped_weapon=value;','func equip_weapon(value: String) -> void:\n\tequipped_weapon=value;inventory.equipment["0"]["weapon"]=value;'),
 ('var payload := {"schema":1,','var payload := {"inventory":inventory.items,"equipment":inventory.equipment,"wrap":inventory.wrap,"skills_v10":skills.levels,"map_marks":map_marks,"schema":1,'),
 ('checkpoint_room=int(saved.room);checkpoint_pos=vector(saved.p);','inventory.restore(saved);skills.restore(saved.get("skills_v10",{}));map_marks=saved.get("map_marks",{});heat=0\n\tcheckpoint_room=int(saved.room);checkpoint_pos=vector(saved.p);'),
 ('magic=minf(100,magic+dt*3)','magic=minf(100,magic+dt*3*(1+float(inventory.stats(active_slot).get("magic",0))));heat=maxf(0,heat-dt*20) if player.position.y>=0 else heat'),
 ('party_hp[active_slot]=maxf(0,party_hp[active_slot]-amount);','amount*=defense_multiplier()\n\tparty_hp[active_slot]=maxf(0,party_hp[active_slot]-amount);'),
 ('func melee_hit(amount: float,reach: float,direction: float,area: bool,tier: String="") -> void:', 'func melee_hit(amount: float,reach: float,direction: float,area: bool,tier: String="") -> void:\n\tamount*=damage_multiplier()'),
 ('shot.damage=amount;shot.friendly=friendly;','shot.damage=amount*(damage_multiplier() if friendly else 1.0);shot.friendly=friendly;'),
 ('shot.damage=power;shot.kind=kind;','shot.damage=power*damage_multiplier();shot.kind=kind;'),
])
edit('scripts/player_v04.gd',[
 ('stamina+25*dt','stamina+25*dt*(1+float(game.inventory.stats(game.active_slot).get("stamina",0))+game.skills.bonus(game.active_slot,"stamina"))'),
 ('game.party_hp[game.active_slot]=maxf(0,game.party_hp[game.active_slot]-amount);','amount*=game.defense_multiplier()\n\tgame.party_hp[game.active_slot]=maxf(0,game.party_hp[game.active_slot]-amount);'),
])
edit('scripts/enemy_v04.gd',[
 ('if not game.defeated.has(uid):game.scrap+=60 if boss() else 8','game.inventory.loot(kind,uid)\n\t\tif not game.defeated.has(uid):game.scrap+=60 if boss() else 8'),
])
edit('scripts/controls_settings.gd',[
 ('"phase":"薄壁相移"}','"phase":"薄壁相移","inventory":"背包","equipment":"装备"}'),
])
print('Integrated inventory, skills and persistent state.')
