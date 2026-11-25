class_name DerbyBribeUI
extends RefCounted

const TYPE_TICK=preload("res://assets/audio/Coins/dialogue_tick.ogg")

static func build(r,root,page: String):
 root.add_child(preload("res://scripts/rider_lounge.gd").new())
 var d=r.dialogue
 var zh: bool=r.language=="zh"
 var offer: Dictionary=d.bribe_offer()
 var ready: bool=d.bribe_available() and r.betting.funds>=int(offer.cost)
 var attempts: int=d.bribe_count()
 var continue_label: String=("继续贿赂" if zh else "MORE RIDER DEALS") if attempts>0 else ("贿赂骑手" if zh else "RIDER DEAL")
 var caption: String=""
 if page in ["wrap_select","wrap_topics"]:
  wrap_menu(r,root,page,zh)
  return
 if page in ["story_select","story_topics"]:
  story_picker(r,root,page,zh)
  return
 if page=="post_bet":
  DerbyMenus.art(root,"rider25/bribe_frame",Rect2(69,10,502,294))
  if zh:caption_cover(r,root,Rect2(226,26,190,36),"赛前贿赂",Color("9f171e"),21)
  var desc: String=("下注已确认 · 支持 #%d · 下注 %d" if zh else "STAKE CONFIRMED / HORSE #%d / STAKE %d") % [r.betting.selected+1,r.betting.amount]
  if r.betting.amount==0:desc=("本轮不下注 · 支持 #%d" if zh else "NO BET / SUPPORTING #%d") % (r.betting.selected+1)
  DerbyMenus.title(r,root,Vector2(116,129),Vector2(408,26),desc,14)
  var prefix: String="剩余金币 " if zh else "FUNDS "
  r.coins.bind(DerbyMenus.title(r,root,Vector2(116,154),Vector2(408,27),prefix+str(r.betting.funds),16,DerbyPainter.GOLD),prefix)
  var deal_tip: String=("每名对手可尝试一次 · 已谈 %d/5" if zh else "ONE ATTEMPT PER RIVAL · %d/5 TRIED") % attempts
  if not d.bribe_available():deal_tip="本轮已与所有对手谈过。" if zh else "YOU'VE APPROACHED EVERY RIVAL THIS ROUND."
  elif not ready:deal_tip=("下一次需要 %d 金币" if zh else "NEXT DEAL REQUIRES %d COINS") % int(offer.cost)
  DerbyMenus.title(r,root,Vector2(116,181),Vector2(408,28),deal_tip,13)
  if not d.offer.is_empty() and (not d.offer.get("answered",false) or d.offer.accepted):
   var id: int=d.offer.id
   var name: String=d.rider_name(id)
   var note: String=("%s 想贿赂你 · 获胜分成 %d" if zh else "%s OFFERS %d IF THEY WIN") % [name,int(d.offer.purse)/2]
   if d.offer.accepted:note=("已答应 %s 的约定 · 记得助推一次" if zh else "DEAL WITH %s / BOOST ONCE") % name
   DerbyMenus.title(r,root,Vector2(116,214),Vector2(408,20),note,12,DerbyPainter.GOLD)
   if not d.offer.answered:DerbyMenus.button(r,root,Rect2(242,239,156,32),"查看约定" if zh else "VIEW OFFER",func():r.show_menu("rider_offer"))
  var more: Button=DerbyMenus.button(r,root,Rect2(109,307,191,36),continue_label,func():r.show_menu("bribe_select"))
  more.name="MoreRiderDeals"
  more.disabled=not ready
  DerbyMenus.button(r,root,Rect2(340,307,191,36),"开始比赛" if zh else "START RACE",r.launch_confirmed_race)
  return
 if page in ["rider_offer","rider_scene","rider_wrap"]:
  var id: int=int(d.offer.get("id",-1)) if page=="rider_offer" else d.scene_id
  if id>=0:story_dialogue(r,root,id,page)
  return
 DerbyMenus.art(root,"rider25/bribe_frame",Rect2(69,10,502,294))
 if zh:caption_cover(r,root,Rect2(226,26,190,36),"贿赂骑手",Color("9f171e"),21)
 if page=="bribe_select":
  caption="选一名对手协助冲刺" if zh else "SELECT A RIVAL TO HELP YOU SPRINT"
  DerbyMenus.title(r,root,Vector2(120,88),Vector2(400,17),caption,15,DerbyPainter.GOLD)
  for id in range(6):
   var target: int=id
   var p:=Vector2(101+(id%3)*147,107+(id/3)*83)
   var panel: TextureRect=DerbyMenus.art(root,"rider25/bribe_"+str(id),Rect2(p,Vector2(136,73)))
   var well:=ColorRect.new()
   well.position=p+Vector2(9,11)
   well.size=Vector2(48,51)
   well.color=Color("111a35")
   well.mouse_filter=Control.MOUSE_FILTER_IGNORE
   root.add_child(well)
   var portrait: TextureRect=DerbyMenus.art(root,"rider25/vn_%d_0" % id,Rect2(p+Vector2(10,10),Vector2(45,54)))
   portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   var available: bool=ready and d.bribe_available(id)
   if zh:caption_cover(r,root,Rect2(p+Vector2(64,14),Vector2(63,14)),d.rider_name(id),Color(["9c1429","124489","15722e","5b276b","775113","8f2252"][id]),10)
   panel.modulate=Color.WHITE if available else Color(.63,.63,.66)
   portrait.modulate=panel.modulate
   var price_or_status: String=str(offer.cost)
   var previous: Dictionary=d.bribe_attempt(id)
   if id==r.betting.selected:price_or_status="自己" if zh else "YOU"
   elif not previous.is_empty():price_or_status=("已答应" if zh else "ACCEPTED") if previous.success else ("已拒绝" if zh else "DECLINED")
   var price: Label=DerbyMenus.title(r,root,p+Vector2(72,40),Vector2(58,21),price_or_status,10,Color("2a2340"))
   price.mouse_filter=Control.MOUSE_FILTER_IGNORE
   if available:DerbyMenus.hit(root,Rect2(p,Vector2(136,73)),func():d.bribe_target=target;r.show_menu("bribe_confirm"))
  var status: String=("余额 %d · 选择骑手查看成功率" if zh else "FUNDS %d / SELECT A RIDER TO SEE ODDS") % r.betting.funds
  if not ready:status=("暂无可谈的骑手或金币不足" if zh else "NO FURTHER DEALS AVAILABLE")
  DerbyMenus.title(r,root,Vector2(83,257),Vector2(474,19),status,11,DerbyPainter.GOLD)
 elif page=="bribe_confirm":
  var id: int=d.bribe_target
  var name: String=d.rider_name(id)
  var avatar: TextureRect=DerbyMenus.art(root,"rider25/vn_%d_0" % id,Rect2(86,77,178,160))
  avatar.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  DerbyMenus.title(r,root,Vector2(105,237),Vector2(141,23),name,17,DerbyPainter.GOLD)
  DerbyMenus.art(root,"rider25/bribe_odds",Rect2(284,104,222,59))
  DerbyMenus.art(root,"rider25/bribe_price",Rect2(284,177,222,60))
  if zh:
   caption_cover(r,root,Rect2(309,110,172,14),"贿赂成功率",Color("111a36"),11)
   caption_cover(r,root,Rect2(333,182,133,15),"所需金币",Color("111a36"),11)
  DerbyMenus.title(r,root,Vector2(327,126),Vector2(136,24),"%s%%" % String.num(float(offer.chance)*100,1),14,Color("2a2340"))
  DerbyMenus.title(r,root,Vector2(356,202),Vector2(108,23),str(offer.cost),14,Color("2a2340"))
  DerbyMenus.title(r,root,Vector2(253,248),Vector2(281,23),("失败退回 %d%% · 每名骑手限一次" if zh else "REFUND ON FAILURE %d%% · ONCE PER RIDER") % roundi(float(offer.refund)*100),11)
  if ready and d.bribe_available(id):DerbyMenus.hit(root,Rect2(341,311,162,37),d.pay_bribe)
  DerbyMenus.art(root,"rider25/bribe_ok",Rect2(341,311,162,37))
  if zh:caption_cover(r,root,Rect2(375,317,94,21),"确认贿赂",Color("92151d"),14)
 else:
  var success: bool=d.bribe.get("success",false)
  var id: int=clampi(int(d.bribe.get("id",d.bribe_target)),0,5)
  var pose: int=1 if success else 3
  var avatar: TextureRect=DerbyMenus.art(root,"rider25/vn_%d_%d" % [id,pose],Rect2(86,77,154,154))
  avatar.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  DerbyMenus.title(r,root,Vector2(86,235),Vector2(154,22),d.rider_name(id),16,DerbyPainter.GOLD)
  caption=("交易成功" if zh else "DEAL ACCEPTED") if success else ("交易失败" if zh else "DEAL REJECTED")
  DerbyMenus.title(r,root,Vector2(248,74),Vector2(292,28),caption,18,DerbyPainter.GOLD)
  var quote_bg:=ColorRect.new()
  quote_bg.position=Vector2(248,106)
  quote_bg.size=Vector2(292,74)
  quote_bg.color=Color("111a36cc")
  quote_bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
  root.add_child(quote_bg)
  var lines_list: Array=d.data.get("bribe_dialogue",[])
  var line_text: String=""
  if id>=0 and id<lines_list.size():
   var entry: Dictionary=lines_list[id].get("success" if success else "fail",{})
   line_text=String(entry.get("zh" if zh else "en",""))
  var quote: Label=DerbyMenus.title(r,root,Vector2(258,112),Vector2(272,62),line_text,12,Color("ffedcf"))
  quote.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
  quote.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  quote.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var message: String=("这名骑手会在比赛后段助推一次。" if zh else "This rider will give you one late boost.") if success else (("退还 %d 金币，这名骑手不会助推。" if zh else "REFUNDED %d · THIS RIDER DECLINED") % int(d.bribe.get("refund",0)))
  var note: Label=DerbyMenus.title(r,root,Vector2(248,186),Vector2(292,38),message,11)
  note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  var prefix: String="总金币 " if zh else "FUNDS "
  r.coins.bind(DerbyMenus.title(r,root,Vector2(248,228),Vector2(292,32),prefix+str(r.betting.funds),18,DerbyPainter.GOLD),prefix)
  r.sound.cue("rider_chat")
  var more: Button=DerbyMenus.button(r,root,Rect2(137,311,155,37),continue_label,func():r.show_menu("bribe_select"))
  more.name="MoreRiderDeals"
  more.disabled=not ready
  DerbyMenus.button(r,root,Rect2(341,311,162,37),"返回赛前" if zh else "PRE-RACE",func():r.show_menu("post_bet"))
  return
 DerbyMenus.button(r,root,Rect2(137,311,155,37),"返回" if zh else "BACK",func():r.show_menu("bribe_select" if page=="bribe_confirm" else "post_bet"))


