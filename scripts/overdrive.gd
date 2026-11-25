class_name DerbyOverdrive
extends RefCounted

const ART="res://assets/ui/overdrive/"
const HORSE_AURA=preload("res://assets/ui/overdrive/horse_aura.tres")
const HORSE_FRAME_RECT=Rect2(-80,-106.667,160,133.333)
const MOUNT_BASE=[Vector2(-0.5,-30.5),Vector2(-1.8,-33.5),Vector2(-1.0,-30.0),Vector2(-2.0,-30.3),Vector2(-0.5,-31.0),Vector2(-2.5,-29.5)]
const MOUNT_STRIDE=[-2.0,-1.3,0.0,1.3,0.7,-0.7]
const MOUNT_STRIDE_X=[-0.7,0.0,0.7,0.7,0.0,-0.7]
const MOUNT_STRIDE_FRAMES=6
const RACE_AREA=Rect2(0,38,640,286)
const TARGET_ART=preload("res://assets/ui/overdrive/ram_target_atlas.png")
const TARGET_RING=Rect2(29,171,365,352)
const LOCKED_RING=Rect2(907,88,499,502)
static var textures: Dictionary={}
var keys: Dictionary={}
var held: float=0.0
var long_press: bool=false
var counter_consumed: bool=false
var counter_sample: Dictionary={}
var shift_target: int=-1
var shift_brake: bool=false
var banner_time: float=0.0
var hit_pause: float=0.0
var locked_target: int=-1
var effects: Array[Dictionary]=[]
var auras: Dictionary={}

func reset():
 keys.clear()
 held=0
 long_press=false
 counter_consumed=false
 counter_sample.clear()
 banner_time=0
 hit_pause=0
 locked_target=-1
 effects.clear()
 for aura: AnimatedSprite2D in auras.values():
  aura.stop()
  aura.hide()

func clear_input(r):
 keys.clear()
 held=0
 long_press=false
 counter_consumed=false
 counter_sample.clear()
 locked_target=-1
 if not r.horses.is_empty():
  r.horses[r.player_id].ram_target=-1

func shift_input(r,event: InputEventKey) -> bool:
 if event.echo:return not keys.is_empty()
 var key: int=event.location
 var racing: bool=r.mode=="race" and not r.paused and not r.horses[r.player_id].finished
 if event.pressed:
  if not racing:return false
  if r.chat.typing():
   if r.combat.sample_counter(r.player_id).is_empty():return false
   r.chat.close()
  if keys.is_empty():
   held=0.0
   long_press=false
   counter_consumed=false
   counter_sample=r.combat.sample_counter(r.player_id) if r.countdown<=0 else {}
   if not counter_sample.is_empty():
    r.combat.counter_press(r,counter_sample)
    counter_sample.clear()
    counter_consumed=true
    keys[key]=true
    return true
   r.refresh_hovered_horse()
   shift_target=r.hovered.id if r.hovered!=null else -1
   shift_brake=shift_target>=0 and r.front
  keys[key]=true
  return true
 if not keys.has(key):return false
 keys.erase(key)
 if keys.is_empty():
  if counter_consumed:
   counter_consumed=false
   return true
  if racing and r.countdown<=0 and held>DerbyConfig.OVERDRIVE_HOLD:long_press=true
  if racing and r.countdown<=0 and not long_press:
   if not counter_sample.is_empty():r.combat.counter_press(r,counter_sample)
   elif r.combat.sample_counter(r.player_id).is_empty():
    if not r.combat.counter_press(r):r.boost_with_shift(shift_target,shift_brake)
  counter_sample.clear()
 return true

func defers_attack(event: Dictionary) -> bool:
 return not long_press and not keys.is_empty() and counter_sample.has("event") and is_same(counter_sample.event,event)

func update(r,dt: float):
 banner_time=maxf(0,banner_time-dt)
 for i in range(effects.size()-1,-1,-1):
  effects[i].age+=dt
  if effects[i].age>=.42:effects.remove_at(i)
 var player: DerbyHorse=r.horses[r.player_id]
 if locked_target>=0 and not valid_ram_target(r,player,r.horses[locked_target]):locked_target=-1
 if not keys.is_empty() and not long_press and not counter_consumed and not player.finished:
  held+=dt
  if held>DerbyConfig.OVERDRIVE_HOLD:
   long_press=true
   counter_sample.clear()
   if not player.overdrive_active and not start(r,player):
    var blocked: bool=player.knockdown>0 or player.stun>0
    var message: String="恢复后可发动暴走" if blocked else "暴走需要满格能量"
    if r.language!="zh":message="RECOVER BEFORE OVERDRIVE" if blocked else "OVERDRIVE NEEDS FULL ENERGY"
    r.announce(message,.85)
 for horse: DerbyHorse in r.horses:
  if horse.finished:
   horse.overdrive_active=false
   continue
  if horse.id!=r.player_id:advance_ai(r,horse,dt)
  if horse.advance_energy(dt):
   if horse.id!=r.player_id:horse.overdrive_cooldown=2.9
   else:locked_target=-1
   r.dialogue.overdrive_line(horse.id,"empty")
  if not horse.overdrive_active:horse.ram_target=-1
  if horse.overdrive_active and horse.id==5:charm_nearby(r,horse)

