class_name DerbyAI
extends RefCounted
static func gap(a: DerbyHorse,b: DerbyHorse) -> float:
 return DerbyTrack.gap(a.progress,b.progress)
static func tick(h: DerbyHorse, horses: Array, dt: float,allow_lane: bool=true,tactical: bool=false,cooperation_leader: int=-1,round_number: int=3,race_distance: float=3400.0,protect_id: int=-1,escort_target: DerbyHorse=null):
 if h.finished or h.knockdown>0:return
 if not allow_lane:return
 h.think -= dt
 if h.think > 0 or h.blend < 1 or absf(h.y-(140+h.lane*27)) > 2: return
 var caution: float=clampf((round_number-2)/6.0,0,1)
 h.think=randf_range(.8,1.5)+h.id*.06
 if tactical:
  h.think=randf_range(.55,.9) if round_number==2 else randf_range(lerpf(.30,.24,caution),lerpf(.49,.43,caution))
 if escort_target!=null and not escort_target.finished:
  var escort_gap: float=gap(h,escort_target)
  var lane_diff: int=escort_target.lane-h.lane
  var want_lane: int=-1
  if lane_diff==0 and absf(escort_gap)<120.0:
   for cand: int in [h.lane-1,h.lane+1]:
    if cand>=0 and cand<6 and DerbyAuto.crossing_clear(horses,h,cand,DerbyAuto.desired_course_speed(h)):
     want_lane=cand
     break
  elif abs(lane_diff)>1:
   var step_lane: int=h.lane+(1 if lane_diff>0 else -1)
   if step_lane>=0 and step_lane<6 and DerbyAuto.crossing_clear(horses,h,step_lane,DerbyAuto.desired_course_speed(h)):
    want_lane=step_lane
  if want_lane>=0:
   h.change(want_lane)
   h.think=.35
   return
 if (tactical and round_number>=3 and h.invincible>.55) or (h.overdrive_active and h.overdrive_remaining>.55):
  var lane:=shield_contact_lane(h,horses,cooperation_leader if h.id!=cooperation_leader else -1,protect_id)
  if lane>=0:
   h.change(lane)
   return
 if tactical:
  var forward:=DerbyAuto.desired_course_speed(h)
  var safe_forward: float=forward*safe_pace(h,horses,round_number)
  var center: int=h.lane
  var best_lane: int=center
  var forecast: float=96.0 if round_number==2 else lerpf(167.0,185.0,caution)
  var best_score: float=DerbyAuto.lane_score(horses,h,center,forward,forecast)
  for adjacent: int in [center-1,center+1]:
   if adjacent<0 or adjacent>=6 or not DerbyAuto.crossing_clear(horses,h,adjacent,safe_forward):continue
   var score: float=DerbyAuto.lane_score(horses,h,adjacent,forward,forecast)-.75
   if score>best_score:
    best_lane=adjacent
    best_score=score
  if best_lane!=center:h.change(best_lane)
  h.attempts=maxi(0,h.attempts-1)
  return
 var blocked := false
 for other in horses:
  if other != h and not other.finished and gap(h,other)>0 and gap(h,other)<85 and absf(other.y-h.y)<20: blocked = true
 if blocked:
  h.lane_blocked_time=.7
  h.think=minf(h.think,.35)
 var forced := h.attempts > 0
 if forced: h.attempts -= 1
 if not forced and not blocked:
  var rival_near := false
  for other in horses:
   if other != h and not other.finished and absf(gap(h,other))<110 and abs(other.lane-h.lane)>0: rival_near = true
  if not rival_near or randf()>h.aggression*.42: return
 var direction := -1 if randf()<0.5 else 1
 for d in [direction, -direction]:
  var next: int = h.lane+d
  if next < 0 or next > 5: continue
  var clear := true
  for other in horses:
   if other==h or other.finished or absf(other.y-(140+next*27))>=22:continue
   var gap_ahead: float=gap(h,other)
   if absf(gap_ahead)<(25 if forced else 53):clear=false
  if clear:
   h.change(next)
   return

static func safe_pace(h: DerbyHorse,horses: Array,round_number: int,escort_target: DerbyHorse=null,race_distance: float=3400.0) -> float:
 var base_pace: float=1.0
 if round_number>=2 and not h.attack_guarded() and not h.overdrive_active and h.knockdown<=0 and h.stun<=0:
  var pace:=DerbyAuto.safe_following_pace(h,horses,DerbyAuto.desired_course_speed(h))
  base_pace=lerpf(1.0,pace,clampf((round_number-1)/4.0,0,1))
 if escort_target!=null and not escort_target.finished and h.knockdown<=0 and h.stun<=0:
  var ahead: float=gap(h,escort_target)
  if ahead>0.0 and ahead<75.0 and absf(escort_target.y-h.y)<22.0:
   return minf(base_pace,.82)
  if ahead>55.0:
   return maxf(base_pace,1.08)
  if ahead<-20.0 and escort_target.progress<race_distance*.86:
   return minf(base_pace,.90)
 return base_pace

static func shield_contact_lane(h: DerbyHorse,horses: Array,only_target: int=-1,avoid_id: int=-1) -> int:
 var selected: int=-1
 var nearest: float=INF
 for other: DerbyHorse in horses:
  if other==h or other.finished or other.protection>0 or other.blend<1 or abs(other.lane-h.lane)!=1:continue
  if avoid_id>=0 and other.id==avoid_id:continue
  if only_target>=0 and other.id!=only_target:continue
  var ahead:=gap(h,other)
  if ahead>0 and ahead<nearest and ahead<DerbyConfig.BODY_LENGTH*.85+(h.speed-other.speed)*.65:
   nearest=ahead
   selected=other.lane
 return selected
