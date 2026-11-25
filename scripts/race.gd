extends Node2D
var champion_time: float=0.0
@export var race_distance: float = DerbyConfig.DISTANCE
@export var race_seed: int = 2026
var coins
var dialogue
var chat
var art_frames: Array = []
var counter_frames: Array=[]
var battle_vfx: DerbyBattleVFX
var collision_sound_clock: float=0
var backdrop = preload("res://assets/backgrounds/stadium-plate.png")
var practice_snapshot: Dictionary={}
var practice_mode:=false
var overview_mode := false
const MINI_ORIGIN=Vector2(531,42)
const MINI_SCALE=Vector2(.15,.18)
const MINI_VIEW=Rect2(534,56,95,43)
var map_dragging:=false
var map_focus:=Vector2.ZERO
var map_previous_overview:=false
var pre_race_deal:=false
var victory_overview:=false
var camera_center:=Vector2(212,102)
const CAMERA_STRETCH := Vector2(1.0,1.81)
const CAMERA_ANCHOR := Vector2(320,207)
var camera_zoom:=2.7
var zoom_bias: float=1.0
var view_zoom:=1.0
var view_offset:=0.0
var view_offset_y:=0.0
var player_id:=0
var betting:=DerbyBetting.new()
var combat:=DerbyCombat.new()
var autopilot:=DerbyAuto.new()
var event_text:=""
var event_time:=0.0
var counter_late:=0.0
var mode := "menu"
var menu_layer: CanvasLayer
var menu_box: VBoxContainer
var horses: Array = []
var order: Array = []
var overdrive:=DerbyOverdrive.new()
var shift_charges: int=DerbyConfig.PLAYER_SHIFT_LIMIT
var countdown: float = 3
var elapsed: float = 0
var camera_x: float = 0
var paused := false
var pinned_target_id: int=-1
var last_hover_id: int=0
var hovered: DerbyHorse
var pointer_position:=Vector2.INF
var selected: DerbyHorse
var front := false
var colors := [Color("ae6943"),Color("664938"),Color("373941"),Color("afb5b5"),Color("d9bf80"),Color("874537")]
var sound: DerbyAudio
var hoof_clock := 0.0
var shake: float = 0
var font = preload("res://assets/fonts/NotoSansSC-BoldSubset.ttf")
var language := "en"
var settings_return := "menu"
var help_return := "menu"
var help_page: int=0
var restart_return := "menu"
var fullscreen_enabled:=false
var settings := ConfigFile.new()
var last_lap_announced := false
func _ready():
 Engine.max_fps = 30
 scale = Vector2(2,2)
 font.oversampling=2.0
 if settings.load("user://settings.cfg")==OK: language = settings.get_value("preferences","language","en")
 texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
 art_frames.append(load("res://assets/horses/chestnut/chestnut.tres"))
 for i in range(1,6): art_frames.append(load("res://assets/horses/horse%d/horse.tres" % (i+1)))
 for h in range(6):
  var frames: Array=[]
  for f in range(6):frames.append(load("res://assets/horses/counter_max/horse%d_%d.png" % [h+1,f]))
  counter_frames.append(frames)
 battle_vfx=DerbyBattleVFX.new()
 add_child(battle_vfx)
 coins=preload("res://scripts/coin_feedback.gd").new()
 coins.race=self
 add_child(coins)
 sound = DerbyAudio.new()
 add_child(sound)
 sound.muted = settings.get_value("preferences","muted",false)
 sound.master_volume=float(settings.get_value("preferences","master_volume",.65))
 sound.hoof_volume=float(settings.get_value("preferences","hoof_volume",.45))
 fullscreen_enabled=bool(settings.get_value("preferences","fullscreen",false))
 if fullscreen_enabled and DisplayServer.get_name()!="headless":DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
 dialogue=preload("res://scripts/rider_dialogue.gd").new()
 dialogue.race=self
 add_child(dialogue)
 chat=preload("res://scripts/rider_chat.gd").new()
 chat.race=self
 dialogue.add_child(chat)
 chat.hide()
 dialogue.restore_campaign(settings.get_value("campaign","rider25",{}))
 betting.prepare(race_seed)
 if settings.has_section_key("campaign","state"):
  betting.restore_state(settings.get_value("campaign","state",{}))
 elif not settings.has_section_key("legacy","funds_before_challenge"):
  settings.set_value("legacy","funds_before_challenge",settings.get_value("bankroll","funds",1000))
 reset()
 if betting.active and not betting.settled:
  var checkpoint: Dictionary=settings.get_value("campaign","checkpoint",{})
  if checkpoint.has("horses") and checkpoint.horses.size()==6:
   restore_checkpoint(checkpoint)
   if overview_mode:toggle_view()
  else:
   betting.refund_abandoned()
   betting.round_number=maxi(0,betting.round_number-1)
 show_menu("menu")
 if "--verify-assets" in OS.get_cmdline_user_args():DerbyReleaseCheck.run.call_deferred(self)
