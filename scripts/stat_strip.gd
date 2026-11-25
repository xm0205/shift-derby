class_name DerbyStatStrip
extends RefCounted

static func build(r,root: Control) -> Control:
 var strip:=Control.new()
 strip.position=Vector2(20,192)
 strip.size=Vector2(602,27)
 strip.mouse_filter=Control.MOUSE_FILTER_IGNORE
 root.add_child(strip)
 var backing:=ColorRect.new()
 backing.position=Vector2(1,2)
 backing.size=Vector2(598,24)
 backing.color=Color("111e3c")
 backing.mouse_filter=Control.MOUSE_FILTER_IGNORE
 strip.add_child(backing)
 if r.language=="zh":
  DerbyMenus.art(strip,"rider25/stats_header",Rect2(0,3,77,21)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 else:
  DerbyMenus.title(r,strip,Vector2(0,3),Vector2(77,21),"HORSE STATS",9,DerbyPainter.GOLD).mouse_filter=Control.MOUSE_FILTER_IGNORE
 return strip

static func show_stats(r,strip: Control,id: int):
 var old:=strip.get_node_or_null("Values")
 if is_instance_valid(old):
  strip.remove_child(old)
  old.queue_free()
 var panel:=Control.new()
 panel.name="Values"
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 strip.add_child(panel)
 var zh: bool=r.language=="zh"
 var horse: String=(DerbyBetting.ZH if zh else DerbyBetting.NAMES)[id]
 var badge: Label=DerbyMenus.title(r,panel,Vector2(72,2),Vector2(78,22),"#%d %s" % [id+1,horse],9,DerbyPainter.GOLD)
 badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var names: Array=["基础速度","超车倾向","碰撞恢复","耐力"] if zh else ["SPEED","PASSING","RECOVERY","STAMINA"]
 var base_stats: Array=DerbyBetting.STATS[id]
 var stam: float=DerbyBetting.STAMINA[id]
 var raw: Array=[base_stats[0],base_stats[1],base_stats[2],stam]
 var values: Array=["%.2f×" % raw[0],"%d%%" % roundi(100*raw[1]),"%.2f×" % raw[2],"%.2f×" % raw[3]]
 var minimum: Array=[.9,0,.8,.85]
 var maximum: Array=[1.1,1,1.2,1.15]
 for i in range(4):
  var x: float=152+i*112
  var label: Label=DerbyMenus.title(r,panel,Vector2(x,0),Vector2(108,16),"%s %s" % [names[i],values[i]],8)
  label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var track:=Rect2(x+14,19,80,5)
  DerbyMenus.art(panel,"rider25/stats_meter",track)
  var bar:=ColorRect.new()
  bar.position=track.position+Vector2(1,1)
  bar.size=Vector2(78*clampf(inverse_lerp(minimum[i],maximum[i],raw[i]),0,1),3)
  bar.color=Color(["81d1f1","efc775","9ac995","f092b4"][i])
  bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
  panel.add_child(bar)
 panel.modulate.a=.3
 panel.create_tween().tween_property(panel,"modulate:a",1.0,.10)
