class_name DerbyCounterUI
extends RefCounted
static var textures: Dictionary={}
static func texture(key: String) -> Texture2D:
 if not textures.has(key):textures[key]=load("res://assets/ui/counter_v2/"+key+".png")
 return textures[key]
static func banner(r,key: String,canvas):
 var tex:=texture(key)
 var size:=tex.get_size()
 size*=minf(174.0/size.x,43.0/size.y)
 canvas.draw_texture_rect(tex,Rect2(Vector2(320-size.x*.5,36),size),false)
static func timing(event: Dictionary) -> Dictionary:
 var duration: float=maxf(.001,event.get("duration",DerbyCombat.WARNING))
 var window: float=event.get("window",DerbyCombat.WINDOW)
 return {"progress":clampf(1-event.time/duration,0,1),"start":clampf(1-event.get("open",window)/duration,0,1),"end":clampf(1-event.get("close",0.0)/duration,0,1),"ready":event.time>=event.get("close",0.0) and event.time<=event.get("open",window) and not event.early}
static func draw_timing(canvas: CanvasItem,event: Dictionary,origin: Vector2,elapsed: float):
 var t:=timing(event)
 var bar:=Rect2(origin+Vector2(7,24),Vector2(274,11))
 canvas.draw_texture_rect(texture("frame_blank"),Rect2(origin+Vector2(0,6),Vector2(288,36)),false)
 canvas.draw_texture_rect(texture("header"),Rect2(origin,Vector2(136,17)),false)
 canvas.draw_texture_rect(texture("prompt"),Rect2(origin+Vector2(149,3),Vector2(137,14)),false)
 var gold_x: float=bar.position.x+bar.size.x*t.start
 var standard_x: float=maxf(bar.position.x,gold_x-bar.size.x*DerbyConfig.STANDARD_COUNTER_WINDOW/maxf(.001,event.get("duration",DerbyCombat.WARNING)))
 var gold_end: float=bar.position.x+bar.size.x*t.end
 var rail:=texture("rail")
 canvas.draw_texture_rect_region(rail,Rect2(bar.position,Vector2(gold_x-bar.position.x,bar.size.y)),Rect2(25,10,650,73))
 canvas.draw_rect(Rect2(standard_x,bar.position.y,gold_x-standard_x,bar.size.y),Color("#418be2b0"))
 canvas.draw_texture_rect_region(rail,Rect2(Vector2(gold_x,bar.position.y),Vector2(gold_end-gold_x,bar.size.y)),Rect2(685,10,500,73),Color(.45,.45,.45) if event.early else Color(1.2,1.2,1.2) if t.ready else Color.WHITE)
 canvas.draw_texture_rect_region(rail,Rect2(Vector2(gold_end,bar.position.y),Vector2(bar.end.x-gold_end,bar.size.y)),Rect2(1200,10,280,73))
 var x: float=bar.position.x+bar.size.x*t.progress
 canvas.draw_texture_rect(texture("pointer_glow" if t.ready else "pointer"),Rect2(x-9,bar.position.y-4,18,19),false)
 if t.ready:
  canvas.draw_texture_rect(texture("flash"),Rect2(x-13,bar.position.y-7,26,26),false,Color(1,1,1,.45+.15*sin(elapsed*20)))
static func draw(r,canvas):
 var event: Dictionary={}
 for pending in r.combat.pending:
  if pending.target==r.player_id and not r.horses[r.player_id].finished:event=pending;break
 var own: DerbyHorse=r.horses[r.player_id]
 var zh: bool=r.language=="zh"
 if not event.is_empty():
  if event.early:banner(r,"early",canvas)
  draw_timing(canvas,event,Vector2(176,278),r.elapsed)
  DerbyPainter.text(r,Vector2(180,326),("已按早，等下一次预警" if zh else "TOO EARLY - WAIT FOR NEXT ATTACK") if event.early else ("短按 SHIFT 或点击 · 金区加能量" if zh else "TAP SHIFT OR CLICK / GOLD + ENERGY"),Color("fff0be"),9,canvas)

 elif r.combat.feedback_time>0:
  var banner_key: String={"perfect":"perfect","early":"early","normal":"counter"}.get(r.combat.feedback_kind,"late")
  banner(r,banner_key,canvas)
  if r.combat.feedback_kind=="perfect":
   var ptxt: String="暴走回能 1/3 · 干涉 +1" if zh else "+1/3 ENERGY / +1 SHIFT"
   var pw: float=r.font.get_string_size(ptxt,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
   DerbyPainter.text(r,Vector2(roundf(320.0-pw*.5),80),ptxt,Color("ffeeb4"),10,canvas)
  elif r.combat.feedback_kind=="normal":
   var ntxt: String="普通反击 · 等指针进金区" if zh else "COUNTER · WAIT FOR GOLD"
   var nw: float=r.font.get_string_size(ntxt,HORIZONTAL_ALIGNMENT_LEFT,-1,9).x
   DerbyPainter.text(r,Vector2(roundf(320.0-nw*.5),80),ntxt,Color("b7dcff"),9,canvas)
 elif own.invincible>0:
  DerbyPainter.ui(r,"cx_boost",Rect2(254,39,132,39),canvas)
