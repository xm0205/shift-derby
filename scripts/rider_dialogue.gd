extends CanvasLayer

const ART="res://assets/ui/rider25/"
const TALK_DISTANCE=110.0
const FAVOR_SIZE=Vector2(190,100)
var race
var data: Dictionary
var rng:=RandomNumberGenerator.new()
var bubble: Control
var bubble_panel: Panel
var bubble_tail: Polygon2D
var bubble_tail_fill: Polygon2D
var face: TextureRect
var emote: TextureRect
var line: Label
var text_area: Control
var favors:=DerbyRiderFavors.new()
var favor_panel: Control
var favor_id: int=-1
var favor_time: float=0.0
var active: Dictionary={}
var queue: Dictionary={}
var player_queue: Dictionary={}
var life: float=0.0
var global_delay: float=0.0
var cooldown: Array[float]=[]
var once: Dictionary={}
var gaps: Array[float]=[]
var checks: float=0.0
var last_countdown_start:=false
var bribe: Dictionary={}
var bribe_deals: Array[Dictionary]=[]
var bribe_target: int=0
var offer: Dictionary={}
const STORY_CHATS_PER_ROUND=3
const STORY_TOPICS=["hello","joke","praise","special","snack","weather","dream","lucky","rival","story"]
var story: Dictionary={}
var story_from_picker: bool=false
var story_topic_page: int=0
var last_affection_before: int=0
var last_affection_gain: int=0
var scene_id: int=0
var scene_kind: String=""
var wrap_topic: String=""
var finish_id: int=-1
var reply: Dictionary={}
var reply_until: float=0
var peer_after: float=11.0

func _ready():
 layer=35
 transform=Transform2D(0,Vector2(2,2),0,Vector2.ZERO)
 rng.randomize()
 data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/rider25.json"))
 bubble=Control.new()
 bubble.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(bubble)
 bubble_tail=Polygon2D.new()
 bubble.add_child(bubble_tail)
 bubble_tail_fill=Polygon2D.new()
 bubble.add_child(bubble_tail_fill)
 bubble_panel=Panel.new()
 bubble_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 bubble.add_child(bubble_panel)
 face=TextureRect.new()
 face.mouse_filter=Control.MOUSE_FILTER_IGNORE
 face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 bubble.add_child(face)
 text_area=Control.new()
 text_area.mouse_filter=Control.MOUSE_FILTER_IGNORE
 text_area.clip_contents=true
 bubble.add_child(text_area)
 line=Label.new()
 line.mouse_filter=Control.MOUSE_FILTER_IGNORE
 line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 line.max_lines_visible=2
 line.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 line.add_theme_font_override("font",race.font)
 line.add_theme_font_size_override("font_size",11)
 line.add_theme_constant_override("line_spacing",-4)
 line.clip_text=true
 line.add_theme_color_override("font_color",Color("24223a"))
 text_area.add_child(line)
 emote=TextureRect.new()
 emote.mouse_filter=Control.MOUSE_FILTER_IGNORE
 emote.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 emote.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 bubble.add_child(emote)
 reset_race()

func reset_race():
 clear_ui()
 queue.clear()
 once.clear()
 cooldown.assign([0.,0.,0.,0.,0.,0.])
 gaps.assign([0.,0.,0.,0.,0.,0.])
 checks=0
 global_delay=0
 last_countdown_start=false
 favors.reset_race()
 finish_id=-1
 reply.clear()
 reply_until=0
 peer_after=11.0

func clear_ui():
 if is_instance_valid(race.sound):race.sound.stop_dialogue_cues()
 active.clear()
 queue.clear()
 player_queue.clear()
 reply.clear()
 for heart in get_tree().get_nodes_in_group("rider25_hearts"):
  if heart.get_parent()==self:heart.queue_free()
 if is_instance_valid(bubble):bubble.hide()
 close_favor()

func campaign_state() -> Dictionary:
 return {"favors":favors.save_state(),"bribe":bribe.duplicate(true),"bribe_deals":bribe_deals.duplicate(true),"offer":offer.duplicate(true),"story":story.duplicate(true)}

func restore_campaign(state: Dictionary):
 favors.restore(state.get("favors",{}))
 bribe=state.get("bribe",{}).duplicate(true)
 bribe_deals.assign(state.get("bribe_deals",[bribe] if not bribe.is_empty() else []).duplicate(true))
 offer=state.get("offer",{}).duplicate(true)
 var saved_story: Dictionary=state.get("story",{})
 story={}
 if not saved_story.is_empty():
  story={"round":saved_story.get("round",0),"kind":saved_story.get("kind",""),"seen":saved_story.get("seen",false),"id":saved_story.get("id",0)}

func texture(key: String) -> Texture2D:
 return load(ART+key+".png")

func rider_name(id: int) -> String:
 var rider: Dictionary=data.riders[id]
 return rider.name if race.language=="zh" else rider.name_en

