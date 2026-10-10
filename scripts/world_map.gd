extends Control
var game: Node3D
var regional := false
var zoom := 1.0
var offset := Vector2.ZERO
var selected := -1
var dragging := false
var region_colors=[Color(.62,.72,.68),Color(.78,.55,.26),Color(.8,.63,.32),Color(.23,.58,.74),Color(.33,.65,.38),Color(.71,.28,.38),Color(.25,.70,.75),Color(.86,.33,.15),Color(.76,.72,.54),Color(.51,.35,.74),Color(.36,.56,.87),Color(.61,.38,.78),Color(.91,.66,.29)]
func _ready() -> void:
 clip_contents=true;mouse_filter=Control.MOUSE_FILTER_STOP;selected=game.room;focus_mode=Control.FOCUS_ALL;grab_focus();fit()
func room_rect(number: int) -> Rect2:
 var r: Dictionary=game.rooms[number];var p: Array=r.get("map",[float(number%8)*70, floorf(number/8.0)*75,60,40])
 return Rect2(float(p[0]),float(p[1]),float(p[2]),float(p[3]))
func visible_rooms() -> Array:
 var result: Array=[]
 for i in game.rooms.size():
  if not regional or int(game.rooms[i].region)==game.map_region:result.append(i)
 return result
func fit() -> void:
 var entries: Array=visible_rooms();var bounds:=room_rect(entries[0])
 for i in entries:bounds=bounds.merge(room_rect(i))
 zoom=minf(size.x*.76/(bounds.size.x+90),size.y*.71/(bounds.size.y+90))
 offset=Vector2(size.x*.39,size.y*.52)-bounds.get_center()*zoom;queue_redraw()
func recenter() -> void:offset=Vector2(size.x*.39,size.y*.52)-room_rect(game.room).get_center()*zoom;queue_redraw()
func transformed(r: Rect2) -> Rect2:return Rect2(r.position*zoom+offset,r.size*zoom)
func connections(number: int) -> Array:
 var r: Dictionary=game.rooms[number];var links: Array=[int(r.previous),int(r.next)]
 for prop in r.props:
  if prop.kind.begins_with("portal"):links.append(int(prop.kind.trim_prefix("portal")))
  if prop.kind=="hub":links.append(11)
  if prop.kind=="side":links.append(17)
 return links
func revealed(number: int) -> bool:
 if game.visited.has(game.rooms[number].id):return true
 for other in connections(number):
  if game.visited.has(game.rooms[other].id):return true
 return false
func _process(dt: float) -> void:
 if game.screen!="map":return
 var axis:=Input.get_vector("left","right","up","down")
 if game.pad>=0:axis+=Vector2(Input.get_joy_axis(game.pad,JOY_AXIS_LEFT_X),Input.get_joy_axis(game.pad,JOY_AXIS_LEFT_Y))
 if axis.length()>.15:offset-=axis*dt*300;queue_redraw()
func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton:
  if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
   var before: Vector2=(event.position-offset)/zoom;zoom=clampf(zoom*(1.15 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.15),.22,5);offset=event.position-before*zoom;accept_event()
  elif event.button_index==MOUSE_BUTTON_MIDDLE:dragging=event.pressed;accept_event()
  elif event.pressed and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
   if event.position.y<45:
    if event.position.x<160:regional=false;fit()
    elif event.position.x<320:regional=true;fit()
    elif event.position.x<480:recenter()
    accept_event();return
   for i in visible_rooms():
    if transformed(room_rect(i)).has_point(event.position) and game.visited.has(game.rooms[i].id):
     selected=i;game.map_region=int(game.rooms[i].region)
     if event.button_index==MOUSE_BUTTON_RIGHT:
      if game.map_marks.has(game.rooms[i].id):game.map_marks.erase(game.rooms[i].id)
      else:game.map_marks[game.rooms[i].id]=true
      game.save_game()
     accept_event();break
 elif event is InputEventMouseMotion and dragging:offset+=event.relative;accept_event()
 elif event is InputEventKey and event.pressed:
  if event.physical_keycode==KEY_R:recenter();accept_event()
 queue_redraw()
