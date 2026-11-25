extends SceneTree

func _initialize():call_deferred("run")

func sample_accounting():
 var b:=DerbyBetting.new()
 b.prepare(1789)
 b.amount=200
 b.selected=4
 assert(b.confirm())
 var finish: Array=[2,4,3,0,5,1]
 var expected: Array=[]
 for id in range(6):
  var place:=finish.find(id)+1
  expected.append(-200 if place>3 else roundi(200*(b.odds[id]-1.0)*DerbyBetting.PODIUM_SHARE[place-1]))
 b.settle(2,finish)
 assert(b.rider_results[1].net==expected and b.net==expected[4] and b.funds==300+b.net)
 var saved: Dictionary=b.save_state()
 b.settle(2,finish)
 assert(b.save_state()==saved)
 var loaded:=DerbyBetting.new()
 loaded.restore_state(saved)
 assert(loaded.rider_standings()==b.rider_standings())
 var ranks:=loaded.rider_standings()
 for i in range(1,6):assert(ranks[i-1].total>=ranks[i].total)
 loaded.funds=1
 assert(loaded.rescue() and loaded.rider_results.is_empty() and loaded.round_number==0)
 loaded.new_game()
 loaded.prepare(1789)
 loaded.funds=50000
 loaded.amount=0
 assert(loaded.confirm())
 loaded.settle(2,finish)
 assert(loaded.rider_standings().all(func(row):return row.total==0))
 assert(loaded.campaign_outcome()=="ongoing")
 print("PASS payout-derived per-rider net, sorted totals, tie by race place, idempotent settlement and rescue rollback")

func capture(r,name: String):
 if DisplayServer.get_name()=="headless":return
 await process_frame
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 assert(image.save_png("res://output/round8/"+name+".png")==OK)

func run():
 sample_accounting()
 var r=load("res://main.tscn").instantiate()
 root.add_child(r)
 await process_frame
 r.set_process(false)
 r.sound.muted=true
 r.new_game()
 var totals: Array[int]=[0,0,0,0,0,0]
 var seeds: Array=[24306,24529,24752,24975,25198,25427,25638,25861]
 var arguments: PackedStringArray=OS.get_cmdline_user_args()
 if arguments.size()==8:
  seeds=[]
  for argument in arguments:seeds.append(int(argument))
 for level in range(1,9):
  r.race_seed=seeds[level-1]
  r.begin_round()
  assert(r.mode=="betting","Campaign must enter the next round")
  var b: DerbyBetting=r.betting
  b.selected=posmod(seeds[level-1],6)
  b.amount=b.maximum() if b.funds<DerbyBetting.ROUND_GATES[level-1]*2 else maxi(50,roundi(b.funds*.20))
  var initial_wallet: int=b.funds
  var stake: int=b.amount
  var odds: Array=b.odds.duplicate()
  r.place_bet()
  if r.pre_race_deal:r.launch_confirmed_race()
  r.countdown=0
  assert(r.mode=="race" and b.round_number==level and b.funds==initial_wallet-stake)
  var own: DerbyHorse=r.horses[r.player_id]
  var points: Array=[.28,.56,.81] if level<=3 else [.23,.44,.65,.85] if level<=5 else [.19,.37,.55,.73,.86]
  var used: int=0
  for step in range(14000):
   var warning: Dictionary=r.combat.sample_counter(r.player_id)
   if not warning.is_empty() and warning.event.time<=warning.event.open and warning.event.time>=warning.event.close:
    r.request_counter()
   if warning.is_empty():
    if used<points.size() and own.progress>=r.race_distance*points[used] and r.apply_shift(own,false):used+=1
    if own.energy>=DerbyConfig.OVERDRIVE_MAX_ENERGY:r.overdrive.start(r,own)
   r._process(.05)
   if r.mode!="race":break
  assert(r.order.size()==6 and r.mode=="leaderboard","Automatic leaderboard after the race")
  assert(b.settled and b.rider_results.size()==level)
  for id in range(6):
   var place: int=r.order.find(id)+1
   var net: int=roundi(stake*(odds[id]-1.0)*DerbyBetting.PODIUM_SHARE[place-1]) if place<=3 else -stake
   assert(b.rider_results[level].net[id]==net)
   totals[id]+=net
  for row: Dictionary in b.rider_standings():assert(row.total==totals[row.rider])
  var wallet: int=b.funds
  b.settle(r.order[0],r.order)
  assert(b.funds==wallet and b.rider_results.size()==level)
  print("ROUND ",level," rider=",r.player_id+1," rank=",r.order.find(r.player_id)+1," stake=",stake," wallet=",wallet," standings=",b.rider_standings())
  if level in [3,8]:
   r.language="zh"
   r.show_leaderboard()
   await capture(r,"group28-standings-zh-"+str(level))
   r.language="en"
   r.show_leaderboard()
   await capture(r,"group28-standings-en-"+str(level))
   r.language="zh"
  r.show_menu("results")
  r.show_leaderboard()
  assert(b.funds==wallet)
  await process_frame
  if level<8:
   assert(b.campaign_outcome()=="ongoing","Seed must reach the next round gate")
   var next_button: Button=r.menu_layer.find_child("LeaderboardNext",true,false)
   assert(next_button!=null and next_button.visible and not next_button.disabled)
   next_button.pressed.emit()
   assert(r.mode=="betting")
 assert(r.betting.rider_results.size()==8)
 var result: Array=r.betting.rider_standings()
 assert(result[0].total==totals.max())
 r.save_settings()
 r.queue_free()
 await process_frame
 await process_frame
 var restored=load("res://main.tscn").instantiate()
 root.add_child(restored)
 await process_frame
 restored.set_process(false)
 assert(restored.betting.rider_standings()==result)
 restored.show_leaderboard()
 assert(restored.mode=="leaderboard" and restored.order.size()==6)
 restored.begin_round()
 assert(restored.mode=="campaign_end")
 print("PASS eight full physics races, round transition, eight persistent entries, final champion and reload")
 restored.queue_free()
 await process_frame
 quit()