static func caption_cover(r,root,rect: Rect2,value: String,color: Color,font_size: int):
 var plate:=ColorRect.new()
 plate.position=rect.position
 plate.size=rect.size
 plate.color=color
 plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
 root.add_child(plate)
 var title: Label=DerbyMenus.title(r,root,rect.position-Vector2(0,2),rect.size,value,font_size,Color("fff1cd"))
 title.mouse_filter=Control.MOUSE_FILTER_IGNORE

static func wrap_menu(r,root,page: String,zh: bool):
 DerbyMenus.art(root,"sx_panel_plain",Rect2(56,40,528,268))
 var d=r.dialogue
 if page=="wrap_select":
  DerbyMenus.title(r,root,Vector2(77,78),Vector2(486,35),"找骑手聊天" if zh else "RIDER CHAT",20,DerbyPainter.GOLD)
  var other_riders: Array=r.order.filter(func(id):return id!=r.player_id)
  for index in range(other_riders.size()):
   var rider_id: int=other_riders[index]
   var rect:=Rect2(90+index*94,122,84,150)
   DerbyMenus.image_button(r,root,"leader_rider_%d" % rider_id,Rect2(rect.position+Vector2(0,9),Vector2(84,91)),func():d.select_result_rider(rider_id),"",true)
   var name: String=d.rider_name(rider_id)
   DerbyMenus.button(r,root,Rect2(rect.position+Vector2(1,105),Vector2(82,32)),name,func():d.select_result_rider(rider_id)).add_theme_font_size_override("font_size",11)
 else:
  var id: int=d.scene_id
  var name: String=d.rider_name(id)
  DerbyMenus.title(r,root,Vector2(272,85),Vector2(266,36),("和%s聊聊" if zh else "TALK WITH %s") % name,19,DerbyPainter.GOLD)
  DerbyMenus.art(root,"rider25/vn_%d_0" % id,Rect2(90,87,176,186)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  var labels: Array=["聊刚才的比赛","聊换道战术","轻松聊两句","聊人与马的默契","聊骑手的往事"] if zh else ["THE RACE","PASSING TACTICS","SMALL TALK","HORSE AND RIDER","RIDER STORIES"]
  for i in range(labels.size()):
   var topic: String=["race","tactics","relax","bond","past"][i]
   DerbyMenus.button(r,root,Rect2(286,120+i*31,232,28),labels[i],func():d.choose_result_topic(topic))
 var back: String="results" if page=="wrap_select" else "wrap_select"
 DerbyMenus.button(r,root,Rect2(244,314,152,34),"返回" if zh else "BACK",func():r.show_menu(back))

static func story_picker(r,root,page: String,zh: bool):
 DerbyMenus.art(root,"sx_panel_plain",Rect2(44,34,552,276))
 var d=r.dialogue
 var left: int=d.story_remaining()
 if page=="story_topics":
  var id: int=d.scene_id
  var name: String=d.rider_name(id)
  var aff: int=d.favors.affection_of(id)
  var stage: int=d.favors.heart_stage(id)
  DerbyMenus.title(r,root,Vector2(252,74),Vector2(316,24),("和%s聊什么 · 剩余 %d/3" if zh else "TALK WITH %s · %d/3 LEFT") % [name,left],15,DerbyPainter.GOLD)
  DerbyMenus.art(root,"rider25/vn_%d_0" % id,Rect2(72,78,158,162)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  var heart: TextureRect=DerbyMenus.art(root,"rider25/heart_%d" % stage,Rect2(96,244,28,28))
  heart.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  DerbyMenus.title(r,root,Vector2(128,248),Vector2(88,20),"%d/100" % aff,13,Color("ff8fb3") if aff>=40 else Color("ffedcf"))
  var topics: Array[String]=d.sorted_story_topics(id)
  var labels_map: Dictionary=d.data.get("scene_topic_labels",{})
  var page_idx: int=clampi(d.story_topic_page,0,1)
  var start_i: int=page_idx*5
  for slot in range(5):
   var idx: int=start_i+slot
   if idx>=topics.size():break
   var topic: String=topics[idx]
   var lbl_dict: Dictionary=labels_map.get(topic,{"zh":topic,"en":topic.to_upper()})
   var caption_txt: String=String(lbl_dict.get("zh" if zh else "en",topic))
   if d.favors.topic_asked(id,topic):caption_txt+=(" · 已聊" if zh else " · DONE")
   var btn: Button=DerbyMenus.button(r,root,Rect2(268,108+slot*32,282,28),caption_txt,func():d.choose_story_topic(topic))
   btn.add_theme_font_size_override("font_size",12)
  DerbyMenus.button(r,root,Rect2(138,316,152,34),"返回" if zh else "BACK",func():r.show_menu("story_select"))
  DerbyMenus.button(r,root,Rect2(342,316,164,34),("更多话题" if page_idx==0 else "上一页话题") if zh else ("MORE TOPICS" if page_idx==0 else "PREV TOPICS"),func():d.story_topic_page=1-page_idx;r.show_menu("story_topics"))
  return
 DerbyMenus.title(r,root,Vector2(70,74),Vector2(500,26),("选择想聊的骑手 · 本轮剩余聊天 %d/3" if zh else "CHOOSE A RIDER TO CHAT · %d/3 LEFT") % left,15,DerbyPainter.GOLD)
 var sub: String="聊天提升好感度，提高贿赂成功率并有机会赛中助推" if zh else "Chat builds affection: higher deal odds & mid-race boosts"
 DerbyMenus.title(r,root,Vector2(70,101),Vector2(500,16),sub,10,Color("c8dcf8"))
 var rivals: Array=[]
 for id in range(6):
  if id!=r.betting.selected:rivals.append(id)
 for index in range(rivals.size()):
  var rid: int=rivals[index]
  var x: float=76+index*98
  var aff: int=d.favors.affection_of(rid)
  var stage: int=d.favors.heart_stage(rid)
  var card_bg:=ColorRect.new()
  card_bg.position=Vector2(x,121)
  card_bg.size=Vector2(88,156)
  card_bg.color=Color("0e1a36cc")
  card_bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
  root.add_child(card_bg)
  DerbyMenus.image_button(r,root,"leader_rider_%d" % rid,Rect2(x+6,125,76,80),func():d.select_story_rider(rid),"",true)
  var name_btn: Button=DerbyMenus.button(r,root,Rect2(x+4,209,80,25),d.rider_name(rid),func():d.select_story_rider(rid))
  name_btn.add_theme_font_size_override("font_size",10)
  var heart: TextureRect=DerbyMenus.art(root,"rider25/heart_%d" % stage,Rect2(x+8,237,24,24))
  heart.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  DerbyMenus.title(r,root,Vector2(x+35,240),Vector2(49,18),"%d/100" % aff,10,Color("ff8fb3") if aff>=40 else Color("ffedcf"))
  var bonus_pct: int=roundi(d.favors.social_bonus(rid)*100.0)
  if bonus_pct>0:
   DerbyMenus.title(r,root,Vector2(x+4,261),Vector2(80,14),("贿赂 +%d%%" if zh else "DEAL +%d%%") % bonus_pct,8,DerbyPainter.GOLD)
 DerbyMenus.button(r,root,Rect2(244,316,152,34),"返回" if zh else "BACK",func():r.show_menu("betting"))

static func story_dialogue(r,root,id: int,page: String):
 var zh: bool=r.language=="zh"
 var d=r.dialogue
 var lines: Array[String]=[]
 var poses: Array[int]=[]
 var speakers: Array[int]=[]
 if page=="rider_offer":
  var wording: Dictionary=d.data.offer_dialogue.pink if id==5 else d.data.offer_dialogue.other
  var offer_lines:=String(wording.zh if zh else wording.en).split("\n")
  lines.append(offer_lines[0])
  lines.append(offer_lines[1] % (int(d.offer.purse)/2))
  poses.assign([2,1])
  speakers.assign([id,id])
 elif page=="rider_wrap":
  var exchange: Dictionary=d.data.post_race[id][d.wrap_topic]
  lines.assign(exchange[r.language])
  poses.assign([0,int(exchange.pose),0])
  speakers.assign([r.player_id,id,id])
 else:
  var entry: Dictionary=d.data.scenes[id][d.scene_kind]
  var prompt_key: String="prompt_zh" if zh else "prompt_en"
  var prompt_line: String=String(entry.get(prompt_key,d.data.scene_prompts[d.scene_kind][r.language]))
  lines.append(prompt_line)
  lines.append(entry.zh if zh else entry.en)
  var pose_id: int=int({"hello":0,"joke":2,"praise":1,"special":3,"snack":1,"weather":0,"dream":2,"lucky":1,"rival":2,"story":3}.get(d.scene_kind,0))
  var more_key: String="more_zh" if zh else "more_en"
  var more_line: String=String(entry.get(more_key,""))
  if not more_line.is_empty():
   lines.append(more_line)
   poses.assign([0,pose_id,1 if pose_id!=1 else 0])
   speakers.assign([r.betting.selected,id,id])
  else:
   poses.assign([0,pose_id])
   speakers.assign([r.betting.selected,id])
 var portrait_id: int=speakers[0]
 var name: String=d.rider_name(portrait_id)
 var portrait: TextureRect=DerbyMenus.art(root,"rider25/vn_%d_%d" % [portrait_id,poses[0]],Rect2(18,27,226,287))
 portrait.name="ScenePortrait"
 place_portrait(portrait)
 if page=="rider_scene":
  var aff_now: int=d.favors.affection_of(id)
  var stage_before: int=DerbyRiderFavors.heart_stage_for(d.last_affection_before)
  var stage_after: int=d.favors.heart_stage(id)
  var aff_box:=ColorRect.new()
  aff_box.position=Vector2(260,122)
  aff_box.size=Vector2(138,68)
  aff_box.color=Color("101c38dc")
  aff_box.mouse_filter=Control.MOUSE_FILTER_IGNORE
  root.add_child(aff_box)
  DerbyMenus.title(r,root,Vector2(266,125),Vector2(126,16),"好感度" if zh else "AFFECTION",10,DerbyPainter.GOLD).mouse_filter=Control.MOUSE_FILTER_IGNORE
  var h_icon: TextureRect=DerbyMenus.art(root,"rider25/heart_%d" % stage_before,Rect2(268,144,38,38))
  h_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  h_icon.pivot_offset=Vector2(19,19)
  var aff_val: Label=DerbyMenus.title(r,root,Vector2(310,146),Vector2(82,20),"%d/100" % aff_now,13,Color("ff8fb3"))
  aff_val.mouse_filter=Control.MOUSE_FILTER_IGNORE
  if d.last_affection_gain>0:
   var badge_icon: TextureRect=DerbyMenus.art(root,"rider25/heart_badge",Rect2(310,166,18,18))
   badge_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   DerbyMenus.title(r,root,Vector2(330,167),Vector2(60,16),"+%d" % d.last_affection_gain,11,DerbyPainter.GOLD).mouse_filter=Control.MOUSE_FILTER_IGNORE
  if stage_after!=stage_before or d.last_affection_gain>0:
   var tw:=h_icon.create_tween()
   tw.tween_interval(.25)
   tw.tween_callback(func():h_icon.texture=d.texture("heart_%d" % stage_after))
   tw.tween_property(h_icon,"scale",Vector2(1.22,1.22),.14)
   tw.tween_property(h_icon,"scale",Vector2.ONE,.16)
 DerbyMenus.art(root,"sx_panel_plain",Rect2(185,211,439,99))
 DerbyMenus.art(root,"button_blank",Rect2(210,209,99,25))
 var nameplate: Label=DerbyMenus.title(r,root,Vector2(210,208),Vector2(100,25),name,13,DerbyPainter.GOLD)
 nameplate.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var details: Label=DerbyMenus.title(r,root,Vector2(220,234),Vector2(370,53),lines[0],12,Color("ffedcf"))
 details.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
 details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 details.mouse_filter=Control.MOUSE_FILTER_IGNORE
 details.name="OfferText"
 details.visible_characters=0
 var player:=AudioStreamPlayer.new()
 player.name="OfferTick"
 player.stream=TYPE_TICK
 player.pitch_scale=1.13 if id==5 else .97
 root.add_child(player)
 var typer:=Timer.new()
 typer.wait_time=.029
 root.add_child(typer)
 var tip: Label=DerbyMenus.title(r,root,Vector2(421,282),Vector2(177,15),"点击或回车继续" if zh else "CLICK OR ENTER TO CONTINUE",9,DerbyPainter.GOLD)
 tip.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var cursor: Dictionary={"line":0,"decided":false,"accepted":false}
 var leave:=func():r.show_menu("wrap_topics" if page=="rider_wrap" else ("story_topics" if page=="rider_scene" and d.story_from_picker and d.story_remaining()>0 else "betting"))
 var reveal:=func():
  details.visible_characters=-1
  typer.stop()
  player.stop()
 var forward:=func():
  if details.visible_characters>=0:
   reveal.call()
   return
  if page=="rider_offer" and bool(cursor.decided):
   d.accept_offer(bool(cursor.accepted))
   return
  cursor.line+=1
  if int(cursor.line)>=lines.size():
   if page=="rider_wrap":d.complete_wrap(id,d.wrap_topic)
   if page!="rider_offer":leave.call()
   else:tip.hide()
   return
  var speaker: int=speakers[cursor.line]
  nameplate.text=d.rider_name(speaker)
  portrait.texture=d.texture("vn_%d_%d" % [speaker,poses[cursor.line]])
  place_portrait(portrait)
  portrait.modulate.a=.6
  portrait.create_tween().tween_property(portrait,"modulate:a",1.0,.14)
  details.text=lines[cursor.line]
  details.visible_characters=0
  typer.start()
 typer.timeout.connect(func():
  var next: int=details.visible_characters+1
  if next>=details.text.length():
   reveal.call()
   return
  details.visible_characters=next
  if next%3==1 and details.text.substr(next-1,1) not in [" ","，","。","…","?","？","！",",","."] and not r.sound.muted and r.sound.master_volume>0:
   player.volume_db=linear_to_db(maxf(.00001,.22*r.sound.master_volume))
   player.play())
 var click:=DerbyMenus.hit(root,Rect2(197,214,420,90),forward)
 click.name="RevealOffer"
 click.focus_mode=Control.FOCUS_ALL
 click.grab_focus()
 typer.start()
 if page=="rider_offer":
  var btn_cancel: Button=DerbyMenus.source_button(r,root,"bx_cancel",Rect2(236,316,165,33),"拒绝" if zh else "DECLINE",func():pass)
  var btn_confirm: Button=DerbyMenus.source_button(r,root,"bx_confirm",Rect2(432,316,165,33),"答应" if zh else "AGREE",func():pass)
  var btn_done: Button=DerbyMenus.button(r,root,Rect2(334,316,165,33),"继续" if zh else "CONTINUE",forward)
  btn_done.hide()
  var respond:=func(agree: bool):
   if bool(cursor.decided):return
   cursor.decided=true
   cursor.accepted=agree
   btn_cancel.hide()
   btn_confirm.hide()
   btn_done.show()
   tip.show()
   var replies: Array=d.data.get("offer_reply",[])
   var reply_text: String=""
   if id>=0 and id<replies.size():
    var entry: Dictionary=replies[id].get("accept" if agree else "decline",{})
    reply_text=String(entry.get("zh" if zh else "en",""))
   if reply_text.is_empty():
    d.accept_offer(agree)
    return
   nameplate.text=d.rider_name(id)
   portrait.texture=d.texture("vn_%d_%d" % [id,1 if agree else 3])
   place_portrait(portrait)
   portrait.modulate.a=.6
   portrait.create_tween().tween_property(portrait,"modulate:a",1.0,.14)
   details.text=reply_text
   details.visible_characters=0
   typer.start()
   click.grab_focus()
  btn_cancel.pressed.connect(func():respond.call(false))
  btn_confirm.pressed.connect(func():respond.call(true))
 else:
  DerbyMenus.button(r,root,Rect2(236,316,165,33),"跳过" if zh else "SKIP",leave)
  DerbyMenus.button(r,root,Rect2(432,316,165,33),"继续" if zh else "CONTINUE",forward)

static func place_portrait(portrait: TextureRect):
 var source:=portrait.texture.get_size()
 var fitted:=source*minf(226.0/source.x,287.0/source.y)
 portrait.position=Vector2(131-fitted.x*.5,314-fitted.y)
 portrait.size=fitted
