extends Node2D
var pause_button: Button
var brake_button: Button
var boost_button: Button
var counter_button: Button
var ram_buttons: Array[Button]=[]
func _ready():
 var r=get_parent()
 pause_button=DerbyMenus.button(r,self,Rect2(548,4,86,28),"PAUSE",r.request_pause)
 pause_button.focus_mode=Control.FOCUS_NONE
 pause_button.tooltip_text="Esc"
 brake_button=click_overlay(Rect2(5,327,118,29),func():r.trigger_hud_action(true))
 boost_button=click_overlay(Rect2(517,327,118,29),func():r.trigger_hud_action(false))
 counter_button=click_overlay(Rect2(166,274,308,56),r.request_counter)
 counter_button.action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS
 counter_button.focus_mode=Control.FOCUS_NONE
 for id in range(6):
  var target: int=id
  var button:=click_overlay(Rect2(0,0,34,34),func():r.overdrive.request_ram(r,target))
  var transparent:=StyleBoxEmpty.new()
  for state in ["normal","hover","pressed"]:button.add_theme_stylebox_override(state,transparent)
  button.hide()
  ram_buttons.append(button)
func click_overlay(rect: Rect2,action: Callable) -> Button:
 var button:=Button.new()
 button.position=rect.position
 button.size=rect.size
 button.focus_mode=Control.FOCUS_NONE
 for state in ["normal","hover","pressed","focus"]:
  var style:=StyleBoxFlat.new()
  style.bg_color=Color(1,1,1,.12) if state=="hover" else Color(0,0,0,.2) if state=="pressed" else Color.TRANSPARENT
  style.border_color=Color("ffe5a0") if state=="hover" else Color.TRANSPARENT
  style.set_border_width_all(1)
  button.add_theme_stylebox_override(state,style)
 button.pressed.connect(action)
 add_child(button)
 return button
func _process(_dt):
 var r=get_parent()
 pause_button.visible=r.mode=="race"
 brake_button.visible=r.mode=="race"
 boost_button.visible=r.mode=="race"
 pause_button.text="暂停 Esc" if r.language=="zh" else "PAUSE Esc"
 brake_button.tooltip_text=("减速目标 #%d" if r.language=="zh" else "BRAKE target #%d") % (r.button_target_id()+1)
 boost_button.tooltip_text=("加速目标 #%d" if r.language=="zh" else "BOOST target #%d") % (r.button_target_id()+1)
 counter_button.visible=r.mode=="race" and r.combat.pending.any(func(event):return event.target==r.player_id)
 counter_button.tooltip_text="等金区和最亮红圈再反击" if r.language=="zh" else "Counter in GOLD with the brightest ring"
 for id in range(ram_buttons.size()):
  var badge: Rect2=r.overdrive.ram_badge(r,id)
  var button: Button=ram_buttons[id]
  button.visible=badge.has_area()
  if button.visible:
   button.position=badge.position
   button.size=badge.size
   var locked: bool=r.overdrive.locked_target==id
   var prompt: String=("再次点击撞飞 %s" if locked else "点击锁定 %s") if r.language=="zh" else ("Click again to ram %s" if locked else "Click to lock %s")
   button.tooltip_text=prompt % r.dialogue.rider_name(id)
 queue_redraw()
func _draw():DerbyPainter.draw_hud(get_parent(),self)
