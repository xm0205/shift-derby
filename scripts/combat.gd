class_name DerbyCombat
extends RefCounted
const WARNING=DerbyConfig.COUNTER_WARNING
const WINDOW=DerbyConfig.COUNTER_WINDOW
const LATE_GRACE=.18
const PLAY_AREA=Rect2(0,34,640,292)
const PLAYER_ATTACK_MINIMUM=2
const BREAKAWAY_GAP=78.0
const COOP_ENTRY_GAP=DerbyTrack.LAP_LENGTH/3.0
const COOP_EXIT_GAP=DerbyTrack.LAP_LENGTH*.25
var cooperation_leader: int=-1
var feedback_kind: String=""
var feedback_time: float=0
var round_level: int=1
var pressure_clock: float=6
var next_pressure_progress: float=0
var pressure_step: float=0
var race_length: float=3400
var opening_sent:=false
var player_pressure:=0
var practice_clock:=2.0
var earned: Array[int]=[0,0,0,0,0,0]
var budgets: Array[int]=[]
var clocks: Array[float]=[]
var pending: Array=[]
var success_count:=0
var attack_count:=0
var assist_count:=0
var self_boost_count:=0
var ai_counter_count:=0
const CATCHUP_ENERGY=.7
const CATCHUP_ORB_SECONDS=22.0
const CATCHUP_ORB_LIMIT=2
var start_rushed:=false
var catchup_clock: Array=[0.0,0.0,0.0,0.0,0.0,0.0]
var catchup_orbs: Array=[0,0,0,0,0,0]
var assist_rewards: Array=[0,0,0,0,0,0]
func reset():
 cooperation_leader=-1
 feedback_kind=""
 feedback_time=0
 round_level=1
 pressure_clock=6
 next_pressure_progress=0
 pressure_step=0
 opening_sent=false
 start_rushed=false
 catchup_clock.fill(0.0)
 catchup_orbs.fill(0)
 assist_rewards.fill(0)
 player_pressure=0
 practice_clock=2.0
 earned.fill(0)
 budgets.assign([1,1,1,1,1,1])
 clocks.assign([8.0,11.0,14.0,17.0,20.0,23.0])
 pending.clear()
 success_count=0
 attack_count=0
 assist_count=0
 self_boost_count=0
 ai_counter_count=0
func schedule(r,attacker: int,target: int,range_limit: float=0,boost_trap: bool=false,leader_pressure: bool=false):
 var duration: float=DerbyDifficulty.warning(round_level)
 var close: float=randf_range(.12,maxf(.13,duration-DerbyDifficulty.window(round_level)-.20))
 pending.append({"range_limit":range_limit,"open":close+DerbyDifficulty.window(round_level),"close":close,"attacker":attacker,"target":target,"time":duration,"duration":duration,"window":DerbyDifficulty.window(round_level),"early":false,"ready_cued":false,"boost_trap":boost_trap,"leader_pressure":leader_pressure})
 attack_count+=1
 if target==r.player_id:
  player_pressure+=1
  r.announce("INCOMING ATTACK!",DerbyDifficulty.warning(round_level))
  r.sound.cue("warning")
func sample_counter(target_id: int) -> Dictionary:
 for event: Dictionary in pending:
  if event.target==target_id:return {"event":event,"time":float(event.time)}
 return {}

func counter_press(r,sample: Dictionary={}) -> bool:
 for event in pending:
  if event.target!=r.player_id:continue
  if sample.has("event") and not is_same(sample.event,event):continue
  var press_time: float=sample.get("time",event.time)
  if press_time>=event.get("close",0.0) and press_time<=event.get("open",event.get("window",WINDOW)) and not event.early:
   pending.erase(event)
   var h: DerbyHorse=r.horses[r.player_id]
   h.grant_counter()
   r.shift_charges=mini(DerbyConfig.shift_limit(round_level),r.shift_charges+1)
   feedback_kind="perfect"
   feedback_time=1.8
   r.announce("PERFECT COUNTER!",1.4)
   r.sound.cue("counter")

   success_count+=1
   r.dialogue.counter_result(event,true)
   r.dialogue.overdrive_line(h.id,"perfect")
  elif not event.early and press_time>event.get("open",WINDOW) and press_time<=event.get("open",WINDOW)+DerbyConfig.STANDARD_COUNTER_WINDOW:
   pending.erase(event)
   feedback_kind="normal"
   feedback_time=.65
   r.sound.cue("ready")
  elif not event.early:
   event.early=true
   event["failure_kind"]="late" if press_time<event.get("close",0.0) else "early"
   feedback_kind="late" if press_time<event.get("close",0.0) else "early"
   feedback_time=.9
   r.sound.cue(feedback_kind)
   r.announce("TOO LATE!" if feedback_kind=="late" else "TOO EARLY!",.5)
  return true
 if feedback_time>0 and feedback_kind in ["early","late"]:return true
 if r.counter_late>0:
  feedback_kind="late"
  feedback_time=.9
  r.announce("TOO LATE!",.5)
  return true
 return false