func glyph(p: Vector2,kind: String,col: Color) -> void:
 if kind=="player":draw_colored_polygon(PackedVector2Array([p+Vector2(-6,-9),p+Vector2(10,0),p+Vector2(-6,9)]),col)
 elif kind in ["save","shop"]:
  draw_rect(Rect2(p-Vector2(7,5),Vector2(14,10)),col,false,2);draw_line(p+Vector2(-5,6),p+Vector2(-5,10),col,2);draw_line(p+Vector2(5,6),p+Vector2(5,10),col,2)
 elif kind=="boss":draw_circle(p,7,col);draw_circle(p+Vector2(-3,-1),2,Color(.02,.03,.04));draw_circle(p+Vector2(3,-1),2,Color(.02,.03,.04));draw_line(p+Vector2(0,5),p+Vector2(0,10),col,3)
 elif kind=="chest":draw_rect(Rect2(p-Vector2(7,5),Vector2(14,10)),col,false,2);draw_rect(Rect2(p-Vector2(2,2),Vector2(4,4)),col)
 elif kind=="lock":draw_arc(p+Vector2(0,-4),5,PI,TAU,12,col,2);draw_rect(Rect2(p-Vector2(6,0),Vector2(12,8)),col)
 elif kind=="mark":draw_arc(p-Vector2(0,4),5,0,TAU,16,col,2);draw_line(p+Vector2(-3,0),p+Vector2(0,8),col,2);draw_line(p+Vector2(3,0),p+Vector2(0,8),col,2)
 else:draw_polyline(PackedVector2Array([p+Vector2(0,-9),p+Vector2(7,0),p+Vector2(0,9),p+Vector2(-7,0),p+Vector2(0,-9)]),col,2)