func reset():
 pre_race_deal=false
 if is_instance_valid(dialogue):dialogue.reset_race()
 if is_instance_valid(chat):
  chat.close()
 victory_overview=false
 if is_instance_valid(battle_vfx):battle_vfx.reset()
 race_distance=DerbyDifficulty.distance(betting.round_number)
 $Stadium/ClosedTrack.queue_redraw()
 collision_sound_clock=0
 champion_time=0
 if has_node("Stadium/Presentation"):$Stadium/Presentation.reset()
 seed(race_seed)
 race_seed += 1
 horses.clear()
 order.clear()
 for i in range(6):
  var horse:=DerbyHorse.new(i)
  horses.append(horse)
 overdrive.reset()
 shift_charges=DerbyConfig.shift_limit(betting.round_number)
 countdown = 3
 elapsed = 0
 camera_x = 0
 paused = false
 shake = 0
 selected = null
 hovered=null
 pinned_target_id=-1
 last_hover_id=player_id
 last_lap_announced = false
 event_time=0
 counter_late=0
 autopilot.reset()
 combat.reset()
 combat.configure(betting.round_number,race_distance)
 camera_center=DerbyTrack.map_position(0,2.5)
 camera_zoom=2.7
 update_camera(0,true)
func _input(event):
 if event is InputEventMouse:
  pointer_position=get_global_transform_with_canvas().affine_inverse()*event.position
 if event is InputEventKey and (event.keycode==KEY_SHIFT or event.physical_keycode==KEY_SHIFT):
  if overdrive.shift_input(self,event):
   get_viewport().set_input_as_handled()
  return
 if mode=="race" and not paused:
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
   var point: Vector2=get_global_transform_with_canvas().affine_inverse()*event.position
   if event.pressed and MINI_VIEW.has_point(point):
    map_dragging=true
    map_previous_overview=overview_mode
    overview_mode=false
    drag_map(point)
    get_viewport().set_input_as_handled()
    return
   if not event.pressed and map_dragging:
    end_map_drag()
    get_viewport().set_input_as_handled()
    return
  if event is InputEventMouseMotion and map_dragging:
   drag_map(get_global_transform_with_canvas().affine_inverse()*event.position)
   get_viewport().set_input_as_handled()
   return
 if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and mode=="race":
  if overview_mode:overview_mode=false
  zoom_bias=clampf(zoom_bias*(1.12 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/1.12),.35,1.8)
  update_camera(0,true)
  get_viewport().set_input_as_handled()
  return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_TAB and mode=="race":
  toggle_view()
  get_viewport().set_input_as_handled()
func _unhandled_key_input(event):
 if is_instance_valid(chat) and chat.typing():
  if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:chat.close()
  return
 if not event is InputEventKey or not event.pressed or event.echo: return
 if mode=="champion":
  if event.keycode==KEY_M:
   sound.muted=not sound.muted
   save_settings()
  elif event.keycode==KEY_ESCAPE:finish_champion_presentation()
  return
 if event.keycode == KEY_M:
  sound.muted = not sound.muted
  if not sound.muted:sound.sync_output_device(true)
  announce("SOUND: OFF" if sound.muted else "SOUND: ON",1.0)
  save_settings()
 if event.keycode == KEY_L: toggle_language()
 if event.keycode == KEY_R: request_restart()
 if event.keycode == KEY_ESCAPE:
  if mode in ["post_bet","rider_offer","bribe_select","bribe_confirm","bribe_result"]:
   if mode=="post_bet":launch_confirmed_race()
   else:show_menu("bribe_select" if mode=="bribe_confirm" else "post_bet")
   return
  if mode=="rider_scene":show_menu("story_topics" if dialogue.story_from_picker and dialogue.story_remaining()>0 else "betting")
  elif mode=="story_topics":show_menu("story_select")
  elif mode=="story_select":show_menu("betting")
  elif mode=="rider_wrap":show_menu("wrap_topics")
  elif mode=="wrap_topics":show_menu("wrap_select")
  elif mode=="wrap_select":show_menu("results")
  elif mode=="leaderboard":show_menu("results")
  elif mode == "race": show_menu("pause")
  elif mode == "pause": resume_race()
  elif mode == "settings":show_menu(settings_return)
  elif mode == "help":show_menu(help_return)
  elif mode in ["bet_confirm","no_bet_confirm"]:show_menu("betting")
  elif mode=="restart_confirm":show_menu(restart_return)