func tick(r,dt: float):
 feedback_time=maxf(0,feedback_time-dt)
 if r.practice_mode:
  practice_clock-=dt
  if practice_clock<=0 and pending.is_empty():
   schedule(r,(r.player_id+1)%6,r.player_id)
   practice_clock=3.5

 for event in pending.duplicate():
  event.time-=dt
  if event.target==r.player_id and event.time<=event.get("open",event.get("window",WINDOW)) and event.time>=event.get("close",0.0) and not event.early and not event.get("ready_cued",false):
   event.ready_cued=true
   r.sound.cue("ready")
  if event.time<=0:
   if r.overdrive.defers_attack(event):continue
   pending.erase(event)
   var target: DerbyHorse=r.horses[event.target]
   var attacker: DerbyHorse=r.horses[event.attacker]
   var range_limit: float=event.get("range_limit",0.0)
   if range_limit>0 and not move_in_range(r,attacker,target,range_limit,event.get("leader_pressure",false)):continue
   if not target.finished and not target.attack_guarded():
    if target.id!=r.player_id and try_ai_counter(r,target):continue
    var trap: bool=event.get("boost_trap",false)
    var prior_attempts: int=target.attempts
    target.hit(not trap)
    if not trap:
     exploit_opening(r,target)
    # This attack gains speed in the current lane, leaving the rider free to dodge.
    if trap:target.attempts=prior_attempts
    if event.target==r.player_id:
     r.dialogue.counter_result(event,false)
     feedback_kind=event.get("failure_kind","early") if event.early else "late"
     feedback_time=1.0
     r.sound.cue("late")
     r.counter_late=LATE_GRACE
     r.announce("TOO LATE!" if trap else "TOO LATE! BRAKE!",.8)
    elif PLAY_AREA.has_point(r.combat_screen(target)):
     r.dialogue.event(target.id,"collision" if trap else "brake")
     r.announce(("#%d BOOST > #%d" if trap else "#%d BRAKE # %d") % [event.attacker+1,event.target+1],.7)
    if trap:r.sound.cue("boost")
 if r.practice_mode:return
 opening_rush(r)
 catch_up(r,dt)
 var leading: float=-INF
 var second: float=-INF
 var first: DerbyHorse=null
 for horse in r.horses:
  if horse.finished:continue
  if horse.progress>leading:
   second=leading
   leading=horse.progress
   first=horse
  else:
   second=maxf(second,horse.progress)
 update_cooperation(r.horses,first)
 if cooperation_leader<0:ensure_player_pressure(r,leading)
 var pressure_rider: int=-1
 var reserved_rider: int=-1
 var leader_limit: float=205.0+round_level*14.0
 if cooperation_leader>=0:
  pressure_rider=cooperative_attacker(r,first,leader_limit,dt)
  if pressure_rider<0:
   var closest_gap: float=INF
   for horse: DerbyHorse in r.horses:
    if horse==first or horse.id==r.player_id or horse.finished or budgets[horse.id]<=0:continue
    var gap: float=leading-horse.progress
    if gap<closest_gap:
     closest_gap=gap
     reserved_rider=horse.id
 for attacker in r.horses:
  if attacker.id==r.player_id or attacker.finished or budgets[attacker.id]<=0:continue
  if attacker.stun>0 or attacker.knockdown>0:continue
  var final_stretch: bool=DerbyDifficulty.in_final_stretch(attacker.progress,race_length)
  if saving_final_charge(attacker,leading):continue
  clocks[attacker.id]-=dt
  if clocks[attacker.id]>0:continue
  clocks[attacker.id]=randf_range(.75,1.45) if round_level>=5 else randf_range(1.0,2.0)
  if cooperation_leader>=0:
   if attacker.id==cooperation_leader:continue
   if attacker.id==pressure_rider:
    spend_charge(attacker.id)
    schedule(r,attacker.id,first.id,leader_limit,false,true)
    continue
   elif can_spend_on_rivals(r.player_id) and (attacker.id!=reserved_rider or budgets[attacker.id]>1):
    if try_assist(r,attacker,leading,true) or try_self_boost(r,attacker,leading):continue
   if round_level<5 or pressure_rider>=0 or budgets[attacker.id]<2 or not can_spend_on_rivals(r.player_id):continue
  var target: DerbyHorse=null
  var best: float=-INF
  var selected_range: float=0.0
  var pressing_player: bool=false
  for opponent in r.horses:
   if opponent==attacker or opponent.finished or not can_pressure(opponent):continue
   if opponent.id==r.player_id and r.dialogue.is_bribed_ally(attacker.id):continue
   if opponent.id==r.player_id and player_pressure>=player_pressure_limit(opponent):continue
   if pending.any(func(e):return e.target==opponent.id):continue
   var leader: bool=opponent.progress>=leading-.01
   var breakaway: bool=leader and leading-second>=BREAKAWAY_GAP
   var limit: float=300.0 if breakaway else 150.0
   var closing_on_player: bool=leader and opponent.id==r.player_id and opponent.progress-attacker.progress>=8.0
   if closing_on_player:
    limit=205.0+round_level*14.0
    if not in_leader_range(r,attacker,opponent,limit):continue
   elif not move_in_range(r,attacker,opponent,limit):continue
   var gap: float=track_gap(attacker,opponent)
   var lanes: float=absf(opponent.y-attacker.y)/27.0
   if not leader and (gap<=0 or lanes>(2.0 if round_level>=2 else 1.15)):continue
   var score: float=150-absf(gap)-lanes*18
   if gap>0:score+=35+round_level*4
   if leader:score+=280 if breakaway else 15
   if closing_on_player:score+=60+round_level*15
   if opponent.id!=r.player_id and gap>0 and gap<135:score+=140+round_level*10
   if score>best:
    best=score
    target=opponent
    selected_range=limit
    pressing_player=closing_on_player
  if (target==null or target.id!=r.player_id) and not can_spend_on_rivals(r.player_id):continue
  if round_level>=4 and final_stretch and not pressing_player and try_self_boost(r,attacker,leading):continue
  if leading-second>=BREAKAWAY_GAP and (target==null or target.progress<leading-.01) and not pressing_player and can_spend_on_rivals(r.player_id):
   if try_assist(r,attacker,leading):continue
   if try_self_boost(r,attacker,leading):continue
   # Preserve the remaining charge when the horse has no useful move.
   continue
  if target!=null:
   var trap: bool=round_level>=3 and target.progress<leading-.01 and boost_trap_lane(r,target)
   spend_charge(attacker.id)
   schedule(r,attacker.id,target.id,selected_range,trap,pressing_player)
   if PLAY_AREA.has_point(r.combat_screen(attacker)):r.dialogue.event(attacker.id,"trap" if trap else "attack")
  else:try_self_boost(r,attacker,leading)

