class_name DerbyBattleVFX
extends Node
var clock: float=0
var last_elapsed: float=-1
var tracks: Dictionary={}
var removed: Array=[]
var previous: Dictionary={}
var textures: Dictionary={}
var sprites: Dictionary={}
var assist_notice: Dictionary={}
var supplied_counter: SpriteFrames=preload("res://assets/vfx/counter_sheet_v3/counter.tres")
var legacy_frames: SpriteFrames=preload("res://assets/vfx/legacy_counter_dynamic/legacy_energy.tres")
const AURA_COLORS=[Color("ff9c20"),Color("24cfff"),Color("36e8d6"),Color("9b53ff"),Color("ffdb42"),Color("ff73bc")]
var base_frames: SpriteFrames=preload("res://assets/vfx/battle_animations.tres")
func texture(path: String) -> Texture2D:
 if not textures.has(path):textures[path]=load("res://assets/"+path+".png")
 return textures[path]
func reset():
 clock=0
 last_elapsed=-1
 tracks.clear()
 removed.clear()
 previous.clear()
 assist_notice.clear()
 for node in sprites.values():
  node.stop()
  node.visible=false
  node.set_meta("was_active",false)
func event_key(e) -> String:return str(e.attacker)+":"+str(e.target)
func advance(r,dt: float):
 if r.elapsed<last_elapsed:reset()
 last_elapsed=r.elapsed
 if r.paused or r.mode!="race" or r.countdown>0:return
 clock+=dt
 if not assist_notice.is_empty():
  assist_notice.time=float(assist_notice.time)-dt
  if float(assist_notice.time)<=0.0:assist_notice.clear()
 var live: Dictionary={}
 for e in r.combat.pending:
  if not r.horses[e.target].finished:live[event_key(e)]=e.duplicate()
 for key in previous:
  if not live.has(key) and previous[key].time>dt:
   removed.append({"target":previous[key].target,"age":0.0})
   var cancel:=sprite(r,previous[key].target,"cancel")
   cancel.visible=true
   cancel.play("cancel")
 previous=live
 for effect in removed:effect.age+=dt
 removed=removed.filter(func(e):return e.age<.36)
 for h in r.horses:
  if not tracks.has(h.id):tracks[h.id]={"age":0.0,"fade":0.0,"sample":0.0,"on":false,"shield":false,"impact":9.0,"ghosts":[],"facing":1.0}
  var t: Dictionary=tracks[h.id]
  var active: bool=not h.finished and (h.counter_time>0 or h.dash_time>0 or (h.effect>0 and h.multiplier>1))
  var facing: float=-1.0 if cos(r.horse_angle(h))<0 else 1.0
  if active and not t.on:t.age=0
  if facing!=t.facing:t.ghosts.clear()
  t.facing=facing
  if h.invincible>0 and not t.shield:t.impact=0
  t.shield=h.invincible>0
  t.impact+=dt
  t.on=active
  t["self_boost"]=h.dash_time>0 or (r.event_time>0 and r.event_text=="#%d BOOST!" % (h.id+1))
  t.age+=dt
  t.fade=move_toward(t.fade,1.0 if active else 0.0,dt*6)
  for ghost in t.ghosts:ghost.life-=dt
  t.ghosts=t.ghosts.filter(func(g):return g.life>0)
  t.sample-=dt
  if not h.finished and (active or h.overdrive_active) and t.sample<=0:
   t.sample=.09
   var anim:=DerbyRider.horse_animation(r,h)
   var counter_body: bool=h.invincible>0 and not h.overdrive_active
   var body: Texture2D=counter_texture(r,h) if counter_body else r.art_frames[h.id].get_frame_texture(anim,DerbyRider.frame(r,h,anim))
   var rider:=DerbyRider.pose(r,h)
   rider["gait_snapshot"]=DerbyRider.gait(r,h)
   t.ghosts.append({"life":.25,"map":DerbyTrack.map_position(h.progress,(h.y-140)/27),"body":body,"rect":Rect2(-94.4,-94.4,188.8,106.2) if counter_body else Rect2(-59,-75,118,83),"rider":rider})
   while t.ghosts.size()>3:t.ghosts.pop_front()
  sync(r,h,t)
 sync_warning(r)
