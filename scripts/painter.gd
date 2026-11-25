class_name DerbyPainter
extends RefCounted
const GOLD = Color("e7c77c")
static var brake_button = preload("res://assets/ui/brake_button.png")
static var boost_button = preload("res://assets/ui/boost_button.png")
static var hint_background: StyleBoxFlat
const NAVY = Color("20233d")
const CLOTH = [Color("cc443b"),Color("427bd9"),Color("4caa62"),Color("9566bd"),Color("d6ad3b"),Color("dc6b9e")]
static var dirt = preload("res://assets/environment/track-tile.png")
static var grass = preload("res://assets/environment/grass.png")
static var fence = preload("res://assets/environment/fence.png")
static var logo = preload("res://assets/ui/logo.png")
static var ui_textures := {}
static func ui(r,name: String,rect: Rect2,canvas=null):
 if not ui_textures.has(name):ui_textures[name]=load("res://assets/ui/cut/"+name+".png")
 (r if canvas==null else canvas).draw_texture_rect(ui_textures[name],rect,false)
static func panel(r,rect: Rect2,canvas=null):
 ui(r,"panel_wide",rect,canvas)
static func text(r,p: Vector2,t: String,c: Color=Color.WHITE,size: int=12,canvas=null):
 var target=r if canvas==null else canvas
 target.draw_string(r.font,p+Vector2.ONE,r.l(t),HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("1b2133"))
 target.draw_string(r.font,p,r.l(t),HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)
static func arrow(r,p: Vector2,up: bool,c: Color):
 var sign_y := -1.0 if up else 1.0
 r.draw_line(p+Vector2(0,5*sign_y),p-Vector2(0,5*sign_y),c,2)
 r.draw_polyline(PackedVector2Array([p+Vector2(-4,sign_y),p+Vector2(0,5*sign_y),p+Vector2(4,sign_y)]),c,2)
static func star(r,p: Vector2,scale: float):
 var pts := PackedVector2Array()
 for i in range(10):
  var angle := i*TAU/10-PI/2
  pts.append(p+Vector2(cos(angle),sin(angle))*(scale if i%2==0 else scale*.42))
 r.draw_colored_polygon(pts,Color("ffe66e"))
 r.draw_polyline(pts+PackedVector2Array([pts[0]]),Color("e79735"),1)
static func horse(r,h,canvas):
 var p: Vector2 = r.horse_screen(h)
 if p.x < -25 or p.x>665 or p.y<60 or p.y>345:
  var hint: String=("< #%d" if p.x<0 else "#%d >") if p.x<0 or p.x>640 else ("^ #%d" if p.y<60 else "v #%d")
  text(r,Vector2(clampf(p.x,4,607),clampf(p.y,120,310)),hint % (h.id+1),CLOTH[h.id],10,canvas)
  return
 var anim:=DerbyRider.horse_animation(r,h)
 var frames: SpriteFrames=r.art_frames[h.id]
 var frame:=DerbyRider.frame(r,h,anim)
 var heading: float=r.horse_angle(h)
 var facing_left: bool=cos(heading)<0
 # Side-view art stays upright on the flat racecourse.
 heading=0.4 if h.knockdown>0 else sin(r.elapsed*16)*.10 if h.recovery>0 else 0.0
 var size_scale: float=r.horse_draw_scale()
 var lift: float=r.overdrive.knockback_lift(h.id)*size_scale
 canvas.draw_set_transform(p-Vector2(0,lift),heading,Vector2(-size_scale if facing_left else size_scale,size_scale))
 var shadow:=PackedVector2Array()
 for i in range(16):shadow.append(Vector2(cos(i*TAU/16)*25,sin(i*TAU/16)*4+1+lift/size_scale))
 canvas.draw_colored_polygon(shadow,Color(.18,.13,.08,.45))
 if is_instance_valid(r.battle_vfx):r.battle_vfx.behind(r,h,canvas)
 if not h.finished and h.speed>10:
  ui(r,"fx_dust_"+str(int(r.elapsed*13+h.id)%8),Rect2(-53,-12,35,17),canvas)
 var mounted: AnimatedSprite2D=r.overdrive.mounted_horse(h.id)
 if mounted!=null and not h.finished:
  canvas.draw_texture_rect(mounted.sprite_frames.get_frame_texture(mounted.animation,mounted.frame),DerbyOverdrive.HORSE_FRAME_RECT,false)
 elif h.invincible>0 and not h.finished and is_instance_valid(r.battle_vfx):
  var fade: float=minf(1.0,h.invincible/.18)
  if fade<1:canvas.draw_texture_rect(frames.get_frame_texture(anim,frame),Rect2(-59,-75,118,83),false,Color(1,1,1,1-fade))
  canvas.draw_texture_rect(r.battle_vfx.counter_texture(r,h),Rect2(-94.4,-94.4,188.8,106.2),false,Color(1,1,1,fade))
 else:canvas.draw_texture_rect(frames.get_frame_texture(anim,frame),Rect2(-59,-75,118,83),false)
 DerbyRider.draw(r,h,canvas)
 if is_instance_valid(r.battle_vfx):r.battle_vfx.front(r,h,canvas)
 canvas.draw_set_transform(Vector2.ZERO)