func update_cooperation(horses: Array,first: DerbyHorse):
 if first==null:
  cooperation_leader=-1
  return
 var chase_gap: float=COOP_ENTRY_GAP
 if round_level>=6 and first.progress>=race_length*.28:chase_gap=220.0
 elif round_level>=3 and first.progress>=race_length*.28:chase_gap=165.0
 var gap: float=chase_gap*.75 if cooperation_leader==first.id else chase_gap
 var behind: int=0
 for horse: DerbyHorse in horses:
  if not horse.finished and first.progress-horse.progress>gap:behind+=1
 cooperation_leader=first.id if behind>=(horses.size()-1)/2+1 else -1

func cooperative_attacker(r,first: DerbyHorse,limit: float,dt: float) -> int:
 if first.id!=r.player_id and not can_spend_on_rivals(r.player_id):return -1
 if not can_pressure(first) or (first.id==r.player_id and player_pressure>=player_pressure_limit(first)):return -1
 if pending.any(func(event):return event.target==first.id):return -1
 var chosen: int=-1
 var best: float=INF
 for horse: DerbyHorse in r.horses:
  if horse==first or horse.id==r.player_id or budgets[horse.id]<=0 or horse.stun>0 or horse.knockdown>0:continue
  if first.id==r.player_id and r.dialogue.is_bribed_ally(horse.id):continue
  if saving_final_charge(horse,first.progress):continue
  if clocks[horse.id]>dt or not move_in_range(r,horse,first,limit,true):continue
  var gap: float=first.progress-horse.progress
  if gap<best:
   chosen=horse.id
   best=gap
 return chosen

