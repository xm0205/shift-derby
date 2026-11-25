extends Node2D
var visual_clock: float=0
var age: float=0
var celebrating: bool=false
var player_won: bool=false
var finish_count: int=0
var state: int=0
var cache: Dictionary={}
const CROWD=[Rect2(357,175,205,40),Rect2(1010,174,280,41),Rect2(19,854,254,56),Rect2(314,855,234,55),Rect2(1150,850,170,60),Rect2(1360,850,280,60)]
func art(key: String,rect: Rect2):
 if not cache.has(key):cache[key]=load("res://assets/presentation/"+key+".png")
 draw_texture_rect(cache[key],rect,false)
func reset():
 age=0
 visual_clock=0
 celebrating=false
 player_won=false
 finish_count=0
 state=0
func champion(id: int):
 if finish_count>0:return
 finish_count=1
 age=0
 celebrating=true
 player_won=id==get_parent().get_parent().player_id
 state=2
func advance(dt):
 var r=get_parent().get_parent()
 if r.paused and r.mode!="results":
  r.sound.set_crowd(false)
  return
 visual_clock+=dt
 if celebrating:age+=dt
 elif r.mode=="race" and r.horses.any(func(h):return h.progress>r.race_distance*.85):state=1
 r.sound.set_crowd(r.mode in ["race","results"],.12 if state==0 else .24 if state==1 else .36)
 queue_redraw()
func _draw():
 var r=get_parent().get_parent()
 for i in range(CROWD.size()):
  var rect: Rect2=CROWD[i]
  var screen:=Rect2(Vector2(4,39)+rect.position*Vector2(632.0/1672,284.0/941),rect.size*Vector2(632.0/1672,284.0/941))
  art("crowd_%d_%d_%d" % [i,state,(int(visual_clock*(3+state*2))+i)%4],screen)
 # Supplied group 15 spectators sit outside the course, above the near straight.
 var cheer_frame:=0 if state==0 else 1+int(visual_clock*4)%3
 art("supplied_spectators_"+str(cheer_frame),Rect2(112,88,72,21))
 art("supplied_spectators_"+str((cheer_frame+1)%4 if state>0 else 0),Rect2(435,88,72,21))
 var finish:=DerbyTrack.map_position(r.race_distance,2.5)
 art("finish_gate",Rect2(DerbyTrack.map_position(r.race_distance,6)-Vector2(26,40),Vector2(52,33)))
 art("advert",Rect2(278,98,42,19))
 for s in [100.0,1700.0,2100.0]:
  var p:=DerbyTrack.map_position(s,6.5)
  art("flag",Rect2(p-Vector2(3,17),Vector2(9+sin(visual_clock*(7 if state>0 else 4)+s)*.6,17)))
 if not celebrating or age>4:return
 for lane in [-1.5,6.5]:
  var p:=DerbyTrack.map_position(r.race_distance,lane)
  art("cannon_"+str(mini(3,int(age*6))),Rect2(p-Vector2(8,22),Vector2(16,27)))
 if age<2.8:
  for i in range(8 if player_won else 3):
   var p:=finish+Vector2(sin(i*4.7)*age*25,-age*28+age*age*8)
   art("confetti_"+str(i%4),Rect2(p-Vector2(10,10),Vector2(20,20)))
 if player_won:
  for i in range(3):
   art("balloon",Rect2(Vector2(160+i*140,292-age*24),Vector2(13,21)))
   if age<2:art("firework_"+str(i),Rect2(Vector2(210+i*90,64),Vector2(25,25)))
