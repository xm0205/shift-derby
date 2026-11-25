extends CanvasLayer
# Presentation only. Never writes to DerbyBetting.
var race
var shown: float=0
var target: int=0
var animation: Tween
var balance_label: Label
var prefix: String=""
var flying: Array[Node2D]=[]
var players: Array[AudioStreamPlayer]=[]
var ticks: int=0
var next_tick: float=0
var playing:=false
var base_color:=Color.WHITE
var initial_gap: float=1.0
const CoinSprites=preload("res://scripts/coin_sprites.gd")
const SPEND=preload("res://assets/audio/Coins/chip-lay-1.ogg")
const GAIN=preload("res://assets/audio/Coins/chips-stack-1.ogg")
const COUNT=preload("res://assets/audio/Coins/chips-collide-1.ogg")
const BIG=preload("res://assets/audio/Coins/chips-stack-6.ogg")
const LOSS=preload("res://assets/audio/Coins/card-place-1.ogg")
func _ready():
 layer=40
 transform=Transform2D(0,Vector2(2,2),0,Vector2.ZERO)
 for i in range(2):
  var p:=AudioStreamPlayer.new()
  add_child(p)
  players.append(p)
func _process(dt):
 for p in players:
  if race.sound.muted or race.sound.master_volume<=0:p.stop()
  p.volume_db=linear_to_db(maxf(.00001,race.sound.master_volume*.26))
  if p.playing and p.get_playback_position()>(.13 if p==players[0] else .4):p.stop()
 if playing:
  next_tick-=dt
  if next_tick<=0 and ticks>0:
   cue(COUNT,0)
   ticks-=1
   next_tick=.13
 if not playing and shown!=race.betting.funds:
  shown=race.betting.funds
 render_value(shown)
func cue(stream: AudioStream,slot: int=1):
 if race.sound.muted or race.sound.master_volume<=0:return
 var p: AudioStreamPlayer=players[slot]
 p.stop()
 p.stream=stream
 p.volume_db=linear_to_db(maxf(.00001,race.sound.master_volume*.26))
 p.play()
func render_value(value: float):
 shown=value
 if is_instance_valid(balance_label):
  balance_label.text=prefix+str(roundi(value))
  var highlight: float=sqrt(clampf(absf(target-shown)/initial_gap,0,1)) if playing else 0.0
  balance_label.add_theme_color_override("font_color",base_color.lerp(Color("fff1b9"),highlight))
func clear():
 if animation!=null:animation.kill()
 playing=false
 ticks=0
 for p in players:p.stop()
 for coin in flying:
  if is_instance_valid(coin):coin.queue_free()
 flying.clear()
 if is_instance_valid(balance_label):
  balance_label.text=prefix+str(race.betting.funds)
  balance_label.add_theme_color_override("font_color",base_color)
 balance_label=null
 shown=race.betting.funds
 target=race.betting.funds
func bind(label: Label,text_prefix: String):
 balance_label=label
 base_color=label.get_theme_color("font_color")
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 prefix=text_prefix
 render_value(shown)
func change(before: int,after: int,reward: bool=false):
 var start: float=shown if playing else float(before)
 var label=balance_label
 var text_prefix=prefix
 clear()
 balance_label=label
 if is_instance_valid(label):label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 prefix=text_prefix
 target=after
 initial_gap=maxf(1.0,absf(after-start))
 if is_equal_approx(start,float(after)):
  render_value(after)
  return
 playing=true
 render_value(start)
 var duration: float=.95 if reward else .30
 animation=create_tween()
 animation.tween_method(render_value,start,float(after),duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
 animation.tween_callback(finish)
 if reward:
  ticks=6 if after-before<1000 else 8
  next_tick=.10
  cue(BIG if after-before>=1000 else GAIN)
  spawn_fixed("spin",Vector2(571,250),13)
  if after-before>=1000:spawn_fixed("burst",Vector2(577,247),33)
  for i in range(8 if after-before>=1000 else 6):spawn_coin(i,duration)
 else:
  cue(SPEND)
  spawn_fixed("spend",Vector2(513,216) if is_instance_valid(balance_label) else Vector2(211,50),22)
func finish():
 playing=false
 ticks=0
 render_value(race.betting.funds)
 for p in players:p.stop()
 for coin in flying:
  if is_instance_valid(coin):coin.queue_free()
 flying.clear()
func spawn_fixed(kind: String,at: Vector2,size: float):
 var icon:=CoinSprites.create(kind,size)
 add_child(icon)
 flying.append(icon)
 icon.position=at
 if kind=="spend":icon.speed_scale=1.8
 icon.play()
 if kind!="spin":icon.animation_finished.connect(icon.queue_free)

func spawn_coin(i: int,duration: float):
 var coin:=CoinSprites.create("fly",15)
 add_child(coin)
 flying.append(coin)
 var start:=Vector2(542+i*6,248+(i%2)*4)
 coin.position=start
 var end:=Vector2(517,266)
 coin.hide()
 var move:=coin.create_tween()
 move.tween_interval(i*.045)
 move.tween_callback(func():coin.show();coin.play())
 var base_scale: Vector2=coin.scale
 move.tween_method(func(t: float):
  coin.position=start.lerp(end,t)+Vector2(0,-sin(t*PI)*15)
  coin.rotation=t*TAU*.6
  coin.scale=base_scale*lerpf(1.15,.65,t)
  coin.modulate=Color(1,1,.8,1-t*t)
 ,0.0,1.0,duration-.32)
 move.tween_callback(coin.queue_free)