func saving_final_charge(horse: DerbyHorse,leading: float) -> bool:
 var gap: float=leading-horse.progress
 if round_level<4 or DerbyDifficulty.in_final_stretch(horse.progress,race_length):return false
 if budgets[horse.id]==1 and gap>190.0 and gap<650.0:return true
 var in_contention: bool=gap<240.0 and horse.progress>=race_length*.27
 return round_level>=7 and in_contention and budgets[horse.id]<=2 and horse.aggression<=.60

func player_pressure_limit(player: DerbyHorse) -> int:
 return DerbyDifficulty.open_attack_slots(round_level,player.progress/race_length)

func can_pressure(horse: DerbyHorse) -> bool:
 return not horse.attack_guarded() and not (horse.effect>0 and horse.multiplier<1.0) and horse.knockdown<=0

func try_assist(r,attacker: DerbyHorse,leading: float,cooperative: bool=false) -> bool:
 var chaser:=choose_chaser(r,attacker,leading,cooperative)
 if chaser==null:return false
 spend_charge(attacker.id)
 chaser.hit(false)
 if round_level>=4:
  if not attacker.overdrive_active:attacker.energy=minf(DerbyConfig.OVERDRIVE_MAX_ENERGY,attacker.energy+8.0)
  if not chaser.overdrive_active:chaser.energy=minf(DerbyConfig.OVERDRIVE_MAX_ENERGY,chaser.energy+5.0)
  assist_rewards[attacker.id]+=1
  if assist_rewards[attacker.id] in [2,4]:
   budgets[attacker.id]=mini(DerbyConfig.shift_limit(round_level),budgets[attacker.id]+1)
 assist_count+=1
 if r.mode=="race" and not r.dialogue.urgent():r.announce("#%d BOOST > #%d" % [attacker.id+1,chaser.id+1],.85)
 if chaser.id==r.player_id:
  r.sound.cue("boost")
  if is_instance_valid(r.battle_vfx):r.battle_vfx.trigger_assist(attacker.id,chaser.id,"ally")
 return true

func can_spend_on_rivals(player_id: int) -> bool:
 if player_pressure>=PLAYER_ATTACK_MINIMUM:return true
 var remaining: int=0
 for id in range(budgets.size()):
  if id!=player_id:remaining+=budgets[id]
 return remaining>PLAYER_ATTACK_MINIMUM-player_pressure

func ensure_player_pressure(r,leading: float):
 var player: DerbyHorse=r.horses[r.player_id]
 if player.finished or player_pressure>=player_pressure_limit(player) or not can_pressure(player) or feedback_time>0:return
 if pending.any(func(event):return event.target==r.player_id):return
 var chosen: DerbyHorse=null
 var best: float=-INF
 var limit: float=205.0+round_level*14.0
 for rival: DerbyHorse in r.horses:
  if rival==player or budgets[rival.id]<=0 or rival.stun>0 or rival.knockdown>0:continue
  if r.dialogue.is_bribed_ally(rival.id):continue
  if saving_final_charge(rival,leading):continue
  if not in_leader_range(r,rival,player,limit) and not in_attack_range(r,rival,player,150):continue
  var score: float=-absf(track_gap(rival,player))
  if score>best:
   best=score
   chosen=rival
 if chosen==null:return
 spend_charge(chosen.id)
 var same_group:=in_leader_range(r,chosen,player,limit)
 var trap: bool=(round_level<=2 or leading-player.progress>=BREAKAWAY_GAP) and boost_trap_lane(r,player)
 schedule(r,chosen.id,player.id,limit if same_group else 150.0,trap,same_group)

func boost_trap_lane(r,target: DerbyHorse) -> bool:
 if target.effect>0 or target.blend<1 or target.knockdown>0 or target.stun>0:return false
 var ahead: bool=false
 var escape_lanes: int=0
 for lane in [target.lane-1,target.lane+1]:
  if lane>=0 and lane<6:escape_lanes|=1<<lane
 for other: DerbyHorse in r.horses:
  if other==target or other.finished:continue
  var gap:=track_gap(target,other)
  if gap>48 and gap<108 and absf(target.y-other.y)<16 and other.speed<=target.speed+8:ahead=true
  if absf(gap)<70:escape_lanes&=~(1<<other.lane)
 return ahead and escape_lanes==0

