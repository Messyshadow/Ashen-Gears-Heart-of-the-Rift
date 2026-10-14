extends RefCounted
var game: Node3D
var checks: Array=[]
func wait(t: float) -> void:await game.get_tree().create_timer(t).timeout
func check(ok: bool,name: String,detail: Variant=null) -> void:checks.append({"pass":ok,"check":name,"detail":detail});print("PASS " if ok else "FAIL ",name," ",detail)
func target(p: Vector3=Vector3(10,0,0)) -> Node:
 var e: Node=game.Enemy.new();e.game=game;e.kind="human";e.uid="window_"+str(e.get_instance_id());e.position=p;game.world.add_child(e);game.enemies.append(e);e.hp=1000;e.max_hp=1000;e.set_physics_process(false);return e
func idle() -> void:
 for action in ["light","heavy","dodge","guard","modifier"]:Input.action_release(action)
 game.player.attack_clock=0;game.player.hurt_clock=0;game.player.hit_pause=0;game.player.dodge_clock=0;game.player.dash_clock=0;game.player.slam_recovery=0;game.player.slamming=false;game.player.guarding=false;game.player.clear_action_buffer();game.player.clear_contact_window();game.player.position=Vector3(6.5,.04,0);game.player.velocity=Vector3.ZERO;game.player.facing=1;game.player.combo=0;game.player.combo_clock=0;game.player.stamina=100
func at(seconds: float) -> void:
 var deadline:=Time.get_ticks_msec()+2000
 while game.player.attack_total-game.player.attack_clock<seconds and Time.get_ticks_msec()<deadline:await game.get_tree().physics_frame