func _process(dt):
 dt=minf(dt,.05)
 if has_node("Stadium/Presentation"):$Stadium/Presentation.advance(dt)
 if not DisplayServer.window_is_focused() and mode != "race": return
 refresh_hovered_horse()
 if mode == "race" and not paused and order.size()<6:
  shake = maxf(0,shake-dt)
  if overdrive.hit_pause>0:
   overdrive.hit_pause=maxf(0,overdrive.hit_pause-dt)
  elif countdown > 0:
   var previous := ceili(countdown)
   countdown -= dt
   if ceili(countdown) != previous: sound.cue("go" if countdown<=0 else "count")
  else:
   elapsed += dt
   event_time=maxf(0,event_time-dt)
   counter_late=maxf(0,counter_late-dt)
   overdrive.update(self,dt)
   combat.tick(self,dt)
   if horses[player_id].x>race_distance*.85 and not last_lap_announced:
    last_lap_announced = true
    sound.cue("final")
   for h in horses:
    DerbyRider.update(self,h,dt)
    if h.finished: continue
    var is_ally: bool=h.id!=player_id and dialogue.is_bribed_ally(h.id)
    var escort: DerbyHorse=horses[player_id] if (h.id!=player_id and dialogue.is_bribed_ally(h.id,true) and not horses[player_id].finished) else null
    if h.id==player_id:
     autopilot.tick(self,dt)
     DerbyAI.tick(h,horses,dt,false)
    else:DerbyAI.tick(h,horses,dt,true,betting.round_number>=2,combat.cooperation_leader,betting.round_number,race_distance,player_id if is_ally else -1,escort)
    var was_down: bool=h.knockdown>0
    var was_recovering: bool=h.recovery>0
    var pace: float=autopilot.pace if h.id==player_id else DerbyAI.safe_pace(h,horses,betting.round_number,escort,race_distance)
    h.tick(dt,pace,race_distance)
    if was_down and h.knockdown<=0:
     announce("GET UP!",.8)

    elif was_recovering and h.recovery<=0:announce("RECOVERED!",.8)
   var before_stuns := 0
   for h in horses:
    if h.stun>0: before_stuns += 1
   var down_before: Array=horses.map(func(h):return h.knockdown>0)
   var impacts: Array=DerbyCollision.tick(horses,elapsed,player_id,dialogue.bribed_ally_ids())
   for impact in impacts:
    if impact.has("rammer"):overdrive.impact(self,int(impact.rammer),int(impact.victim),bool(impact.heavy))
    else:
     for id in impact.horses:dialogue.event(int(id),"collision")
   collision_sound_clock=maxf(0,collision_sound_clock-dt)
   var standard_impacts: Array=impacts.filter(func(e):return int(e.get("rammer",-1))!=player_id)
   if not standard_impacts.is_empty() and collision_sound_clock<=0:
    sound.cue("heavy_hit" if standard_impacts.any(func(e):return e.heavy) else "hit")
    if standard_impacts.any(func(e):return e.heavy):sound.cue("crowd_gasp")
    for h in horses:
     if h.knockdown>0 and not down_before[h.id] and standard_impacts.any(func(e):return h.id in e.horses):sound.cue("fall")
    collision_sound_clock=.14
   var after_stuns := 0
   for h in horses:
    if h.stun>0: after_stuns += 1
   if after_stuns>before_stuns:
    announce("HEAVY HIT!" if horses.any(func(h):return h.knockdown>0) else "COLLISION!",.8)
    shake = 0.16
   var sorted := horses.duplicate()
   sorted.sort_custom(func(a,b): return a.x>b.x)
   for h in sorted:
    if h.x >= race_distance and not h.finished:
     h.finished = true
     h.overdrive_active=false
     if h.id==player_id:sound.stop_ram_cues()
     if not (h.id in order):order.append(h.id)
     if order.size()==1:
      champion_time=elapsed
      $Stadium/Presentation.champion(h.id)
      dialogue.finish_quote(h.id)
      if h.id==player_id and not overview_mode:
       victory_overview=true
       toggle_view()
      sound.cue("cannon")
      sound.cue("neigh")
      if h.id==player_id:sound.cue("firework")
      sound.cue("crowd_win" if h.id==player_id else "crowd_cheer")
     sound.cue("win" if h.id==player_id and order[0]==player_id else "finish")
     if order.size()==1 and h.id!=player_id: sound.cue("lose")
 sound.set_racing(mode=="race" and not paused and countdown<=0 and order.size()<6,clampf(horses[player_id].speed/70,.8,1.35))
 if victory_overview and $Stadium/Presentation.age>=2.5:
  victory_overview=false
  overview_mode=false
  update_camera(0,true)
 if is_instance_valid(battle_vfx):battle_vfx.advance(self,dt)
 update_camera(dt)
 overdrive.sync_auras(self)
 if order.size()<6 and horses.size()==6 and horses.all(func(h):return h.finished):
  for h in horses:
   if not (h.id in order):order.append(h.id)
 if not order.is_empty() and mode=="race" and not paused and has_node("Stadium/Presentation") and not $Stadium/Presentation.celebrating:
  $Stadium/Presentation.champion(int(order[0]))
 if order.size()==6 and mode == "race" and $Stadium/Presentation.age>=3.5:
  if practice_mode:
   leave_practice()
   return
  var balance_before: int=betting.funds
  var fresh: bool=betting.active and not betting.settled
  betting.settle(order[0],order)
  if fresh:dialogue.pay_offer(order[0])
  save_settings()
  show_menu("leaderboard" if betting.rider_results.has(betting.round_number) else "results")
  if fresh and betting.funds>balance_before:coins.change(balance_before,betting.funds,true)
  elif fresh and betting.amount>0:coins.cue(coins.LOSS)
 dialogue.advance(dt)
 chat.update_visibility()
 queue_redraw()
