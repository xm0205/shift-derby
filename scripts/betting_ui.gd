class_name DerbyBettingUI
extends RefCounted
static var hold_dir: int=0
static var hold_steps: int=0
static func build(r,root):
 var zh: bool=r.language=="zh"
 var b: DerbyBetting=r.betting
 DerbyMenus.art(root,"sx_panel",Rect2(8,50,624,273))
 DerbyMenus.art(root,"bet_header",Rect2(171,0,300,81))
 DerbyMenus.art(root,"bx_round",Rect2(14,5,99,62))
 DerbyNumberField.put(r,root,"bx_round","value",Rect2(14,5,99,62),"%d / %d" % [mini(DerbyBetting.ROUND_LIMIT,b.round_number+1),DerbyBetting.ROUND_LIMIT],17,DerbyPainter.GOLD)
 DerbyMenus.art(root,"bx_funds_full",Rect2(485,6,145,57))
 DerbyNumberField.put(r,root,"bx_funds_full","value",Rect2(485,6,145,57),str(b.funds),16)
 var stats:=DerbyStatStrip.build(r,root)
 DerbyStatStrip.show_stats(r,stats,b.selected)
 for i in range(6):
  var id: int=i
  var x: float=20+i*100
  DerbyMenus.art(root,"bx_horse_"+str(i),Rect2(x,83,98,112))
  if i==b.selected:DerbyMenus.art(root,"you_marker",Rect2(x+68,73,24,23))
  DerbyNumberField.put(r,root,"bx_horse_"+str(i),"odds",Rect2(x,83,98,112),"%.1f" % b.odds[i],10)
  DerbyNumberField.put(r,root,"bx_horse_"+str(i),"name",Rect2(x,83,98,112),DerbyBetting.ZH[i] if zh else DerbyBetting.NAMES[i],12)
  var card:=DerbyMenus.hit(root,Rect2(x,83,98,112),func():
   b.selected=id
   r.sound.cue("click")
   r.show_menu("betting"))
  card.mouse_entered.connect(func():DerbyStatStrip.show_stats(r,stats,id))
  card.mouse_exited.connect(func():DerbyStatStrip.show_stats(r,stats,b.selected))
 var need: int=DerbyBetting.ROUND_GATES[clampi(b.round_number,0,DerbyBetting.ROUND_LIMIT-1)]
 DerbyMenus.title(r,root,Vector2(489,63),Vector2(135,16),("晋级至少 %d" if zh else "ROUND MIN %d") % need,9,DerbyPainter.GOLD)
 DerbyMenus.art(root,"bx_amount",Rect2(20,219,226,99))
 DerbyMenus.title(r,root,Vector2(96,225),Vector2(74,17),"下注金额" if zh else "BET AMOUNT",11,DerbyPainter.GOLD)
 DerbyNumberField.put(r,root,"bx_amount","value",Rect2(20,219,226,99),str(b.amount),20)
 for entry in [[Rect2(38,243,34,28),-50],[Rect2(193,243,34,28),50],[Rect2(31,280,66,28),-500],[Rect2(100,280,66,28),1000],[Rect2(169,280,66,28),-999999]]:
  var rect: Rect2=entry[0]
  var change: int=entry[1]
  var is_step: bool=rect.position.y<260
  var btn: Button=DerbyMenus.hit(root,rect,func():
   if is_step and hold_steps>0:
    hold_dir=0
    hold_steps=0
    return
   if change==-999999:b.amount=b.maximum()
   else:b.adjust(change)
   r.sound.cue("click")
   r.show_menu("betting"))
  if is_step:
   btn.button_down.connect(func():
    hold_dir=signi(change)
    hold_steps=1
    b.adjust(change)
    r.sound.cue("click")
    r.show_menu("betting"))
 if hold_dir!=0:
  if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
   hold_dir=0
   hold_steps=0
  else:
   var timer:=Timer.new()
   timer.one_shot=true
   timer.wait_time=.30 if hold_steps==1 else (.09 if hold_steps<6 else (.06 if hold_steps<14 else .045))
   root.add_child(timer)
   timer.timeout.connect(func():
    if r.mode!="betting" or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
     hold_dir=0
     hold_steps=0
     return
    var step: int=50 if hold_steps<5 else (100 if hold_steps<11 else (250 if hold_steps<18 else 500))
    hold_steps+=1
    var before_amt: int=b.amount
    b.adjust(hold_dir*step)
    if b.amount==before_amt:
     hold_dir=0
     hold_steps=0
     return
    r.show_menu("betting"))
   timer.start()
 for j in range(3):
  var key: String=["bx_odds","bx_return","bx_profit"][j]
  var x: float=258+j*124
  DerbyMenus.art(root,key,Rect2(x,220,116,73))
  DerbyMenus.title(r,root,Vector2(x+9,225),Vector2(98,22),(["头名赔率","第一返还","第一净收益"] if zh else ["WIN ODDS","1ST RETURN","1ST PROFIT"])[j],12,DerbyPainter.GOLD)
  var value: String=["%.1fx" % b.odds[b.selected],str(b.projected_return(1)),"%+d" % (b.projected_return(1)-b.amount)][j]
  DerbyNumberField.put(r,root,key,"value",Rect2(x,220,116,73),value,18)
 for i in range(4):
  var chips: int=[50,100,200,500][i]
  DerbyMenus.art(root,"bx_chip"+str(chips),Rect2(265+i*40,291,33,33))
  DerbyMenus.hit(root,Rect2(265+i*40,291,33,33),func():b.adjust(chips);r.sound.cue("click");r.show_menu("betting"))
 var info_rect:=Rect2(427,291,196,33)
 DerbyMenus.art(root,"bx_info_bar",info_rect)
 var deal_cost: int=int(r.dialogue.bribe_offer(b.selected).cost)
 var deal_text: String=(("本轮贿赂需 %d 金币" if zh else "DEAL COST %d") % deal_cost) if r.dialogue.deals_unlocked() else ("第4轮开放贿赂" if zh else "DEALS OPEN R4")
 if b.amount>0:
  var podium: String=("第二净赚 %d · 第三净赚 %d" if zh else "2ND +%d / 3RD +%d") % [b.projected_return(2)-b.amount,b.projected_return(3)-b.amount]
  DerbyMenus.title(r,root,Vector2(436,297),Vector2(178,10),podium,8,DerbyPainter.GOLD).mouse_filter=Control.MOUSE_FILTER_IGNORE
  DerbyMenus.title(r,root,Vector2(436,308),Vector2(178,10),deal_text,8,Color("9ed8ff")).mouse_filter=Control.MOUSE_FILTER_IGNORE
 else:
  DerbyMenus.title(r,root,Vector2(436,301),Vector2(178,13),deal_text,9,Color("9ed8ff")).mouse_filter=Control.MOUSE_FILTER_IGNORE
 var left_chats: int=r.dialogue.story_remaining()
 var chat_caption: String=("和骑手聊聊 (%d/3)" if zh else "RIDER CHAT (%d/3)") % left_chats
 var captions: Array=["主菜单","不下注",chat_caption,"确认下注"] if zh else ["MAIN MENU","NO BET",chat_caption,"CONFIRM BET"]
 var actions: Array=[r.request_main_menu,func():b.amount=0;r.request_bet_confirmation(),r.dialogue.open_story_select,r.request_bet_confirmation]
 for i in range(4):
  var button: Button=DerbyMenus.button(r,root,Rect2(17+i*154,325,144,30),captions[i],actions[i])
  button.name=["BetMainMenu","BetNoStake","BetRiderChat","BetConfirm"][i]
  if i==2:
   if not r.dialogue.story_available() and int(r.dialogue.story.get("round",0))!=r.dialogue.bribe_round():r.dialogue.prepare_story()
   button.disabled=not r.dialogue.story_available()
   if button.disabled:button.tooltip_text="本轮聊天次数已用完" if zh else "No rider chats left this round"
  elif i==3:
   button.add_theme_color_override("font_color",DerbyPainter.GOLD)