func label(p: Vector2,value: String,font_size: int,col: Color) -> void:draw_string(ThemeDB.fallback_font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,col)
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color(.012,.025,.033))
 var map_area:=Rect2(0,48,size.x*.78,size.y-95)
 for x in range(0,int(size.x*.78),45):draw_line(Vector2(x,48),Vector2(x,size.y-47),Color(.08,.14,.16,.4))
 for y in range(48,int(size.y-47),45):draw_line(Vector2(0,y),Vector2(size.x*.78,y),Color(.08,.14,.16,.4))
 var entries: Array=visible_rooms()
 for i in entries:
  if not revealed(i):continue
  for other in connections(i):
   if other==i or other not in entries or not revealed(other):continue
   var a: Vector2=transformed(room_rect(i)).get_center();var b: Vector2=transformed(room_rect(other)).get_center()
   if not map_area.has_point(a) and not map_area.has_point(b):continue
   var corner:=Vector2(b.x,a.y)
   draw_line(a,corner,Color(.35,.37,.31,.65),1);draw_line(corner,b,Color(.35,.37,.31,.65),1)
 for i in entries:
  if not revealed(i):continue
  var r: Dictionary=game.rooms[i];var rect: Rect2=transformed(room_rect(i));var known: bool=game.visited.has(r.id);var color: Color=region_colors[int(r.region)]
  if not map_area.intersects(rect):continue
  draw_rect(rect,Color(color,.18 if known else .025));draw_rect(rect,ui_gold() if i==selected else color if known else Color(.25,.32,.36),false,2 if i==selected else 1)
  if known:
   for floor in r.platforms:
    if zoom<.85:break
    var a:=Vector2(float(floor[0])/44+.5,1-(float(floor[2])+1)/float(r.bounds[3]+2))*rect.size+rect.position
    var b:=a+Vector2((float(floor[1])-float(floor[0]))/44*rect.size.x,0)
    draw_line(a,b,Color(color,.55),1)
   var icon_pos: Vector2=rect.get_center();var mark_kind: String=""
   for e in r.enemies:
    var def: Dictionary=game.Content.ENEMIES[e.kind]
    if def.get("boss",false) and not game.flags.get(def.flag,false):mark_kind="boss"
   for prop in r.props:
    if "chest" in prop.kind and not game.opened.has(r.id+":"+prop.kind) and mark_kind.is_empty():mark_kind="chest"
    if prop.kind in ["travel","shop"] and mark_kind.is_empty():mark_kind="travel" if prop.kind=="travel" else "shop"
   if i==game.room:glyph(icon_pos,"player",Color(.1,.9,1))
   elif game.map_marks.has(r.id):glyph(icon_pos,"mark",ui_gold())
   elif not mark_kind.is_empty():glyph(icon_pos,mark_kind,color.lightened(.4))
   elif r.has("checkpoint") and r.get("rest",true):glyph(icon_pos,"save",Color(.85,.84,.70))
   if not str(r.get("gate","")).is_empty() and not game.flags.get(r.gate,false):glyph(rect.end-Vector2(5,5),"lock",Color(.9,.3,.2))
   if zoom>1.05:label(rect.position+Vector2(2,-5),r.name,12,color.lightened(.3))
 if not regional:
  for region in range(13):
   var bounds: Rect2;var found:=false;var discovered:=false
   for i in entries:
    if int(game.rooms[i].region)!=region:continue
    bounds=bounds.merge(room_rect(i)) if found else room_rect(i);found=true
    if game.visited.has(game.rooms[i].id):discovered=true
   if not found or not discovered:continue
   var title_pos:=transformed(bounds).position+Vector2(0,-12)
   if map_area.has_point(title_pos):label(title_pos,game.Content.REGIONS[region],18,region_colors[region].lightened(.2))
 draw_rect(Rect2(0,0,size.x,48),Color(.025,.035,.04));label(Vector2(15,29),"世界",22,ui_gold() if not regional else Color(.5,.6,.65));label(Vector2(175,29),"区域",22,ui_gold() if regional else Color(.5,.6,.65));label(Vector2(335,29),"R 定位玩家",17,Color(.7,.75,.75))
 var explored:=0
 for i in game.rooms.size():
  if game.visited.has(game.rooms[i].id):explored+=1
 label(Vector2(size.x*.62,29),"探索 %d%%  %d/%d"%[explored*100/game.rooms.size(),explored,game.rooms.size()],18,ui_gold())
 draw_rect(Rect2(size.x*.78,48,size.x*.22,size.y-48),Color(.021,.028,.034,.98));label(Vector2(size.x*.80,85),"地图图例",23,ui_gold())
 var legends: Array=[["player","当前位置"],["save","休息灯"],["travel","传送站"],["shop","商人"],["boss","未击败首领"],["chest","未领取宝箱"],["lock","能力 / 机关门"],["mark","自定义标记"]]
 for i in legends.size():glyph(Vector2(size.x*.814,120+i*32),legends[i][0],Color(.24,.82,.9) if i==0 else ui_gold());label(Vector2(size.x*.836,126+i*32),legends[i][1],16,Color(.82,.81,.76))
 if selected>=0:
  var room: Dictionary=game.rooms[selected]
  label(Vector2(size.x*.80,size.y*.73),room.id,16,ui_gold());label(Vector2(size.x*.80,size.y*.78),room.name,18,Color(.9,.88,.8));label(Vector2(size.x*.80,size.y*.835),game.Content.REGIONS[int(room.region)],15,Color(.6,.7,.74))
 draw_rect(Rect2(0,size.y-44,size.x*.78,44),Color(.021,.032,.037));label(Vector2(12,size.y-17),"WASD / 摇杆移动   中键拖动   滚轮缩放   右键添加 / 删除标记",16,Color(.67,.73,.73))
func ui_gold() -> Color:return Color(.87,.68,.36)
