extends SceneTree

func _initialize():call_deferred("run")

func capture(name: String):
 if DisplayServer.get_name()=="headless":return
 await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://output/round8/"+name+".png")==OK)

func run():
 var race=load("res://main.tscn").instantiate()
 root.add_child(race)
 await process_frame
 race.set_process(false)
 race.language="zh"
 race.sound.muted=true
 var b: DerbyBetting=race.betting
 for id in range(6):
  b.new_game()
  b.prepare(2030)
  b.funds=75000
  b.round_number=8
  b.selected=id
  b.active=true
  b.settled=true
  var finish: Array=[id]
  for other in range(6):
   if other!=id:finish.append(other)
  for level in range(1,9):
   var profit: Array=[100,100,100,100,100,100]
   profit[id]=2000+level
   b.rider_results[level]={"net":profit,"order":finish.duplicate()}
  b.selected=(id+1)%6
  assert(not b.champion_presentation_available())
  race.show_leaderboard()
  var next: Button=race.menu_layer.find_child("LeaderboardNext",true,false)
  assert(next.text=="挑战结算")
  if id==0:
   await create_timer(DerbyLeaderboardUI.CHAMPION_PREVIEW_SECONDS+.3).timeout
   assert(race.mode=="leaderboard","A non-champion must remain on final standings")
  b.selected=id
  assert(b.champion_presentation_available())
  race.show_leaderboard()
  await process_frame
  if id==0:await capture("group28-final-podium-750")
  next=race.menu_layer.find_child("LeaderboardNext",true,false)
  assert(next.text.begins_with("自动播放"))
  var start_board: int=Time.get_ticks_msec()
  while race.mode=="leaderboard" and Time.get_ticks_msec()-start_board<6500:
   await create_timer(.1).timeout
  assert(race.mode=="champion")
  assert(Time.get_ticks_msec()-start_board>=3600)
  var playback: VideoStreamPlayer=race.menu_layer.find_child("ChampionVideo",true,false)
  var photo: TextureRect=race.menu_layer.find_child("ChampionPhoto",true,false)
  assert(playback!=null and playback.stream is VideoStreamTheora and playback.stream.file.ends_with(DerbyChampionUI.RIDERS[id]+".ogv"))
  assert(photo!=null and not photo.visible)
  assert(race.sound.pool.all(func(p):return not p.playing) and race.coins.players.all(func(p):return not p.playing))
  var start: int=Time.get_ticks_msec()
  while not photo.visible and Time.get_ticks_msec()-start<15000:
   await create_timer(.1).timeout
  var elapsed: float=(Time.get_ticks_msec()-start)/1000.0
  assert(photo.visible and not playback.is_playing() and elapsed>=7.2 and elapsed<10.5,
   "Rider %d elapsed %.3fs, photo %s, playing %s, position %.3f" % [id+1,elapsed,photo.visible,playback.is_playing(),playback.stream_position])
  var back: Button=race.menu_layer.find_child("ChampionReturn",true,false)
  assert(back!=null and back.visible)
  if id==0:await capture("group28-champion-freeze-750")
  back.pressed.emit()
  assert(race.mode=="campaign_end" and b.champion_seen and not b.champion_presentation_available())
  assert(b.funds==75000 and b.rider_results.size()==8)
  race.request_main_menu()
  assert(race.mode=="menu" and b.funds==75000 and b.rider_results.size()==8)
  if id==0:
   race.show_leaderboard()
   assert(race.menu_layer.find_child("LeaderboardNext",true,false).text=="挑战结算")
   race.request_main_menu()
  print("PASS champion rider ",id+1," auto started and played in ",elapsed," seconds, freeze, conditional gate, no double audio or settlement")
  await process_frame
 print("PASS all six Godot video playback and champion-photo transitions")
 b.new_game()
 race.show_menu("pause")
 race.request_main_menu()
 assert(race.mode=="exit_choice")
 print("PASS completed campaign returns directly to menu; unfinished campaign retains exit options")
 race.queue_free()
 await process_frame
 quit()
