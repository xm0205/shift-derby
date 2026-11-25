class_name DerbyMenus
extends RefCounted
static var textures := {}
static func art(parent,name: String,rect: Rect2):
 if not textures.has(name):
  var folder: String="res://assets/ui/" if name.begins_with("rider25/") else "res://assets/ui/cut/"
  textures[name]=load(folder+name+".png")
 var image := TextureRect.new()
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.texture=textures[name]
 image.position=rect.position
 image.size=rect.size
 image.stretch_mode=TextureRect.STRETCH_SCALE
 image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(image)
 return image
static func atlas_patch(parent,source: Texture2D,region: Rect2,rect: Rect2) -> TextureRect:
 var cropped:=AtlasTexture.new()
 cropped.atlas=source
 cropped.region=region
 cropped.filter_clip=true
 var patch:=TextureRect.new()
 patch.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 patch.texture=cropped
 patch.position=rect.position
 patch.size=rect.size
 patch.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(patch)
 return patch
static func image_button(r,parent,asset: String,rect: Rect2,action: Callable,label: String="",preserve_aspect: bool=false,pointer_feedback: bool=true):
 var image=art(parent,asset,rect)
 if preserve_aspect:image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 var hit:=Button.new()
 hit.position=rect.position
 hit.size=rect.size
 hit.tooltip_text=""
 for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:hit.add_theme_stylebox_override(state,StyleBoxEmpty.new())
 hit.pressed.connect(action)
 if pointer_feedback:
  hit.mouse_entered.connect(func():image.modulate=Color(1.15,1.15,1.15))
  hit.mouse_exited.connect(func():image.modulate=Color.WHITE)
  hit.button_down.connect(func():image.modulate=Color(.8,.8,.8))
  hit.button_up.connect(func():image.modulate=Color.WHITE)
 parent.add_child(hit)
 if label!="":
  var caption=title(r,parent,rect.position+Vector2(50,0),rect.size-Vector2(58,0),label,16)
  caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return hit

static func title(r,parent,p: Vector2,size: Vector2,value: String,font_size: int=18,color: Color=Color.WHITE):
 var label := Label.new()
 label.text=value
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 label.add_theme_font_override("font",r.font)
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",color)
 parent.add_child(label)
 label.position=p
 label.size=size
 return label
static func box(parent,rect: Rect2,color: Color=Color("20233d")):
 return art(parent,"panel_tall" if rect.size.y>rect.size.x else "panel_wide",rect)
static func button(r,parent,rect: Rect2,label: String,action: Callable,accent: bool=false):
 var visual=art(parent,"button_blank",rect)
 var b:=Button.new()
 b.text=label
 b.add_theme_font_override("font",r.font)
 b.add_theme_font_size_override("font_size",14)
 for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
 b.add_theme_color_override("font_color",Color("fff0c9"))
 b.mouse_entered.connect(func():visual.modulate=Color(1.15,1.15,1.15))
 b.mouse_exited.connect(func():visual.modulate=Color.WHITE)
 b.button_down.connect(func():visual.modulate=Color(.8,.8,.8))
 b.button_up.connect(func():visual.modulate=Color.WHITE)
 b.pressed.connect(action)
 parent.add_child(b)
 b.position=rect.position
 b.size=rect.size
 b.visibility_changed.connect(func():visual.visible=b.visible)
 return b
static func sprite(r,parent,id: int,rect: Rect2,animation: String="run"):
 var image := TextureRect.new()
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.texture=r.art_frames[id].get_frame_texture(animation,0)
 image.position=rect.position
 image.size=rect.size
 image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(image)