func refresh_hovered_horse():
 hovered=null
 selected=horses[button_target_id()] if not horses.is_empty() else null
 var mouse:=pointer_position if pointer_position.is_finite() else get_local_mouse_position()
 var closest:=INF
 for h: DerbyHorse in horses:
  if h.finished:continue
  var horse_mouse:= (mouse-horse_screen(h))/horse_draw_scale()
  if cos(horse_angle(h))<0:horse_mouse.x=-horse_mouse.x
  var distance: float=horse_mouse.distance_to(Vector2(0,-20))
  if Rect2(Vector2(-50,-58),Vector2(98,62)).has_point(horse_mouse) and distance<closest:
   closest=distance
   selected=h
   hovered=h
   last_hover_id=h.id
   front=horse_mouse.x>=0
func label(pos: Vector2, value: String, color: Color = Color.WHITE, size: int = 14):
 draw_string(font,pos,l(value),HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func _draw():
 pass

func track_wave(_distance: float) -> float:
 return 0
func horse_screen(h: DerbyHorse) -> Vector2:
 return course_screen(h.progress,(h.y-140.0)/27.0)+Vector2(sin(elapsed*90)*shake*6,0)
func horse_draw_scale() -> float:
 return .23 if overview_mode else .27*camera_zoom
func course_screen(progress: float, lane_position: float) -> Vector2:
 return world_to_screen(DerbyTrack.map_position(progress,lane_position))
func horse_angle(h: DerbyHorse) -> float:
 return (course_screen(h.x+1,(h.y-140.0)/27.0)-course_screen(h.x,(h.y-140.0)/27.0)).angle()
func draw_ellipse_shadow(p: Vector2):
 draw_rect(Rect2(p+Vector2(-20,8),Vector2(40,3)),Color(0,0,0,0.25))

func start_race():
 practice_mode=false
 if not betting.active or betting.settled:
  if betting.campaign_outcome()!="ongoing":
   show_menu("campaign_end")
   return
  betting.prepare(race_seed)
  if not betting.confirm():return
 player_id=betting.selected
 overview_mode=false
 reset()
 shuffle_starting_lanes()
 mode = "race"
 if is_instance_valid(menu_layer): menu_layer.queue_free()
func resume_race():
 paused = false
 mode = "race"
 if is_instance_valid(menu_layer): menu_layer.queue_free()
func show_menu(page: String):
 overdrive.clear_input(self)
 sound.stop_ram_cues()
 if is_instance_valid(chat):
  chat.close()
  chat.hide()
 if map_dragging:end_map_drag()
 if is_instance_valid(dialogue):dialogue.clear_ui()
 if is_instance_valid(coins):coins.clear()
 mode = page
 paused = true
 sound.set_racing(false)
 if is_instance_valid(menu_layer): menu_layer.queue_free()
 menu_layer = CanvasLayer.new()
 menu_layer.transform = Transform2D(0,Vector2(2,2),0,Vector2.ZERO)
 add_child(menu_layer)
 DerbyMenus.build(self,page)
 if not practice_mode:save_settings()
 queue_redraw()
func _notification(what):
 if not is_node_ready(): return
 if what == NOTIFICATION_APPLICATION_FOCUS_IN and is_instance_valid(sound): sound.sync_output_device(true)
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "race": show_menu.call_deferred("pause")
 if what==NOTIFICATION_WM_CLOSE_REQUEST:save_settings()

func player_rank() -> int:
 if horses.is_empty(): return 1
 if player_id in order: return order.find(player_id)+1
 var rank := order.size()+1
 for h in horses:
  if not h.finished and h.id!=player_id and h.x>horses[player_id].x: rank += 1
 return rank
func target_risky(h: DerbyHorse) -> bool:
 for other in horses:
  if other!=h and absf(other.x-h.x)<75 and absf(other.y-h.y)<40: return true
 return false
func boost_with_shift(target_id: int=-1,brake: bool=false):
 if practice_mode:return
 var own: DerbyHorse=horses[player_id]
 if own.knockdown>0 or own.stun>0 or own.finished:return
 if target_id>=0:
  apply_shift(horses[target_id],brake)
  return
 if own.effect>0 and own.multiplier>1:return
 apply_shift(own,false)

func apply_shift(h: DerbyHorse, brake: bool) -> bool:
 if h==null or h.finished or countdown>0 or paused or mode!="race" or not order.is_empty():return false
 if shift_charges<=0:
  announce("干涉次数已用完" if language=="zh" else "NO SHIFT CHARGES LEFT",.7)
  return false
 if brake and h.attack_guarded():
  announce("护盾阻挡" if language=="zh" else "SHIELD BLOCKED",.7)
  return false
 sound.cue("brake" if brake else "boost")
 if not (brake and h.id!=player_id and combat.try_ai_counter(self,h)):
  h.hit(brake)
  if not brake:dialogue.note_player_boost(h.id)
  if brake:dialogue.event(h.id,"brake")
 shift_charges-=1
 return true

func save_settings():
 settings.set_value("preferences","language",language)
 settings.set_value("preferences","muted",sound.muted)
 settings.set_value("preferences","master_volume",sound.master_volume)
 settings.set_value("preferences","hoof_volume",sound.hoof_volume)
 settings.set_value("preferences","fullscreen",fullscreen_enabled)
 if not practice_mode:
  if order.size()==6 and betting.active and not betting.settled:
   betting.settle(order[0],order)
   dialogue.pay_offer(order[0])
  settings.set_value("campaign","state",betting.save_state())
  settings.set_value("campaign","rider25",dialogue.campaign_state())
  settings.set_value("campaign","checkpoint",save_checkpoint() if betting.active and not betting.settled else {})
 settings.save("user://settings.cfg")

func toggle_language():
 language = "en" if language=="zh" else "zh"
 save_settings()
 if mode!="race": show_menu(mode)
 queue_redraw()
func l(value: String) -> String:
 if language!="zh": return value
 var words := {
  "INCOMING ATTACK!":"敌方攻击预警！", "PERFECT COUNTER!":"完美反击！", "TOO EARLY!":"太早了！", "TOO LATE! BRAKE!":"太迟了！减速！", "TOO LATE!":"太迟了！", "COLLISION!":"碰撞！", "KNOCKDOWN!":"倒地！", "GET UP!":"起身！",
  "MAIN MENU":"返回主菜单", "HOW TO PLAY":"操作说明", "REMATCH":"再赛一场", "RESUME":"继续比赛", "PLAY":"开始比赛", "QUIT":"退出游戏",
  "SOUND: OFF":"音效：关", "SOUND: ON":"音效：开", "YOU WIN!":"你赢了！", "YOU LOSE":"再接再厉", "Horse #":"赛马 #", "YOU":"支持",
  "Support #1. Only THREE interventions!":"支持 1 号赤栗，每局只有三次干涉！", "Hover HEAD + Shift: BRAKE / cancel lane":"指向马头按 Shift：减速并打断变道", "Hover TAIL + Shift: BOOST / two lane tries":"指向马尾按 Shift：加速并尝试两次变道", "You can target any horse, including yours.":"可以干涉任意马匹，包括自己的马。", "R: rematch   Esc: pause   M: sound":"R 重开 · Esc 暂停 · M 音效 · L 中英文",
  "HOVER A HORSE + SHIFT  |  ESC PAUSE":"鼠标指向马头或马尾 + SHIFT · ESC 暂停", "0 SHIFTS - COUNTER STILL AVAILABLE":"主动次数已用完，仍可完美反击！", "BRAKE / CANCEL LANE":"减速 / 打断变道", "BOOST / 2 LANE TRIES":"加速 / 两次变道尝试", "BEND  >>  SPEED +18%":"弯道 +18% · 内道更短", "! TRAFFIC":"！附近拥挤", "OTHERS FINISHING":"其他马匹正在冲线", "WINNER #":"冠军 #", "BOOST":"加速", "BRAKE":"减速", "START":"起点", "GO!":"冲！", "FIN":"终", "ISH":"点"
 }
 if words.has(value): return words[value]
 for key in words:
  if key in ["FIN","ISH"]:continue
  value = value.replace(key,words[key])
 return value

func open_settings(from_page: String):
 settings_return=from_page
 show_menu("settings")
func set_language(code: String):
 if code not in ["zh","en"]:return
 language=code
 save_settings()
 show_menu("settings")

func _unhandled_input(event):
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and mode=="race" and not paused:
  var point: Vector2=get_global_transform_with_canvas().affine_inverse()*event.position
  if Rect2(522,42,112,72).has_point(point):return
  elif not select_target_at(point) and countdown<=0 and not combat.sample_counter(player_id).is_empty():combat.counter_press(self)
func select_target_at(point: Vector2) -> bool:
 var best: DerbyHorse=null
 var attack: DerbyHorse=null
 var distance:=INF
 var attack_distance:=INF
 var own: DerbyHorse=horses[player_id]
 for h in horses:
  if h.finished:continue
  var center:=horse_screen(h)-Vector2(0,20)*horse_draw_scale()
  var gap:=point.distance_to(center)
  if own.overdrive_active and gap<attack_distance and overdrive.valid_ram_target(self,own,h):
   var attack_rect:=Rect2(center-Vector2(49,36)*horse_draw_scale(),Vector2(98,59)*horse_draw_scale())
   if attack_rect.has_point(point):
    attack=h
    attack_distance=gap
  if gap<distance and Rect2(center-Vector2(21,15)*camera_click_scale(),Vector2(42,30)*camera_click_scale()).has_point(point):
   best=h
   distance=gap
 if attack!=null and overdrive.request_ram(self,attack.id):return true
 if best==null:return false
 pinned_target_id=best.id
 last_hover_id=best.id
 selected=best
 announce(("目标 #%d" if language=="zh" else "TARGET #%d") % (best.id+1),.65)
 return true
func button_target_id() -> int:
 return pinned_target_id if pinned_target_id>=0 and pinned_target_id<horses.size() else clampi(last_hover_id,0,maxi(0,horses.size()-1))
func trigger_hud_action(brake: bool) -> bool:
 if mode!="race" or paused or map_dragging or countdown>0:return false
 if combat.counter_press(self):return true
 var target: DerbyHorse=horses[button_target_id()]
 return apply_shift(target,brake)
func request_pause():
 if mode=="race":show_menu("pause")
func request_counter():
 if mode=="race" and not paused and countdown<=0:combat.counter_press(self)

func announce(text: String,seconds: float=1.0):
 event_text=text
 event_time=seconds
func show_leaderboard():
 var current: Dictionary=betting.rider_results.get(betting.round_number,{})
 if current.is_empty():return
 if order.size()!=6 or order!=current.order:
  order=current.order.duplicate()
  player_id=betting.selected
 show_menu("leaderboard")
func show_champion_presentation():
 if not betting.champion_presentation_available():
  begin_round()
  return
 for player: AudioStreamPlayer in sound.pool:player.stop()
 show_menu("champion")
func finish_champion_presentation():
 betting.champion_seen=true
 show_menu("campaign_end")
func begin_round():
 if practice_mode:
  leave_practice()
  return
 if betting.active and not betting.settled and not practice_mode:
  if pre_race_deal:show_menu("post_bet")
  else:resume_race()
  return
 if betting.campaign_outcome()!="ongoing":
  show_menu("campaign_end")
  return
 practice_mode=false
 combat.reset()
 event_time=0
 betting.prepare(race_seed)
 dialogue.prepare_story()
 show_menu("betting")
func request_bet_confirmation():
 if betting.campaign_outcome()!="ongoing":show_menu("campaign_end")
 else:show_menu("no_bet_confirm" if betting.amount==0 else "bet_confirm")
func place_bet():
 var before: int=betting.funds
 if not betting.confirm():return
 start_race()
 if dialogue.deals_unlocked():
  pre_race_deal=true
  dialogue.prepare_offer()
  show_menu("post_bet")
 elif betting.amount>0:announce("BET PLACED!",1.5)
 coins.change(before,betting.funds)
 save_settings()

func launch_confirmed_race():
 if not pre_race_deal or not betting.active or betting.settled:return
 pre_race_deal=false
 coins.clear()
 resume_race()
 if betting.amount>0:announce("BET PLACED!",1.5)
 save_settings()
func request_restart():
 if mode=="restart_confirm":return
 restart_return=mode
 show_menu("restart_confirm")
func can_retry_round() -> bool:
 if practice_mode or restart_return in ["menu","betting","bet_confirm","no_bet_confirm"]:return false
 if betting.settled and betting.campaign_outcome()=="victory":return false
 return betting.retry_round_available(int(dialogue.offer.get("paid",0)))
func retry_round():
 if not can_retry_round():return
 var offer_paid: int=int(dialogue.offer.get("paid",0))
 if not betting.retry_current_round(offer_paid):return
 if not dialogue.offer.is_empty():
  dialogue.offer.boosted=false
  dialogue.offer.paid=0
 for deal: Dictionary in dialogue.bribe_deals:
  if int(deal.get("round",0))==betting.round_number:deal.used=false
 if not dialogue.bribe.is_empty() and int(dialogue.bribe.get("round",0))==betting.round_number:
  dialogue.bribe.used=false
 pre_race_deal=false
 coins.clear()
 race_seed+=1
 player_id=betting.selected
 reset()
 shuffle_starting_lanes()
 resume_race()
 save_settings()
func shuffle_starting_lanes():
 if horses.size()!=6:return
 var gates: Array[int]=[0,1,2,3,4,5]
 var gate_rng:=RandomNumberGenerator.new()
 gate_rng.seed=race_seed+77
 for k in range(5,0,-1):
  var swap: int=gate_rng.randi_range(0,k)
  var tmp: int=gates[k]
  gates[k]=gates[swap]
  gates[swap]=tmp
 for i in range(6):
  var horse: DerbyHorse=horses[i]
  horse.lane=gates[i]
  horse.origin=gates[i]
  horse.target=gates[i]
  horse.y=140+gates[i]*27
func request_new_game():
 if (betting.round_number>0 or betting.rescue_used) and (betting.campaign_outcome()=="ongoing" or betting.can_rescue()):request_restart()
 else:new_game()
func use_rescue():
 if mode=="campaign_end" and betting.rescue():
  dialogue.bribe.clear()
  dialogue.bribe_deals.clear()
  begin_round()
func new_game():
 practice_snapshot.clear()
 practice_mode=false
 betting.new_game()
 dialogue.restore_campaign({})
 reset()
 save_settings()
 begin_round()
func show_help(from_page: String,page_index: int=0):
 help_return=from_page
 help_page=clampi(page_index,0,DerbyMenuPages.GUIDE_PAGES-1)
 settings.set_value("preferences","guide_seen",true)
 show_menu("help")
func change_help_page(offset: int=1):
 var page:=clampi(help_page+offset,0,DerbyMenuPages.GUIDE_PAGES-1)
 if page==help_page:return
 help_page=page
 show_menu("help")
func toggle_fullscreen():
 fullscreen_enabled=not fullscreen_enabled
 if DisplayServer.get_name()!="headless":
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED)
 save_settings()
 show_menu("settings")
