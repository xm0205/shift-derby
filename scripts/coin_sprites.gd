extends RefCounted

static var frames: SpriteFrames
const COUNTS={"spin":8,"fly":8,"burst":7,"spend":7}

static func create(animation: String, target_size: float) -> AnimatedSprite2D:
 if frames==null:
  frames=SpriteFrames.new()
  for kind in COUNTS:
   frames.add_animation(kind)
   frames.set_animation_loop(kind,kind=="spin")
   frames.set_animation_speed(kind,15)
   for i in range(COUNTS[kind]):
    frames.add_frame(kind,load("res://assets/ui/rider25/coin_%s_%d.png" % [kind,i]))
 var icon:=AnimatedSprite2D.new()
 icon.sprite_frames=frames
 icon.animation=animation
 var texture_size: Vector2=frames.get_frame_texture(animation,0).get_size()
 icon.scale=Vector2.ONE*(target_size/maxf(texture_size.x,texture_size.y))
 return icon
