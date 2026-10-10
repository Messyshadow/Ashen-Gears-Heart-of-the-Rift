extends RefCounted
var ui: Control
var roster_selected := 0
func draw_screen() -> void:
	var g: Node3D=ui.game;var w: float=ui.size.x;var h: float=ui.size.y
	if g.screen=="rest":
		ui.text_at(Vector2(w*.25,h*.26),"休息灯 · 全队恢复并保存",36,ui.GOLD)
		ui.text_at(Vector2(w*.25,h*.34),"在此调整三人编队、回访已发现区域或查看任务。",20,ui.MUTED)
	elif g.screen=="settings":
		ui.text_at(Vector2(w*.23,h*.24),"设置",40,ui.GOLD)
		ui.text_at(Vector2(w*.23,h*.32),"氛围与画面、音频和按键分别设置，自动保存。",20,ui.MUTED)
	elif g.screen=="controls":
		ui.text_at(Vector2(w*.18,h*.16),"按键设置",38,ui.GOLD)
		ui.text_at(Vector2(w*.18,h*.24),"点击动作后按新键；Esc 取消。鼠标与手柄保留默认布局。",18,ui.MUTED)
		if not g.controls.capturing.is_empty():ui.text_at(Vector2(w*.18,h*.86),"等待按键："+g.controls.LABELS[g.controls.capturing],20,ui.GOLD)
		elif g.toast_clock>0:ui.text_at(Vector2(w*.18,h*.86),g.status,18,ui.GOLD)
	elif g.screen=="roster":
		ui.text_at(Vector2(w*.12,h*.16),"同伴名册 · %d / %d"%[g.available_slots().size(),g.Content.ROSTER.size()],38,ui.GOLD)
		ui.text_at(Vector2(w*.12,h*.24),"招募同伴，三人出战。休息灯附近且脱离战斗时可编队。",19,ui.MUTED)
		var profile: Dictionary=g.Content.ROSTER[roster_selected]
		ui.text_at(Vector2(w*.49,h*.36),profile.name+" · "+profile.role,27,ui.GOLD)
		var chunks: PackedStringArray=profile.desc.split("；")
		for i in chunks.size():ui.text_at(Vector2(w*.49,h*(.43+i*.06)),chunks[i],18,ui.TEXT)
		ui.text_at(Vector2(w*.49,h*.59)," / ".join(profile.skills),18,ui.MUTED)
		ui.text_at(Vector2(w*.49,h*.65),"按 F 轮换，数字 1 / 2 / 3 对应当前编队槽位。",17,ui.MUTED)
		if g.toast_clock>0:ui.text_at(Vector2(w*.12,h*.93),g.status,17,ui.GOLD)
	elif g.screen=="journal":
		ui.text_at(Vector2(w*.12,h*.16),"任务与证物",38,ui.GOLD)
		for i in range(ui.v10.journal_page*6,mini(ui.v10.journal_page*6+6,g.Content.QUESTS.size())):
			var q: Dictionary=g.Content.QUESTS[i];var done: bool=g.flags.get(q.flag,false)
			ui.text_at(Vector2(w*.12,h*(.29+(i%6)*.082)),("✓ " if done else "◇ ")+q.title,22,ui.GOLD if done else ui.TEXT)
			ui.text_at(Vector2(w*.12,h*(.322+(i%6)*.082)),q.goal,16,ui.MUTED)
		var clues: Array=[]
		for pair in [["manifest","转运表"],["clue_water","水管便笺"],["clue_names","名字碎片"],["blood_record","血契旧账"],["lab_evidence","实验记录"]]:
			if g.flags.get(pair[0],false):clues.append(pair[1])
		ui.text_at(Vector2(w*.12,h*.82),"已记录："+(" / ".join(clues) if not clues.is_empty() else "尚未发现"),18,ui.GOLD)
	elif g.screen=="travel":
		ui.text_at(Vector2(w*.20,h*.18),"已发现通道 · 休息灯传送",38,ui.GOLD)
		ui.text_at(Vector2(w*.20,h*.26),"只能前往已探索区域入口；进度、同伴和奖励保持。",20,ui.MUTED)
		if not g.can_organize():ui.text_at(Vector2(w*.20,h*.87),"请靠近休息灯，脱离战斗后传送。",20,ui.GOLD)
	elif g.screen=="map":
		ui.text_at(Vector2(w*.10,h*.14),"灰炉城 · "+g.Content.REGIONS[g.map_region],36,ui.GOLD)
		ui.text_at(Vector2(w*.10,h*.23),"区域内编号按主线顺序连接；左门回前室，金色右门继续推进。",18,ui.MUTED)
		ui.text_at(Vector2(w*.10,h*.83),"维修所与矿牢为支线；角色、证物与机关位置显示在已探索房间详情中。",18,ui.MUTED)
		ui.text_at(Vector2(w*.10,h*.90),"当前："+g.rooms[g.room].id+" · "+g.rooms[g.room].name+"    /    M 返回",18,ui.GOLD)