func event(id: int,key: String,force: bool=false,priority: int=0):
 if race.practice_mode:return
 if id<0 or id>=data.riders.size() or not near_player(id):return
 var rider: Dictionary=data.riders[id]
 if not force and (cooldown[id]>0 or global_delay>0 or not active.is_empty()):return
 for entry in rider.special:
  if entry.event!=key or once.has(entry.id):continue
  if force or rng.randf()<float(data.special_chance):
   push_entry(id,entry,priority+1)
   return
 if not force and rng.randf()>=float(data.ordinary_chance):return
 if key in ["passed","overtake","ai_counter","counter_ok","trap"]:
  var lines: Dictionary=data.race_reactions[id]
  var options: Array=lines[key]
  var reaction: Dictionary=options[rng.randi_range(0,options.size()-1)]
  push_entry(id,{"text":reaction[race.language],"face":int(reaction.face)},priority)
  return
 var ordinary: Array=rider.normal.filter(func(e):return e.event==key)
 if ordinary.is_empty():return
 push_entry(id,ordinary[rng.randi_range(0,ordinary.size()-1)],priority)

func push_entry(id: int,entry: Dictionary,priority: int):
 if (not queue.is_empty() and int(queue.priority)>priority) or (not active.is_empty() and int(active.priority)>priority):return
 if race.language=="en" and entry.has("text_en"):
  entry=entry.duplicate()
  entry.text=entry.text_en
 queue={"id":id,"entry":entry,"priority":priority,"expires":race.elapsed+(2.6 if priority>=2 else 1.2)}

func send_player_message(message: String,emote_id: int,target: int=-1,topic: String=""):
 if target>=0 and not near_player(target):return
 player_queue={"id":race.player_id,"entry":{"text":message,"face":4,"player":true,"emote":emote_id,"recipient":target,"topic":topic},"priority":2}
 show_queued()

func overdrive_line(id: int,kind: String):
 if race.practice_mode or global_delay>0 or not active.is_empty() or not queue.is_empty():return
 if id!=race.player_id and not near_player(id):return
 var lines: Array=data.overdrive_lines[id][kind][race.language]
 var words: String=lines[rng.randi_range(0,lines.size()-1)]
 var face_id: int=1 if kind in ["hit","empty"] else 4
 push_entry(id,{"text":words,"face":face_id,"direct":id==race.player_id},3 if kind=="perfect" else 1)

func advance(dt: float):
 if race.practice_mode:return
 if race.mode=="results":
  if not active.is_empty():render_bubble(dt)
  return
 if race.mode!="race" or race.paused or race.countdown>0:return
 for i in range(6):cooldown[i]=maxf(cooldown[i]-dt,0)
 global_delay=maxf(global_delay-dt,0)
 update_favor(dt)
 checks-=dt
 if checks<=0:
  checks=.25
  race_events()
 var danger: bool=urgent()
 advance_reply(danger)
 if not queue.is_empty():
  if float(queue.expires)<race.elapsed:queue.clear()
 if not player_queue.is_empty() or not queue.is_empty():show_queued()
 if not active.is_empty():render_bubble(dt)

func urgent() -> bool:
 return race.combat.feedback_time>0 or race.combat.pending.any(func(e):return e.target==race.player_id)

func race_events():
 var own: DerbyHorse=race.horses[race.player_id]
 if not last_countdown_start:
  last_countdown_start=true
  var visible_ids: Array=race.horses.filter(func(h):return near_player(h.id))
  if not visible_ids.is_empty():event(visible_ids[rng.randi_range(0,visible_ids.size()-1)].id,"start",true)
 advance_bribe(own)
 var requester:=favors.observe(race)
 if requester>=0 and not is_instance_valid(favor_panel):
  if not open_favor(requester):favors.check_after=race.elapsed+float(favors.rules.request.retry_after)
 try_approach_line()
 for h in race.horses:
  if h.id==own.id or h.finished or own.finished:continue
  var gap: float=h.progress-own.progress
  if absf(gap)<145:
   if gap>12 and gaps[h.id]<-12:
    var side: bool=h.id==3 and absf(h.y-own.y)>16
    event(h.id,"side_pass" if side and not once.has("R25-PURPLE-01") else "passed",side)
   elif gap<-12 and gaps[h.id]>12:event(h.id,"overtake")
   elif reply.is_empty() and absf(gap)<75 and rng.randf()<.24:event(h.id,"near")
  if absf(gap)>12:gaps[h.id]=gap
 if own.progress>=race.race_distance*.85 and not once.has("finish_event"):
  once.finish_event=true
  var nearby: Array=race.horses.filter(func(h):return near_player(h.id))
  if not nearby.is_empty():event(nearby[rng.randi_range(0,nearby.size()-1)].id,"finish",true)
 var pink: DerbyHorse=race.horses[5]
 if pink.progress>=race.race_distance*.72 and pink.progress<race.race_distance and (pink.multiplier>1 or pink.dash_time>0) and not once.has("R25-PINK-04"):
  event(5,"sprint",true,1)
 try_peer_exchange()

func finish_reaction(id: int, won: bool) -> Dictionary:
 var pool: Array=data.finish_reactions[id]["win" if won else "loss"]
 return pool[posmod(race.race_seed+id,pool.size())]

func finish_quote(winner: int):
 if race.practice_mode:return
 finish_id=winner
 var reaction:=finish_reaction(winner,true)
 var entry: Dictionary={"text":reaction[race.language],"face":int(reaction.face),"finish":true}
 push_entry(winner,entry,5)
 # The winner can be far ahead. Use the same safe screen-space placement as dialogue.
 queue.expires=race.elapsed+3.0

