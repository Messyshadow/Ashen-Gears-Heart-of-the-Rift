extends RefCounted
var game: Node3D
func handle(kind: String) -> bool:
	var g:=game;var flag: String=""
	if kind.begins_with("recruit") and kind!="recruit":
		var slot:=int(kind.trim_prefix("recruit"));if slot<3 or slot>6:return false
		if g.available_slots().has(slot):return true
		if g.alive_count()>0:g.toast("击退本室敌人，再与同伴交谈");return true
		flag=g.Content.ROSTER[slot].flag;g.flags[flag]=true;g.skill_points+=2;g.learned["%d_0"%slot]=true
		if g.flags.get("airdash",false):g.learned["%d_2"%slot]=true
		g.consume_prop();g.field_slots();g.show_story(g.Content.ROSTER[slot].name+" 加入名册。\n"+g.Content.ROSTER[slot].desc+"\nC 查看同伴；在休息灯附近调整三人编队。");g.save_game();return true
	if kind.begins_with("portal"):
		var target:=int(kind.trim_prefix("portal"));g.sound("door");g.call_deferred("load_room",target);return true
	if kind=="travel":g.set_screen("travel");return true
	if kind=="story":g.show_story(g.nearest.text);return true
	if kind in ["clue_water","clue_names","blood_record","lab_evidence"]:
		g.flags[kind]=true;g.show_story(g.nearest.text+"\n记录已收入任务册，N 查看。");g.consume_prop();g.save_game();return true
	if kind=="airdash":
		g.flags.airdash=true
		for slot in g.available_slots():g.learned["%d_2"%slot]=true
		g.show_story("空中冲刺训练完成。\n全队 Ctrl + Space 空冲；每次腾空一次。\n以后招募的同伴也保留训练成果。");g.consume_prop();g.save_game();return true
	if kind=="phase_step":g.flags.phase_step=true;g.show_story("薄壁相移：靠近紫色标记墙，面向墙按 G。\n消耗 16 魔力，只穿越标记薄壁。\n落点必须安全，相移不会刷新二段跳。");g.consume_prop();g.save_game();return true
	if kind=="final_report":g.flags.stage_complete=true;g.save_game();g.set_screen("chapter_complete");return true
	if kind in ["root_light","root_lock","root_reset"]:
		if g.flags.get("root_bridge",false):g.toast("迁木桥已锁定，回访保持位置");return true
		if kind=="root_light":g.flags.root_light=not g.flags.get("root_light",false);g.toast("灯位接通，迁木桥移动" if g.flags.root_light else "灯位关闭，桥返回")
		if kind=="root_reset":g.flags.root_light=false;g.toast("桥已复位，重新接通灯位")
		if kind=="root_lock":
			var extension: RefCounted=g.world_builder.extension
			if is_instance_valid(extension.root) and absf(extension.root.position.x-float(g.rooms[g.room].root_bridge.high))<.2:flag="root_bridge"
			else:g.toast("等桥到达右侧灯位后再锁定")
	elif kind in ["mirror_a","mirror_b","mirror_reset"]:
		if g.flags.get("clock_open",false):g.toast("双镜光路已稳定");return true
		if kind=="mirror_reset":g.flags.mirror_a=false;g.flags.mirror_b=false;g.toast("双镜已复位")
		else:g.flags[kind]=not g.flags.get(kind,false);g.toast("镜面已对齐" if g.flags[kind] else "镜面偏离")
		if g.flags.get("mirror_a",false) and g.flags.get("mirror_b",false):flag="clock_open"
	elif kind in ["scan","copy","plate_left","plate_right","copy_reset"]:
		if g.flags.get("copy_complete",false):g.toast("双板已固定，复制室已开放");return true
		if kind=="copy_reset":
			for key in ["scan","copy","plate_left","plate_right"]:g.flags[key]=false
			g.toast("样本与压板复位")
		elif kind=="scan":g.flags.scan=true;g.toast("重块样本登记完成")
		elif kind=="copy":
			if not g.flags.get("scan",false):g.toast("先登记左侧重块样本")
			else:g.flags.copy=true;g.toast("复制重块完成，分别交付左右压板")
		else:
			if not g.flags.get("copy",false):g.toast("先登记并复制重块")
			else:g.flags[kind]=true;g.toast("压板已固定")
		if g.flags.get("plate_left",false) and g.flags.get("plate_right",false):flag="copy_complete"
	elif kind in ["power","split","coolant","door_link","insulate","power_reset"]:
		if g.flags.get("circuit",false):g.toast("链路总控已完成");return true
		if kind=="power_reset":
			g.flags.circuit_pending=false;g.flags.circuit_time=0.0
			for key in ["route_power","split","coolant","door_link","insulate"]:g.flags[key]=false
			g.toast("电路断电复位，可以安全重接")
		elif kind=="power":
			g.flags.route_power=not g.flags.get("route_power",false)
			if g.flags.route_power:
				if g.flags.get("split",false) and g.flags.get("coolant",false) and g.flags.get("door_link",false) and g.flags.get("insulate",false):g.flags.circuit_pending=true;g.flags.circuit_time=0.0;g.toast("四路联锁就绪 · 冷却 2 秒后门锁开启")
				else:g.flags.route_power=false;g.toast("保护跳闸 · 缺少分流、冷却、门锁或绝缘，可重新接线")
			else:g.flags.circuit_pending=false;g.toast("电源关闭，可调整链路")
		elif g.flags.get("route_power",false):g.toast("先断电，才能接线")
		else:g.flags[kind]=not g.flags.get(kind,false);g.toast("链路接入" if g.flags[kind] else "链路断开")
	else:return false
	if not flag.is_empty():g.flags[flag]=true;g.sound("gear_start");g.toast("联锁完成 · 主线通道已开启",4)
	g.save_game();return true
