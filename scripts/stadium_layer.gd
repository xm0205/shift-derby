extends Node2D
@export var kind: int=0
const OFFICIAL=preload("res://assets/ui/cut/official_map.png")
func _draw():
 if kind==0:
  draw_rect(Rect2(-2048,-2048,4096,4096),Color("477440"))
  draw_texture_rect(OFFICIAL,Rect2(4,39,632,284),false)
 if kind==2:
  var r=get_parent().get_parent()
  var a:=DerbyTrack.map_position(r.race_distance,-.5)
  var b:=DerbyTrack.map_position(r.race_distance,5.5)
  for i in range(12):draw_line(a.lerp(b,i/12.0),a.lerp(b,(i+1)/12.0),Color.WHITE if i%2==0 else Color("20233d"),2.0)
