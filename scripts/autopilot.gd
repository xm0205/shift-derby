class_name DerbyAuto
extends RefCounted

const LANES := 6
const LOOK_STEPS := [0.0, .22, .45, .70, .95, 1.25]
const BODY_MARGIN := 5.0

var think_clock := 0.0
var decisions := 0
var pace := 1.0

func reset() -> void:
 decisions = 0
 think_clock = 0
 pace = 1.0

func tick(r, dt: float) -> void:
 var horse: DerbyHorse = r.horses[r.player_id]
 if horse.knockdown > 0 or horse.stun > 0 or horse.recovery > 0 or horse.finished:
  pace = 1.0
  return
 if r.overdrive.steer_ram(r,horse):
  pace=1.0
  return

 var forward := desired_course_speed(horse)
 var lane := horse.target if horse.blend < 1.0 else horse.lane
 var following_pace := safe_following_pace(horse,r.horses,forward)
 pace = following_pace if following_pace < pace else move_toward(pace,following_pace,dt*2.6)

 think_clock = maxf(0.0,think_clock-dt)
 if horse.blend < 1.0 or think_clock > 0.0 or (horse.effect > 0 and horse.multiplier < 1.0):return
 think_clock = .16
 decisions += 1
 var wanted := lane
 var best := lane_score(r.horses,horse,lane,forward)
 for adjacent in [lane-1,lane+1]:
  if adjacent<0 or adjacent>=LANES:continue
  if not crossing_clear(r.horses,horse,adjacent,forward*pace):continue
  var score := lane_score(r.horses,horse,adjacent,forward)-1.2
  if score > best+.3:
   wanted = adjacent
   best = score
 if wanted != lane:
  horse.change(wanted)
  horse.attempts = maxi(0,horse.attempts-1)
  think_clock = .7
 elif horse.attempts>0:
  horse.attempts -= 1

static func course_speed(horse: DerbyHorse) -> float:
 return horse.speed * DerbyTrack.progress_factor(horse.progress,(horse.y-140.0)/27.0)

static func desired_course_speed(horse: DerbyHorse) -> float:
 var desired := horse.base * horse.multiplier
 desired *= lerpf(1.0,DerbyConfig.BEND_BOOST,DerbyTrack.bend_weight(horse.progress))
 if horse.dash_time>0 and horse.effect<=0:desired*=DerbyConfig.AUTO_BOOST
 if horse.counter_time>0:desired*=DerbyConfig.COUNTER_SPEED
 if horse.overdrive_active:desired=minf(desired*DerbyConfig.OVERDRIVE_SPEED,horse.base*DerbyConfig.OVERDRIVE_MAX_SPEED_FACTOR)
 if horse.overdrive_stall>0:desired*=DerbyConfig.OVERDRIVE_STALL_SPEED
 if horse.charm>0:desired*=DerbyConfig.OVERDRIVE_PINK_SPEED
 return desired*DerbyTrack.progress_factor(horse.progress,(horse.y-140.0)/27.0)

static func safe_following_pace(horse: DerbyHorse,horses: Array,forward: float) -> float:
 var pace:=1.0
 for other: DerbyHorse in horses:
  if other==horse or other.finished:continue
  var gap:=DerbyTrack.gap(horse.progress,other.progress)
  if gap<=0.0 or gap>175.0:continue
  if minf(absf(other.y-horse.y),absf(project_y(other,.7)-project_y(horse,.7)))>=DerbyConfig.BODY_WIDTH+2.0:continue
  var spacing:=DerbyConfig.BODY_LENGTH+13.0
  pace=minf(pace,clampf((course_speed(other)+(gap-spacing)/1.04)/maxf(1.0,forward),.12,1.0))
 return pace

static func project_y(horse: DerbyHorse,seconds: float) -> float:
 if horse.blend>=1.0:return horse.y
 var blend := minf(1.0,horse.blend+seconds/horse.lane_change_seconds)
 return lerpf(horse.lane_start_y,140.0+horse.target*27.0,smoothstep(0.0,1.0,blend))

static func crossing_clear(horses: Array,horse: DerbyHorse,lane: int,forward: float) -> bool:
 var target_y := 140.0+lane*27.0
 for other: DerbyHorse in horses:
  if other==horse or other.finished:continue
  var gap := DerbyTrack.gap(horse.progress,other.progress)
  if absf(gap)>195.0:continue
  var relative := course_speed(other)-forward
  for seconds: float in LOOK_STEPS:
   var lateral := lerpf(horse.y,target_y,smoothstep(0.0,DerbyConfig.LANE_CHANGE_SECONDS,seconds))
   if absf(gap+relative*seconds)>=DerbyConfig.BODY_LENGTH+BODY_MARGIN:continue
   if absf(project_y(other,seconds)-lateral)<DerbyConfig.BODY_WIDTH+1.0:
    # Permit an escape from current close traffic only when separation is increasing.
    if other.blend>=1.0 and other.lane==horse.lane and gap>0.0 and relative>=0.0 and absf(other.y-target_y)>DerbyConfig.BODY_WIDTH:continue
    return false
 return true

static func lane_score(horses: Array,horse: DerbyHorse,lane: int,forward: float,lookahead: float=90.0) -> float:
 var bend := maxf(DerbyTrack.bend_weight(horse.progress),DerbyTrack.bend_weight(horse.progress+lookahead))
 var score := (5.0-lane)*bend*2.0
 var lane_y := 140.0+lane*27.0
 for other: DerbyHorse in horses:
  if other==horse or other.finished:continue
  var gap := DerbyTrack.gap(horse.progress,other.progress)
  if gap < -70.0 or gap > 190.0 or absf(project_y(other,.8)-lane_y)>=DerbyConfig.BODY_WIDTH:continue
  var future_gap := gap+(course_speed(other)-forward)*1.05
  if gap>0.0:score -= 25.0*(1.0-smoothstep(54.0,159.0,future_gap))
  else:score -= 12.0*(1.0-smoothstep(38.0,80.0,absf(future_gap)))
 return score