static func build(r,page: String):
 var root := Control.new()
 root.size=Vector2(640,360)
 r.menu_layer.add_child(root)
 var shade := ColorRect.new()
 shade.size=Vector2(640,360)
 shade.color=Color(.035,.06,.12,.76)
 root.add_child(shade)
 var zh: bool=r.language=="zh"
 if page=="betting":
  DerbyBettingUI.build(r,root)
 elif page in ["post_bet","rider_offer","story_select","story_topics","rider_scene","rider_wrap","wrap_select","wrap_topics","bribe_select","bribe_confirm","bribe_result"]:
  DerbyBribeUI.build(r,root,page)
 elif page=="menu":
  art(root,"menu_clean",Rect2(0,0,640,360))
  var logo: TextureRect=art(root,"menu_logo_zh" if zh else "menu_logo_en",Rect2(73,14,327,140))
  logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  var has_run: bool=r.betting.round_number>0 or r.betting.rescue_used
  var ongoing: bool=r.betting.campaign_outcome()=="ongoing" or r.betting.can_rescue()
  var primary_action: Callable=r.begin_round if has_run else r.request_new_game
  if r.betting.round_number==DerbyBetting.ROUND_LIMIT and r.betting.rider_results.has(DerbyBetting.ROUND_LIMIT):primary_action=r.show_leaderboard
  var primary_art: String=("menu_zh_continue" if has_run else "menu_atlas_play_zh") if zh else ("menu_zh_continue" if has_run else "menu_atlas_play")
  var primary_label: String=""
  if has_run and (not zh or not ongoing):primary_label=("挑战结算" if zh else "RUN RESULTS") if not ongoing else "CONTINUE"
  var items: Array=[["ContinueGame" if has_run else "NewGame",primary_art,primary_action,primary_label]]
  if has_run:items.append(["NewGame","menu_zh_restart",r.request_new_game,"" if zh else "RESTART"])
  items.append(["Help","menu_zh_help" if zh else "menu_atlas_help",func():r.show_help("menu"),""])
  items.append(["Settings","menu_zh_settings" if zh else "menu_atlas_settings",func():r.open_settings("menu"),""])
  if not OS.has_feature("web"):items.append(["Quit","menu_zh_quit" if zh else "menu_atlas_quit",func():r.get_tree().quit(),""])
  var start_y: float=107.0 if items.size()==5 else 127.0
  for i in range(items.size()):
   var item: Array=items[i]
   var rect:=Rect2(414,start_y+i*46,194,40)
   var plate: TextureRect=art(root,item[1],rect)
   if item[0]=="Help" and not has_run and not r.settings.get_value("preferences","guide_seen",false):
    plate.name="GuideHighlight"
    plate.modulate=Color(1.35,1.23,1.04)
    var glow:=plate.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    glow.tween_property(plate,"modulate",Color(1.04,1.01,1.0),.75)
    glow.tween_property(plate,"modulate",Color(1.35,1.23,1.04),.75)
   if not String(item[3]).is_empty():
    if i==0:
     atlas_patch(root,plate.texture,Rect2(195,22,9,67),Rect2(rect.position+Vector2(75,8),Vector2(98,25)))
    var caption:=Rect2(rect.position+Vector2(74,0),Vector2(99,40))
    if i==1:
     atlas_patch(root,plate.texture,Rect2(139,23,8,65),Rect2(rect.position+Vector2(53,8),Vector2(90,25)))
     caption=rect
    title(r,root,caption.position,caption.size,item[3],14 if zh else 12,Color("fff3de")).mouse_filter=Control.MOUSE_FILTER_IGNORE
   var entry:=hit(root,rect,item[2])
   entry.name=item[0]
 elif page=="exit_choice":DerbyMenuPages.exit_choice(r,root)
 elif page=="settings":DerbyMenuPages.settings(r,root)
 elif page=="pause":DerbyMenuPages.pause(r,root)
 elif page=="help":DerbyMenuPages.help(r,root)
 elif page in ["bet_confirm","no_bet_confirm"]:DerbyBettingUI.confirmation(r,root)
 elif page=="restart_confirm":DerbyMenuPages.restart(r,root)
 elif page=="campaign_end":DerbyMenuPages.campaign_end(r,root)
 elif page=="leaderboard":DerbyLeaderboardUI.build(r,root)
 elif page=="champion":
  var champion:=DerbyChampionUI.new()
  champion.race=r
  root.add_child(champion)
 elif page=="results":
  var won: bool=r.order[0]==r.player_id
  var place: int=r.order.find(r.player_id)+1
  var chat_btn: Button=button(r,root,Rect2(516,7,108,24),"找骑手聊天" if zh else "RIDER CHAT",r.dialogue.open_result_scene)
  chat_btn.add_theme_color_override("font_color",DerbyPainter.GOLD)
  if r.betting.rider_results.has(r.betting.round_number):
   button(r,root,Rect2(348,4,104,22),"金额排行榜" if zh else "STANDINGS",r.show_leaderboard)
  art(root,"results_header",Rect2(27,5,270,77))
  art(root,"rankings",Rect2(24,79,284,216))
  if place in [2,3]:
   box(root,Rect2(370,39,216,70))
   art(root,"race_rank_%d" % place,Rect2(397,49,42,48)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   title(r,root,Vector2(439,48),Vector2(127,50),("亚军" if place==2 else "季军") if zh else ("2ND PLACE" if place==2 else "3RD PLACE"),19,DerbyPainter.GOLD)
  else:
   art(root,"victory" if won else "defeat",Rect2(346,29,261,92)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  var quote: Dictionary=r.dialogue.finish_reaction(r.player_id,won)
  title(r,root,Vector2(339,117),Vector2(276,28),quote[r.language],12,DerbyPainter.GOLD)
  sprite(r,root,r.order[0],Rect2(354,137,105,72),"win")
  title(r,root,Vector2(458,147),Vector2(142,25),("冠军 #%d" if zh else "WINNER #%d") % (r.order[0]+1),14,DerbyPainter.GOLD)
  title(r,root,Vector2(458,174),Vector2(142,23),("时间 %.1f 秒" if zh else "TIME %.1fs") % (r.champion_time if r.champion_time>0 else r.elapsed),13)
  var names := DerbyBetting.ZH if zh else DerbyBetting.NAMES
  for i in range(6):
   var id: int=r.order[i]
   title(r,root,Vector2(73,116+i*27.3),Vector2(225,26),"#%d  %s %s" % [id+1,names[id],"★" if id==r.player_id else ""],13,DerbyPainter.GOLD if id==r.player_id else Color.WHITE)
  title(r,root,Vector2(350,193),Vector2(255,20),("第 %d/8 轮 · 目标 50000" if zh else "ROUND %d/8 · GOAL 50000") % r.betting.round_number,12,DerbyPainter.GOLD)
  var b=r.betting
  var rider_share: int=int(r.dialogue.offer.get("paid",0))
  box(root,Rect2(330,213,285,83))
  title(r,root,Vector2(340,230),Vector2(265,20),("下注 %d · 第 %d 名" if zh else "BET %d · PLACE %d") % [b.amount,place],13)
  title(r,root,Vector2(340,250),Vector2(265,20),("到账 %d · 净收益 %+d" if zh else "PAYOUT %d · NET %+d") % [b.reward,b.net],13)
  var balance_rect:=Rect2(340,266,134,21) if rider_share>0 else Rect2(340,266,265,21)
  var balance_label=title(r,root,balance_rect.position,balance_rect.size,("总金币 %d" if zh else "FUNDS %d") % b.funds,14,DerbyPainter.GOLD)
  r.coins.bind(balance_label,"总金币 " if zh else "FUNDS ")
  if rider_share>0:
   title(r,root,Vector2(474,266),Vector2(126,21),("邀约分成 +%d" if zh else "RIDER SHARE +%d") % rider_share,11,DerbyPainter.GOLD)
  image_button(r,root,"result_again",Rect2(24,309,186,43),r.request_restart,"重新挑战" if zh else "NEW RUN")
  image_button(r,root,"result_menu",Rect2(227,309,186,43),r.request_main_menu,"主菜单" if zh else "MAIN MENU")
  var next_label: String="下一轮" if zh else "NEXT ROUND"
  if r.betting.can_rescue():next_label="救济重赛" if zh else "ONE RETRY"
  elif r.betting.campaign_outcome()!="ongoing":next_label="挑战结算" if zh else "RUN RESULTS"
  image_button(r,root,"result_next",Rect2(430,309,186,43),r.begin_round,next_label)

static func hit(parent,rect: Rect2,action: Callable) -> Button:
 var b:=Button.new()
 b.position=rect.position
 b.size=rect.size
 b.focus_mode=Control.FOCUS_NONE
 for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
 b.pressed.connect(action)
 parent.add_child(b)
 return b
static func source_button(r,parent,asset: String,rect: Rect2,label: String,action: Callable,icon: bool=false,pointer_feedback: bool=true):
 var image=art(parent,asset,rect)
 var b=hit(parent,rect,action)
 var margin: float=rect.size.x*.25 if icon else 4.0
 var caption=title(r,parent,rect.position+Vector2(margin,0),rect.size-Vector2(margin+4,0),label,13,Color("fff1c8"))
 caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if pointer_feedback:
  b.mouse_entered.connect(func():image.modulate=Color(1.18,1.18,1.18))
  b.mouse_exited.connect(func():image.modulate=Color.WHITE)
  b.button_down.connect(func():image.modulate=Color(.8,.8,.8))
  b.button_up.connect(func():image.modulate=Color.WHITE)
 return b
static func volume_slider(parent,rect: Rect2,value: float,action: Callable):
 var track_rect:=Rect2(rect.position+Vector2(0,5),Vector2(rect.size.x,16))
 art(parent,"sx_slider",track_rect)
 var fill:=Control.new()
 fill.position=track_rect.position
 fill.size=Vector2(track_rect.size.x*value/100,16)
 fill.clip_contents=true
 fill.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(fill)
 art(fill,"sx_slider_fill",Rect2(Vector2.ZERO,track_rect.size))
 var slider:=HSlider.new()
 slider.position=rect.position
 slider.size=rect.size
 slider.min_value=0
 slider.max_value=100
 slider.step=5
 slider.value=value
 slider.focus_mode=Control.FOCUS_NONE
 for style_name in ["slider","grabber_area","grabber_area_highlight"]:slider.add_theme_stylebox_override(style_name,StyleBoxEmpty.new())
 for icon_name in ["grabber","grabber_highlight","grabber_disabled"]:slider.add_theme_icon_override(icon_name,load("res://assets/ui/cut/sx_knob.png"))
 slider.value_changed.connect(func(next):fill.size.x=track_rect.size.x*next/100;action.call(next))
 parent.add_child(slider)
 return slider