func result(winner: int):
 finish_quote(winner)

func try_approach_line():
 if race.elapsed<3.0 or urgent() or global_delay>0 or not active.is_empty() or not queue.is_empty() or not player_queue.is_empty() or not reply.is_empty() or is_instance_valid(favor_panel):return
 var id:=closest_rider(true)
 if id<0:return
 var words: String=data.nearby_interactions[id].approach[race.language]
 var ask_red: bool=race.player_id==0 and id!=0 and not once.has("ask_hong_jianguo")
 if ask_red:words="红建国是谁啊？" if race.language=="zh" else "Who's Hong Jianguo?"
 if not bubble_slot(id,words).has_area():return
 if ask_red:once["ask_hong_jianguo"]=true
 push_entry(id,{"id":"rider_approach_%d" % id,"text":words,"face":4,"approach":true},2)

func counter_result(attack: Dictionary,success: bool):
 event(int(attack.attacker),"counter_ok" if success else "counter_miss",success,2)

func show_queued():
 if is_instance_valid(favor_panel):
  if not favor_blocked():return
  close_favor()
 var urgent_now:=urgent()
 var use_player: bool=not player_queue.is_empty() and not urgent_now and int(queue.get("priority",0))<3 and int(active.get("priority",0))<=2
 var next: Dictionary=player_queue if use_player else queue
 if next.is_empty() or (urgent_now and int(next.priority)<3):return
 if not active.is_empty() and int(active.priority)>int(next.priority):return
 var entry: Dictionary=next.entry
 var id: int=next.id
 var directed: bool=entry.get("direct",false)
 var mixed: bool=int(entry.get("emote",-1))!=-1 and not String(entry.text).is_empty()
 var rect:=bubble_slot(id,entry.text,entry.get("finish",false) or entry.get("player",false) or directed,mixed)
 if not rect.has_area() and (use_player or directed):
  for corner in [Vector2(12,250),Vector2(394,250),Vector2(206,257)]:
   var candidate:=Rect2(corner,bubble_dimensions(entry.text,mixed))
   if ui_clear(candidate):
    rect=candidate
    break
 if not rect.has_area():return
 active=next.duplicate()
 next.clear()
 if entry.has("id"):once[entry.id]=true
 global_delay=3.0
 cooldown[id]=rng.randf_range(float(data.cooldown[0]),float(data.cooldown[1]))
 life=2.5
 var trim: Color=DerbyPainter.CLOTH[id].darkened(.13)
 var plate:=StyleBoxFlat.new()
 plate.bg_color=Color("#fff2ceeb")
 plate.border_color=trim
 plate.set_border_width_all(2)
 plate.set_corner_radius_all(10)
 bubble_panel.add_theme_stylebox_override("panel",plate)
 bubble_panel.size=rect.size
 bubble_tail.color=trim
 bubble_tail_fill.color=plate.bg_color
 bubble_tail.hide()
 bubble_tail_fill.hide()
 face.texture=texture("face_%d_%d" % [id,int(entry.face)])
 line.text=entry.text
 var icon_id: int=int(entry.get("emote",-1))
 emote.visible=icon_id!=-1
 line.visible=not String(entry.text).is_empty()
 if emote.visible:emote.texture=texture(emote_key(id,icon_id))
 size_bubble(rect)
 bubble.modulate.a=0
 bubble.show()
 if entry.get("player",false):prepare_reply(icon_id,entry.text,int(entry.get("recipient",-1)),entry.get("topic",""))
 elif entry.has("peer"):prepare_peer_reply(id,int(entry.peer),icon_id)
 if not urgent():race.sound.cue("rider_chat")
 if String(entry.get("id",""))=="R25-PINK-04":pink_hearts(race.horses[id])

func emote_key(rider_id: int,icon_id: int) -> String:
 if icon_id>=0:return "sticker_%d" % icon_id
 return "face_%d_%d" % [rider_id,-2-icon_id]

func pink_hearts(horse: DerbyHorse):
 var facing: float=signf(cos(race.horse_angle(horse)))
 var base: Vector2=race.horse_screen(horse)+Vector2(-42*facing,-16)*race.horse_draw_scale()
 for i in range(3):
  var heart:=Sprite2D.new()
  heart.texture=texture("heart")
  heart.scale=Vector2.ONE*.08
  heart.position=base+Vector2(-facing*i*7,i*4)
  add_child(heart)
  heart.add_to_group("rider25_hearts")
  var fly:=heart.create_tween().set_parallel()
  fly.tween_property(heart,"position",heart.position+Vector2(-23*facing,-19-i*5),.55)
  fly.tween_property(heart,"modulate:a",0,.55)
  fly.chain().tween_callback(heart.queue_free)

func size_bubble(rect: Rect2):
 bubble.position=rect.position
 bubble.size=rect.size
 face.position=Vector2(6,4)
 face.size=Vector2(29,rect.size.y-8)
 text_area.position=Vector2(37,5)
 text_area.size=Vector2(rect.size.x-46,rect.size.y-10)
 line.position=Vector2.ZERO
 line.size=text_area.size
 emote.position=Vector2((rect.size.x+13)*.5,5)
 emote.size=Vector2(27,27)
 if emote.visible and line.visible:
  emote.position=Vector2(33,5)
  text_area.position.x=62
  text_area.size.x=rect.size.x-69
  line.size=text_area.size

