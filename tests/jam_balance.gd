extends SceneTree
func _initialize():call_deferred("run")

func judge(r,level:int,seed_id:int,skip_at:int) -> Dictionary:
 r.betting.new_game()
 r.betting.round_number=level
 r.race_seed=seed_id
 r.player_id=posmod(seed_id,6)
 r.reset()
 r.mode="race"
 r.countdown=0
 r.sound.muted=true
 var interventions: int=0
 var own: DerbyHorse=r.horses[r.player_id]
 var points: Array=[.28,.56,.81]
 if level>=6:points=[.19,.37,.55,.73,.86]
 elif level>=4:points=[.23,.44,.65,.85]
 var player_overdrives: int=0
 var skipped: int=0
 var last_event: Dictionary={}
 var seen: int=0
 var landed: int=0
 var ai_overdrives: int=0
 var active_rivals: int=0
 var team_ticks: int=0
 for step in range(12000):
  var warning: Dictionary=r.combat.sample_counter(r.player_id)
  if not warning.is_empty():
   var event: Dictionary=warning.event
   if float(event.time)>=float(event.close) and float(event.time)<=float(event.open):
    if not is_same(event,last_event):
     last_event=event
     seen+=1
     if skip_at<0 or skip_at==seen or (skip_at==12 and seen<=2):
      skipped+=1
     else:
      r.request_counter()
  if warning.is_empty() and interventions<points.size() and own.progress>=r.race_distance*float(points[interventions]):
   if r.apply_shift(own,false):interventions+=1
  if warning.is_empty() and own.energy>=DerbyConfig.OVERDRIVE_MAX_ENERGY and r.overdrive.start(r,own):player_overdrives+=1
  var late_before: float=r.counter_late
  r._process(.05)
  if r.counter_late>late_before:landed+=1
  if r.combat.cooperation_leader==r.player_id:team_ticks+=1
  var current_rivals: int=0
  for rival: DerbyHorse in r.horses:
   if rival==own or not rival.overdrive_active:continue
   current_rivals|=1<<rival.id
   if (active_rivals & (1<<rival.id))==0:ai_overdrives+=1
  active_rivals=current_rivals
  if r.order.size()==6:break
 assert(r.order.size()==6)
 return {"rank":r.order.find(r.player_id)+1,"warnings":r.combat.player_pressure,"skipped":skipped,"landed":landed,"perfect":r.combat.success_count,"player_overdrives":player_overdrives,"ai_perfect":r.combat.ai_counter_count,"ai_overdrives":ai_overdrives,"ai_assists":r.combat.assist_count,"team_seconds":snappedf(team_ticks*.05,.1)}

func run():
 var r=load("res://main.tscn").instantiate()
 root.add_child(r)
 r.set_process(false)
 r.resume_race()
 await process_frame
 var arguments: PackedStringArray=OS.get_cmdline_user_args()
 var levels: Array=[1,2,3,4] if "opening" in arguments else [5,6,7,8]
 var seeds: Array=[1224,7909,110,7089,8020,9317] if "fresh" in arguments else [3702,7501,8102,2205,4216,6461]
 if "matrix" in arguments:
  seeds=[]
  for i in range(24):seeds.append(24306+i*222+i%6)
 for argument in arguments:
  if argument.is_valid_int():levels=[int(argument)]
 for level: int in levels:
  var cohorts: Dictionary={"perfect":[],"skip_first":[],"skip_second":[],"skip_third":[],"skip_two":[],"skip_all":[]}
  var policies: Dictionary={"perfect":0,"skip_first":1,"skip_second":2,"skip_third":3,"skip_two":12,"skip_all":-1}
  if level in [3,4,5,6]:
   cohorts["skip_fourth"]=[]
   policies["skip_fourth"]=4
  for seed_id: int in seeds:
   for policy: String in cohorts:
    cohorts[policy].append(judge(r,level,seed_id,policies[policy]))
  print("ROUND_DETAIL ",level," ",JSON.stringify(cohorts))
  await process_frame
 r.queue_free()
 await process_frame
 print("PASS matched-seed race comparisons")
 quit()