func save_checkpoint() -> Dictionary:
 return {"race_distance":race_distance,"champion_time":champion_time,"horses":horses.map(func(h):return h.save_state()),"player_id":player_id,"elapsed":elapsed,"shift_charges":shift_charges,"countdown":countdown,"order":order.duplicate(),"race_seed":race_seed,"combat":combat.save_state(),"dialogue_once":dialogue.once.duplicate(),"pre_race_deal":pre_race_deal,"overview_mode":overview_mode}
func restore_checkpoint(state: Dictionary):
 race_distance=state.get("race_distance",DerbyDifficulty.distance(betting.round_number))
 $Stadium/ClosedTrack.queue_redraw()
 player_id=clampi(int(state.get("player_id",0)),0,5)
 for i in range(6):horses[i].restore_state(state.horses[i])
 elapsed=state.get("elapsed",0)
 var charge_limit:=DerbyConfig.shift_limit(betting.round_number)
 shift_charges=clampi(int(state.get("shift_charges",charge_limit)),0,charge_limit)
 champion_time=state.get("champion_time",0)
 countdown=state.get("countdown",3)
 overdrive.reset()
 order=state.get("order",[]).duplicate()
 if not order.is_empty() and has_node("Stadium/Presentation"):
  $Stadium/Presentation.champion(int(order[0]))
  if order.size()==6:$Stadium/Presentation.age=3.5
 race_seed=state.get("race_seed",2026)
 overview_mode=state.get("overview_mode",false)
 pre_race_deal=state.get("pre_race_deal",false)
 combat.restore_state(state.get("combat",{}))
 dialogue.once=state.get("dialogue_once",{}).duplicate()
 update_camera(0,true)

