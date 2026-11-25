class_name DerbyHorse
extends RefCounted
var recovered_flash: float=0
var lane_blocked_time: float=0
var invincible: float=0
var energy: float=DerbyConfig.OVERDRIVE_START_ENERGY
var overdrive_active: bool=false
var overdrive_stall: float=0
var charm: float=0
var ram_cooldowns: Dictionary={}
var charm_cooldowns: Dictionary={}
var overdrive_cooldown: float=0
var overdrive_remaining: float=0
var overdrive_refill: float=0
var rider_anchor:=Vector2.ZERO
var rider_state: String="run"
var rider_previous_state: String="run"
var rider_transition: float=1
var rider_initialized: bool=false
var rider_offset:=Vector2.ZERO
var rider_size:=Vector2.ZERO
var stride_phase: float=0
var dash_interval: float=DerbyConfig.AUTO_BOOST_COOLDOWN
var counter_time: float=0
var knockdown: float=0
var recovery: float=0
var recovery_stat: float=1
var stamina_stat: float=1
var aggression: float=.6
var dash_time: float = 0
var dash_cooldown: float = 0
var dash_count: int = 0
var change_count: int = 0
var collision_count: int = 0
var lane_start_y: float = 0
var lane_change_seconds: float=DerbyConfig.LANE_CHANGE_SECONDS
var ram_target: int=-1
var protection: float = 0
var progress: float=0
# Compatibility alias for old tests; movement is closed-path progress, not screen X.
var x: float:
 get:return progress
 set(value):progress=value
var y: float
var lane: int
var origin: int
var target: int
var blend: float = 1
var speed: float = 70
var base: float
var effect: float = 0
var multiplier: float = 1
var stun: float = 0
var attempts: int = 0
var think: float = 0
var finished: bool = false
var id: int
func _init(number: int):
 id = number
 stride_phase=number*.8
 dash_cooldown = 3.5+number*0.9
 lane = number
 origin = lane
 target = lane
 y = 140 + lane * 27
 base = 68.0*DerbyBetting.STATS[id][0]
 aggression=DerbyBetting.STATS[id][1]
 recovery_stat=DerbyBetting.STATS[id][2]
 stamina_stat=DerbyBetting.STAMINA[id]
func change(next: int,seconds: float=DerbyConfig.LANE_CHANGE_SECONDS):
 if next < 0 or next > 5 or blend < 1: return
 lane_start_y = y
 lane_change_seconds=seconds
 change_count += 1
 origin = lane
 target = next
 blend = 0
func hit(front: bool):
 if front and attack_guarded():return
 effect = DerbyConfig.EFFECT_SECONDS
 multiplier = DerbyConfig.BRAKE if front else DerbyConfig.BOOST
 if front:
  attempts = 0
  if blend < 1:
   target = origin
   lane = origin
   lane_start_y = y
   blend = 0
 else:
  attempts += 2
  think = minf(think,0.1)
