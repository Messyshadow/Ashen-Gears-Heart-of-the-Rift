extends RefCounted
var game: Node3D
var checks: Array=[]
func wait(t: float) -> void:await game.get_tree().create_timer(t).timeout
func check(ok: bool,name: String,detail: Variant=null) -> void:checks.append({"pass":ok,"check":name,"detail":detail});print("PASS " if ok else "FAIL ",name," ",detail)
func target(kind: String="human",p: Vector3=Vector3(8,0,0)) -> Node:
 var e: Node=game.Enemy.new();e.game=game;e.kind=kind;e.position=p;e.uid="impact_"+str(e.get_instance_id());game.world.add_child(e);game.enemies.append(e);e.hp=1000;e.max_hp=1000;e.state="recover";e.clock=-20;return e
func idle() -> void:
 game.player.attack_clock=0;game.player.hit_pause=0;game.player.hurt_clock=0;game.player.combo=0;game.player.combo_clock=0;game.player.clear_action_buffer();game.player.position=Vector3(6.5,.04,0);game.player.velocity=Vector3.ZERO;game.player.facing=1
func run(g: Node3D,directory: String="") -> Array:
 game=g;game.new_game();game.load_room(11);game.set_screen("play");game.graphics.reset_feedback();idle();var e: Node=target();await wait(.2)
 game.player.begin_attack(false);var deadline:=Time.get_ticks_msec()+1000
 while e.hp==1000 and Time.get_ticks_msec()<deadline:await game.get_tree().physics_frame;await game.get_tree().process_frame
 var pose: float=game.player.animator.current_animation_position/game.player.animator.get_animation("Dagger1").length
 check(e.hp<1000 and pose>=.49 and pose<.65,"匕首实际命中同步接触姿势，告别动画未挥到先扣血",pose)
 var hit_point: Vector3=game.feedback.last_event.point
 check(hit_point.x>7.5 and is_equal_approx(hit_point.z,.18),"冲击特效位于真实目标接触点")
 check(game.feedback.cues.size()>0 and game.feedback.last_event.material=="flesh","有效帧刀光与血肉命中圈实际渲染")
 Input.action_press("light");await wait(.03);Input.action_release("light");await wait(.10)
 check(game.player.attack_clip=="Dagger2","命中确认后 80ms 可衔接下一刀，无需等全部收招")
 await wait(.6);idle();e.position=Vector3(18,0,0);e.state="recover";e.clock=-20;game.player.begin_attack(false);Input.action_press("light");await wait(.02);Input.action_release("light");await wait(.20)
 check(not game.player.hit_confirmed and game.player.attack_clip=="Dagger1","挥空保留更晚取消边界，不能刷无风险连击")
 await wait(.35);idle();e.position=Vector3(8,0,0);e.hit_pause=0;e.hurt(50,1,35,"heavy",game.player);var start: float=e.position.x;await wait(.40)
 check(e.position.x-start>.55,"重击产生可见实体后退并保留碰撞支撑",e.position.x-start)
 e.state="recover";e.clock=-20;e.position=Vector3(8,0,0);idle();game.feedback.reset();e.hurt(1,1,1,"heavy",game.player);var trauma: float=game.feedback.trauma
 for i in range(4):var other: Node=target("human",Vector3(9+i*.2,0,0));other.hurt(1,1,1,"heavy",game.player)
 check(is_equal_approx(trauma,game.feedback.trauma) and game.player.hit_pause<=.11,"同物理帧群攻只取最大震屏和顿帧，不按人数累加")
 game.feedback.reset();var far: Node=target("human",Vector3(-15,0,0));far.hurt(1,1,1,"heavy")
 check(game.feedback.trauma==0,"远处命中不强行震动玩家镜头")
 game.graphics.settings.shake=0;game.graphics.settings.zoom=0;game.graphics.settings.flash=0;game.graphics.settings.blood=0
 e.hurt(1,1,1,"light");await wait(.05)
 check(game.feedback.camera_offset()==Vector3.ZERO and game.feedback.zoom_factor()==1,"关闭震屏与缩放立即生效")
 check(e.visual.find_children("*","MeshInstance3D",true,false).all(func(m):return m.material_overlay==null),"关闭闪光后原材质保持可见")
 check(game.feedback.last_event.particles==3 and game.feedback.last_event.point.is_finite(),"关闭血雾仍保留中性方向提示与命中音")
 game.graphics.settings.shake=.25;game.graphics.save_settings();game.graphics.settings.shake=1;game.graphics.load_settings()
 check(is_equal_approx(float(game.graphics.settings.shake),.25),"反馈强度保存在原画面配置，旧配置默认补齐")
 game.graphics.reset_feedback();game.set_screen("feedback");await wait(.05)
 check(game.ui.graphics_controls.size()==5,"五项独立反馈设置实际存在并可交互")
 if not directory.is_empty():await RenderingServer.frame_post_draw;game.get_viewport().get_texture().get_image().save_png(directory.path_join("feedback_settings.png"))
 game.set_screen("play");game.feedback.reset()
 var shield: Node=target("shield",Vector3(12,0,0));shield.facing=-1;shield.hurt(40,1,1,"heavy")
 check(game.feedback.last_event.tier=="block" and shield.hp==988,"盾牌阻挡使用独立护甲声和阻挡提示，真实减伤不变")
 var soul: Node=target("specter",Vector3(14,0,0));soul.hurt(10,1,10,"light")
 check(game.feedback.last_event.material=="soul" and game.feedback.last_cue.color.b>.8,"亡灵显示魂裂色而非机械火花")
 var boss: Node=target("mother",Vector3(15,0,0));boss.state="windup";boss.hurt(1,1,10,"light")
 check(boss.state=="windup","强化视觉反馈不破坏首领轻击霸体")
 game.feedback.reset()
 for i in range(40):game.feedback.contact_cue(Vector3(8,1,0),1,"heavy",Color(1,.6,.1))
 check(game.feedback.cues.size()==12,"高频冲击圈同时最多十二个，无无限节点增长")
 await wait(.25);var pool: int=game.feedback.cue_pool.size();game.feedback.contact_cue(Vector3(8,1,0),1,"heavy",Color(1,.6,.1))
 check(pool==12 and game.feedback.cue_pool.size()==11,"冲击圈结束后复用同一节点与材质")
 idle();e.position=Vector3(8,0,0);e.hurt(9999,1,90,"critical",game.player);await wait(.05)
 check(is_instance_valid(e) and e.hp==0 and e.state=="dead" and e.is_visible_in_tree(),"击杀保留短促倒下收尾，奖励已提交且尸体不能再受击")
 var money: int=game.scrap;var resonance: float=game.campaign.resonance
 for other in game.enemies:
  if is_instance_valid(other) and other!=e:other.position.x=-18
 check(game.melee_hit(30,2,1,false)==0 and game.scrap==money and game.campaign.resonance==resonance,"尸体不重复发命中资源、吸血或掉落")
 await wait(.4);check(not is_instance_valid(e),"击杀收尾限时释放，不滞留碰撞体")
 game.load_room(11);check(game.feedback.cues.is_empty() and game.feedback.cue_pool.is_empty(),"换房清理刀光、冲击圈和复用引用")
 game.graphics.reset_feedback();return checks
