from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def edit(path,changes):
 p=ROOT/path;s=p.read_text(encoding='utf-8')
 for old,new in changes:
  if old not in s:raise RuntimeError((path,old[:80]))
  s=s.replace(old,new,1)
 p.write_text(s,encoding='utf-8')
edit('scripts/hud.gd',[
 ('var extension: RefCounted','var v10: RefCounted\nvar extension: RefCounted'),
 ('extension=preload("res://scripts/menus_v06.gd").new();extension.ui=self','extension=preload("res://scripts/menus_v06.gd").new();extension.ui=self\n\tv10=preload("res://scripts/menus_v10.gd").new();v10.ui=self'),
 ('var w := size.x;var h := size.y','if v10.manages(game.screen):v10.draw_screen();return\n\tvar w := size.x;var h := size.y'),
 ('var w := get_viewport_rect().size.x;var h := get_viewport_rect().size.y','var w := get_viewport_rect().size.x;var h := get_viewport_rect().size.y\n\tif v10.manages(game.screen):v10.build();return'),
 ('actor_override: int=-1) -> void:', 'actor_override: int=-1,clip_override: String="",training: bool=false) -> void:'),
 ('if actor_slot>=3 and preview_slot!=2:', 'if actor_slot>=3 and actor_slot<7 and preview_slot!=2:'),
 ('var anim: Animation=animator.get_animation(clip).duplicate();','if actor_slot>=7:clip="RoleSkill"\n\tif not clip_override.is_empty():clip=clip_override\n\tif not animator.has_animation(clip):clip="Jump" if animator.has_animation("Jump") else "PassageIdle"\n\tif training:\n\t\tvar dummy: Node3D=game.instantiate_model("kain_v04");scene.add_child(dummy);dummy.position=Vector3(1.2,0,0);dummy.rotation.y=-PI/2\n\t\tvar floor_mesh:=MeshInstance3D.new();scene.add_child(floor_mesh);var box:=BoxMesh.new();box.size=Vector3(5,.1,3);floor_mesh.mesh=box;floor_mesh.position=Vector3(0,-.07,0)\n\t\tcamera.position=Vector3(1.3,1.5,5);camera.look_at(Vector3(.6,.85,0));camera.size=3.2\n\t\tvar demonstration:=preload("res://scripts/skill_preview.gd").new();demonstration.actor=actor;demonstration.dummy=dummy;demonstration.clip=clip;demonstration.node_id=game.skills.selected;scene.add_child(demonstration);return\n\tvar anim: Animation=animator.get_animation(clip).duplicate();'),
])
edit('scripts/menus_v06.gd',[
 ('for i in range(7):','for i in range(ui.v10.roster_page*6,mini(ui.v10.roster_page*6+6,g.Content.ROSTER.size())):'),
 ('h*(.30+i*.075)','h*(.30+(i%6)*.075)'),
 ('"同伴名册 · %d / 7"%g.available_slots().size()','"同伴名册 · %d / %d"%[g.available_slots().size(),g.Content.ROSTER.size()]'),
 ('"收集七名角色，三人出战。休息灯附近且脱离战斗时可编队。"','"招募同伴，三人出战。休息灯附近且脱离战斗时可编队。"'),
 ('for i in g.Content.QUESTS.size():','for i in range(ui.v10.journal_page*6,mini(ui.v10.journal_page*6+6,g.Content.QUESTS.size())):'),
 ('h*(.29+i*.082)','h*(.29+(i%6)*.082)'),
 ('h*(.322+i*.082)','h*(.322+(i%6)*.082)'),
 ('ui.add_button("返回",Vector2(w*.49,h*.85),func():g.set_screen("play"),200)','ui.add_button("查看此人技能",Vector2(w*.49,h*.81),g.skills.choose_actor.bind(roster_selected),w*.30)\n\t\tui.add_button("上一页",Vector2(w*.12,h*.79),func():ui.v10.roster_page=maxi(0,ui.v10.roster_page-1);ui.rebuild_buttons(),w*.13)\n\t\tui.add_button("下一页",Vector2(w*.27,h*.79),func():ui.v10.roster_page=mini(ceili(g.Content.ROSTER.size()/6.0)-1,ui.v10.roster_page+1);ui.rebuild_buttons(),w*.13)\n\t\tui.add_button("返回",Vector2(w*.49,h*.88),func():g.set_screen("play"),200)'),
 ('elif g.screen=="journal":ui.add_button("返回",Vector2(w*.70,h*.86),func():g.set_screen("play"),220)','elif g.screen=="journal":\n\t\tui.add_button("上一页",Vector2(w*.12,h*.88),func():ui.v10.journal_page=maxi(0,ui.v10.journal_page-1);ui.rebuild_buttons(),160)\n\t\tui.add_button("下一页",Vector2(w*.30,h*.88),func():ui.v10.journal_page=mini(ceili(g.Content.QUESTS.size()/6.0)-1,ui.v10.journal_page+1);ui.rebuild_buttons(),160)\n\t\tui.add_button("返回",Vector2(w*.70,h*.86),func():g.set_screen("play"),220)'),
 ('Vector2(w*.20,h*(.32+i*.072))','Vector2(w*(.12+(i%2)*.45),h*(.32+floori(i/2.0)*.072))'),
 ('g.fast_travel.bind(target),w*.54','g.fast_travel.bind(target),w*.40'),
])
print('Integrated new menu navigation, character skill links and preview scenes.')
