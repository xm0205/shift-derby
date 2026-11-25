extends Control

var race
var panel: Control
var input: LineEdit
var chat_icon: TextureRect
var emote_icon: TextureRect
var chat_button: Button
var emote_button: Button
const INTERACT_ATLAS=preload("res://assets/ui/rider25/quick_interact.png")
const INTERACT_SCALE=0.193
const INTERACT_OFFSET=Vector2(133,5)
var nearby_id: int=-2
var nearby_face: TextureRect
var nearby_label: Label
var nearby_lines: Array[Label]=[]
var nearby_buttons: Array[Button]=[]

func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 chat_icon=DerbyMenus.art(self,"rider25/chat_open",Rect2(452,45,30,33))
 emote_icon=DerbyMenus.art(self,"rider25/chat_emote",Rect2(485,45,30,33))
 chat_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 emote_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 chat_button=DerbyMenus.hit(self,Rect2(452,45,30,33),func():open(false))
 emote_button=DerbyMenus.hit(self,Rect2(485,45,30,33),func():open(true))

func update_visibility():
 var running: bool=race.mode=="race" and not race.paused and race.countdown<=0 and not race.practice_mode
 visible=running
 chat_button.tooltip_text="快捷台词" if race.language=="zh" else "Quick chat"
 emote_button.tooltip_text="发送表情" if race.language=="zh" else "Emotes"
 if is_instance_valid(panel) and (not running or race.map_dragging):close()
 if is_instance_valid(panel) and not nearby_lines.is_empty():sync_nearby()

func typing() -> bool:
 return is_instance_valid(input) and input.has_focus()

func close():
 if is_instance_valid(panel):
  panel.hide()
  panel.queue_free()
 panel=null
 input=null
 nearby_lines.clear()
 nearby_buttons.clear()
 nearby_id=-2

func available(at: Vector2,dims: Vector2,check_horses: bool=true) -> bool:
 var rect:=Rect2(at,dims)
 if check_horses and not race.dialogue.safe(rect):return false
 if not race.dialogue.ui_clear(rect):return false
 return not rect.intersects(race.dialogue.favor_rect())

func open(emote: bool, rider_faces: bool=false):
 if race.mode!="race" or race.paused:return
 var previous:=panel.position if is_instance_valid(panel) else Vector2(-1,-1)
 close()
 var dims:=Vector2(211,162) if emote else INTERACT_ATLAS.get_size()*INTERACT_SCALE
 var slot:=Vector2(-1,-1)
 var candidates: Array=[previous,Vector2(404,114),Vector2(11,106),Vector2(12,114)] if not emote else [previous,Vector2(417,115),Vector2(11,105),Vector2(415,120),Vector2(11,113)]
 for at in candidates:
  if available(at,dims):
   slot=at
   break
 if slot.x<0:
  for at in candidates:
   if available(at,dims,false):
    slot=at
    break
 if slot.x<0:return
 var zh: bool=race.language=="zh"
 panel=Control.new()
 panel.name="RiderChatPanel"
 panel.position=slot
 panel.size=dims
 panel.mouse_filter=Control.MOUSE_FILTER_STOP
 add_child(panel)
 if emote:
  DerbyMenus.art(panel,"sx_panel_plain",Rect2(Vector2.ZERO,dims))
  decorate_title("")
  var general: Button=DerbyMenus.button(race,panel,Rect2(20,6,65,18),"通用" if zh else "STICKERS",func():open(true))
  var personal: Button=DerbyMenus.button(race,panel,Rect2(90,6,65,18),"骑手" if zh else "RIDER",func():open(true,true))
  for tab in [general,personal]:tab.add_theme_font_size_override("font_size",10)
  (personal if rider_faces else general).add_theme_color_override("font_color",Color("7ef3ff"))
  for i in range(10 if rider_faces else 20):
   var id: int=-2-i if rider_faces else i
   var rect:=Rect2(15+36*(i%5),34+26*(i/5),32,25)
   if rider_faces:rect=Rect2(16+36*(i%5),39+47*(i/5),34,39)
   var key: String=race.dialogue.emote_key(race.player_id,id)
   DerbyMenus.image_button(race,panel,"rider25/"+key,rect,func():send("",id),"",true)
 else:build_interactions(zh)

func board_rect(x: float,y: float,w: float,h: float) -> Rect2:
 return Rect2((Vector2(x,y)-INTERACT_OFFSET)*INTERACT_SCALE,Vector2(w,h)*INTERACT_SCALE)

func board_patch(area: Rect2,sample_x: float):
 var source:=Rect2(Vector2(sample_x,area.position.y)-INTERACT_OFFSET,Vector2(5,area.size.y))
 DerbyMenus.atlas_patch(panel,INTERACT_ATLAS,source,board_rect(area.position.x,area.position.y,area.size.x,area.size.y))

func board_text(rect: Rect2,words: String,font_size: int=9,left: bool=false) -> Label:
 var label: Label=DerbyMenus.title(race,panel,rect.position,rect.size,words,font_size,Color("fff1d3"))
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if left:label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
 label.clip_text=true
 label.size=rect.size
 return label

