class_name DerbyRider
extends RefCounted
static var cache: Dictionary={}
static var mounts: Dictionary={}
# Local RiderAnchor corrections are independent for each horse.
const OFFSETS=[Vector2(-4.8,0),Vector2(-5.7,.5),Vector2(-5.8,.5),Vector2(-4.5,0),Vector2(.5,0),Vector2(-4.9,.2)]
const SCALES=[.98,1.0,.97,.98,1.0,.97]
const PIXEL_SCALE=[34.0/198,34.0/198,34.0/201,34.0/196,34.0/198,34.0/189]
const GOLD_HIPS={"run":Vector2(.1464,.8024),"boost":Vector2(.3845,.7688),"brake":Vector2(.4091,.7739)}
const HIPS={"run":Vector2(.22,.80),"boost":Vector2(.36,.77),"brake":Vector2(.45,.82),"hit":Vector2(.50,.80),"counter":Vector2(.36,.82),"win":Vector2(.45,.88)}
static func state(r,h) -> String:
 if h.finished:return "win" if not r.order.is_empty() and r.order[0]==h.id else "brake"
 if h.knockdown>0 or h.stun>0 or h.recovery>0:return "hit"
 if h.overdrive_active:return "boost"
 if h.invincible>0:return "counter"
 if h.effect>0:return "boost" if h.multiplier>1 else "brake"
 return "boost" if h.dash_time>0 else "run"
static func horse_animation(r,h) -> String:
 if h.finished:return "win" if not r.order.is_empty() and r.order[0]==h.id else "lose"
 if h.knockdown>0 or h.stun>0 or h.recovery>0:return "hit"
 if h.overdrive_active:return "boost"
 if h.effect>0:return "boost" if h.multiplier>1 else "brake"
 return "boost" if h.dash_time>0 or h.counter_time>0 else "run"
static func frame(r,h,animation: String) -> int:
 var frames: SpriteFrames=r.art_frames[h.id]
 return (int(h.stride_phase) if animation in ["run","boost","brake"] else int(r.elapsed*9+h.id))%frames.get_frame_count(animation)
static func saddle(r,h) -> Vector2:
 var mounted: AnimatedSprite2D=r.overdrive.mounted_horse(h.id)
 if mounted!=null and not h.finished:return r.overdrive.mount_anchor(h.id,mounted)
 if mounts.is_empty():mounts=JSON.parse_string(FileAccess.get_file_as_string("res://assets/presentation/rider_mounts.json"))
 var anim:=horse_animation(r,h)
 var index: int=int(h.stride_phase)%6 if h.invincible>0 and not h.finished else frame(r,h,anim)
 var values: Array=mounts[str(h.id)]["run" if h.invincible>0 and not h.finished else anim]
 var point: Array=values[index%values.size()]
 var normal: Vector2=Vector2(point[0],point[1])+OFFSETS[h.id]
 if h.invincible>0 and not h.finished and is_instance_valid(r.battle_vfx):return normal.lerp(r.battle_vfx.counter_anchor(h.id),minf(1.0,h.invincible/.18))
 return normal
static func pose(r,h,override_state: String="") -> Dictionary:
 var current: String=state(r,h) if override_state.is_empty() else override_state
 if h.id==4:
  var gold_pose: String="brake" if current in ["brake","hit"] else "boost" if current in ["boost","counter"] else "run"
  var gold_key: String="gold_mount_"+gold_pose
  if not cache.has(gold_key):cache[gold_key]=load("res://assets/ui/rider25/"+gold_key+".png")
  var gold_tex: Texture2D=cache[gold_key]
  var gold_size: Vector2=gold_tex.get_size()*(31.0 if gold_pose=="boost" else 34.0)/gold_tex.get_height()
  var gold_anchor:=saddle(r,h)
  var gold_hip: Vector2=GOLD_HIPS[gold_pose]
  return {"texture":gold_tex,"size":gold_size,"offset":gold_anchor-gold_size*gold_hip,"anchor":gold_anchor,"state":current,"hip":gold_hip.y}
 var key: String="rider_%d_%s" % [h.id,current]
 if not cache.has(key):cache[key]=load("res://assets/presentation/"+key+".png")
 var texture: Texture2D=cache[key]
 var size: Vector2=Vector2(texture.get_width(),texture.get_height())*PIXEL_SCALE[h.id]*SCALES[h.id]
 var anchor:=saddle(r,h)
 return {"texture":texture,"size":size,"offset":anchor-size*HIPS[current],"anchor":anchor,"state":current}
static func update(r,h,dt):
 var target:=pose(r,h)
 if not h.rider_initialized:
  h.rider_state=target.state
  h.rider_previous_state=target.state
  h.rider_transition=1
 elif h.rider_state!=target.state:
  h.rider_previous_state=h.rider_state
  h.rider_state=target.state
  h.rider_transition=0
 h.rider_transition=minf(1,h.rider_transition+dt/.12)
 h.rider_anchor=target.anchor
 h.rider_offset=target.offset
 h.rider_size=target.size
 h.rider_initialized=true
static func draw(r,h,canvas):
 if not h.rider_initialized:update(r,h,0)
 var current:=pose(r,h)
 # Registered hips remain attached during the brief pose blend; art pixels keep a constant scale.
 if h.rider_transition<1:
  var previous:=pose(r,h,h.rider_previous_state)
  draw_rig(r,h,canvas,previous,1-h.rider_transition)
 draw_rig(r,h,canvas,current,h.rider_transition)
static func gait(r,h) -> Vector2:
 if h.finished or h.speed<1:return Vector2.ZERO
 var phase: float=h.stride_phase*TAU/6.0
 var mounted: AnimatedSprite2D=r.overdrive.mounted_horse(h.id)
 if mounted!=null:phase=(mounted.frame+mounted.frame_progress)*TAU/6.0
 elif h.invincible>0 and is_instance_valid(r.battle_vfx):
  var driver: AnimatedSprite2D=r.battle_vfx.sprites.get(str(h.id)+"counter_body")
  if driver!=null:phase=(driver.frame+driver.frame_progress)*TAU/6.0
 var amplitude: float=1.35 if h.overdrive_active else 1.25 if h.invincible>0 or h.dash_time>0 or (h.effect>0 and h.multiplier>1) else .65 if h.effect>0 else 1.0
 return Vector2(sin(phase)*1.4,cos(phase)*1.3)*amplitude
static func draw_rig(r,h,canvas,pose: Dictionary,alpha: float):
 # Five horizontal joints: head, shoulders, hands, planted pelvis, feet.
 # The original art is gently articulated, with no new character generation.
 var hip: float=pose.get("hip",HIPS[pose.state].y)
 var rows: Array=[0.0,.28,.58,hip,(hip+1.0)*.5,1.0]
 var motion: Vector2=pose.get("gait_snapshot",gait(r,h))
 for row in range(rows.size()-1):
  var uv:=PackedVector2Array([Vector2(0,rows[row]),Vector2(1,rows[row]),Vector2(1,rows[row+1]),Vector2(0,rows[row+1])])
  var points:=PackedVector2Array()
  for coord in uv:
   var p: Vector2=pose.offset+coord*pose.size
   if coord.y<hip:
    var weight: float=(hip-coord.y)/hip
    p+=Vector2(motion.x*weight,motion.y*weight)
   else:
    p.x+=motion.x*.30*sin((coord.y-hip)/maxf(.01,1-hip)*PI)
   points.append(p)
  canvas.draw_polygon(points,PackedColorArray([Color(1,1,1,alpha)]),uv,pose.texture)