func start(r,horse: DerbyHorse) -> bool:
 if horse.overdrive_active or horse.energy<DerbyConfig.OVERDRIVE_MAX_ENERGY or horse.finished or horse.knockdown>0 or horse.stun>0:return false
 horse.overdrive_active=true
 horse.overdrive_remaining=DerbyConfig.OVERDRIVE_DURATION
 horse.overdrive_refill=0
 r.dialogue.overdrive_line(horse.id,"start")
 if horse.id==r.player_id:
  banner_time=.5
  r.sound.cue("overdrive")
 return true

func advance_ai(r,horse: DerbyHorse,dt: float):
 horse.overdrive_cooldown=maxf(0,horse.overdrive_cooldown-dt)
 if horse.overdrive_active:
  if horse.ram_target<0 and r.betting.round_number>=3:choose_ai_ram(r,horse)
  return
 if horse.overdrive_cooldown>0 or horse.energy<DerbyConfig.OVERDRIVE_MAX_ENERGY or horse.knockdown>0 or horse.stun>0:return
 if horse.progress<r.race_distance*.12:return
 var saving_finish: bool=r.betting.round_number==4 and not DerbyDifficulty.in_final_stretch(horse.progress,r.race_distance)
 var closing:=false
 var pass_now:=false
 var pulling_away:=false
 for target: DerbyHorse in r.horses:
  if target==horse or target.finished:continue
  if target.id==r.combat.cooperation_leader and target.progress-horse.progress>105.0:pulling_away=true
  var gap:=DerbyAI.gap(horse,target)
  if gap>28.0 and gap<154.0 and absf(target.y-horse.y)<47.0:
   closing=true
   if gap<88.0 and absf(target.y-horse.y)>=DerbyConfig.BODY_WIDTH:pass_now=true
 if saving_finish and not pass_now and not pulling_away:return
 var remaining: float=r.race_distance-horse.progress
 var exit_bend: bool=horse.is_bend() and not DerbyTrack.bend(horse.progress+72)
 var sprint: bool=remaining<(470.0 if r.betting.round_number>=4 else 330.0) and remaining>45.0
 var chasing: bool=r.combat.cooperation_leader>=0 and r.combat.cooperation_leader!=horse.id
 if closing or sprint or pulling_away or exit_bend or chasing:start(r,horse)

func choose_ai_ram(r,horse: DerbyHorse):
 var leader: int=r.combat.cooperation_leader
 var best: float=INF
 for target: DerbyHorse in r.horses:
  if leader>=0 and leader!=horse.id and target.id!=leader:continue
  if not valid_ram_target(r,horse,target) or target.overdrive_active:continue
  if target.id==r.player_id and r.dialogue.is_bribed_ally(horse.id):continue
  var gap:=target.progress-horse.progress
  if gap<=12.0 or gap>=100.0 or absf(target.y-horse.y)>27.0:continue
  if gap<best:
   best=gap
   horse.ram_target=target.id

func valid_ram_target(r,player: DerbyHorse,rival: DerbyHorse) -> bool:
 if not player.overdrive_active or player==rival or player.knockdown>0 or player.stun>0:return false
 if rival.finished or rival.attack_guarded() or float(player.ram_cooldowns.get(rival.id,0))>r.elapsed:return false
 var gap: float=DerbyAI.gap(player,rival)
 return gap>=-12.0 and gap<=DerbyConfig.OVERDRIVE_RAM_RANGE and absf(player.y-rival.y)<=36.0

func ram_badge(r,id: int) -> Rect2:
 if r.mode!="race" or r.paused or r.countdown>0 or r.map_dragging or r.dialogue.urgent():return Rect2()
 var player: DerbyHorse=r.horses[r.player_id]
 var rival: DerbyHorse=r.horses[id]
 if not valid_ram_target(r,player,rival):return Rect2()
 var position: Vector2=r.horse_screen(rival)
 var scale: float=r.horse_draw_scale()
 var pose:=DerbyRider.pose(r,rival)
 var anchor: Vector2=pose.offset+pose.size*Vector2(.59,.30)
 if cos(r.horse_angle(rival))<0.0:anchor.x*=-1.0
 var center:=position+anchor*scale
 var rect:=Rect2(center-Vector2(17,17),Vector2(34,34))
 return rect if RACE_AREA.has_point(position) and r.dialogue.ui_clear(rect) else Rect2()