func build_interactions(zh: bool):
 DerbyMenus.art(panel,"rider25/quick_interact",Rect2(Vector2.ZERO,panel.size))
 DerbyMenus.hit(panel,board_rect(1150,70,110,100),close).name="Close"
 if not zh:
  board_patch(Rect2(578,87,307,59),566)
  board_text(board_rect(560,80,333,70),"QUICK CHAT",11)
  board_patch(Rect2(822,410,294,47),811)
  board_text(board_rect(820,405,310,52),"AUTO TARGET",8)
 var phrases: Array=race.dialogue.data.quick_chat[race.language]
 for i in range(6):
  var y: int=193+int(i/3)*100
  var x: int=222+(i%3)*344
  var words: String=phrases[i]
  if not zh:
   board_patch(Rect2(x+80,y+11,175,61),x+70)
   board_text(board_rect(x+35,y,254,75),words,10)
  var quick: Button=DerbyMenus.hit(panel,board_rect(x,y,322,82),func():send(words))
  quick.tooltip_text=words
 board_patch(Rect2(420,412,211,45),409)
 nearby_label=board_text(board_rect(422,404,225,55),"",10)
 var portrait_field:=ColorRect.new()
 var face_box:=board_rect(306,402,76,61)
 portrait_field.position=face_box.position
 portrait_field.size=face_box.size
 portrait_field.color=Color("1a2341")
 portrait_field.mouse_filter=Control.MOUSE_FILTER_IGNORE
 panel.add_child(portrait_field)
 nearby_face=DerbyMenus.art(panel,"rider25/face_0_4",face_box)
 nearby_face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 for i in range(3):
  var y: int=488+i*90
  board_patch(Rect2(476,y+11,655,55),462)
  nearby_lines.append(board_text(board_rect(484,y+2,647,68),"",9,true))
  nearby_buttons.append(DerbyMenus.hit(panel,board_rect(240,y,969,76),func():choose_nearby_line(i)))
 input=LineEdit.new()
 input.name="ChatLine"
 input.position=board_rect(231,790,732,77).position
 input.max_length=24
 input.placeholder_text="输入一句话" if zh else "Type a message"
 input.add_theme_font_override("font",race.font)
 input.add_theme_font_size_override("font_size",9)
 input.add_theme_color_override("font_placeholder_color",Color("b6c2df"))
 var field:=StyleBoxFlat.new()
 field.bg_color=Color("111c34")
 field.set_corner_radius_all(4)
 field.content_margin_top=1
 field.content_margin_bottom=1
 field.content_margin_left=6
 field.content_margin_right=5
 input.add_theme_stylebox_override("normal",field)
 panel.add_child(input)
 input.size=board_rect(231,790,732,77).size
 input.text_submitted.connect(func(words: String):send(words))
 if not zh:
  board_patch(Rect2(1062,803,121,57),1048)
  board_text(board_rect(1027,792,181,69),"SEND",10)
 var send_button:=DerbyMenus.hit(panel,board_rect(997,786,237,91),func():send(input.text))
 send_button.tooltip_text="发送" if zh else "Send"
 if not zh:
  board_patch(Rect2(578,913,290,70),565)
  board_text(board_rect(548,905,338,84),"ASK FOR BOOST",8)
 var ask:=DerbyMenus.hit(panel,board_rect(407,914,625,111),func():ask_nearby())
 ask.name="AskForBoost"
 ask.tooltip_text="向附近骑手请求助推" if zh else "Ask a nearby rider for a boost"
 sync_nearby()

func sync_nearby():
 var id: int=race.dialogue.closest_rider()
 if id==nearby_id:return
 nearby_id=id
 var zh: bool=race.language=="zh"
 nearby_face.visible=id>=0
 if id>=0:nearby_face.texture=race.dialogue.texture("face_%d_0" % id)
 var rider_name: String=race.dialogue.rider_name(id) if id>=0 else ""
 nearby_label.text=(rider_name if zh else rider_name.trim_suffix(" Rider")) if id>=0 else ("附近无人" if zh else "NO RIDER")
 for i in range(3):
  var label:=nearby_lines[i]
  label.text=race.dialogue.data.nearby_interactions[id][race.language][i] if id>=0 else ("靠近骑手后可用" if zh else "AVAILABLE NEAR A RIDER") if i==1 else ""
  var font_size: int=9
  while font_size>7 and race.font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>label.size.x:
   font_size-=1
  label.add_theme_font_size_override("font_size",font_size)
  label.modulate.a=1.0 if id>=0 else .65
  nearby_buttons[i].disabled=id<0
  nearby_buttons[i].tooltip_text=label.text

func choose_nearby_line(index: int):
 if nearby_id<0 or not race.dialogue.near_player(nearby_id):return
 if index==2:
  ask_nearby()
  return
 var id:=nearby_id
 var words:=nearby_lines[index].text
 close()
 race.dialogue.send_player_message(words,-1,id,"tease" if index==0 else "cheer")

func ask_nearby():
 var id:=nearby_id
 close()
 race.dialogue.request_boost(id)

func decorate_title(title: String):
 if not title.is_empty():
  var label: Label=DerbyMenus.title(race,panel,Vector2(38,11),Vector2(131,15),title,10,DerbyPainter.GOLD)
  label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var close_rect:=Rect2(176,6,24,22) if title.is_empty() else Rect2(176,10,18,16)
 DerbyMenus.image_button(race,panel,"rider25/chat_close",close_rect,close,"",true)

func send(words: String,emote: int=-1):
 var message:=words.strip_edges().left(24)
 if race.mode!="race" or (message.is_empty() and emote==-1):return
 close()
 race.dialogue.send_player_message(message,emote)