func build() -> void:
	var g: Node3D=ui.game;var w: float=ui.size.x;var h: float=ui.size.y
	if g.screen=="rest":
		for row in [["继续探索","play"],["同伴名册与编队","roster"],["已发现区域传送","travel"],["任务与证物","journal"]]:
			ui.add_button(row[0],Vector2(w*.25,h*(.44+[["继续探索","play"],["同伴名册与编队","roster"],["已发现区域传送","travel"],["任务与证物","journal"]].find(row)*.105)),func():g.set_screen(row[1]),w*.5)
	elif g.screen=="settings":
		ui.add_button("氛围与画面",Vector2(w*.23,h*.43),g.open_graphics,380)
		ui.add_button("音频",Vector2(w*.23,h*.53),func():g.set_screen("audio"),380)
		ui.add_button("按键",Vector2(w*.23,h*.63),func():g.set_screen("controls"),380)
		ui.add_button("返回",Vector2(w*.23,h*.77),func():g.set_screen(g.settings_return),380)
	elif g.screen=="controls":
		var actions: Array=g.controls.LABELS.keys();var start: int=g.controls.page*8
		for i in range(start,mini(start+8,actions.size())):
			var action: String=actions[i];ui.add_button(g.controls.LABELS[action]+"    "+g.controls.label(action),Vector2(w*.18+(i-start)%2*w*.33,h*(.33+floori(float(i-start)/2)*.11)),g.controls.begin.bind(action),w*.30)
		ui.add_button("上一页",Vector2(w*.18,h*.78),func():g.controls.page=maxi(0,g.controls.page-1);ui.rebuild_buttons(),150)
		ui.add_button("下一页",Vector2(w*.36,h*.78),func():g.controls.page=mini(2,g.controls.page+1);ui.rebuild_buttons(),150)
		ui.add_button("恢复默认",Vector2(w*.54,h*.78),g.controls.reset,160)
		ui.add_button("返回",Vector2(w*.73,h*.78),func():g.controls.capturing="";g.set_screen("settings"),150)
	elif g.screen=="roster":
		var party: Array=g.field_slots()
		ui.build_preview(Vector2(w*.81,h*.32),Vector2(w*.16,h*.29),roster_selected)
		for i in range(ui.v10.roster_page*6,mini(ui.v10.roster_page*6+6,g.Content.ROSTER.size())):
			var collected: bool=i in g.available_slots();var text: String=g.Content.ROSTER[i].name+("  · 编队 %d"%(party.find(i)+1) if i in party else "  · 候补" if collected else "  · 未招募")
			ui.add_button(text,Vector2(w*.12,h*(.30+(i%6)*.075)),func():roster_selected=i;ui.rebuild_buttons(),w*.29)
		for i in range(3):
			ui.add_button("编入 %d 槽"%(i+1),Vector2(w*(.49+i*.135),h*.73),g.assign_party.bind(roster_selected,i),w*.12)
		ui.add_button("查看此人技能",Vector2(w*.49,h*.81),g.skills.choose_actor.bind(roster_selected),w*.30)
		ui.add_button("上一页",Vector2(w*.12,h*.79),func():ui.v10.roster_page=maxi(0,ui.v10.roster_page-1);ui.rebuild_buttons(),w*.13)
		ui.add_button("下一页",Vector2(w*.27,h*.79),func():ui.v10.roster_page=mini(ceili(g.Content.ROSTER.size()/6.0)-1,ui.v10.roster_page+1);ui.rebuild_buttons(),w*.13)
		ui.add_button("返回",Vector2(w*.49,h*.88),func():g.set_screen("play"),200)
	elif g.screen=="journal":
		ui.add_button("上一页",Vector2(w*.12,h*.88),func():ui.v10.journal_page=maxi(0,ui.v10.journal_page-1);ui.rebuild_buttons(),160)
		ui.add_button("下一页",Vector2(w*.30,h*.88),func():ui.v10.journal_page=mini(ceili(g.Content.QUESTS.size()/6.0)-1,ui.v10.journal_page+1);ui.rebuild_buttons(),160)
		ui.add_button("返回",Vector2(w*.70,h*.86),func():g.set_screen("play"),220)
	elif g.screen=="travel":
		for i in range(g.Content.STARTS.size()):
			var target: int=g.Content.STARTS[i];var discovered: bool=g.visited.has(g.rooms[target].id)
			ui.add_button(g.Content.REGIONS[i]+("" if discovered else " · 未发现"),Vector2(w*(.12+(i%2)*.45),h*(.32+floori(i/2.0)*.072)),g.fast_travel.bind(target),w*.40)
		ui.add_button("返回",Vector2(w*.76,h*.83),func():g.set_screen("play"),150)
	elif g.screen=="map":
		for region in range(7):ui.add_button(g.Content.REGIONS[region],Vector2(w*(.10+region*.116),h*.28),func():g.map_region=region;ui.rebuild_buttons(),w*.109)
		var entries: Array=[]
		for number in g.rooms.size():
			if int(g.rooms[number].get("region",1))==g.map_region:entries.append(number)
		for i in entries.size():
			var number: int=entries[i];var r: Dictionary=g.rooms[number];var seen: bool=g.visited.has(r.id)
			ui.add_button(("● " if number==g.room else "")+r.id+"  "+(r.name if seen else "未探索"),Vector2(w*(.10+(i%3)*.285),h*(.41+floori(float(i)/3)*.115)),show_room.bind(number),w*.26)

func show_room(number: int) -> void:
	var g: Node3D=ui.game;var r: Dictionary=g.rooms[number]
	if not g.visited.has(r.id):g.toast("该房间尚未探索");return
	var lines: Array=[r.id+" · "+r.name,"← "+g.rooms[int(r.previous)].name+"    → "+g.rooms[int(r.next)].name,r.hint]
	for prop in r.props:
		if prop.kind.begins_with("recruit") or prop.kind.begins_with("portal"):lines.append(prop.text)
	g.show_story("\n".join(lines.slice(0,5)))