func render_bubble(dt: float):
 var obscured: bool=urgent() and int(active.priority)<3 and race.mode!="results"
 if obscured and active.entry.get("player",false):
  bubble.hide()
  return
 life-=dt
 if life<=0:
  bubble.hide()
  active.clear()
  return
 bubble.visible=not obscured
 if not bubble.visible:return
 if active.entry.get("approach",false) and not near_player(active.id):
  bubble.hide()
  active.clear()
  return
 update_bubble_tail(int(active.id))
 bubble.modulate.a=.9*minf(clampf((2.5-life)/.15,0,1),clampf(life/.42,0,1))

func update_bubble_tail(id: int):
 var horse: DerbyHorse=race.horses[id]
 var anchor: Vector2=race.horse_screen(horse)-Vector2(0,72*race.horse_draw_scale())
 var point: Vector2=anchor-bubble.position
 var half: Vector2=bubble.size*.5
 var offset:=point-half
 var outside:=Rect2(0,34,640,290).has_point(anchor) and not Rect2(Vector2.ZERO,bubble.size).has_point(point)
 bubble_tail.visible=outside
 bubble_tail_fill.visible=outside
 if not outside:return
 var edge_scale: float=minf((half.x-5)/maxf(.01,absf(offset.x)),(half.y-5)/maxf(.01,absf(offset.y)))
 var base:=half+offset*edge_scale
 var direction: Vector2=(point-base).normalized()
 var across:=direction.orthogonal()
 var tip:=base+direction*minf(23.0,base.distance_to(point))
 bubble_tail.polygon=PackedVector2Array([base-across*7,tip,base+across*7])
 bubble_tail_fill.polygon=PackedVector2Array([base-across*4,tip-direction*4,base+across*4])

func bubble_dimensions(value: String,mixed: bool=false) -> Vector2:
 if mixed:return Vector2(172 if value.length()<10 else 198,46)
 if value.length()<9:return Vector2(112,38)
 if value.length()<15:return Vector2(163,43)
 return Vector2(198,49)

func bubble_slot(id: int,value: String,allow_gap: bool=false,mixed: bool=false) -> Rect2:
 var dims:=bubble_dimensions(value,mixed)
 if race.mode=="results":return Rect2(Vector2(396,2),Vector2(224,33))
 if not allow_gap and not near_player(id):return Rect2()
 var point: Vector2=race.horse_screen(race.horses[id])
 if not Rect2(4,34,632,292).has_point(point):
  if not allow_gap or id!=finish_id:return Rect2()
  point=Vector2(320,140)
 var s: float=race.horse_draw_scale()
 var right: float=67*s+12
 var left: float=-dims.x-right
 var slots: Array=[point+Vector2(right,-49),point+Vector2(left,-49),point+Vector2(right,-8),point+Vector2(left,-8),point+Vector2(-dims.x*.5,-93*s-dims.y-8),point+Vector2(-dims.x*.5,14)]
 for edge_y in [122,192,256]:
  slots.append(Vector2(12,edge_y))
  slots.append(Vector2(628-dims.x,edge_y))
 var chat_panel: Control=race.chat.panel if is_instance_valid(race.chat) else null
 for p in slots:
  var rect:=Rect2(p,dims)
  if not safe(rect):continue
  if is_instance_valid(chat_panel) and chat_panel.visible and rect.intersects(Rect2(chat_panel.position,chat_panel.size)):continue
  return rect
 return Rect2()

func near_player(id: int) -> bool:
 if id==race.player_id or race.horses.size()!=6:return false
 return race.combat.in_attack_range(race,race.horses[id],race.horses[race.player_id],TALK_DISTANCE)

func ui_clear(rect: Rect2) -> bool:
 if not Rect2(10,37,620,284).encloses(rect):return false
 if race.combat.cooperation_leader>=0 and rect.intersects(Rect2(10,89,137,17)):return false
 if race.overdrive.banner_time>0 and rect.intersects(Rect2(153,37,238,34)):return false
 if urgent() and (rect.intersects(Rect2(8,73,195,50)) or rect.intersects(Rect2(164,270,312,60))):return false
 for reserved in [Rect2(445,43,75,60),Rect2(0,36,155,53),Rect2(169,36,302,64),Rect2(516,39,124,75)]:
  if rect.intersects(reserved):return false
 return true

func safe(rect: Rect2) -> bool:
 if not ui_clear(rect):return false
 for horse in race.horses:
  var point: Vector2=race.horse_screen(horse)
  var s: float=race.horse_draw_scale()
  var occupied:=Rect2(point+Vector2(-67,-93)*s,Vector2(134,104)*s).grow(5)
  if rect.intersects(occupied):return false
 return true

func favor_rect() -> Rect2:
 return Rect2(favor_panel.position,favor_panel.size) if is_instance_valid(favor_panel) else Rect2()