func start_counter_practice():
 if not practice_mode:practice_snapshot={"betting":betting.save_state(),"race":save_checkpoint(),"return":help_return}
 player_id=betting.selected
 practice_mode=true
 reset()
 horses[player_id].energy=0
 countdown=0
 mode="race"
 paused=false
 if is_instance_valid(menu_layer):menu_layer.queue_free()
 announce("COUNTER PRACTICE",2)

func camera_click_scale() -> float:
 return horse_draw_scale()
func world_to_screen(point: Vector2) -> Vector2:
 if overview_mode:return point
 return (point-view_center())*CAMERA_STRETCH*camera_zoom+CAMERA_ANCHOR
func screen_to_world(point: Vector2) -> Vector2:
 if overview_mode:return point
 return (point-CAMERA_ANCHOR)/camera_zoom/CAMERA_STRETCH+view_center()
func update_camera(dt: float,immediate: bool=false):
 if horses.is_empty():return
 var own: DerbyHorse=horses[player_id]
 var own_position:=DerbyTrack.map_position(own.progress,(own.y-140)/27)
 var bounds:=Rect2(own_position,Vector2.ZERO)
 for h in horses:
  if absf(h.progress-own.progress)<=420:
   bounds=bounds.expand(DerbyTrack.map_position(h.progress,(h.y-140)/27))
 var focus: Vector2=own_position.lerp(bounds.get_center(),.5)
 var zoom:=zoom_bias*1.43*clampf(minf(510/(bounds.size.x+50),245/(bounds.size.y*2.6+45)),2.2,3.2)
 var own_screen: Vector2=(own_position-focus)*CAMERA_STRETCH*zoom+CAMERA_ANCHOR
 var safe_screen:=own_screen.clamp(Vector2(110,135),Vector2(530,285))
 focus+=(own_screen-safe_screen)/(CAMERA_STRETCH*zoom)
 var weight: float=1.0 if immediate else minf(1,dt*3)
 camera_center=camera_center.lerp(focus,weight)
 camera_zoom=lerpf(camera_zoom,zoom,weight)
 var stadium=get_node_or_null("Stadium")
 if stadium!=null:
  stadium.scale=Vector2.ONE if overview_mode else CAMERA_STRETCH*camera_zoom
  stadium.position=Vector2.ZERO if overview_mode else CAMERA_ANCHOR-view_center()*CAMERA_STRETCH*camera_zoom