static func badge_rect(r,h,size: Vector2) -> Rect2:
 var p: Vector2=r.horse_screen(h)
 var scale: float=r.horse_draw_scale()
 var candidates=[p+Vector2(60*scale+29,-24),p+Vector2(-60*scale-6-size.x,-24),p+Vector2(-size.x*.5,-72*scale-size.y-5)]
 var best:=Rect2(candidates[0],size)
 var best_score:=INF
 for point in candidates:
  var box:=Rect2(Vector2(clampf(point.x,4,636-size.x),clampf(point.y,80,320-size.y)),size)
  var score: float=point.distance_to(box.position)
  for other in r.horses:
   var body:=Rect2(r.horse_screen(other)+Vector2(-60,-68)*scale,Vector2(120,72)*scale)
   if box.intersects(body):score+=1000
  if score<best_score:
   best_score=score
   best=box
 return best
static func indicators(r,h,canvas):
 var p: Vector2=r.horse_screen(h)
 if p.x<0 or p.x>640 or p.y<75 or p.y>325:return
 var size_scale: float=r.horse_draw_scale()
 var facing_left: bool=cos(r.horse_angle(h))<0
 text(r,p+Vector2(-48*size_scale-8,-16*size_scale),str(h.id+1),CLOTH[h.id],10,canvas)
 if h.id==r.player_id:
  var pose:=DerbyRider.pose(r,h)
  var head: Vector2=pose.offset+Vector2(pose.size.x*.65,0)
  if facing_left:head.x=-head.x
  if h.knockdown>0:head=head.rotated(.4)
  ui(r,"you_marker",Rect2(p+head*size_scale-Vector2(9.5,20),Vector2(19,16)),canvas)
 if h.blend<1:ui(r,"arrow_up" if 140+h.target*27<h.y else "arrow_down",Rect2(p+Vector2(-48*size_scale-23,-25*size_scale),Vector2(13,12)),canvas)
 if h.stun>0:
  ui(r,("fx_hit_" if h.stun>.6 else "fx_stun_")+str(int(r.elapsed*12)%4),Rect2(p+Vector2(-9,-74*size_scale),Vector2(18,14)),canvas)
 var side: String=""
 if h.knockdown>0:side="ev_down"
 elif h.stun>0:side="ev_stunned"
 elif h.recovered_flash>0:side="ev_back"
 elif h.lane_blocked_time>0:side="ev_blocked"
 if not side.is_empty() and (h==r.selected or h.id==r.player_id):ui(r,side,badge_rect(r,h,Vector2(80,26)),canvas)
 if h.effect>1.8 and h.multiplier<1:
  text(r,p+Vector2(-42*size_scale-38,-43*size_scale),"BRAKE",Color("ff8179"),10,canvas)
 if h==r.selected:
  var target := p+Vector2((39 if r.front else -35)*(-1 if facing_left else 1),-35 if r.front else -20)*size_scale
  ui(r,"target_brake" if r.front else "target_boost",Rect2(target-Vector2(13,13)*size_scale,Vector2(26,26)*size_scale),canvas)
  if r.target_risky(h) and side.is_empty():ui(r,"ev_risk",badge_rect(r,h,Vector2(70,17)),canvas)