func favor_blocked() -> bool:
 var own: DerbyHorse=race.horses[race.player_id]
 return race.mode!="race" or race.paused or race.practice_mode or race.map_dragging or own.finished or urgent() or own.overdrive_active or own.knockdown>0 or own.stun>0 or race.shake>0 or race.overdrive.banner_time>0

func favor_words(id: int,kind: String) -> String:
 var lines: Array=favors.rules.riders[id][kind][race.language]
 return lines[rng.randi_range(0,lines.size()-1)]

func open_favor(id: int) -> bool:
 if id==race.player_id or not near_player(id) or favor_blocked() or is_instance_valid(favor_panel):return false
 if is_instance_valid(race.chat.panel) or not active.is_empty() or not player_queue.is_empty() or int(queue.get("priority",0))>=2:return false
 var point: Vector2=race.horse_screen(race.horses[id])
 var y:=clampf(point.y-56,114,212)
 var columns: Array=[433.0,17.0] if point.x>320 else [17.0,433.0]
 var box:=Rect2()
 for x in columns:
  for row in [y,114.0,170.0,212.0]:
   var rect:=Rect2(Vector2(x,row),FAVOR_SIZE)
   if not safe(rect):continue
   box=rect
   break
  if box.has_area():break
 if not box.has_area() or not favors.begin(id,race.betting.round_number):return false
 var zh: bool=race.language=="zh"
 favor_id=id
 favor_time=float(favors.rules.request.visible_seconds)
 favor_panel=Control.new()
 favor_panel.name="RiderFavor"
 favor_panel.position=box.position
 favor_panel.size=box.size
 favor_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(favor_panel)
 DerbyMenus.art(favor_panel,"sx_panel_plain",Rect2(Vector2.ZERO,FAVOR_SIZE))
 var heading: String=("%s · 请求帮忙" if zh else "%s ASKS A FAVOR") % rider_name(id)
 DerbyMenus.title(race,favor_panel,Vector2(9,5),Vector2(172,17),heading,10,DerbyPainter.GOLD)
 var portrait: TextureRect=DerbyMenus.art(favor_panel,"rider25/face_%d_4" % id,Rect2(9,28,34,34))
 portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 DerbyMenus.art(favor_panel,"rider25/chat_speech",Rect2(43,22,138,51))
 var speech: Label=DerbyMenus.title(race,favor_panel,Vector2(54,29),Vector2(110,32),favor_words(id,"request"),10 if zh else 8,Color("252539"))
 speech.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
 speech.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 speech.add_theme_constant_override("line_spacing",-4)
 speech.clip_text=true
 var yes: Button=DerbyMenus.button(race,favor_panel,Rect2(12,74,80,18),"答应帮忙" if zh else "HELP",func():answer_favor(true))
 var no: Button=DerbyMenus.button(race,favor_panel,Rect2(98,74,80,18),"婉言拒绝" if zh else "DECLINE",func():answer_favor(false))
 yes.name="Help"
 no.name="Decline"
 for choice in [yes,no]:
  choice.add_theme_font_size_override("font_size",10)
  choice.focus_mode=Control.FOCUS_NONE
 race.sound.cue("rider_chat")
 race.save_settings()
 return true

func update_favor(dt: float):
 if not is_instance_valid(favor_panel):return
 favor_time-=dt
 if favor_time<=0 or favor_blocked() or not near_player(favor_id):
  close_favor()
  return
 favor_panel.visible=safe(favor_rect())

func close_favor():
 if is_instance_valid(favor_panel):
  favor_panel.hide()
  favor_panel.queue_free()
 favor_panel=null
 favor_id=-1
 favor_time=0

func answer_favor(accepted: bool):
 if not is_instance_valid(favor_panel) or not favor_panel.visible or favor_blocked() or not near_player(favor_id) or not safe(favor_rect()):return
 var id:=favor_id
 if not favors.respond(id,race.betting.round_number,accepted):return
 close_favor()
 push_entry(id,{"text":favor_words(id,"accept" if accepted else "decline"),"face":4 if accepted else 0,"direct":true},2)
 show_queued()
 race.save_settings()

func complete_wrap(id: int,topic: String):
 if race.mode=="rider_wrap" and scene_id==id and wrap_topic==topic and favors.record_chat(id,"post_race_"+topic):
  race.save_settings()

const BRIBE_FIRST_ROUND=4
func bribe_round() -> int:
 var next: int=race.betting.round_number+int(not race.betting.active or race.betting.settled)
 return clampi(next,1,DerbyBetting.ROUND_LIMIT)
func deals_unlocked() -> bool:
 return bribe_round()>=BRIBE_FIRST_ROUND

func bribe_offer(id: int=-1) -> Dictionary:
 var n:=bribe_round()-1
 var target:=bribe_target if id<0 else id
 return {"cost":int(data.bribe.cost[n]),"chance":favors.chance_for(float(data.bribe.chance[n]),target),"refund":float(data.bribe.refund[n])}

func bribe_attempt(id: int) -> Dictionary:
 for deal: Dictionary in bribe_deals:
  if int(deal.round)==bribe_round() and int(deal.id)==id:return deal
 return {}

func bribe_count() -> int:
 var round_id:=bribe_round()
 return bribe_deals.filter(func(deal):return int(deal.round)==round_id).size()

