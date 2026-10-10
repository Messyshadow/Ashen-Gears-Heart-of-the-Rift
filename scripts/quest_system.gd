extends RefCounted
var game: Node3D
var catalog: Array=[]
func setup(g: Node3D) -> void:game=g;catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/quests.json"))
func find(id: String) -> Dictionary:
 for q in catalog:
  if q.id==id:return q
 return {}
func handle(kind: String) -> bool:
 if not kind.begins_with("quest_") and not kind.begins_with("proof_"):return false
 var id: String=kind.trim_prefix("quest_").trim_prefix("proof_");var q: Dictionary=find(id)
 if q.is_empty():return false
 var state: int=int(game.campaign.quest_states.get(id,0))
 if state>=3:game.toast(q.title+" · 已完成");return true
 if kind.begins_with("proof_"):
  if state==0:game.toast("先在 "+game.rooms[q.room].name+" 接取委托");return true
  game.campaign.quest_states[id]=2;game.toast("证物已保全 · 返回 "+game.rooms[q.room].name);game.sound("chest")
 elif state==0:game.campaign.quest_states[id]=1;game.show_story(q.title+"\n"+q.description+"\n证物收进任务记录，不会被出售或读档丢失。")
 elif state==1:game.toast("证物尚未取得 · "+game.rooms[q.proof_room].name)
 elif state==2:
  if game.alive_count()>0:game.toast("先击退委托地点的追兵，再交付证物");return true
  game.campaign.quest_states[id]=3;game.flags[id]=true;game.skill_points+=3;game.scrap+=35;game.inventory.grant(q.reward);game.sound("save");game.toast(q.title+" · 完成，技能点 +3 与 "+game.inventory.CATALOG[q.reward].name,5)
 game.save_game();return true
