extends Node2D

const BACKGROUND=preload("res://assets/ui/rider25/lounge_background.png")

func _draw():
 draw_texture_rect(BACKGROUND,Rect2(0,0,640,360),false)
