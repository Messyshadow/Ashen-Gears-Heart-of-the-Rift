from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
p=ROOT/'scripts/qa_v06.gd';s=p.read_text(encoding='utf-8')
s=s.replace('game.rooms.size()==50 and game.Content.ROSTER.size()==7','game.rooms.size()==126 and game.Content.ROSTER.size()==17').replace('"50 房间、七名可收集角色与六个主线区域"','"扩展世界仍保留原六区的稳定身份"').replace('int(r.next)>=50','int(r.next)>=126').replace('int(r.previous)>=50','int(r.previous)>=126').replace('ids.size()==50','ids.size()==126')
s=s.replace('if number==49:\n\t\t\tif game.room!=49 or game.screen!="chapter_complete":forward_ok=false\n\t\telif game.room!=int(game.rooms[number].next):','if game.room!=int(game.rooms[number].next):')
s=s.replace('50 个前门实际步行推进，最终终点明确停留完成界面','原 50 个前门实际步行推进，R06 接入 R07')
s=s.replace('check(game.ui.buttons.size()==15,"区域分页地图显示七个区域与八个房间")','check(is_instance_valid(game.ui.v10.map_view),"世界地图已改为真实空间布局与世界区域视图")')
s=s.replace('game.interact();check(game.screen=="chapter_complete" and game.flags.get("stage_complete",false),"R06 终点保存阶段完成记录，回访入口明确")','game.interact();await wait(.2);check(game.room==50,"R06 运输梯继续进入熔海，不再截断主线")')
p.write_text(s,encoding='utf-8')
p=ROOT/'scripts/qa_weapons.gd';s=p.read_text(encoding='utf-8').replace('game.party_hp.size()==7','game.party_hp.size()==17').replace('旧三人 HP 存档兼容升级到七人名册','旧三人 HP 存档兼容升级到完整名册');p.write_text(s,encoding='utf-8')
p=ROOT/'scripts/qa_v04.gd';s=p.read_text(encoding='utf-8').replace('\tvar failures:=0','\tchecks.append_array(await preload("res://scripts/qa_v10.gd").new().run(game,directory.get_base_dir().path_join("v10_screenshots") if not directory.is_empty() else ""))\n\tvar failures:=0');p.write_text(s,encoding='utf-8')
print('Preserved older movement/combat tests, updated intentional campaign changes; added v10 acceptance.')
