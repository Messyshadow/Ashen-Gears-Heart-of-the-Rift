"""One-time migration of the prototype coordinator to authored 0.4 layouts."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'scripts/game.gd';s=p.read_text(encoding='utf8')
assert 'var world_builder' not in s,'Migration already applied'
s=s.replace('res://scripts/player.gd','res://scripts/player_v04.gd').replace('res://scripts/enemy.gd','res://scripts/enemy_v04.gd')
s=s.replace('var main_clock := 0.0','var main_clock := 0.0\nvar world_builder: RefCounted\nvar hitstop := 0.0\nvar overview := false\nvar transition_pending := false')
s=s.replace('[100.0,110.0]','[100.0,110.0,95.0]').replace('user://ashen_save.json','user://ashen_save_v04.json')
s=s.replace('"pause":[KEY_ESCAPE]','"pause":[KEY_ESCAPE],"run":[KEY_ALT],"overview":[KEY_TAB]')
start=s.index('\tdata=JSON.parse_string(',s.index('func load_room'))
end=s.index('\tfor anchor in rooms[room]',start)
s=s[:start]+'''\tdata=rooms[room]
\tworld_builder=preload("res://scripts/world_v04.gd").new()
\tworld_builder.build(self,rooms[room])
\ttransition_pending=false
'''+s[end:]
s=s.replace('if defeated.has(uid):continue','if spec.kind=="boss" and flags.get("boss",false):continue\n\t\tif spec.kind=="minotaur" and flags.get("boss2",false):continue')
s=s.replace('player.last_floor=true;visited[rooms[room].id]=true','visited[rooms[room].id]=true\n\tcheckpoint_room=room;checkpoint_pos=vector(rooms[room].spawn)')
s=s.replace('\tui.queue_redraw()\n\nfunc add_prop','\tif screen!="title":save_game()\n\tui.queue_redraw()\n\nfunc add_prop',1)
a=s.index('\tvar label := marker(',s.index('func add_prop'));b=s.index('\tif kind=="rescue":',a)
s=s[:a]+'''\tvar label := marker(("→  " if kind=="exit" else "←  " if kind=="back" else "✦  ")+text_value,Color(.22,.68,1) if kind in ["save","grapple","wall"] else Color(.97,.64,.27))
\tworld.add_child(label);label.position=pos+Vector3(0,3.6 if kind in ["exit","back"] else 2.1,0);label.font_size=26;label.pixel_size=.01
\tvar prop: MeshInstance3D=world_builder.part("Gate" if kind in ["exit","back","side","hub"] else "Coil" if kind in ["save","grapple","wall"] else "Crate",pos+Vector3(0,0,-.65),Vector3.ONE if kind in ["exit","back","side","hub"] else Vector3(.6,.6,.6))
\tif kind in ["exit","back"]:prop.rotation.y=PI/2
'''+s[b:]
s=s.replace('res://assets/models/ashen_actor.glb','res://assets/models/luomao_v04.glb')
s=s.replace('\t\ttoast_clock=maxf(0,toast_clock-dt);','\t\thitstop=maxf(0,hitstop-dt)\n\t\tworld_builder.tick(dt)\n\t\ttoast_clock=maxf(0,toast_clock-dt);')
s=s.replace('\t\tupdate_nearest()','\t\tupdate_nearest()\n\t\tcheck_auto_exit()',1)
s=s.replace('desired.x=clampf(desired.x,-18+half,18-half)','desired.x=clampf(desired.x,-22+half,22-half)')
s=s.replace('desired.y=clampf(desired.y,3.0,10)','desired.y=clampf(desired.y,3.0,float(rooms[room].bounds[3])-1)\n\t\tif overview:desired=Vector3(0,(float(rooms[room].bounds[3])-5)*.5+1,0)\n\t\tcamera.size=lerpf(camera.size,maxf(18,float(rooms[room].bounds[3])+4) if overview else 12.5,1-exp(-dt*4))')
s=s.replace('func _unhandled_input(event: InputEvent) -> void:','func _unhandled_input(event: InputEvent) -> void:\n\tif event.is_action_pressed("overview") and screen=="play":overview=not overview')
s=s.replace('event.keycode in [KEY_1,KEY_2]','event.keycode in [KEY_1,KEY_2,KEY_3]')
s=s.replace('player.tree.active=not paused','player.set_animation_paused(paused)')
s=s.replace('checkpoint_pos=Vector3(-10,7,0)','checkpoint_pos=Vector3(-19,0,0)')
s=s.replace('func max_hp() -> float:return 110 if active_slot==1 else 100','func max_hp() -> float:return [100.0,110.0,95.0][active_slot]')
s=s.replace('func interact() -> void:\n\tif nearest.is_empty():return','func interact() -> void:\n\tif world_builder.activate_deck():return\n\tif nearest.is_empty():return')
s=s.replace('["exit","back","loop","hub","shortcut"]','["exit","back","loop","hub","shortcut","side","rust_loop","rust_shortcut"]')
s=s.replace('if room==10:flags.slice_complete=true;', 'if room==16:flags.slice_complete=true;')
s=s.replace('var previous := room-1','var previous := int(rooms[room].previous)')
s=s.replace('\t\tif kind=="shortcut":flags.shortcut=true;call_deferred("load_room",1,Vector3(10,7,0));return','\t\tif kind=="shortcut":flags.shortcut=true;call_deferred("load_room",1);return\n\t\tif kind=="side":call_deferred("load_room",17);return\n\t\tif kind=="rust_loop":call_deferred("load_room",8);return\n\t\tif kind=="rust_shortcut":call_deferred("load_room",9);return')
s=s.replace('toast("休息灯已保存 · 全队恢复");return','toast("休息灯已保存 · 全队恢复，普通敌人刷新");call_deferred("load_room",room,player.position);return')
s=s.replace('\tif kind=="chest":', '''\tif kind=="wall":flags.wall=true;show_story("壁抓与壁跳已学会。\\n跳向蓝色标记墙，按住朝墙方向抓壁；Space 蹬墙。\\n抓壁最多 0.65 秒，空中切人不会刷新次数。");save_game();return
\tif kind in ["mobility","training"]:
\t\tlearned["%d_2"%active_slot]=true;show_story("身法训练：Alt 冲跑，S 蹲行，Shift 翻滚。\\n低障碍前 Space 翻越；空中 K 下砸。\\nCtrl + Space 空中冲刺，每次腾空一次，消耗 16 魔力。");save_game();return
\tif kind=="recruit":
\t\tfor enemy in enemies:
\t\t\tif is_instance_valid(enemy) and enemy.hp>0:toast("先击退矿牢守卫");return
\t\tflags.ranger=true;skill_points+=3;show_story("伊瑟：这份名册，我会带给还活着的人。\\n伊瑟自愿加入。3 或 F 切换第三槽，弓箭可以远距支援。");save_game();return
\tif kind=="completion":flags.slice_complete=true;skill_points+=1;show_story("总井图纸交付。灰闸囚厂与锈脊齿轮井回环开放。\\n接下来要修复雾肺水务区，寻找米菈的真实去向。\\n0.4.0 当前章节结束，可以继续回访、训练与救援。");save_game();return
\tif kind=="chest":''')
a=s.index('func switch_actor(');b=s.index('func damage_player',a)
s=s[:a]+'''func available_slots() -> Array:
\treturn [0,1,2] if flags.get("ranger",false) else [0,1] if flags.get("rescued",false) else [0]

func switch_actor(slot: int = -1) -> void:
\tvar slots: Array=available_slots()
\tif slots.size()==1:toast("救援后可以切换同伴");return
\tif switch_cooldown>0 or player.hurt_clock>0 or player.attack_clock>0 or player.motion=="vault":return
\tvar next: int=slots[(slots.find(active_slot)+1)%slots.size()] if slot<0 else slot
\tif not next in slots or party_hp[next]<=0 or next==active_slot:return
\tactive_slot=next;switch_cooldown=1;player.set_actor(next);toast(["凯恩 · 匕首","洛铆 · 机械重击","伊瑟 · 弓箭"][next])

func menu_actor(slot: int) -> void:
\tif slot in available_slots():active_slot=slot;player.set_actor(slot);ui.rebuild_buttons()

func actor_down() -> void:
\tfor slot in available_slots():
\t\tif party_hp[slot]>0:active_slot=slot;player.set_actor(slot);toast("接替倒地同伴");return
\tparty_hp=[100.0,110.0,95.0];magic=100;potion=3
\tshow_story("回声暂歇。你将在当前房间安全入口醒来。");call_deferred("load_room",room)

func reset_player() -> void:
\tparty_hp[active_slot]=maxf(1,party_hp[active_slot]-10)
\tcall_deferred("load_room",room);toast("坠落受伤 · 在本室入口重试，不退回煤仓")

func environment_damage(amount: float) -> void:
\tif player.invulnerable>0:return
\tparty_hp[active_slot]=maxf(0,party_hp[active_slot]-amount);player.invulnerable=.8;player.hurt_clock=.25
\tif party_hp[active_slot]<=0:actor_down()

'''+s[b:]
s=s.replace('if d<distance:','if d<distance and (p.x-player.position.x)*player.facing>-.3:')
s=s.replace('res://scripts/qa.gd','res://scripts/qa_v04.gd')
s+='''
func check_auto_exit() -> void:
\tif transition_pending or paused:return
\tfor prop in props:
\t\tif prop.kind=="exit" and player.position.distance_to(prop.p)<.8 and player.move_axis()>.2:
\t\t\tvar gate: String=rooms[room].get("gate","")
\t\t\tif gate.is_empty() or flags.get(gate,false):nearest=prop;transition_pending=true;interact()

func melee_hit(amount: float,reach: float,direction: float,area: bool) -> void:
\tfor enemy in enemies:
\t\tif not is_instance_valid(enemy):continue
\t\tvar d: Vector3=enemy.position-player.position
\t\tif absf(d.x)>reach or absf(d.y)>1.7 or absf(d.z)>1.5 or (not area and direction*d.x<-.3):continue
\t\tvar query:=PhysicsRayQueryParameters3D.create(player.position+Vector3(0,1,0),enemy.position+Vector3(0,1,0),1)
\t\tif get_world_3d().direct_space_state.intersect_ray(query).is_empty():enemy.hurt(amount,direction,30 if amount>=35 else 12);hitstop=.045

func fire_projectile(pos: Vector3,direction: float,amount: float,friendly: bool,source: Node) -> void:
\tvar shot:=preload("res://scripts/projectile.gd").new();shot.game=self;shot.position=pos;shot.direction=direction;shot.damage=amount;shot.friendly=friendly;shot.source=source;world.add_child(shot)
'''
p.write_text(s,encoding='utf8')
for filename in ['project.godot','source/package.ps1']:
    p=root/filename;p.write_text(p.read_text(encoding='utf8').replace('0.1.0','0.4.0'),encoding='utf8')
print('V04 COORDINATOR UPGRADED')