func request_ram(r,id: int) -> bool:
 if r.mode!="race" or r.paused or r.countdown>0 or r.map_dragging:return false
 var player: DerbyHorse=r.horses[r.player_id]
 var rival: DerbyHorse=r.horses[id]
 if not valid_ram_target(r,player,rival) or not RACE_AREA.has_point(r.horse_screen(rival)):return false
 if player.ram_target>=0:return true
 if locked_target!=id:
  locked_target=id
  return true
 locked_target=-1
 player.ram_target=id
 r.sound.ram_started()
 return true

func steer_ram(r,horse: DerbyHorse) -> bool:
 if horse.ram_target<0:return false
 var rival: DerbyHorse=r.horses[horse.ram_target]
 if not valid_ram_target(r,horse,rival):
  horse.ram_target=-1
  return false
 if horse.blend>=1.0 and horse.lane!=rival.lane:
  horse.change(rival.lane,DerbyConfig.OVERDRIVE_LANE_SECONDS)
 return true

func charm_nearby(r,horse: DerbyHorse):
 for target: DerbyHorse in r.horses:
  if target==horse or target.finished or target.attack_guarded():continue
  if target.id==r.player_id and r.dialogue.is_bribed_ally(horse.id):continue
  var leader: int=r.combat.cooperation_leader
  if leader>=0 and horse.id!=r.player_id and horse.id!=leader and target.id!=leader:continue
  if absf(DerbyAI.gap(horse,target))>DerbyConfig.OVERDRIVE_PINK_RANGE or absf(horse.y-target.y)>DerbyConfig.OVERDRIVE_PINK_WIDTH:continue
  if float(horse.charm_cooldowns.get(target.id,0.0))>r.elapsed:continue
  horse.charm_cooldowns[target.id]=r.elapsed+DerbyConfig.OVERDRIVE_PINK_COOLDOWN
  target.charm=DerbyConfig.OVERDRIVE_PINK_STALL
  effects.append({"age":0.0,"target":target.id,"kind":"petal"})

func impact(r,attacker: int,target: int,knockback: bool=false):
 effects.append({"age":0.0,"target":target,"kind":"impact","knockback":knockback})
 if attacker==r.player_id:r.sound.ram_hit(knockback)
 r.dialogue.overdrive_line(attacker,"ram")
 r.dialogue.overdrive_line(target,"hit")
 if attacker==r.player_id or target==r.player_id:
  hit_pause=DerbyConfig.OVERDRIVE_HIT_STOP
  r.shake=maxf(r.shake,.09)

func knockback_lift(id: int) -> float:
 for effect: Dictionary in effects:
  if int(effect.target)==id and effect.get("knockback",false) and float(effect.age)<.30:
   return 14.0*sin(float(effect.age)*PI/.30)
 return 0.0

static func texture(key: String) -> Texture2D:
 if not textures.has(key):textures[key]=load(ART+key+".png")
 return textures[key]

func sync_auras(r):
 if r.mode!="race" or r.paused:
  for aura: AnimatedSprite2D in auras.values():
   aura.pause()
   if r.mode!="race":aura.hide()
  return
 for horse: DerbyHorse in r.horses:
  var active: bool=horse.overdrive_active and not horse.finished
  if not auras.has(horse.id):
   if not active:continue
   make_aura(r,horse.id)
  var aura: AnimatedSprite2D=auras[horse.id]
  var prefix: String="aura_%d_" % horse.id
  if active:
   if not aura.visible or aura.animation==prefix+"end":
    aura.play(prefix+"start")
    aura.show()
   elif not aura.is_playing():
    aura.play()
  elif aura.visible and aura.animation!=prefix+"end":
   aura.play(prefix+"end")
  elif aura.visible and not aura.is_playing():
   aura.play()

func mounted_horse(id: int) -> AnimatedSprite2D:
 var sprite: AnimatedSprite2D=auras.get(id)
 return sprite if sprite!=null and sprite.visible else null

func mount_anchor(id: int,sprite: AnimatedSprite2D) -> Vector2:
 if DerbyRider.mounts.is_empty():DerbyRider.mounts=JSON.parse_string(FileAccess.get_file_as_string("res://assets/presentation/rider_mounts.json"))
 var frame: int=sprite.frame
 if String(sprite.animation).ends_with("_end"):frame+=1
 var mvals: Array=DerbyRider.mounts[str(id)]["boost"]
 var mpt: Array=mvals[posmod(frame,mvals.size())]
 return Vector2(mpt[0],mpt[1])+DerbyRider.OFFSETS[id]