func bribe_available(id: int=-1) -> bool:
 if not (race.pre_race_deal and race.betting.active and not race.betting.settled and deals_unlocked()):return false
 if id>=0:return id!=race.betting.selected and bribe_attempt(id).is_empty()
 return bribe_count()<race.horses.size()-1

func pay_bribe():
 if race.mode!="bribe_confirm" or not bribe_available(bribe_target):return
 var offer:=bribe_offer()
 var before: int=race.betting.funds
 if before<int(offer.cost):return
 var success:=rng.randf()<float(offer.chance)
 var refund:=0 if success else floori(int(offer.cost)*float(offer.refund))
 bribe_deals=bribe_deals.filter(func(deal):return int(deal.round)==bribe_round())
 bribe={"round":bribe_round(),"id":bribe_target,"success":success,"refund":refund,"used":false}
 bribe_deals.append(bribe)
 race.betting.funds-=int(offer.cost)-refund
 race.show_menu("bribe_result")
 race.coins.change(before,race.betting.funds)
 race.save_settings()

func is_bribed_ally(id: int,pending_only: bool=false) -> bool:
 for deal: Dictionary in bribe_deals:
  if int(deal.get("round",0))==race.betting.round_number and bool(deal.get("success",false)) and int(deal.get("id",-1))==id:
   if not pending_only or not bool(deal.get("used",false)):return true
 return false

func bribed_ally_ids() -> Array[int]:
 var ids: Array[int]=[]
 for deal: Dictionary in bribe_deals:
  if int(deal.get("round",0))==race.betting.round_number and bool(deal.get("success",false)):
   var id: int=int(deal.get("id",-1))
   if id>=0 and not (id in ids):ids.append(id)
 return ids

func advance_bribe(own: DerbyHorse):
 if own.finished or own.knockdown>0 or own.stun>0 or own.progress<race.race_distance*.50:return
 if own.effect>0 and own.multiplier>1:return
 var unused: Array[Dictionary]=bribe_deals.filter(func(deal):return deal.success and not deal.used and int(deal.round)==race.betting.round_number)
 var deadline: float=.88-.044*maxi(0,unused.size()-1)
 for deal: Dictionary in unused:
  var helper: DerbyHorse=race.horses[int(deal.id)]
  if helper.id==own.id:continue
  var in_position: bool=race.combat.in_attack_range(race,helper,own,220) and helper.knockdown<=0 and helper.stun<=0
  if own.progress<race.race_distance*deadline and (not in_position or own.invincible>0 or own.effect>0 or urgent()):continue
  deal.used=true
  if bribe.get("id",-1)==deal.id and bribe.get("round",0)==deal.round:bribe.used=true
  own.hit(false)
  race.sound.cue("boost")
  if is_instance_valid(race.battle_vfx):race.battle_vfx.trigger_assist(helper.id,own.id,"bribe")
  race.announce("#%d BOOST > #%d" % [helper.id+1,own.id+1],.85)
  event(helper.id,"bribe",true,2)
  race.save_settings()
  return
 advance_affection_assist(own)

func advance_affection_assist(own: DerbyHorse):
 if own.progress<race.race_distance*.45 or own.overdrive_active or own.invincible>0 or own.effect>0 or urgent():return
 for h: DerbyHorse in race.horses:
  if h.id==own.id or h.finished or h.knockdown>0 or h.stun>0:continue
  var aff: int=favors.affection_of(h.id)
  if aff<40 or favors.mid_assist_used[h.id]:continue
  if not race.combat.in_attack_range(race,h,own,170):continue
  favors.mid_assist_used[h.id]=true
  if rng.randf()<float(aff)/100.0:
   own.hit(false)
   race.sound.cue("boost")
   if is_instance_valid(race.battle_vfx):race.battle_vfx.trigger_assist(h.id,own.id,"affection")
   race.announce("好感助推！" if race.language=="zh" else "FRIEND BOOST!",.9)
   push_entry(h.id,{"text":favor_words(h.id,"boost_yes"),"face":4,"direct":true},2)
   show_queued()
   return

func prepare_offer():
 offer.clear()
 if not deals_unlocked() or rng.randf()>=float(data.offer_chance):return
 var candidates: Array[int]=[]
 for id in range(6):
  if id!=race.betting.selected and id!=4:candidates.append(id)
 candidates.sort_custom(func(a,b):return race.betting.odds[a]>race.betting.odds[b])
 var id: int=candidates[rng.randi_range(0,1)]
 if 5 in candidates and race.betting.odds[candidates[0]]-race.betting.odds[5]<=.35:id=5
 var purse: int=int(data.offer_purse[bribe_round()-1])
 offer={"id":id,"purse":purse,"accepted":false,"answered":false,"boosted":false,"paid":0}

func prepare_story():
 var round_id:=bribe_round()
 if int(story.get("round",0))==round_id and story.has("chats_used"):return
 story={"round":round_id,"kind":"hello","seen":false,"id":0,"chats_used":0,"chatted":[]}
 offer.clear()
 var weights: Dictionary=data.scene_weights
 var pick:=rng.randi_range(1,int(weights.hello+weights.joke+weights.praise+weights.special))
 for kind in ["hello","joke","praise","special"]:
  pick-=int(weights[kind])
  if pick<=0:
   story.kind=kind
   break
 story.id=(race.betting.selected+rng.randi_range(1,5))%6

