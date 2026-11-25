class_name DerbyReleaseCheck
extends RefCounted
static func run(r):
 if not FileAccess.file_exists("res://assets/presentation/rider_mounts.json"):
  push_error("Release check: missing RiderAnchor metadata")
  r.get_tree().quit(1)
  return
 var checks:=0
 var battle: SpriteFrames=load("res://assets/vfx/battle_animations.tres")
 if battle==null or battle.get_frame_count("perfect")!=8:
  push_error("Release check: missing battle animations")
  r.get_tree().quit(1)
  return
 var target_sheet:=Rect2(Vector2.ZERO,DerbyOverdrive.TARGET_ART.get_size())
 if not target_sheet.encloses(DerbyOverdrive.LOCKED_RING) or not target_sheet.encloses(DerbyOverdrive.TARGET_RING):
  push_error("Release check: missing ram targeting artwork")
  r.get_tree().quit(1)
  return
 var knockback: AudioStream=DerbyAudio.RAM_CUES.knockback
 if not knockback is AudioStreamMP3 or knockback.get_length()<=0:
  push_error("Release check: missing KNOCKBACK voice")
  r.get_tree().quit(1)
  return
 for key in ["name","banner","body","energy","ready","active","locked","petal"]:
  if DerbyOverdrive.texture(key)==null:
   push_error("Release check: missing Overdrive texture "+key)
   r.get_tree().quit(1)
   return
 for group in ["spark","wave","trail"]:
  for i in range(4):
   if DerbyOverdrive.texture("%s_%d" % [group,i])==null:
    push_error("Release check: missing Overdrive frames "+group)
    r.get_tree().quit(1)
    return
 for id in range(6):
  for stage in ["start","loop","end"]:
   if DerbyOverdrive.HORSE_AURA.get_frame_count("aura_%d_%s" % [id,stage])<4:
    push_error("Release check: missing stage 26 horse frames")
    r.get_tree().quit(1)
    return
 for key in DerbyAudio.SOUNDS:
  var stream: AudioStream=DerbyAudio.SOUNDS[key]
  if stream==null or stream.get_length()<=0:
   push_error("Release check: missing audio "+str(key))
   r.get_tree().quit(1)
   return
 for horse in r.horses:
  for state in ["run","boost","brake","hit","counter","win"]:
   var pose:=DerbyRider.pose(r,horse,state)
   if pose.texture==null or pose.size.x<1:
    push_error("Release check: missing rider pose")
    r.get_tree().quit(1)
    return
   checks+=1
 if DerbyBetting.TARGET_FUNDS!=50000 or DerbyBetting.ROUND_LIMIT!=8 or DerbyDifficulty.DISTANCE_LAPS!=[1.0,1.2,1.5,1.8,2.0,2.2,2.4,2.6]:
  push_error("Release check: incorrect current rules")
  r.get_tree().quit(1)
  return
 var official: Texture2D=load("res://assets/ui/cut/official_map.png")
 if official==null or official.get_width()!=1672 or official.get_height()!=941:
  push_error("Release check: missing official map")
  r.get_tree().quit(1)
  return
 if r.dialogue.data.riders.size()!=6 or r.dialogue.texture("face_4_9")==null or r.dialogue.favors.rules.riders.size()!=6:
  push_error("Release check: missing rider dialogue resources")
  r.get_tree().quit(1)
  return
 for art in ["guide_rounds","guide_deals","guide_overdrive"]:
  if r.dialogue.texture(art)==null:
   push_error("Release check: missing gameplay guide "+art)
   r.get_tree().quit(1)
   return
 for art in ["menu_clean","menu_logo_en","menu_logo_zh"]:
  if load("res://assets/ui/cut/"+art+".png")==null:
   push_error("Release check: missing menu art "+art)
   r.get_tree().quit(1)
   return
 if r.dialogue.data.nearby_interactions.size()!=6 or r.dialogue.texture("quick_interact")==null:
  push_error("Release check: missing quick interactions")
  r.get_tree().quit(1)
  return
 for i in range(20):
  if r.dialogue.texture("sticker_%d" % i)==null:
   push_error("Release check: missing emote %d" % i)
   r.get_tree().quit(1)
   return
 for id in range(6):
  var portrait: Texture2D=load("res://assets/ui/cut/leader_rider_%d.png" % id)
  if portrait==null or portrait.get_size()!=Vector2(192,180):
   push_error("Release check: incorrect leaderboard portrait")
   r.get_tree().quit(1)
   return
  var name_id: String=DerbyChampionUI.RIDERS[id]
  var movie: VideoStream=load("res://assets/champion/%s.ogv" % name_id)
  var photo: Texture2D=load("res://assets/champion/%s.png" % name_id)
  if not movie is VideoStreamTheora or photo==null or photo.get_size()!=Vector2(1280,720):
   push_error("Release check: missing champion video or freeze frame")
   r.get_tree().quit(1)
   return
  for pose in range(4):
   if r.dialogue.texture("vn_%d_%d" % [id,pose])==null:
    push_error("Release check: missing portrait %d / %d" % [id,pose])
    r.get_tree().quit(1)
    return
 var coin: AnimatedSprite2D=load("res://scripts/coin_sprites.gd").create("fly",16)
 var count: int=coin.sprite_frames.get_frame_count("fly")
 coin.free()
 if count!=8 or r.coins.GAIN.get_length()<=0:
  push_error("Release check: missing coin frames or audio")
  r.get_tree().quit(1)
  return
 print("PASS packaged release: "+str(checks)+" rider poses, six champion clips and photos, per-frame saddle metadata, official map size="+str(official.get_size())+"; editor="+str(OS.has_feature("editor")))
 r.get_tree().quit()