func behind(r,h,canvas):
 if not tracks.has(h.id):return
 var t: Dictionary=tracks[h.id]
 var scale: float=r.horse_draw_scale()
 for g in t.ghosts:
  var delta: Vector2=(r.world_to_screen(g.map)-r.horse_screen(h))/scale
  delta.x*=t.facing
  var alpha: float=.16*g.life/.25
  canvas.draw_texture_rect(g.body,Rect2(g.rect.position+delta,g.rect.size),false,Color(1,1,1,alpha))
  var rider: Dictionary=g.rider.duplicate()
  rider.offset+=delta
  DerbyRider.draw_rig(r,h,canvas,rider,alpha)
func front(r,h,canvas):
 if tracks.has(h.id) and tracks[h.id].get("self_boost",false) and tracks[h.id].age<.7:
  canvas.draw_string(r.font,Vector2(-72,-78),"SELF BOOST",HORIZONTAL_ALIGNMENT_LEFT,-1,8,DerbyPainter.CLOTH[h.id])
func main_event(r) -> Dictionary:
 for e in r.combat.pending:
  if e.target==r.player_id and not r.horses[e.target].finished:return e
 return {}
func alert_rect(r) -> Rect2:
 var best:=Rect2(8,76,192,44)
 var score:=INF
 for origin in [Vector2(8,110),Vector2(440,118),Vector2(8,228)]:
  var box:=Rect2(origin,Vector2(192,44))
  var cost:=0.0
  for h in r.horses:
   if box.intersects(Rect2(r.horse_screen(h)+Vector2(-62,-92)*r.horse_draw_scale(),Vector2(124,100)*r.horse_draw_scale())):cost+=1
  if cost<score:
   score=cost
   best=box
 return best if score==0 else Rect2()
func trigger_assist(helper_id: int,target_id: int,kind: String="bribe"):
 assist_notice={"helper":helper_id,"target":target_id,"kind":kind,"time":3.2,"duration":3.2}