static func confirmation(r,root):
 var zh: bool=r.language=="zh"
 var b: DerbyBetting=r.betting
 if b.amount==0:
  DerbyMenus.art(root,"bx_no_panel",Rect2(159,25,322,287))
  DerbyMenus.title(r,root,Vector2(206,135),Vector2(227,29),"不下注？" if zh else "NO BET?",22,DerbyPainter.GOLD)
  DerbyMenus.title(r,root,Vector2(189,194),Vector2(263,68),"本轮只支持马匹，不消耗金币。\n仍会消耗八轮中的一轮。" if zh else "Support your horse without a stake.\nThis still uses one of your eight rounds.",14)
 else:
  DerbyMenus.art(root,"bx_confirm_panel",Rect2(124,8,392,317))
  DerbyMenus.title(r,root,Vector2(190,72),Vector2(260,31),"确认下注？" if zh else "CONFIRM BET?",20,DerbyPainter.GOLD)
  var labels: Array=["支持马匹","下注金额","第一净赚","第二净赚","第三净赚"] if zh else ["HORSE","BET","1ST PROFIT","2ND PROFIT","3RD PROFIT"]
  var values: Array=["#%d %s" % [b.selected+1,DerbyBetting.ZH[b.selected] if zh else DerbyBetting.NAMES[b.selected]],str(b.amount),"+%d" % (b.projected_return(1)-b.amount),"+%d" % (b.projected_return(2)-b.amount),"+%d" % (b.projected_return(3)-b.amount)]
  for i in range(5):
   DerbyMenus.title(r,root,Vector2(198,125+i*32.4),Vector2(158,27),labels[i],14,DerbyPainter.GOLD)
   DerbyMenus.title(r,root,Vector2(359,125+i*32.4),Vector2(138,27),values[i],15)
 DerbyMenus.source_button(r,root,"bx_cancel",Rect2(132,320,174,34),"返回修改" if zh else "CANCEL",func():r.show_menu("betting"))
 DerbyMenus.source_button(r,root,"bx_start" if b.amount==0 else "bx_confirm",Rect2(333,320,174,34),"确认" if zh else "CONFIRM",r.place_bet)

