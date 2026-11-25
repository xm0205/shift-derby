class_name DerbyChampionUI
extends Control

const RIDERS=["red","blue","green","purple","gold","pink"]
var race
var video: VideoStreamPlayer
var still: TextureRect
var skip: Button
var continued: bool=false

func _ready():
 size=Vector2(640,360)
 var zh: bool=race.language=="zh"
 var key: String=RIDERS[race.betting.selected]
 var backdrop:=ColorRect.new()
 backdrop.color=Color.BLACK
 backdrop.size=size
 add_child(backdrop)
 still=TextureRect.new()
 still.name="ChampionPhoto"
 still.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 still.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 still.size=size
 still.texture=load("res://assets/champion/%s.png" % key)
 still.hide()
 add_child(still)
 video=VideoStreamPlayer.new()
 video.name="ChampionVideo"
 video.expand=true
 video.size=size
 video.loop=false
 video.stream=load("res://assets/champion/%s.ogv" % key)
 add_child(video)
 video.finished.connect(show_photo)
 skip=DerbyMenus.button(race,self,Rect2(515,324,115,26),"跳过" if zh else "SKIP",show_photo)
 skip.name="SkipVideo"
 _process(0.0)
 if video.stream!=null:video.play()
 else:show_photo()

func _process(_delta):
 if is_instance_valid(video):
  var level: float=0.0 if race.sound.muted else race.sound.master_volume
  video.volume_db=linear_to_db(maxf(.00001,level))

func show_photo():
 if continued:return
 continued=true
 video.stop()
 video.hide()
 still.show()
 skip.hide()
 var return_button: Button=DerbyMenus.button(race,self,Rect2(475,320,153,32),"返回结算" if race.language=="zh" else "RUN RESULTS",race.finish_champion_presentation)
 return_button.name="ChampionReturn"
