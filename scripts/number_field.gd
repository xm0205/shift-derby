class_name DerbyNumberField
extends Control
const REGIONS = {
 "bx_horse_0":{
  "odds":Rect2(0.65702479,0.59926471,0.21900826,0.09558824),
  "name":Rect2(0.17768595,0.79411765,0.64462810,0.10294118),
 },
 "bx_horse_1":{
  "odds":Rect2(0.66527197,0.59926471,0.22175732,0.09558824),
  "name":Rect2(0.17991632,0.79411765,0.65271967,0.10294118),
 },
 "bx_horse_2":{
  "odds":Rect2(0.65271967,0.59926471,0.21757322,0.09558824),
  "name":Rect2(0.18410042,0.79411765,0.63598326,0.10294118),
 },
 "bx_horse_3":{
  "odds":Rect2(0.65236052,0.59926471,0.22317597,0.09558824),
  "name":Rect2(0.16738197,0.79411765,0.64806867,0.10294118),
 },
 "bx_horse_4":{
  "odds":Rect2(0.64806867,0.59926471,0.21888412,0.09558824),
  "name":Rect2(0.16309013,0.79411765,0.65236052,0.10294118),
 },
 "bx_horse_5":{
  "odds":Rect2(0.62962963,0.59926471,0.20987654,0.09558824),
  "name":Rect2(0.16460905,0.79411765,0.62139918,0.10294118),
 },
 "bx_amount":{
  "value":Rect2(0.285,0.295,0.430,0.215),
 },
 "bx_odds":{
  "value":Rect2(0.13986014,0.45698925,0.73426573,0.30107527),
 },
 "bx_return":{
  "value":Rect2(0.14506173,0.44086022,0.69135802,0.31182796),
 },
 "bx_profit":{
  "value":Rect2(0.12341772,0.44623656,0.69620253,0.30645161),
 },
 "bx_funds_full":{
  "value":Rect2(0.30497925,0.48734177,0.49585062,0.25949367),
 },
 "bx_round":{
  "value":Rect2(0.16000000,0.41000000,0.70000000,0.47000000),
 },
}
const INK_METRICS = {7:[-6,1,-6,1],8:[-7,1,-7,1],9:[-7,1,-8,1],10:[-8,1,-9,1],11:[-9,1,-10,2],12:[-10,1,-11,2],13:[-10,1,-12,2],14:[-11,1,-12,2],15:[-12,1,-13,2],16:[-13,1,-14,2],17:[-13,1,-15,2],18:[-14,1,-16,2],19:[-15,1,-17,2],20:[-16,1,-17,2],21:[-16,1,-18,2],22:[-17,1,-19,3],23:[-18,1,-20,3],24:[-19,1,-21,3]}
var font: Font
var text: String=""
var requested_size: int=18
var ink_color:=Color("282538")
static func put(r,parent,asset: String,slot: String,art_rect: Rect2,value: String,font_size: int=18,color: Color=Color("282538")):
 var field:=DerbyNumberField.new()
 var region: Rect2=REGIONS[asset][slot]
 field.position=art_rect.position+region.position*art_rect.size
 field.size=region.size*art_rect.size
 field.font=r.font
 field.text=value
 field.requested_size=font_size
 field.ink_color=color
 field.mouse_filter=Control.MOUSE_FILTER_IGNORE
 field.clip_contents=true
 parent.add_child(field)
 return field
func fitted_size() -> int:
 var pixel_size:=requested_size
 while pixel_size>7:
  var metric: Vector2=ink_metric(pixel_size)
  if font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixel_size).x<=size.x-1 and metric.y-metric.x<=size.y-.5:break
  pixel_size-=1
 return pixel_size
func ink_metric(pixel_size: int) -> Vector2:
 var chinese:=false
 for letter in text:
  if letter.unicode_at(0)>127:chinese=true
 var values: Array=INK_METRICS[pixel_size]
 return Vector2(values[2] if chinese else values[0],values[3] if chinese else values[1])
func ink_bounds() -> Rect2:
 var pixel_size:=fitted_size()
 var metric:=ink_metric(pixel_size)
 var width: float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixel_size).x
 return Rect2(Vector2((size.x-width)*.5,(size.y-(metric.y-metric.x))*.5),Vector2(width,metric.y-metric.x))
func _draw():
 var pixel_size:=fitted_size()
 var metric:=ink_metric(pixel_size)
 var width: float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixel_size).x
 var baseline: float=size.y*.5-(metric.x+metric.y)*.5
 draw_string(font,Vector2((size.x-width)*.5,baseline),text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixel_size,ink_color)
