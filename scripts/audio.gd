class_name DerbyAudio
extends Node
const SOUNDS={
 "rider_chat":preload("res://assets/audio/Coins/dialogue_tick.ogg"),
 "crowd_cheer":preload("res://assets/audio/Crowd/sports_cheer.wav"),"crowd_win":preload("res://assets/audio/Crowd/finish_cheer.wav"),
 "crowd_gasp":preload("res://assets/audio/Crowd/crowd_gasp.wav"),"cannon":preload("res://assets/audio/Celebration/confetti_pop.wav"),
 "neigh":preload("res://assets/audio/Horses/horse_neigh.wav"),"firework":preload("res://assets/audio/Celebration/firework.wav"),
 "count":preload("res://assets/audio/count.wav"),"go":preload("res://assets/audio/Actions/starting_shot.wav"),
 "boost":preload("res://assets/audio/boost.wav"),"brake":preload("res://assets/audio/brake.wav"),
 "warning":preload("res://assets/audio/warning.wav"),"ready":preload("res://assets/audio/ready.wav"),
 "early":preload("res://assets/audio/early.wav"),"late":preload("res://assets/audio/late.wav"),
 "counter":preload("res://assets/audio/Actions/perfect_counter_voice.wav"),"ai_counter":preload("res://assets/audio/counter.wav"),"overdrive":preload("res://assets/audio/Actions/overdrive_voice.mp3"),"win":preload("res://assets/audio/win.wav"),
 "lose":preload("res://assets/audio/lose.wav"),"finish":preload("res://assets/audio/finish.wav"),
 "final":preload("res://assets/audio/final.wav"),"hit":preload("res://assets/audio/Actions/Kenney_impact_sounds/Ready/impactSoft_medium_000.wav"),
 "heavy_hit":preload("res://assets/audio/Actions/Kenney_impact_sounds/Ready/impactPunch_heavy_000.wav"),"fall":preload("res://assets/audio/Actions/Kenney_impact_sounds/Ready/impactSoft_heavy_000.wav"),
 "click":preload("res://assets/audio/click.wav"),"hoof":preload("res://assets/audio/gallop_recorded.wav")}
const LOCAL_COUNTER_VOICE="res://assets/audio/Actions/perfect_counter_voice.wav"
# Keep a preloaded handle so the perfect-counter voice is part of the exported
# pack. A bare load() at runtime is not a dependency and got stripped from the
# build, silently falling back to the plain impact sound.
const LOCAL_COUNTER_STREAM=preload("res://assets/audio/Actions/perfect_counter_voice.wav")
const CUE_GAIN={"rider_chat":.18,"crowd_gasp":.25,"crowd_cheer":.35,"crowd_win":.45,"cannon":.5,"firework":.3,"neigh":.55,"ai_counter":.65,"overdrive":1.15}
const PRIORITY_CUES=["counter","overdrive","warning","ready","go","win","lose","finish","final","early","late"]
const RAM_CUES={
 "ram":preload("res://assets/audio/Actions/overdrive_ram.wav"),
 "hit":preload("res://assets/audio/Actions/overdrive_hit.wav"),
 "knockback":preload("res://assets/audio/Actions/overdrive_knockback_voice.mp3"),
}
const RAM_GAIN={"ram":.70,"hit":.88,"knockback":.79}
var muted:=false:
 set(value):
  muted=value
  if muted:stop_ram_cues()
  refresh_levels()
var master_volume: float=.65:
 set(value):
  master_volume=clampf(value,0,1)
  if master_volume==0:stop_ram_cues()
  refresh_levels()
var hoof_volume: float=.45:
 set(value):
  hoof_volume=clampf(value,0,1)
  refresh_levels()
var pool: Array[AudioStreamPlayer]=[]
var crowd: AudioStreamPlayer
var crowd_level: float=.25
var reaction_cooldown: float=0
var gallop: AudioStreamPlayer
var ram_player: AudioStreamPlayer
var ram_kind: String=""
var ram_start_cooldown: float=0.0
var knockback_pending: bool=false
var device_check_clock: float=0.0
var last_devices: PackedStringArray=PackedStringArray()
var racing_active: bool=false
var crowd_active: bool=false
func _ready():
 if DisplayServer.get_name()!="headless":
  AudioServer.set_bus_mute(0,false)
  AudioServer.set_bus_volume_db(0,0.0)
  AudioServer.output_device="Default"
  last_devices=AudioServer.get_output_device_list()
 for i in range(8):
  var player:=AudioStreamPlayer.new()
  add_child(player)
  pool.append(player)
 ram_player=AudioStreamPlayer.new()
 add_child(ram_player)
 ram_player.finished.connect(finish_ram_cue)
 gallop=AudioStreamPlayer.new()
 var stream: AudioStreamWAV=SOUNDS.hoof.duplicate()
 stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
 stream.loop_begin=0
 stream.loop_end=stream.data.size()/2
 gallop.stream=stream
 add_child(gallop)
 crowd=AudioStreamPlayer.new()
 var ambience: AudioStreamWAV=load("res://assets/audio/crowd_ambient.wav").duplicate()
 ambience.loop_mode=AudioStreamWAV.LOOP_FORWARD
 ambience.loop_end=ambience.data.size()/2
 crowd.stream=ambience
 add_child(crowd)
 refresh_levels()