func make_aura(r,id: int):
 var aura:=AnimatedSprite2D.new()
 aura.sprite_frames=HORSE_AURA
 # The horse and rider are drawn together in track order by DerbyPainter.
 aura.self_modulate=Color.TRANSPARENT
 aura.hide()
 aura.animation_finished.connect(func():
  if String(aura.animation).ends_with("_start"):
   aura.play("aura_%d_loop" % id)
   aura.set_frame_and_progress(0,0.0)
  else:aura.hide())
 r.get_node("Horses").add_child(aura)
 auras[id]=aura

func draw_effects(r,canvas: CanvasItem):
 for effect in effects:
  var position: Vector2=r.horse_screen(r.horses[int(effect.target)])
  if not RACE_AREA.has_point(position):continue
  var age: float=effect.age
  var fade: float=1.0-smoothstep(.23,.42,age)
  if effect.kind=="petal":
   for index in range(5):
    var angle: float=index*TAU/5.0+age*3.0
    var offset: Vector2=Vector2.from_angle(angle)*(8+54*age)
    canvas.draw_texture_rect(texture("petal"),Rect2(position+Vector2(-5,-17)+offset,Vector2(9,8)),false,Color(1,1,1,fade))
  else:
   var frame: int=mini(3,int(age/.10))
   canvas.draw_texture_rect(texture("wave_%d" % frame),Rect2(position-Vector2(26,11),Vector2(52,17)),false,Color(1,1,1,.8*fade))
   canvas.draw_texture_rect(texture("spark_%d" % frame),Rect2(position+Vector2(-13,-27),Vector2(26,24)),false,Color(1,1,1,fade))

func draw_hud(r,canvas: CanvasItem):
 var horse: DerbyHorse=r.horses[r.player_id]
 var active: bool=horse.overdrive_active
 var ready: bool=horse.energy>=DerbyConfig.OVERDRIVE_MAX_ENERGY
 var theme_color:=Color("ffbd4b") if active else Color("d6b76a")
 var state: String="active" if active else "ready" if ready else "locked"
 canvas.draw_texture_rect(texture(state),Rect2(137,6,12,11),false)
 canvas.draw_texture_rect(texture("name"),Rect2(151,7,50,8),false)
 var meter:=Rect2(137,18,88,9)
 canvas.draw_rect(meter.grow(1),theme_color)
 canvas.draw_texture_rect(texture("body"),meter,false)
 var ratio: float=clampf(horse.energy/DerbyConfig.OVERDRIVE_MAX_ENERGY,0.0,1.0)
 if ratio>0:
  var fill:=Rect2(meter.position,Vector2(meter.size.x*ratio,meter.size.y))
  var material:=texture("energy")
  var dims:=material.get_size()
  var flare: float=1+.22*sin(r.elapsed*20) if active else 1.0
  canvas.draw_texture_rect_region(material,fill,Rect2(Vector2.ZERO,Vector2(dims.x*ratio,dims.y)),Color(flare,flare,flare))
 for i in range(1,DerbyConfig.OVERDRIVE_SEGMENTS):
  var x: float=meter.position.x+meter.size.x*i/DerbyConfig.OVERDRIVE_SEGMENTS
  canvas.draw_line(Vector2(x,meter.position.y),Vector2(x,meter.end.y),Color("fff1cd"),1)
 var percent: String="%d%%" % floori(horse.energy)
 var percent_width: float=r.font.get_string_size(percent,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
 DerbyPainter.text(r,Vector2(225-percent_width,15),percent,Color("fff4d0"),8,canvas)
 var stock: int=DerbyConfig.shift_limit(r.betting.round_number)
 var step: float=54.0/stock
 var orb: float=minf(16.0,step-1.0)
 for i in range(stock):
  DerbyPainter.ui(r,"cx_charge_on" if i<r.shift_charges else "cx_charge_off",Rect2(roundf(232+i*step+(step-orb)*.5),roundf(15-orb*.5),orb,orb),canvas)
 var stock_label: String="干涉次数" if r.language=="zh" else "SHIFT STOCK"
 var stock_width: float=r.font.get_string_size(stock_label,HORIZONTAL_ALIGNMENT_LEFT,-1,7).x
 DerbyPainter.text(r,Vector2(259-stock_width*.5,29),stock_label,Color("c6eaf4"),7,canvas)
 if r.mode=="race":
  if active:
   for rival: DerbyHorse in r.horses:
    var badge:=ram_badge(r,rival.id)
    if not badge.has_area():continue
    var locked: bool=locked_target==rival.id or horse.ram_target==rival.id
    canvas.draw_texture_rect_region(TARGET_ART,badge,LOCKED_RING if locked else TARGET_RING,Color.WHITE if locked else Color(1,1,1,.76))
  if banner_time>0:
   var box:=Rect2(153,38,102,24) if r.dialogue.urgent() else Rect2(249,37,142,34)
   canvas.draw_texture_rect(texture("banner"),box,false,Color(1,1,1,minf(1,banner_time/.12)))