func draw_assist(r,canvas,alert_box: Rect2):
 if assist_notice.is_empty():return
 var remain: float=float(assist_notice.get("time",0.0))
 if remain<=0.0:return
 var total: float=maxf(.01,float(assist_notice.get("duration",3.2)))
 var alpha: float=clampf(remain/.35,0.0,1.0)*clampf((total-remain)/.16,0.0,1.0)
 var mod:=Color(1,1,1,alpha)
 var origin:=Vector2(20,112)
 if alert_box.size!=Vector2.ZERO and alert_box.position.x<220 and alert_box.position.y<175:
  origin=Vector2(20,160)
 var card:=Rect2(origin,Vector2(226,90))
 canvas.draw_texture_rect(texture("ui/cut/assist_card"),card,false,mod)
 var helper_id: int=clampi(int(assist_notice.get("helper",0)),0,5)
 var target_id: int=clampi(int(assist_notice.get("target",0)),0,5)
 var left_rect:=Rect2(card.position+Vector2(29,41),Vector2(24,24))
 var right_rect:=Rect2(card.position+Vector2(90,41),Vector2(24,24))
 canvas.draw_texture_rect(texture("ui/cut/assist_rider_%d" % helper_id),left_rect,false,mod)
 canvas.draw_texture_rect(texture("ui/cut/assist_rider_%d" % target_id),right_rect,false,mod)
 var zh: bool=r.language=="zh"
 var tag: String="获得加速!" if zh else "SPEED BOOST!"
 var badge_size: int=9 if zh else 7
 var tw: float=r.font.get_string_size(tag,HORIZONTAL_ALIGNMENT_LEFT,-1,badge_size).x
 var badge_cx: float=card.position.x+card.size.x*.808
 var badge_y: float=card.position.y+card.size.y*.620
 DerbyPainter.text(r,Vector2(roundf(badge_cx-tw*.5),roundf(badge_y)),tag,Color(1,.93,.64,alpha),badge_size,canvas)
 var bar_ratio: float=clampf(remain/total,0.0,1.0)
 var bar_x: float=card.position.x+card.size.x*.058
 var bar_y: float=card.position.y+card.size.y*.818
 var bar_w: float=card.size.x*.884*bar_ratio
 var bar_h: float=card.size.y*.056
 canvas.draw_rect(Rect2(bar_x,bar_y,bar_w,bar_h),Color(1,.82,.28,.88*alpha))
 var who: String="#%d %s > #%d %s" % [helper_id+1,r.dialogue.rider_name(helper_id),target_id+1,"支持" if zh and target_id==r.player_id else ("YOU" if target_id==r.player_id else r.dialogue.rider_name(target_id))]
 var ww: float=r.font.get_string_size(who,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
 var pill:=Rect2(card.position+Vector2(roundf((card.size.x-ww-14)*.5),card.size.y+1),Vector2(ww+14,13))
 canvas.draw_rect(pill,Color(.06,.11,.22,.86*alpha))
 canvas.draw_rect(pill,Color(.88,.70,.28,.85*alpha),false,1)
 DerbyPainter.text(r,Vector2(pill.position.x+7,pill.position.y+10),who,Color(1,.92,.65,alpha),8,canvas)
func draw_alert(r,canvas):
 var e:=main_event(r)
 var box:=Rect2()
 if not e.is_empty():
  box=alert_rect(r)
 if box.size!=Vector2.ZERO:
  canvas.draw_texture_rect(texture("ui/attack_alert/panel_blank"),box,false)
  for i in range(2):
   var id: int=e.attacker if i==0 else e.target
   canvas.draw_texture_rect(texture("ui/attack_alert/horse_"+str(id)),Rect2(box.position+Vector2(5+i*45,3),Vector2(27,27)),false)
  DerbyPainter.text(r,box.position+Vector2(34,20),">",DerbyPainter.GOLD,12,canvas)
  canvas.draw_texture_rect(texture("ui/attack_alert/header"),Rect2(box.position+Vector2(88,0),Vector2(99,17)),false)
  canvas.draw_texture_rect(texture("ui/attack_alert/boost" if e.get("boost_trap",false) else "ui/attack_alert/brake"),Rect2(box.position+Vector2(88,17),Vector2(57,16)),false)
  DerbyPainter.text(r,box.position+Vector2(153,29),"%.1fs" % maxf(0,e.time),Color.WHITE,9,canvas)
  var names: String="#%d %s > #%d %s" % [e.attacker+1,DerbyBetting.ZH[e.attacker] if r.language=="zh" else DerbyBetting.NAMES[e.attacker],e.target+1,"YOU" if e.target==r.player_id else DerbyBetting.ZH[e.target] if r.language=="zh" else DerbyBetting.NAMES[e.target]]
  DerbyPainter.text(r,box.position+Vector2(6,38),names,DerbyPainter.GOLD,8,canvas)
 draw_assist(r,canvas,box)

func _process(_dt):
 var r=get_parent()
 for node in sprites.values():node.speed_scale=0.0 if r.paused or r.mode!="race" or node.get_meta("manual",false) else 1.0
func sprite(r,id: int,kind: String) -> AnimatedSprite2D:
 var key:=str(id)+kind
 if sprites.has(key):return sprites[key]
 var node:=AnimatedSprite2D.new()
 node.name="Battle_"+key
 node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 node.sprite_frames=base_frames
 node.z_index=-1 if kind=="energy" else 1
 if kind=="energy":
  var frames:=SpriteFrames.new()
  for clip in ["start","loop","end"]:
   frames.add_animation(clip)
   frames.set_animation_speed(clip,14)
   frames.set_animation_loop(clip,clip=="loop")
   var source: String="horse_%d_%s" % [id,clip]
   for i in range(legacy_frames.get_frame_count(source)):
    frames.add_frame(clip,legacy_frames.get_frame_texture(source,i))
  node.sprite_frames=frames
 if kind=="counter_body":
  var frames:=SpriteFrames.new()
  for clip in ["start","loop","end"]:
   frames.add_animation(clip)
   frames.set_animation_speed(clip,14)
   frames.set_animation_loop(clip,clip=="loop")
   var clip_key: String="horse_%d_%s" % [id,clip]
   for i in range(supplied_counter.get_frame_count(clip_key)):frames.add_frame(clip,supplied_counter.get_frame_texture(clip_key,i))
  node.sprite_frames=frames
 if kind=="aura":
  node.sprite_frames=r.art_frames[id]
  node.set_meta("manual",true)
  node.z_index=-1
  var material:=ShaderMaterial.new()
  material.shader=preload("res://assets/vfx/legacy_counter_dynamic/live_aura.gdshader")
  material.set_shader_parameter("aura_color",AURA_COLORS[id])
  node.material=material
 node.visible=false
 node.animation_finished.connect(func():
  if kind=="counter_body" and node.animation=="start" and tracks.has(id) and tracks[id].shield:node.play("loop")
  elif kind=="energy" and node.animation=="start" and ((tracks.has(id) and tracks[id].on) or (id<r.horses.size() and r.horses[id].overdrive_active and not r.horses[id].finished)):node.play("loop")
  else:node.visible=false)
 r.get_node("Horses").add_child(node)
 sprites[key]=node
 return node
func sync(r,h,t):
 var scale: float=r.horse_draw_scale()
 var facing: float=t.facing
 var energy:=sprite(r,h.id,"energy")
 energy.position=r.horse_screen(h)+Vector2(0,-35.4)*scale
 energy.scale=Vector2.ONE*scale*.36875
 energy.flip_h=facing<0
 var od_vfx: bool=h.overdrive_active and not h.finished
 var energy_on: bool=t.on or od_vfx
 energy.modulate=Color(1,1,1,0.0 if (h.invincible>0 and not od_vfx) else (.85 if od_vfx else .50))
 if bool(energy.get_meta("was_active",false))!=energy_on:
  energy.visible=true
  energy.play("start" if energy_on else "end")
  energy.set_meta("was_active",energy_on)
 var counter:=sprite(r,h.id,"counter_body")
 var active: bool=h.invincible>0 and not h.finished
 if bool(counter.get_meta("was_active",false))!=active:
  counter.play("start" if active else "end")
  counter.set_meta("ending",not active)
  counter.set_meta("was_active",active)
 if active and h.invincible<=.23 and not counter.get_meta("ending",false):
  counter.play("end")
  counter.set_meta("ending",true)
 counter.visible=false
 var aura:=sprite(r,h.id,"aura")
 var anim:=DerbyRider.horse_animation(r,h)
 aura.play(anim)
 aura.set_frame_and_progress(DerbyRider.frame(r,h,anim),0)
 aura.visible=t.fade>0 and h.invincible<=0 and not od_vfx
 aura.position=r.horse_screen(h)+Vector2(0,-33.5)*scale
 var body: Texture2D=r.art_frames[h.id].get_frame_texture(anim,DerbyRider.frame(r,h,anim))
 aura.scale=Vector2(118.0/body.get_width(),83.0/body.get_height())*scale
 aura.flip_h=facing<0
 aura.rotation=.4 if h.knockdown>0 else sin(r.elapsed*16)*.10 if h.recovery>0 else 0.0
 aura.material.set_shader_parameter("strength",t.fade*(1.0 if h.invincible>0 else .5))
 var impact:=sprite(r,h.id,"impact")
 impact.position=r.horse_screen(h)+Vector2(12*facing,-35)*scale
 impact.scale=Vector2.ONE*scale*.6
 if t.impact<=.051 and t.shield and not impact.visible:
  impact.visible=true
  impact.play("perfect")
 var cancel:=sprite(r,h.id,"cancel")
 cancel.position=r.horse_screen(h)+Vector2(39*facing,-35)*scale
 cancel.scale=Vector2.ONE*.25
func sync_warning(r):
 for key in sprites:
  if key.ends_with("lock") or key.ends_with("danger") or key.ends_with("approach"):sprites[key].visible=false
 var e:=main_event(r)
 if e.is_empty():return
 var h=r.horses[e.target]
 var t:=DerbyCounterUI.timing(e)
 var point: Vector2=r.horse_screen(h)+Vector2(39*(-1 if cos(r.horse_angle(h))<0 else 1),-35)*r.horse_draw_scale()
 for kind in ["lock","danger","approach"]:
  var node:=sprite(r,h.id,kind)
  node.set_meta("manual",true)
  node.visible=kind!="danger" or t.progress>.65
  node.position=point+Vector2(13,-16) if kind=="danger" else Vector2(174,307) if kind=="approach" else point
  node.scale=Vector2.ONE*(.14 if kind=="danger" else .16 if kind=="approach" else .26)
  node.play(kind)
  var count:=base_frames.get_frame_count(kind)
  var phase: float=t.progress*(4+8*t.progress)
  var index: int=3 if t.ready else [0,1,0,1,2,1][int(phase)%6] if kind=="lock" else int(phase)%count
  node.set_frame_and_progress(index,fposmod(phase,1))
  node.speed_scale=0

func counter_texture(r,h) -> Texture2D:
 var node:=sprite(r,h.id,"counter_body")
 if not node.is_playing() and node.animation!="end":node.play("start")
 return node.sprite_frames.get_frame_texture(node.animation,node.frame)
func counter_anchor(id: int) -> Vector2:
 return [Vector2(-.5,-30),Vector2(0,-30),Vector2(0,-30),Vector2(0,-29),Vector2(.5,-27),Vector2(0,-29)][id]