func _process(dt):
 reaction_cooldown=maxf(0,reaction_cooldown-dt)
 ram_start_cooldown=maxf(0.0,ram_start_cooldown-dt)
 device_check_clock-=dt
 if device_check_clock<=0.0:
  device_check_clock=1.5
  sync_output_device(false)
func sync_output_device(force: bool=false):
 if DisplayServer.get_name()=="headless":return
 var devices: PackedStringArray=AudioServer.get_output_device_list()
 if not force and devices==last_devices:return
 last_devices=devices
 AudioServer.set_bus_mute(0,false)
 AudioServer.set_bus_volume_db(0,0.0)
 AudioServer.output_device="Default"
 refresh_levels()
 if racing_active and not muted and master_volume>0 and hoof_volume>0 and is_instance_valid(gallop):
  gallop.stop()
  gallop.play()
 if crowd_active and not muted and master_volume>0 and is_instance_valid(crowd):
  crowd.stop()
  crowd.play()
func refresh_levels():
 if DisplayServer.get_name()!="headless":
  AudioServer.set_bus_mute(0,false)
  AudioServer.set_bus_volume_db(0,0.0)
 var volume: float=0.0 if muted else master_volume
 for player in pool:player.volume_db=linear_to_db(maxf(.00001,volume*.55*float(player.get_meta("cue_gain",1.0))))
 if is_instance_valid(gallop):gallop.volume_db=linear_to_db(maxf(.00001,volume*hoof_volume*.70))
 if is_instance_valid(crowd):crowd.volume_db=linear_to_db(maxf(.00001,volume*crowd_level))
 if is_instance_valid(ram_player):ram_player.volume_db=linear_to_db(maxf(.00001,volume*.55*float(RAM_GAIN.get(ram_kind,1.0))))

func play_ram_cue(kind: String):
 if muted or master_volume<=0:return
 ram_kind=kind
 ram_player.stream=RAM_CUES[kind]
 ram_player.volume_db=linear_to_db(master_volume*.55*float(RAM_GAIN[kind]))
 ram_player.play()

func ram_started():
 if muted or master_volume<=0 or ram_player.playing or ram_start_cooldown>0:return
 ram_start_cooldown=.36
 play_ram_cue("ram")

func ram_hit(knockback: bool):
 if muted or master_volume<=0:return
 knockback_pending=knockback_pending or knockback
 if ram_player.playing and ram_kind=="hit":return
 play_ram_cue("hit")

func finish_ram_cue():
 if ram_kind=="hit" and knockback_pending:
  knockback_pending=false
  play_ram_cue("knockback")
 else:ram_kind=""

func stop_ram_cues():
 knockback_pending=false
 ram_start_cooldown=0.0
 ram_kind=""
 if is_instance_valid(ram_player):ram_player.stop()
func set_crowd(active: bool,intensity: float=.25):
 crowd_active=active
 if not is_instance_valid(crowd):return
 crowd_level=intensity
 refresh_levels()
 if active and not muted and master_volume>0:
  if not crowd.playing:crowd.play()
 else:crowd.stop()
func stop_dialogue_cues():
 for player in pool:
  if player.playing and player.get_meta("cue_kind","")=="rider_chat":player.stop()
func cue(kind: String):
 if muted or master_volume<=0:return
 if kind in ["warning","ready","counter"]:stop_dialogue_cues()
 if kind.begins_with("crowd_"):
  if reaction_cooldown>0:return
  reaction_cooldown=1.5
 var chosen: AudioStreamPlayer=null
 for player in pool:
  if not player.playing:
   chosen=player
   break
 if chosen==null and kind in PRIORITY_CUES:
  for player in pool:
   if not (player.get_meta("cue_kind","") in PRIORITY_CUES):
    chosen=player
    break
  if chosen==null and not pool.is_empty():chosen=pool[0]
 if chosen==null:return
 chosen.stop()
 chosen.set_meta("cue_kind",kind)
 chosen.set_meta("cue_gain",CUE_GAIN.get(kind,1.0))
 chosen.volume_db=linear_to_db(maxf(.00001,master_volume*.55*float(chosen.get_meta("cue_gain",1.0))))
 chosen.stream=LOCAL_COUNTER_STREAM if kind=="counter" else SOUNDS.get(kind,SOUNDS.click)
 chosen.play()
func set_racing(active: bool,pace: float=1.0):
 racing_active=active
 if not is_instance_valid(gallop):return
 active=active and not muted and master_volume>0 and hoof_volume>0
 if active:
  gallop.pitch_scale=clampf(pace,.8,1.35)
  if not gallop.playing:gallop.play()
 elif gallop.playing:gallop.stop()
func synth(kind: String) -> AudioStream:
 return SOUNDS.get(kind,SOUNDS.click)
func play_tone(_frequency: float,_duration: float,_volume: float=.22):cue("count")

func _exit_tree():
 stop_ram_cues()
 if is_instance_valid(crowd):
  crowd.stop()
  crowd.stream=null
 for player in pool:
  if is_instance_valid(player):
   player.stop()
   player.stream=null
 if is_instance_valid(gallop):
  gallop.stop()
  gallop.stream=null