func story_remaining() -> int:
 var round_id:=bribe_round()
 if int(story.get("round",0))!=round_id:return STORY_CHATS_PER_ROUND
 if story.has("chats_used"):return maxi(0,STORY_CHATS_PER_ROUND-int(story.get("chats_used",0)))
 return 0 if bool(story.get("seen",false)) else STORY_CHATS_PER_ROUND

func story_available() -> bool:
 return story_remaining()>0

func open_story_select():
 if race.mode!="betting":return
 prepare_story()
 if not story_available():return
 race.show_menu("story_select")

func select_story_rider(id: int):
 if race.mode!="story_select" or not story_available() or id==race.betting.selected or id<0 or id>=6:return
 scene_id=id
 story_topic_page=0
 race.show_menu("story_topics")

func sorted_story_topics(id: int) -> Array[String]:
 var fresh: Array[String]=[]
 var done: Array[String]=[]
 var used_round: Array=story.get("round_topics",[])
 for t: String in STORY_TOPICS:
  if not favors.topic_asked(id,t) and not (t in used_round):fresh.append(t)
 for t: String in STORY_TOPICS:
  if not favors.topic_asked(id,t) and (t in used_round) and not (t in fresh):fresh.append(t)
 for t: String in STORY_TOPICS:
  if favors.topic_asked(id,t):done.append(t)
 fresh.append_array(done)
 return fresh

func choose_story_topic(topic: String):
 if race.mode!="story_topics" or not story_available() or not (topic in STORY_TOPICS):return
 var id: int=scene_id
 var chatted: Array=story.get("chatted",[])
 var streak3: bool=chatted.size()>=2 and int(chatted[chatted.size()-1])==id and int(chatted[chatted.size()-2])==id
 chatted.append(id)
 story["chatted"]=chatted
 var round_topics: Array=story.get("round_topics",[])
 if not (topic in round_topics):round_topics.append(topic)
 story["round_topics"]=round_topics
 story["chats_used"]=int(story.get("chats_used",0))+1
 story["seen"]=story_remaining()<=0
 story_from_picker=true
 scene_kind=topic
 favors.mark_topic_asked(id,topic)
 var gain_base: int=10 if streak3 else 5
 last_affection_before=favors.affection_of(id)
 last_affection_gain=favors.add_affection(id,gain_base)
 race.save_settings()
 race.show_menu("rider_scene")

func open_story():
 if race.mode!="betting" or not story_available():return
 story.seen=true
 story["chats_used"]=int(story.get("chats_used",0))+1
 story_from_picker=false
 scene_id=int(story.id)
 if scene_id==race.betting.selected:scene_id=(scene_id+1)%6
 scene_kind=String(story.get("kind","hello"))
 if scene_kind.is_empty():scene_kind="hello"
 last_affection_before=favors.affection_of(scene_id)
 last_affection_gain=favors.add_affection(scene_id,5)
 race.show_menu("rider_scene")

func open_result_scene():
 if race.mode!="results" or race.order.is_empty():return
 race.show_menu("wrap_select")

func select_result_rider(id: int):
 if race.mode!="wrap_select" or id==race.player_id or id not in race.order:return
 scene_id=id
 race.show_menu("wrap_topics")

func choose_result_topic(topic: String):
 if race.mode!="wrap_topics" or not data.post_race[scene_id].has(topic):return
 wrap_topic=topic
 race.show_menu("rider_wrap")

func accept_offer(value: bool):
 if not race.pre_race_deal or race.mode!="rider_offer" or offer.is_empty() or offer.get("answered",false):return
 offer.accepted=value
 offer.answered=true
 race.show_menu("post_bet")

func note_player_boost(id: int):
 if offer.get("accepted",false) and id==int(offer.id):offer.boosted=true

func pay_offer(winner: int):
 if offer.get("accepted",false) and offer.get("boosted",false) and winner==int(offer.id) and winner!=race.player_id and int(offer.paid)==0:
  offer.paid=int(offer.purse)/2
  race.betting.funds+=int(offer.paid)


func closest_rider(unspoken_only: bool=false) -> int:
 var own: DerbyHorse=race.horses[race.player_id]
 var closest: float=INF
 var id: int=-1
 for horse: DerbyHorse in race.horses:
  if not near_player(horse.id) or (unspoken_only and once.has("rider_approach_%d" % horse.id)):continue
  var distance:=absf(DerbyAI.gap(own,horse))
  if distance>=closest:continue
  closest=distance
  id=horse.id
 return id

func nearby_chat_target() -> int:
 var selected: int=race.pinned_target_id
 if selected>=0 and selected!=race.player_id and near_player(selected):return selected
 return closest_rider()