func exploit_opening(r,slowed: DerbyHorse):
 var available: int=DerbyDifficulty.opening_after_hit(round_level)
 if available==0 or not can_spend_on_rivals(r.player_id):return
 var closing: Array[DerbyHorse]=[]
 var reach: float=200.0 if round_level>=7 else 145.0 if round_level>=4 else 110.0
 for horse: DerbyHorse in r.horses:
  if horse==slowed or horse.id==r.player_id or horse.finished or budgets[horse.id]<=0:continue
  if horse.progress-slowed.progress>52.0 or slowed.progress-horse.progress>reach or absf(slowed.y-horse.y)>108.0:continue
  if cooperation_leader>=0 and slowed.id!=cooperation_leader:continue
  closing.append(horse)
 closing.sort_custom(func(a,b):return absf(a.progress-slowed.progress)<absf(b.progress-slowed.progress))
 for horse: DerbyHorse in closing:
  if horse.knockdown>0 or horse.stun>0 or not can_spend_on_rivals(r.player_id):continue
  if try_self_boost(r,horse,slowed.progress,true):
   available-=1
   if available==0:break

func try_self_boost(r,horse: DerbyHorse,leading: float,opening: bool=false) -> bool:
 if horse.overdrive_active or horse.effect>0 or horse.dash_time>0 or horse.counter_time>0 or horse.stun>0 or horse.knockdown>0:return false
 if race_length-horse.progress<48:return false
 var behind: float=leading-horse.progress
 if not opening and behind<45 and not DerbyDifficulty.in_final_stretch(horse.progress,race_length):return false
 # A trapped horse should save the boost until it finds a usable lane.
 for rival in r.horses:
  if rival==horse or rival.finished:continue
  var gap: float=track_gap(horse,rival)
  if gap>0 and gap<46 and absf(horse.y-rival.y)<16:return false
 spend_charge(horse.id)
 horse.hit(false)
 self_boost_count+=1
 return true

# Two or three rivals spend a real charge to jump at the start, like the player.
func opening_rush(r):
 if start_rushed:return
 start_rushed=true
 var riders: Array=r.horses.filter(func(h):return h.id!=r.player_id and budgets[h.id]>0 and h.progress<race_length*.05)
 riders.shuffle()
 var count: int=2 if round_level<=3 else (3 if round_level<=5 else 4)
 for i in range(mini(count,riders.size())):
  budgets[riders[i].id]-=1
  riders[i].hit(false)
  self_boost_count+=1

# The last two horses slowly regain energy and a limited number of charges.
func catch_up(r,dt: float):
 if round_level<3:return
 var alive: Array=r.horses.filter(func(h):return not h.finished)
 if alive.size()<3:return
 alive.sort_custom(func(a,b):return a.progress<b.progress)
 var cap: int=DerbyConfig.shift_limit(round_level)
 for i in range(2):
  var h: DerbyHorse=alive[i]
  if h.progress<race_length*.15:continue
  if not h.overdrive_active:h.energy=minf(DerbyConfig.OVERDRIVE_MAX_ENERGY,h.energy+CATCHUP_ENERGY*dt)
  catchup_clock[h.id]+=dt
  if catchup_clock[h.id]<CATCHUP_ORB_SECONDS or catchup_orbs[h.id]>=CATCHUP_ORB_LIMIT:continue
  catchup_clock[h.id]=0.0
  if h.id==r.player_id:
   if r.shift_charges>=cap:continue
   r.shift_charges+=1
  else:
   if budgets[h.id]>=cap:continue
   budgets[h.id]+=1
  catchup_orbs[h.id]+=1

func spend_charge(horse_id: int):
 budgets[horse_id]-=1
 clocks[horse_id]=maxf(2.6,9.4-round_level*.82)+randf_range(0,1.5)

func choose_chaser(r,attacker: DerbyHorse,leading: float,cooperative: bool=false) -> DerbyHorse:
 var chaser: DerbyHorse=null
 var best_score: float=-INF
 for horse in r.horses:
  if horse==attacker or horse.finished or horse.progress>=leading-.01:continue
  var gap: float=horse.progress-attacker.progress
  if cooperative:
   if horse.id==r.player_id or gap< -52.0 or gap>190.0 or absf(horse.y-attacker.y)>81.0:continue
  elif gap<=0 or gap>150 or leading-horse.progress>500 or not in_attack_range(r,attacker,horse,150):continue
  if horse.effect>0 or horse.dash_time>0 or horse.counter_time>0:continue
  if horse.stun>0 or horse.knockdown>0 or horse.recovery>0:continue
  if pending.any(func(e):return e.target==horse.id):continue
  var score: float=horse.progress+(horse.speed-horse.base)*.9
  if score>best_score:
   chaser=horse
   best_score=score
 return chaser