func tick(dt: float, pace: float=1.0, race_distance: float=3400.0):
 overdrive_stall=maxf(0,overdrive_stall-dt)
 charm=maxf(0,charm-dt)
 recovered_flash=maxf(0,recovered_flash-dt)
 var was_recovering: bool=recovery>0
 lane_blocked_time=maxf(0,lane_blocked_time-dt)
 invincible=maxf(0,invincible-dt)
 var was_down: bool=knockdown>0
 counter_time=maxf(0,counter_time-dt)
 knockdown=maxf(0,knockdown-dt*recovery_stat)
 recovery=maxf(0,recovery-dt*recovery_stat)
 if was_down and knockdown<=0:recovery=.45
 elif was_recovering and recovery<=0:recovered_flash=.65
 dash_time = maxf(0,dash_time-dt)
 dash_cooldown = maxf(0,dash_cooldown-dt)
 protection = maxf(0, protection-dt)
 effect = maxf(0, effect-dt)
 stun = maxf(0, stun-dt)
 if effect == 0: multiplier = 1
 var stamina_factor: float=lerpf(1.0,1.0+(stamina_stat-1.0)*.55,smoothstep(.60,1.0,progress/maxf(1.0,race_distance)))
 speed = base * pace * stamina_factor * lerpf(1.0,DerbyConfig.BEND_BOOST,DerbyTrack.bend_weight(progress)) * multiplier * (DerbyConfig.AUTO_BOOST if dash_time>0 and effect<=0 else 1.0) * (DerbyConfig.COUNTER_SPEED if counter_time>0 else 1.0) * (0.06 if knockdown>0 else 0.55 if recovery>0 else 0.18 if stun > 0 else 1.0)
 if overdrive_active:speed=minf(speed*DerbyConfig.OVERDRIVE_SPEED,base*DerbyConfig.OVERDRIVE_MAX_SPEED_FACTOR)
 if overdrive_stall>0:speed*=DerbyConfig.OVERDRIVE_STALL_SPEED
 if charm>0:speed*=DerbyConfig.OVERDRIVE_PINK_SPEED
 stride_phase+=dt*DerbyConfig.RUN_FPS*clampf(speed/maxf(1,base),.25,1.8)
 progress += speed * DerbyTrack.progress_factor(progress,(y-140.0)/27.0) * dt
 if blend < 1 and knockdown<=0:
  blend = minf(1, blend + dt / lane_change_seconds)
  y = lerpf(lane_start_y,140.0+target*27,smoothstep(0.0,1.0,blend))
  if blend == 1: lane = target

func is_bend() -> bool:
 return DerbyTrack.bend(progress)

func grant_counter():
 if overdrive_active:
  overdrive_refill=minf(DerbyConfig.OVERDRIVE_MAX_ENERGY,overdrive_refill+DerbyConfig.OVERDRIVE_COUNTER_ENERGY)
 else:
  energy=minf(DerbyConfig.OVERDRIVE_MAX_ENERGY,energy+DerbyConfig.OVERDRIVE_COUNTER_ENERGY)
 counter_time=DerbyConfig.COUNTER_BOOST_SECONDS
 invincible=DerbyConfig.COUNTER_INVINCIBILITY
 protection=maxf(protection,invincible)
 effect=0
 multiplier=1
 stun=0
 knockdown=0
 recovery=0
 overdrive_stall=0
 charm=0

func attack_guarded() -> bool:
 return invincible>0 or (id==3 and overdrive_active)

func advance_energy(dt: float) -> bool:
 if not overdrive_active:return false
 overdrive_remaining=maxf(0,overdrive_remaining-dt)
 energy=DerbyConfig.OVERDRIVE_MAX_ENERGY*overdrive_remaining/DerbyConfig.OVERDRIVE_DURATION
 if overdrive_remaining>.00001:return false
 overdrive_remaining=0
 energy=overdrive_refill
 overdrive_refill=0
 overdrive_active=false
 return true
func save_state() -> Dictionary:
 var state: Dictionary={}
 for key in ["stride_phase","recovered_flash","lane_blocked_time","id","progress","y","lane","origin","target","blend","lane_start_y","lane_change_seconds","speed","effect","multiplier","stun","attempts","think","finished","counter_time","invincible","knockdown","recovery","protection","dash_time","dash_cooldown","dash_count","change_count","collision_count"]:state[key]=get(key)
 state.merge({"energy":energy,"overdrive_remaining":overdrive_remaining if overdrive_active else 0.0,"overdrive_refill":overdrive_refill,"overdrive_stall":overdrive_stall,"charm":charm,"ram_cooldowns":ram_cooldowns.duplicate(),"charm_cooldowns":charm_cooldowns.duplicate(),"overdrive_cooldown":overdrive_cooldown})
 return state
func restore_state(state: Dictionary):
 for key in state:
  if key in save_state():set(key,state[key])
 energy=clampf(energy,0,DerbyConfig.OVERDRIVE_MAX_ENERGY)
 overdrive_active=overdrive_remaining>0.0 and not finished