func view_center() -> Vector2:
 return map_focus if map_dragging else camera_center

func combat_screen(h: DerbyHorse) -> Vector2:
 var point:=DerbyTrack.map_position(h.progress,(h.y-140)/27)
 if (map_previous_overview if map_dragging else overview_mode):return point
 return (point-camera_center)*CAMERA_STRETCH*camera_zoom+CAMERA_ANCHOR

func drag_map(point: Vector2):
 var pos:=point.clamp(MINI_VIEW.position,MINI_VIEW.end)
 map_focus=(pos-MINI_ORIGIN)/MINI_SCALE
 update_camera(0)

func end_map_drag():
 map_dragging=false
 overview_mode=map_previous_overview
 update_camera(0)

func minimap_view_rect() -> Rect2:
 if overview_mode:return MINI_VIEW
 var a: Vector2=MINI_ORIGIN+screen_to_world(Vector2(0,34))*MINI_SCALE
 var b: Vector2=MINI_ORIGIN+screen_to_world(Vector2(640,329))*MINI_SCALE
 return Rect2(a,b-a).intersection(MINI_VIEW)

func toggle_view():
 if map_dragging:end_map_drag()
 overview_mode=not overview_mode
 update_camera(0,true)
 for layer in $Stadium.get_children():layer.queue_redraw()
 queue_redraw()

func leave_practice():
 practice_mode=false
 if not practice_snapshot.is_empty():
  betting.restore_state(practice_snapshot.betting)
  restore_checkpoint(practice_snapshot.race)
  var destination: String=practice_snapshot.get("return","menu")
  practice_snapshot.clear()
  show_menu(destination)
 else:show_menu("menu")

var exit_return: String="pause"
func request_main_menu():
 if practice_mode:
  leave_practice()
  return
 if betting.settled and betting.round_number>=DerbyBetting.ROUND_LIMIT and not betting.can_rescue():
  show_menu("menu")
  return
 exit_return=mode
 show_menu("exit_choice")
func abandon_to_menu():
 practice_snapshot.clear()
 practice_mode=false
 betting.new_game()
 dialogue.restore_campaign({})
 reset()
 save_settings()
 show_menu("menu")

func cancel_exit():
 if exit_return=="pause" or exit_return=="race":resume_race()
 else:show_menu(exit_return)

