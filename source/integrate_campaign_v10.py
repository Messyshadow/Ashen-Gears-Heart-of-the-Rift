from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def edit(path,changes):
 p=ROOT/path;s=p.read_text(encoding='utf-8')
 for old,new in changes:
  if old not in s:raise RuntimeError((path,old[:100]))
  s=s.replace(old,new,1)
 p.write_text(s,encoding='utf-8')
edit('scripts/game.gd',[
 ('var heat := 0.0','var campaign: RefCounted\nvar heat := 0.0'),
 ('party_hp=full_health()\n\tsetup_input();','campaign=preload("res://scripts/progression_v10.gd").new();campaign.game=self\n\tparty_hp=full_health()\n\tsetup_input();'),
 ('"equipment":[KEY_O]}','"equipment":[KEY_O],"transform":[KEY_B]}'),
 ('if not paused:\n\t\tdoorway_cooldown','if not paused:\n\t\tcampaign.tick(dt)\n\t\tdoorway_cooldown'),
 ('func damage_multiplier() -> float:return 1.0+','func damage_multiplier() -> float:return (0.20+skills.level(active_slot,"T2")*.05 if campaign and campaign.form_time>0 else 0.0)+1.0+'),
 ('float(inventory.stats(active_slot).get("defense",0))+skills.bonus(active_slot,"defense"))','float(inventory.stats(active_slot).get("defense",0))+skills.bonus(active_slot,"defense")+(.10 if campaign and campaign.form_time>0 else 0))'),
 ('if progression.handle(kind):return','if campaign.handle(kind):return\n\tif progression.handle(kind):return'),
 ('flags.stage_complete=true;checkpoint_room=room;checkpoint_pos=player.position;save_game();transition_pending=false;set_screen("chapter_complete");return','if flags.get("boss12",false) and flags.get("mila_wish",false):transition_pending=false;set_screen("ending")\n\t\t\t\telse:transition_pending=false;toast("击败摄政并保全米菈的意愿后再作最终选择")\n\t\t\t\treturn'),
 ('if event.is_action_pressed("interact"):interact()','if event.is_action_pressed("transform"):campaign.transform()\n\tif event.is_action_pressed("interact"):interact()'),
 ('inventory.reset();skills.levels={};map_marks={};heat=0;','inventory.reset();skills.levels={};map_marks={};heat=0;campaign.form_time=0;campaign.resonance=0;campaign.quest_states={};'),
 ('"inventory":inventory.items,','"quests_v10":campaign.quest_states,"inventory":inventory.items,'),
 ('inventory.restore(saved);skills.restore','campaign.quest_states=saved.get("quests_v10",{});campaign.form_time=0;campaign.resonance=0\n\tinventory.restore(saved);skills.restore'),
 ('if kind=="manifest":flags.manifest=true;','if kind=="manifest":inventory.grant("manifest");flags.manifest=true;'),
 ('if get_world_3d().direct_space_state.intersect_ray(query).is_empty():enemy.hurt(amount,direction,30 if amount>=35 else 12,tier,player)','if get_world_3d().direct_space_state.intersect_ray(query).is_empty():\n\t\t\tvar before: float=enemy.hp;enemy.hurt(amount,direction,30 if amount>=35 else 12,tier,player)\n\t\t\tcampaign.resonance=minf(100,campaign.resonance+8)\n\t\t\tparty_hp[active_slot]=minf(max_hp(),party_hp[active_slot]+minf(before,amount)*float(inventory.stats(active_slot).get("leech",0)))'),
])
edit('scripts/progression_v06.gd',[
 ('if slot<3 or slot>6:return false','if slot<3 or slot>=g.Content.ROSTER.size():return false'),
 ('flag=g.Content.ROSTER[slot].flag;g.flags[flag]=true;','if slot==16 and not (g.flags.get("core1",false) and g.flags.get("core2",false) and g.flags.get("core3",false)):g.toast("归还三个观测核后再与星烬交谈");return true\n\t\tif slot==8 and not g.flags.get("lab_evidence",false):g.toast("先取实验室原始日志，再来审计绘笔");return true\n\t\tflag=g.Content.ROSTER[slot].flag;g.flags[flag]=true;'),
 ('g.sound("door");g.call_deferred("load_room",target);return true','if g.campaign.entry_allowed(target):g.sound("door");g.call_deferred("load_room",target)\n\t\treturn true'),
 ('g.flags[kind]=true;g.show_story(g.nearest.text','g.flags[kind]=true\n\t\tif g.inventory.CATALOG.has(kind) and g.inventory.owned(kind)==0:g.inventory.grant(kind)\n\t\tg.show_story(g.nearest.text'),
 ('if kind=="final_report":g.flags.stage_complete=true;g.save_game();g.set_screen("chapter_complete");return true','if kind=="final_report":g.flags.lab_report=true;g.save_game();g.show_story("原始日志已保全。\n右侧运输梯进入烬海熔炉，寻找三源分离材料。 ");return true'),
])
edit('scripts/world_extension.gd',[
 ('var spec: Dictionary','var late: RefCounted\nvar spec: Dictionary'),
 ('var region: int=int(spec.region)','var region: int=int(spec.region)\n\tif region>=7:late=preload("res://scripts/world_v10.gd").new();late.build(b,spec,top);return'),
 ('func tick(dt: float) -> void:\n\telapsed','func tick(dt: float) -> void:\n\tif late:late.tick(dt);return\n\telapsed'),
])
edit('scripts/enemy_v04.gd',[
 ('var edge_safe := true','var edge_safe := true\nvar last_pattern := ""'),
 ('var label: Label3D=game.marker({','var label: Label3D=game.marker(definition.get("name",{'),
 ('.get(kind,""),Color(.9,.3,.16))','.get(kind,"")),Color(.9,.3,.16))'),
 ('if kind in ["mother","witch","lord","editor"]:strike_extended(diff,same)','if kind in ["mother","witch","lord","editor"] or definition.get("extended",false):strike_extended(diff,same)'),
 ('else 9.0 if kind in ["mother","witch","lord","editor"]','else 9.0 if kind in ["mother","witch","lord","editor"] or definition.get("extended",false)'),
 ('if kind in ["mother","witch","lord","editor"]:pattern=definition.patterns[attacks%3]','if kind in ["mother","witch","lord","editor"] or definition.get("extended",false):\n\t\t\t\t\tvar choices: Array=definition.patterns.duplicate();choices.erase(last_pattern)\n\t\t\t\t\tpattern=choices[attacks%choices.size()];last_pattern=pattern'),
 ('if tier.is_empty():tier=Tuning.tier_for_damage(amount)','if definition.get("shield",false) and force*facing<0 and state!="stunned" and amount<900:amount*=.30;game.sound("guard",position)\n\tif tier.is_empty():tier=Tuning.tier_for_damage(amount)'),
 ('if not game.defeated.has(uid):game.scrap+=60 if boss() else 8','if not game.defeated.has(uid):\n\t\t\tgame.scrap+=60 if boss() else 8\n\t\t\tgame.flags.kill_progress=int(game.flags.get("kill_progress",0))+1\n\t\t\tif int(game.flags.kill_progress)%4==0:game.skill_points+=1'),
])
edit('scripts/controls_settings.gd',[( '"equipment":"装备"}','"equipment":"装备","transform":"共鸣形态"}')])
edit('scripts/hud.gd',[
 ('六个主线区域 × 维修所   /   50 房间 · 七名同伴','十二个主线区域 × 维修所   /   126 房间 · 十六位同伴'),
 ('"R01 — R06 · 阶段完成"','"灰炉城 · 旅程完成"'),
 ('"复制链路被切断，伪造的名字与幸存者记录已保全。"','"城市的未来已记录，结局档案与全部探索进度保留。"'),
 ('"六个区域已连通；下一阶段 R07「倒吊钟楼」尚未开放。"','"十二个区域连通，可返回终战前或中枢继续寻找同伴与遗物。"'),
 ('if game.screen=="graphics":build_graphics()','if game.screen=="ending":\n\t\tfor i in range(3):add_button(["共同分离 · 余烬黎明","停止献祭 · 封炉长夜","接管炉心 · 灰冠继承"][i],Vector2(w*.24,h*(.44+i*.105)),game.campaign.complete_ending.bind(i+1),w*.5)\n\t\tadd_button("返回修复城市锚点",Vector2(w*.24,h*.79),game.chapter_return.bind(102),w*.5)\n\tif game.screen=="graphics":build_graphics()'),
 ('elif game.screen=="chapter_complete":','elif game.screen=="ending":\n\t\ttext_at(Vector2(w*.24,h*.25),"裂界之心 · 米菈的选择",40,GOLD)\n\t\ttext_at(Vector2(w*.24,h*.33),"水锚 %s / 气锚 %s / 电锚 %s"%["已修复" if game.flags.get("anchor_water",false) else "未修复","已修复" if game.flags.get("anchor_air",false) else "未修复","已修复" if game.flags.get("anchor_power",false) else "未修复"],22,TEXT)\n\telif game.screen=="chapter_complete":'),
])
print('Integrated campaign gates, endings, new role entries and late worlds.')