func request_boost(target: int=-1):
 if favor_blocked() or is_instance_valid(favor_panel):return
 var round_no: int=race.betting.round_number
 if round_no<1:return
 var zh: bool=race.language=="zh"
 if int(favors.last_player_request.get("round",0))>=round_no:
  race.announce("本轮已经请求过助推" if zh else "BOOST REQUEST ALREADY USED",1.1)
  return
 var id:=target if target>=0 else nearby_chat_target()
 if id<0 or not near_player(id):
  race.announce("附近没有可求助的骑手" if zh else "NO RIDER IN RANGE",1.1)
  return
 var own: DerbyHorse=race.horses[race.player_id]
 if own.effect>0 or own.dash_time>0 or own.counter_time>0:
  race.announce("当前状态无法接收助推" if zh else "CANNOT RECEIVE A BOOST RIGHT NOW",1.1)
  return
 var ally: DerbyHorse=race.horses[id]
 var available: bool=ally.stun<=0 and ally.knockdown<=0 and not ally.overdrive_active and race.combat.cooperation_leader!=own.id
 var chance: float=favors.chance_for(float(favors.rules.player_request.base_chance),id)
 var accepted:=available and rng.randf()<chance
 favors.last_player_request={"round":round_no,"id":id,"accepted":accepted}
 if accepted:
  own.dash_time=float(favors.rules.player_request.boost_seconds)
  race.sound.cue("boost")
  if is_instance_valid(race.battle_vfx):race.battle_vfx.trigger_assist(id,own.id,"ally")
  race.announce("队友助推！" if zh else "RIDER ASSIST!",.85)
 push_entry(id,{"text":favor_words(id,"boost_yes" if accepted else "boost_no"),"face":4 if accepted else 0,"direct":true},2)
 show_queued()
 race.save_settings()

func prepare_reply(emote_id: int,spoken: String="",target: int=-1,topic: String=""):
 if race.elapsed<reply_until:return
 var id:=target if target>=0 else nearby_chat_target()
 if id<0 or not near_player(id):return
 var text:=spoken.to_lower()
 var tone: String=""
 if "弱" in text or "老大" in text or "weak" in text or "boss" in text or emote_id in [8,10,12,14]:tone="tease"
 elif "加油" in text or "漂亮" in text or "nice" in text or emote_id in [6,7,9,16,19]:tone="cheer"
 if not topic.is_empty():tone=topic
 var signal_id: String="compliment" if topic=="cheer" else favors.friendly_topic(spoken,emote_id)
 if tone!="tease" and favors.record_chat(id,signal_id):race.save_settings()
 var entry:=reply_entry(id,emote_id,tone)
 reply={"id":id,"entry":entry,"at":race.elapsed+1.75,"until":race.elapsed+4.7}
 reply_until=race.elapsed+7.0

func reply_entry(id: int,emote_id: int,tone: String="") -> Dictionary:
 if not tone.is_empty():
  var response: Dictionary=data.reaction_replies[id][tone]
  return {"text":response[race.language],"emote":int(response.icon),"face":int(response.face)}
 var stickers: Array=data.reply_stickers[id]
 var icon: int=int(stickers[rng.randi_range(0,stickers.size()-1)]) if emote_id!=-1 and rng.randf()<.65 else -1
 var words: Array=(data.chat_replies if race.language=="zh" else data.chat_replies_en)[id]
 return {"text":words[rng.randi_range(0,words.size()-1)] if icon==-1 else "","emote":icon,"face":4}

func try_peer_exchange():
 if is_instance_valid(favor_panel) or race.elapsed<peer_after or urgent() or not active.is_empty() or int(queue.get("priority",0))>=1 or not player_queue.is_empty() or not reply.is_empty():return
 var start:=rng.randi_range(0,race.horses.size()-1)
 for i in range(race.horses.size()):
  var speaker: DerbyHorse=race.horses[(start+i)%race.horses.size()]
  if speaker.id==race.player_id or speaker.finished:continue
  for partner: DerbyHorse in race.horses:
   if partner==speaker or partner.id==race.player_id or not race.combat.in_attack_range(race,speaker,partner,96.0):continue
   var phrases: Array=data.peer_lines[speaker.id][race.language]
   var line_text: String=phrases[rng.randi_range(0,phrases.size()-1)]
   var icon: int=int(data.reaction_replies[speaker.id].cheer.icon) if rng.randf()<.33 else -1
   push_entry(speaker.id,{"text":line_text,"emote":icon,"face":4,"peer":partner.id,"direct":true},1)
   peer_after=race.elapsed+11.0
   return
 peer_after=race.elapsed+1.0

func prepare_peer_reply(speaker_id: int,partner_id: int,emote_id: int):
 if not reply.is_empty():return
 var reaction:=reply_entry(partner_id,emote_id,"" if emote_id!=-1 else "tease")
 reaction.direct=true
 reply={"id":partner_id,"entry":reaction,"peer":speaker_id,"at":race.elapsed+1.6,"until":race.elapsed+5.2}

func advance_reply(danger: bool):
 if reply.is_empty():return
 var can_answer: bool=near_player(reply.id)
 if reply.has("peer"):
  can_answer=race.combat.in_attack_range(race,race.horses[int(reply.peer)],race.horses[int(reply.id)],115.0)
 elif reply.entry.get("direct",false):
  can_answer=true
 if race.elapsed>float(reply.until) or not can_answer:
  reply.clear()
  return
 if danger or race.elapsed<float(reply.at) or not active.is_empty() or not queue.is_empty():return
 push_entry(reply.id,reply.entry,2 if reply.entry.get("direct",false) and not reply.has("peer") else 1)
 reply.clear()