static func draw_hud(r,canvas):
 ui(r,"hud_frame",Rect2(2,2,636,34),canvas)
 r.overdrive.draw_hud(r,canvas)
 text(r,Vector2(287,22),"#%d" % (r.player_id+1),Color("88e9ff"),8,canvas)
 ui(r,"race_rank_"+str(r.player_rank()),Rect2(301,4,25,27),canvas)
 text(r,Vector2(326,23),"/6",GOLD,8,canvas)
 ui(r,"timer_blank",Rect2(342,5,93,30),canvas)
 text(r,Vector2(378,25),"%02d:%02d" % [int(r.elapsed)/60,int(r.elapsed)%60],Color.WHITE,12,canvas)
 ui(r,"progress_frame",Rect2(445,9,98,22),canvas)
 var progress: float=clampf(r.horses[r.player_id].x/r.race_distance,0,1)
 if progress>0:ui(r,"progress_fill",Rect2(450,16,87*progress,7),canvas)
 ui(r,"progress_horse",Rect2(445+progress*83,9,15,15),canvas)

 ui(r,"brake_new",Rect2(5,327,118,29),canvas)
 action_caption(r,canvas,72,"BRAKE")
 ui(r,"boost_new",Rect2(517,327,118,29),canvas)
 action_caption(r,canvas,585,"BOOST")
 var hint := ("目标 #%d · 点选马匹，再用减速或加速" if r.language=="zh" else "TARGET #%d · SELECT HORSE, THEN BRAKE / BOOST") % (r.button_target_id()+1)
 if r.shift_charges<=0:
  hint="干涉次数已用完 · 仍可反击" if r.language=="zh" else "NO SHIFTS LEFT / COUNTER AVAILABLE"
 elif r.hovered!=null:hint = "#%d  %s" % [r.selected.id+1,"BRAKE / CANCEL LANE" if r.front else "BOOST / 2 LANE TRIES"]
 if hint_background==null:
  hint_background=StyleBoxFlat.new()
  hint_background.bg_color=Color("#101b32ec")
  hint_background.border_color=Color("8e7245")
  hint_background.set_border_width_all(1)
  hint_background.set_corner_radius_all(4)
 var hint_width: float=minf(382,r.font.get_string_size(r.l(hint),HORIZONTAL_ALIGNMENT_LEFT,-1,11).x+20)
 var hint_x: float=roundf(320.0-hint_width*.5)
 canvas.draw_style_box(hint_background,Rect2(hint_x,330,hint_width,25))
 text(r,Vector2(hint_x+10,347),hint,Color("fff2ce"),11,canvas)
 # Same map geometry and race distances drive both the main view and minimap.
 ui(r,"mm_frame",Rect2(522,42,112,72),canvas)
 var course:=PackedVector2Array()
 for i in range(81):
  var point: Vector2=DerbyTrack.map_position(i*3400.0/80,2.5)
  course.append(Vector2(531,42)+point*Vector2(.15,.18))
 canvas.draw_polyline(course,Color("d9c793"),1)
 for h in r.horses:
  var point: Vector2=Vector2(531,42)+DerbyTrack.map_position(h.x,(h.y-140)/27)*Vector2(.15,.18)
  canvas.draw_circle(point,2,CLOTH[h.id])
  if h.id==r.player_id:canvas.draw_arc(point,3,0,TAU,12,GOLD,1)
 text(r,Vector2(528,107),("按住拖动 · TAB 全景" if r.language=="zh" else "DRAG MAP · TAB VIEW"),Color("fff0c7"),9,canvas)
 var view: Rect2=r.minimap_view_rect()
 if view.has_area():canvas.draw_rect(view,Color("fff0b5"),false,1)
 var finish: Vector2=Vector2(531,42)+DerbyTrack.map_position(r.race_distance,2.5)*Vector2(.15,.18)
 canvas.draw_line(finish-Vector2(0,3),finish+Vector2(0,3),Color.WHITE,1)
 if r.mode=="race":text(r,Vector2(11,52),("第%d/8轮 · 金币%d · 下注%d" if r.language=="zh" else "ROUND %d/8 · FUNDS %d · BET %d") % [r.betting.round_number,roundi(r.coins.shown),r.betting.amount],GOLD,9,canvas)
 if r.mode=="race":
  if r.combat.cooperation_leader>=0:
   var coop_txt: String=("合作追赶 #%d" if r.language=="zh" else "PACK CHASING #%d") % (r.combat.cooperation_leader+1)
   var coop_w: float=r.font.get_string_size(coop_txt,HORIZONTAL_ALIGNMENT_LEFT,-1,9).x
   panel(r,Rect2(10,89,137,19),canvas)
   text(r,Vector2(roundf(10.0+(137.0-coop_w)*.5),102),coop_txt,GOLD,9,canvas)
  var run: float=minf(r.race_distance,r.horses[r.player_id].progress)
  text(r,Vector2(11,66),("赛程 %.1f / %.1f 圈" if r.language=="zh" else "LAPS %.1f / %.1f") % [run/DerbyTrack.LAP_LENGTH,r.race_distance/DerbyTrack.LAP_LENGTH],GOLD,11,canvas)
 if r.event_time>0 and r.mode=="race" and r.order.is_empty():
  var events: Dictionary={"COLLISION!":"ev_collision","HEAVY HIT!":"ev_heavy","KNOCKDOWN!":"ev_down","GET UP!":"ev_up","RECOVERED!":"ev_recovered","STUNNED!":"ev_stunned","BET PLACED!":"bx_placed"}
  if events.has(r.event_text):
   ui(r,events[r.event_text],Rect2(224,43,192,65),canvas)
  elif "PERFECT COUNTER" not in r.event_text and r.event_text not in ["INCOMING ATTACK!","TOO EARLY!","TOO LATE!","TOO LATE! BRAKE!"]:
   ui(r,"event_frame",Rect2(198,52,244,25),canvas)
   var notice: String=r.l(r.event_text)
   var size: int=11
   if r.font.get_string_size(notice,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>211.0:size=9
   var width: float=r.font.get_string_size(notice,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
   text(r,Vector2(roundf(320-width*.5),68),notice,Color("fff0ae"),size,canvas)
 if r.mode=="race":
  DerbyCounterUI.draw(r,canvas)
  if is_instance_valid(r.battle_vfx):r.battle_vfx.draw_alert(r,canvas)
 if r.countdown>0 and r.mode=="race":
  panel(r,Rect2(281,156,78,52),canvas)
  var cd_txt: String=str(ceili(r.countdown))
  var cd_w: float=r.font.get_string_size(cd_txt,HORIZONTAL_ALIGNMENT_LEFT,-1,34).x
  text(r,Vector2(roundf(320.0-cd_w*.5),194),cd_txt,GOLD,34,canvas)
 elif r.elapsed<.65 and r.mode=="race":text(r,Vector2(285,190),"GO!",GOLD,36,canvas)
 if not r.order.is_empty() and r.mode=="race":
  panel(r,Rect2(185,40,270,22),canvas)
  var win_txt: String=r.l("WINNER #%d - OTHERS FINISHING" % (r.order[0]+1))
  var win_w: float=r.font.get_string_size(win_txt,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
  text(r,Vector2(roundf(320.0-win_w*.5),56),win_txt,GOLD,12,canvas)

static func action_caption(r,canvas,center: float,key: String):
 var width: float=r.font.get_string_size(r.l(key),HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
 text(r,Vector2(center-width*.5,347),key,Color.WHITE,15,canvas)