func track_gap(attacker: DerbyHorse,target: DerbyHorse) -> float:
 var lap: float=DerbyTrack.LAP_LENGTH
 return fposmod(target.progress-attacker.progress+lap*.5,lap)-lap*.5

func in_attack_range(r,attacker: DerbyHorse,target: DerbyHorse,limit: float) -> bool:
 return (not attacker.finished and not target.finished
  and absf(track_gap(attacker,target))<=limit and absf(target.y-attacker.y)<=54
  and PLAY_AREA.has_point(r.combat_screen(attacker)) and PLAY_AREA.has_point(r.combat_screen(target)))

func in_leader_range(r,attacker: DerbyHorse,target: DerbyHorse,limit: float) -> bool:
 return (not attacker.finished and not target.finished
  and absf(target.progress-attacker.progress)<=limit and absf(target.y-attacker.y)<=27.0*(3 if round_level<=2 else 4)
  and PLAY_AREA.has_point(r.combat_screen(attacker)) and PLAY_AREA.has_point(r.combat_screen(target)))

func move_in_range(r,attacker: DerbyHorse,target: DerbyHorse,limit: float,leader_pressure: bool=false) -> bool:
 if attacker.id==r.player_id or target.id==r.player_id:
  return in_leader_range(r,attacker,target,limit) if leader_pressure else in_attack_range(r,attacker,target,limit)
 if attacker.finished or target.finished:return false
 var gap: float=target.progress-attacker.progress if leader_pressure else track_gap(attacker,target)
 var width: float=27.0*(3 if round_level<=2 else 4) if leader_pressure else 54.0
 return absf(gap)<=limit and absf(target.y-attacker.y)<=width

func try_ai_counter(r,target: DerbyHorse) -> bool:
 if target.finished or target.attack_guarded() or target.knockdown>0 or target.stun>0:return false
 var chance: float=DerbyDifficulty.counter_odds(round_level)
 if randf()>=chance:return false
 target.grant_counter()
 ai_counter_count+=1
 if budgets[target.id]<DerbyConfig.shift_limit(round_level) and earned[target.id]<2:
  budgets[target.id]+=1
  earned[target.id]+=1
 if PLAY_AREA.has_point(r.combat_screen(target)):
  r.sound.cue("ai_counter")
  r.dialogue.event(target.id,"ai_counter",true,1)
  if sample_counter(r.player_id).is_empty():
   var name_str: String=DerbyBetting.ZH[target.id] if r.language=="zh" else DerbyBetting.NAMES[target.id]
   r.announce("【%s】完美反击！" % name_str if r.language=="zh" else "#%d %s PERFECT COUNTER!" % [target.id+1,name_str],.8)
 return true

func save_state() -> Dictionary:
 return {"assist_rewards":assist_rewards.duplicate(),"start_rushed":start_rushed,"catchup_clock":catchup_clock.duplicate(),"catchup_orbs":catchup_orbs.duplicate(),"earned":earned.duplicate(),"round_level":round_level,"pressure_clock":pressure_clock,"next_pressure_progress":next_pressure_progress,"pressure_step":pressure_step,"race_length":race_length,"opening_sent":opening_sent,"player_pressure":player_pressure,"practice_clock":practice_clock,"budgets":budgets.duplicate(),"clocks":clocks.duplicate(),"pending":pending.duplicate(true),"success_count":success_count,"attack_count":attack_count,"assist_count":assist_count,"self_boost_count":self_boost_count,"cooperation_leader":cooperation_leader,"feedback_kind":feedback_kind,"feedback_time":feedback_time}
func restore_state(state: Dictionary):
 for key in state:
  if key=="earned":earned.assign(state[key])
  elif key=="budgets":budgets.assign(state[key])
  elif key=="clocks":clocks.assign(state[key])
  elif key in save_state():set(key,state[key])

func configure(level: int,distance: float):
 round_level=clampi(level,1,DerbyBetting.ROUND_LIMIT)
 race_length=distance
 earned.fill(0)
 start_rushed=false
 catchup_clock.fill(0.0)
 catchup_orbs.fill(0)
 assist_rewards.fill(0)
 budgets.fill(DerbyConfig.shift_limit(round_level))
 for i in range(6):clocks[i]=maxf(2.8,5.6-round_level*.32)+i*.55
 pressure_clock=6
