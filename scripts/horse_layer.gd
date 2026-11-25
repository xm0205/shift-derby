extends Node2D
func _process(_dt):queue_redraw()
func _draw():
 var race=get_parent()
 var ordered: Array=race.horses.duplicate()
 ordered.sort_custom(func(a,b):return race.horse_screen(a).y<race.horse_screen(b).y)
 for horse in ordered:DerbyPainter.horse(race,horse,self)
 race.overdrive.draw_effects(race,self)
 for horse in ordered:DerbyPainter.indicators(race,horse,self)