func run(g: Node3D) -> Array:
 game=g;game.new_game();game.load_room(11);game.set_screen("play");idle();await wait(.2)
 var e: Node=target();game.player.begin_attack(false)
 await at(game.player.hit_at);check(e.hp==1000,"匕首前摇结束时范围外目标不受伤")
 e.position=Vector3(7.7,0,0);await wait(.12)
 check(e.hp==978 and game.player.hit_confirmed,"目标在有效窗口后半进入范围也会命中，修复瞬间漏判")
 var resonance: float=game.campaign.resonance;await wait(.3)
 check(e.hp==978 and game.campaign.resonance==resonance,"单段持续重叠不重复扣血或刷共鸣")
 idle();e.position=Vector3(10,0,0);await wait(.1);game.player.begin_attack(false);await at(game.player.hit_at+.08);e.position=Vector3(7.7,0,0);await wait(.15)
 check(e.hp==978,"有效窗口结束后再进入不受旧挥击伤害")
 await wait(.2);idle();e.hp=1000;e.position=Vector3(7.7,0,0);var other: Node=target(Vector3(8,0,0));await wait(.1);game.player.attack_area=true;game.player.start_companion("Skill",.65,20,3,.15);await wait(.4)
 check(e.hp==980 and other.hp==980,"同段群攻每个目标分别命中一次，不按帧重复")
 await wait(.3);idle();other.position.x=-18;e.hp=1000;e.position=Vector3(7.7,0,0);game.learned["0_1"]=true;game.magic=100;game.skill_cooldown=0;game.campaign.resonance=0;game.player.begin_skill(1);await wait(1.3)
 check(is_equal_approx(e.hp,931.69) and game.campaign.resonance==24,"三段技能分别开启新窗口，同目标正好三次伤害",e.hp)
 check(game.player.contact_targets.is_empty(),"攻击结束清理本段命中记录")
 idle();e.position.x=-18;await wait(.1);game.player.begin_attack(true);await at(.12);Input.action_press("dodge");await wait(.03);Input.action_release("dodge");await wait(.13)
 check(game.player.attack_clock>0 and game.player.dodge_clock<=0,"重击前摇不允许翻滚取消")
 await at(game.player.attack_total*.85);Input.action_press("dodge");await wait(.03);Input.action_release("dodge")
 check(game.player.dodge_clock>0 and game.player.attack_clock<=0,"普通重击后半收招可用真实翻滚输入取消")
 await wait(.4);idle();game.learned["0_1"]=true;game.magic=100;game.skill_cooldown=0;game.player.begin_skill(1);await at(.60);Input.action_press("dodge");await wait(.03);Input.action_release("dodge")
 check(game.player.attack_clock>0 and game.player.dodge_clock<=0,"多段技能不能借重击取消规则跳过末段")
 await wait(.4);idle();game.player.position.y=3;game.player.slamming=true;game.player.velocity=Vector3(0,-10,0)
 var landing_deadline:=Time.get_ticks_msec()+1500
 while game.player.slamming and Time.get_ticks_msec()<landing_deadline:await game.get_tree().physics_frame
 check(game.player.slam_recovery>0 and not game.can_switch_weapon(),"下砸接地有短促收招，期间不能切武器绕过")
 game.flags[game.Content.ROSTER[3].flag]=true;game.party=[0,3];game.party_hp=game.full_health();game.switch_cooldown=0;game.switch_actor(3)
 check(game.active_slot==0,"下砸收招期间快捷键换人同样被拒绝，不绕过控制锁")
 var stamp: float=game.campaign.resonance;await wait(.10)
 check(game.player.slam_recovery>0 and game.campaign.resonance==stamp,"下砸落地只结算一次，不逐帧重复冲击")
 await wait(.3);check(game.player.slam_recovery<=0,"下砸收招限时结束，不粘住控制")
 game.switch_cooldown=0;game.switch_actor(3);check(game.active_slot==3,"下砸收招结束后正常换人，不永久锁住编队");game.switch_cooldown=0;game.switch_actor(0)
 idle();e.position=Vector3(8,0,0);game.player.stamina=5;game.player.guarding=true;game.player.guard_clock=.20;game.player.invulnerable=0;game.player.pending_action="light";game.player.receive_damage(20,-1,e)
 check(game.player.stamina==0 and game.player.hurt_clock>=.59 and not game.player.guarding and game.player.pending_action.is_empty(),"格挡耗尽耐力进入 0.6 秒崩防并清理旧连招")
 await wait(.85);check(game.player.hurt_clock<=0 and game.player.stamina>0,"崩防结束后恢复耐力与行动，不永久失控")
 idle();game.graphics.settings.blood=0;game.feedback.impact(e,1,"parry",game.player)
 check(game.feedback.last_event.particles==11 and game.feedback.last_cue.color.b>.9,"血雾关闭不削减弹反的蓝色提示")
 game.feedback.impact(e,1,"block",game.player);check(game.feedback.last_event.particles==7,"血雾关闭不削减护甲阻挡火花")
 game.graphics.reset_feedback();idle();e.hp=0;e.state="dead";game.player.guarding=true;game.player.guard_clock=.05;game.player.invulnerable=0;game.player.receive_damage(10,-1,e)
 check(e.state=="dead","弹反已死亡的弹道来源不改写尸体状态")
 game.player.guarding=false;idle();e.hp=1000;e.position=Vector3(7.7,0,0);await wait(.1);game.player.begin_attack(false);await at(game.player.hit_at);game.player.invulnerable=0;game.environment_damage(5)
 check(game.player.contact_window_end<0 and game.player.contact_targets.is_empty(),"受伤立即关闭有效窗口，不在硬直后补发旧伤害")
 await wait(.3);var end_hp: float=e.hp;await wait(.1);check(e.hp==end_hp,"受伤中断后目标不再被残留窗口扣血")
 idle();e.hp=0;e.state="dead";e.position=Vector3(8,0,0);other.hp=1000;other.position=Vector3(10,2,0);await wait(.1)
 game.fire_projectile(Vector3(6.5,1,0),1,20,true,null)
 var shot: Node=game.world.get_child(game.world.get_child_count()-1)
 check(shot.travel.y>.3,"自动瞄准跳过近处尸体，锁定前方存活目标",shot.travel.y);shot.queue_free()
 game.snare_nearby(3);check(e.state=="dead","范围控制技能跳过尸体，不中断击杀收尾")
 e.hp=1000;e.state="idle";e.position=Vector3(7.7,0,0);other.position.x=-18;idle()
 var wall:=StaticBody3D.new();wall.collision_layer=1;wall.position=Vector3(7.1,1,0)
 var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.12,3,2);collision.shape=shape;wall.add_child(collision);game.world.add_child(wall);await wait(.1)
 game.player.begin_attack(false);await wait(.5)
 check(e.hp==1000,"持续有效窗口仍遵守遮挡，隔墙不造成近战伤害");wall.queue_free();await wait(.1)
 game.set_screen("play");game.load_room(11);game.graphics.reset_feedback();return checks
