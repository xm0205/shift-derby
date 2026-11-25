class_name DerbyMenuPages
extends RefCounted
const GUIDE_PAGES=6
static func settings(r,root):
 var zh: bool=r.language=="zh"
 DerbyMenus.art(root,"sx_panel_plain",Rect2(24,72,592,269))
 DerbyMenus.art(root,"sx_header_zh" if zh else "sx_header_en",Rect2(174,0,292,89))
 var master=DerbyMenus.title(r,root,Vector2(55,114),Vector2(291,23),("音效音量 %d%%" if zh else "SFX VOLUME %d%%") % roundi(r.sound.master_volume*100),15,DerbyPainter.GOLD)
 var hoof=DerbyMenus.title(r,root,Vector2(55,184),Vector2(291,23),("马蹄音量 %d%%" if zh else "GALLOP VOLUME %d%%") % roundi(r.sound.hoof_volume*100),15,DerbyPainter.GOLD)
 DerbyMenus.art(root,"sx_sound",Rect2(48,140,26,25))
 DerbyMenus.art(root,"sx_sound",Rect2(48,218,26,25))
 DerbyMenus.volume_slider(root,Rect2(85,139,259,26),r.sound.master_volume*100,func(value):
  r.sound.master_volume=value/100
  master.text=("音效音量 %d%%" if zh else "SFX VOLUME %d%%") % roundi(value)
  r.save_settings())
 DerbyMenus.volume_slider(root,Rect2(85,217,259,26),r.sound.hoof_volume*100,func(value):
  r.sound.hoof_volume=value/100
  hoof.text=("马蹄音量 %d%%" if zh else "GALLOP VOLUME %d%%") % roundi(value)
  r.save_settings())
 DerbyMenus.title(r,root,Vector2(390,114),Vector2(191,22),"界面语言" if zh else "LANGUAGE",15,DerbyPainter.GOLD)
 DerbyMenus.image_button(r,root,"sx_language_en",Rect2(393,136,85,33),func():r.set_language("en"))
 DerbyMenus.image_button(r,root,"sx_language_zh",Rect2(500,136,85,33),func():r.set_language("zh"))
 DerbyMenus.title(r,root,Vector2(382,187),Vector2(105,29),"全部音效" if zh else "SOUND",14)
 DerbyMenus.image_button(r,root,"sx_toggle_off" if r.sound.muted else "sx_toggle_on",Rect2(493,181,93,39),func():
  r.sound.muted=not r.sound.muted
  r.save_settings()
  r.show_menu("settings"))
 DerbyMenus.art(root,"sx_fullscreen",Rect2(389,236,27,27))
 DerbyMenus.title(r,root,Vector2(415,236),Vector2(73,29),"全屏" if zh else "FULL",14)
 DerbyMenus.image_button(r,root,"sx_toggle_on" if r.fullscreen_enabled else "sx_toggle_off",Rect2(493,230,93,39),r.toggle_fullscreen)
 DerbyMenus.button(r,root,Rect2(64,282,140,34),"试听枪声" if zh else "TEST SFX",func():r.sound.sync_output_device(true);r.sound.cue("go")).name="SettingsAudioTest"
 DerbyMenus.title(r,root,Vector2(231,285),Vector2(178,28),"更改会自动保存" if zh else "SAVED AUTOMATICALLY",10,DerbyPainter.GOLD)
 DerbyMenus.button(r,root,Rect2(436,282,140,34),"返回" if zh else "BACK",func():r.show_menu(r.settings_return)).name="SettingsBack"
static func pause(r,root):
 var zh: bool=r.language=="zh"
 DerbyMenus.art(root,"px_shell",Rect2(22,71,255,277))
 DerbyMenus.art(root,"px_header_blank",Rect2(25,1,250,92))
 DerbyMenus.title(r,root,Vector2(80,42),Vector2(142,30),"比赛暂停" if zh else "PAUSED",22,DerbyPainter.GOLD)
 var labels: Array=["继续比赛","退出练习" if r.practice_mode else "重新挑战","游戏设置","主菜单"] if zh else ["RESUME","LEAVE PRACTICE" if r.practice_mode else "RESTART RUN","SETTINGS","MAIN MENU"]
 var actions: Array=[r.resume_race,r.leave_practice if r.practice_mode else r.request_restart,func():r.open_settings("pause"),r.request_main_menu]
 for i in range(4):DerbyMenus.source_button(r,root,["px_resume","px_restart","px_settings","px_menu"][i],Rect2(46,112+i*52,207,43),labels[i],actions[i],true)
 DerbyMenus.art(root,"sx_panel_plain",Rect2(292,69,324,275))
 DerbyMenus.title(r,root,Vector2(312,106),Vector2(282,25),"操作速查" if zh else "QUICK CONTROLS",19,DerbyPainter.GOLD)
 var lines: Array=["赛马自动选择跑道；滚轮缩放","选中马匹后点减速或加速，每次消耗一个蓝球","短按 SHIFT 加速或反击，长按暴走","每次金区位置不同；指针进金区再反击","完美反击：恢复三分之一能量，加速并无敌 2.5 秒","挑战：300 本金，八轮内达到 50000"] if zh else ["Automatic lane choice / MOUSE WHEEL: zoom","SELECT HORSE / BRAKE OR BOOST (ONE BLUE ORB)","Tap SHIFT to boost/counter; hold to Overdrive","GOLD moves each attack. Press inside GOLD.","Perfect: +1/3 energy, boost, 2.5s shield","300 funds / eight rounds / goal 50000"]
 for i in range(lines.size()):DerbyMenus.title(r,root,Vector2(309,142+i*22),Vector2(286,22),lines[i],11,Color("eee5d6"))
 DerbyMenus.button(r,root,Rect2(340,280,221,35),"图解说明 / 反击练习" if zh else "GUIDE / COUNTER PRACTICE",func():r.show_help("pause",2))
static func help(r,root):
 var zh: bool=r.language=="zh"
 var lang: String="zh" if zh else "en"
 DerbyMenus.art(root,"sx_panel_plain",Rect2(18,90,604,234))
 DerbyMenus.art(root,"hx_header_"+lang,Rect2(169,3,302,76)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 var topics: Array=["八轮挑战 · 300 金币起步 · 金额排行榜","指向马头或马尾，短按 Shift","攻击预警与反击","骑手聊天与合作","暴走能量与速度","暴走撞击 · 锁定目标"] if zh else ["EIGHT ROUNDS · START WITH 300 · RIDER STANDINGS","HOVER OVER A HORSE'S HEAD OR TAIL AND TAP SHIFT","ATTACK WARNINGS AND COUNTERS","RIDER CHAT AND DEALS","OVERDRIVE ENERGY AND SPEED","OVERDRIVE RAM · TARGET LOCK"]
 DerbyMenus.title(r,root,Vector2(35,81),Vector2(570,24),topics[r.help_page],13,DerbyPainter.GOLD)
 if r.help_page==0:
  DerbyMenus.art(root,"rider25/guide_rounds",Rect2(49,126,276,116)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  DerbyMenus.title(r,root,Vector2(330,121),Vector2(253,19),"各轮赛程与晋级门槛" if zh else "DISTANCE AND FUNDS TO ADVANCE",11,DerbyPainter.GOLD)
  for column in range(2):
   var x: float=332+column*128
   var headings: Array=["轮次","圈数","金币"] if zh else ["RD","LAPS","FUNDS"]
   var widths: Array=[32,40,52]
   for row in range(5):
    var index: int=column*4+row-1
    var values: Array=headings if row==0 else [str(index+1),String.num(float(DerbyDifficulty.DISTANCE_LAPS[index]),1),str(DerbyBetting.ROUND_GATES[index])]
    var cell_x: float=x
    for i in range(3):
     DerbyMenus.title(r,root,Vector2(cell_x,144+row*18),Vector2(widths[i],18),values[i],10,DerbyPainter.GOLD if row==0 else Color.WHITE)
     cell_x+=widths[i]
  guide_note(r,root,Rect2(63,247,254,51),"前三名拿回本金" if zh else "TOP THREE GET THEIR STAKE BACK",["净收益按冠军的 100% / 60% / 40% 计算"] if zh else ["Net profit: 100% / 60% / 40% of the winner’s."])
  guide_note(r,root,Rect2(335,250,250,51),"救济重赛" if zh else "ONE RELIEF RETRY",["未达门槛时可重赛同一轮，整场限一次"] if zh else ["Below the target? Replay that round once."])
 elif r.help_page==1:
  var captions: Array=["减速，打断正在进行的变道","加速并尝试两次相邻变道","拥堵时可能被挡住","碰撞失速后会恢复"] if zh else ["Brake to cancel a lane change","Boost and try two lanes","Traffic can block a lane change","Recover after a collision"]
  for i in range(4):
   var rect:=Rect2(112+(i%2)*236,119+floori(i/2.0)*77,180,74)
   var card: TextureRect=DerbyMenus.art(root,"hx_"+["brake","boost","lane","collision"][i]+"_"+lang,rect)
   card.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   DerbyMenus.title(r,root,rect.position+Vector2(15,52),Vector2(150,16),captions[i],9,Color("282538"))
  DerbyMenus.title(r,root,Vector2(56,272),Vector2(528,16),"每次干涉用一个蓝球 · 第 4 轮起有 4 个，第 6 轮起有 5 个" if zh else "ONE ORB PER MOVE · ROUND 4: FOUR ORBS · ROUND 6: FIVE ORBS",10,DerbyPainter.GOLD)
 elif r.help_page==2:
  var headlines: Array=["1 看到红色预警","2 指针进入金区","3 完美反击"] if zh else ["1 WATCH FOR RED","2 WAIT FOR GOLD","3 PERFECT COUNTER"]
  var instructions: Array=["留意开始走动的指针","短按 Shift 或点击反击条","加速 · 回能 1/3 · 无敌 2.5 秒"] if zh else ["Watch the moving pointer.","Tap Shift or click the bar.","Boost · +1/3 energy · 2.5s shield"]
  for i in range(3):
   var x: float=51+i*183
   DerbyMenus.art(root,["cx_incoming","cx_now","cx_perfect"][i],Rect2(x,123,172,58)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   guide_note(r,root,Rect2(x,185,172,46),headlines[i],[instructions[i]],true)
  var preview:=Node2D.new()
  root.add_child(preview)
  var example:= {"duration":2.65,"window":.55,"open":1.16,"close":.61,"time":.89,"early":false}
  preview.draw.connect(func():DerbyCounterUI.draw_timing(preview,example,Vector2(176,230),0))
  DerbyMenus.title(r,root,Vector2(54,271),Vector2(532,22),"每次金区位置会变 · 蓝区普通反击 · 金区完美反击" if zh else "BLUE: STANDARD COUNTER · GOLD: PERFECT · THE ZONES MOVE EACH ATTACK",11,DerbyPainter.GOLD)
 elif r.help_page==3:
  DerbyMenus.art(root,"rider25/guide_deals",Rect2(48,128,325,160)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  guide_note(r,root,Rect2(389,128,197,50),"赛中聊天" if zh else "ON THE TRACK",["点小地图旁的图标聊天、发表情，","或请附近骑手助推。"] if zh else ["Chat, send emotes or ask a nearby","rider for a boost."])
  guide_note(r,root,Rect2(389,185,197,50),"答应帮忙" if zh else "HELP A RIDER",["该骑手的贿赂成功率提高 10 个百分点。","拒绝或错过都没有惩罚。"] if zh else ["Gain 10 points in deal odds with them.","You can safely skip or decline."])
  guide_note(r,root,Rect2(389,242,197,50),"第 4 轮起 · 赛前协助" if zh else "PRE-RACE DEALS · ROUND 4+",["下注后可与多名对手交易，","每名答应的骑手会助推一次。"] if zh else ["Deal with rivals after betting.","Each deal grants one boost."])
 elif r.help_page==4:
  DerbyMenus.art(root,"rider25/guide_overdrive",Rect2(46,126,397,168)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  guide_note(r,root,Rect2(459,128,127,50),"满格后启动" if zh else "FULL METER TO START",["长按 Shift 0.18 秒","暴走 5 秒 · 2 倍速"] if zh else ["Hold Shift for 0.18s.", "Double speed for 5s."])
  guide_note(r,root,Rect2(459,185,127,50),"持续五秒" if zh else "FIVE-SECOND SPRINT",["松开 Shift 后持续","暴走期间的回能会保留"] if zh else ["Release Shift to keep", "New charge is retained."])
  guide_note(r,root,Rect2(459,242,127,50),"能量从 0 开始" if zh else "STARTS AT 0 ENERGY",["完美反击回能 1/3","蓝球单独计算"] if zh else ["Perfect counter: +1/3.", "Separate blue orbs."])
 else:
  var headings: Array=["1  满格后暴走","2  第一次点击","3  再次点击"] if zh else ["1  FULL METER","2  FIRST CLICK","3  CLICK AGAIN"]
  var instructions: Array=[["长按 Shift 启动","速度 2 倍 · 持续 5 秒"],["锁定附近对手","红色准星确认目标"],["向目标发动撞击","命中后击飞并减速"]] if zh else [["Hold Shift to activate.","Double speed for 5 seconds."],["Lock a nearby rival.","The red ring marks your target."],["Ram the chosen rival.","Contact knocks them back."]]
  for i in range(3):
   var x: float=47+i*183
   DerbyLeaderboardUI.panel(root,Rect2(x,127,180,143),Color("10203e"),Color("d6ad58"),5)
   DerbyMenus.title(r,root,Vector2(x+4,134),Vector2(172,20),headings[i],13,DerbyPainter.GOLD)
   guide_note(r,root,Rect2(x+4,212,172,40),"",instructions[i],true)
  var energy: Texture2D=DerbyOverdrive.texture("energy")
  DerbyMenus.atlas_patch(root,energy,Rect2(Vector2.ZERO,energy.get_size()),Rect2(74,189,126,14))
  DerbyMenus.title(r,root,Vector2(74,156),Vector2(126,25),"100% · SHIFT",16,Color.WHITE)
  DerbyMenus.art(root,"guide_mouse",Rect2(248,156,40,64)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  DerbyMenus.art(root,"guide_arrows",Rect2(290,177,37,28)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  DerbyMenus.art(root,"leader_rider_2",Rect2(330,158,57,57))
  DerbyMenus.atlas_patch(root,DerbyOverdrive.TARGET_ART,DerbyOverdrive.LOCKED_RING,Rect2(327,155,63,63))
  DerbyMenus.sprite(r,root,0,Rect2(420,156,85,65))
  DerbyMenus.sprite(r,root,2,Rect2(499,151,85,65))
  var spark: Texture2D=DerbyOverdrive.texture("spark_2")
  DerbyMenus.atlas_patch(root,spark,Rect2(Vector2.ZERO,spark.get_size()),Rect2(475,164,48,44))
  DerbyMenus.title(r,root,Vector2(44,278),Vector2(552,18),"只能锁定有效距离内的其他骑手 · 暴走结束自动清除锁定" if zh else "ONLY RIVALS IN RANGE CAN BE LOCKED · TARGET CLEARS WHEN OVERDRIVE ENDS",10,DerbyPainter.GOLD)
 var back: Button=DerbyMenus.button(r,root,Rect2(30,322,124,30),"返回" if zh else "BACK",func():r.show_menu(r.help_return))
 back.name="GuideBack"
 var prev: Button=DerbyMenus.button(r,root,Rect2(174,322,95,30),"上一页" if zh else "PREVIOUS",func():r.change_help_page(-1))
 prev.name="GuidePrevious"
 prev.disabled=r.help_page==0
 DerbyMenus.title(r,root,Vector2(275,322),Vector2(90,30),"%d / %d" % [r.help_page+1,GUIDE_PAGES],14,DerbyPainter.GOLD)
 var next: Button=DerbyMenus.button(r,root,Rect2(371,322,95,30),"下一页" if zh else "NEXT",r.change_help_page)
 next.name="GuideNext"
 next.disabled=r.help_page==GUIDE_PAGES-1
 var practice: Button=DerbyMenus.button(r,root,Rect2(486,322,124,30),"反击练习" if zh else "PRACTICE",r.start_counter_practice)
 practice.name="GuidePractice"

static func guide_note(r,root,rect: Rect2,heading: String,lines: Array,center: bool=false):
 var alignment:=HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
 DerbyMenus.title(r,root,rect.position,Vector2(rect.size.x,17),heading,12,DerbyPainter.GOLD).horizontal_alignment=alignment
 for i in range(lines.size()):
  DerbyMenus.title(r,root,rect.position+Vector2(0,18+i*14),Vector2(rect.size.x,14),lines[i],10).horizontal_alignment=alignment
static func restart(r,root):
 var zh: bool=r.language=="zh"
 DerbyMenus.art(root,"sx_panel_plain",Rect2(79,39,482,287))
 DerbyMenus.art(root,"px_header_blank",Rect2(182,1,276,100))
 DerbyMenus.title(r,root,Vector2(220,42),Vector2(200,35),"重新挑战？" if zh else "RESTART?",20,DerbyPainter.GOLD)
 if r.can_retry_round():
  var fee: int=r.betting.retry_round_fee()
  var body: String=("重新本轮：花费 %d 金币直接重跑，已下注优先减少下注额。\n全部重新：放弃本次挑战，本金重置为 300 从第一轮开始。" if zh else "RETRY ROUND: Spend %d coins to rerun now (reduces stake first).\nNEW RUN: Abandon this run and restart Round 1 with 300.") % fee
  var lbl: Label=DerbyMenus.title(r,root,Vector2(104,136),Vector2(432,88),body,13)
  lbl.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  var btn_cancel: Button=DerbyMenus.button(r,root,Rect2(96,246,104,46),"取消" if zh else "CANCEL",func():r.show_menu(r.restart_return))
  btn_cancel.name="RestartCancel"
  var btn_retry: Button=DerbyMenus.source_button(r,root,"bx_confirm",Rect2(208,246,184,46),("重新本轮 -%d" if zh else "RETRY -%d") % fee,r.retry_round)
  btn_retry.name="RetryRound"
  var btn_full: Button=DerbyMenus.source_button(r,root,"bx_cancel",Rect2(400,246,144,46),"全部重新 300" if zh else "NEW RUN 300",r.new_game)
  btn_full.name="RestartFull"
  return
 DerbyMenus.title(r,root,Vector2(115,163),Vector2(410,65),"将完全放弃本次挑战。\n本金重置为 300，从第一轮重新开始。" if zh else "This abandons the entire current run.\nFunds reset to 300. Start again from round one.",16)
 DerbyMenus.source_button(r,root,"bx_cancel",Rect2(121,245,181,47),"取消" if zh else "CANCEL",func():r.show_menu(r.restart_return))
 DerbyMenus.source_button(r,root,"bx_confirm",Rect2(338,245,181,47),"从 300 重新开始" if zh else "RESTART WITH 300",r.new_game)
static func campaign_end(r,root):
 var zh: bool=r.language=="zh"
 var win: bool=r.betting.campaign_outcome()=="victory"
 var relief: bool=r.betting.can_rescue()
 DerbyMenus.art(root,"sx_panel_plain",Rect2(64,76,512,246))
 DerbyMenus.art(root,"victory" if win else "defeat",Rect2(190,0,260,95))
 DerbyMenus.title(r,root,Vector2(95,101),Vector2(450,36),("金币挑战成功！" if win else ("还有一次重赛机会" if relief else "本次挑战结束")) if zh else ("COIN CHALLENGE WON!" if win else ("ONE RETRY AVAILABLE" if relief else "RUN OVER")),24,DerbyPainter.GOLD)
 if win:DerbyMenus.art(root,"run_trophy",Rect2(448,145,72,70))
 DerbyMenus.art(root,"bx_coin",Rect2(188,145,62,65))
 DerbyMenus.title(r,root,Vector2(260,149),Vector2(200,61),str(r.betting.funds),38,DerbyPainter.GOLD)
 var reason: String=("已赚到 50000！" if zh else "TARGET 50000 REACHED!") if win else ("金币已输光" if zh else "NO FUNDS LEFT") if r.betting.funds<=0 else ("未达到本轮金币门槛" if zh else "ROUND FUNDS REQUIREMENT NOT MET")
 if relief:
  var aid: int=r.betting.rescue_balance()-r.betting.funds
  reason=("未过门槛 · 救济 +%d 金币" if zh else "BELOW THE GATE / RELIEF +%d") % aid if aid>0 else ("未过门槛 · 可用现有金币重赛" if zh else "BELOW THE GATE / RETRY WITH YOUR FUNDS")
 DerbyMenus.title(r,root,Vector2(100,217),Vector2(440,28),reason,17)
 var detail: String=("完成 %d / 8 轮  ·  初始本金 300" if zh else "%d / 8 ROUNDS  /  STARTING FUNDS 300") % r.betting.round_number
 if relief:detail=("重赛第 %d 轮 · 整场挑战限用一次" if zh else "RETRY ROUND %d / ONCE PER RUN") % r.betting.round_number
 var ranking_available: bool=r.betting.rider_results.has(r.betting.round_number)
 if r.betting.round_number==DerbyBetting.ROUND_LIMIT and ranking_available and not relief:
  var leader: Dictionary=r.betting.rider_standings()[0]
  detail=("金额冠军：%s · 完成 8/8 轮" if zh else "EARNINGS CHAMPION: %s · 8/8 ROUNDS") % r.dialogue.rider_name(leader.rider)
 DerbyMenus.title(r,root,Vector2(100,251),Vector2(440,24),detail,14,DerbyPainter.GOLD)
 if ranking_available:
  var restart_label: String=("领取救济" if relief else "再挑战一次") if zh else ("CLAIM RELIEF" if relief else "NEW CHALLENGE")
  DerbyMenus.button(r,root,Rect2(83,285,152,34),restart_label,r.use_rescue if relief else r.new_game)
  DerbyMenus.button(r,root,Rect2(244,285,152,34),"金额排行榜" if zh else "STANDINGS",r.show_leaderboard)
  DerbyMenus.button(r,root,Rect2(405,285,152,34),"主菜单" if zh else "MAIN MENU",r.request_main_menu)
  return
 if relief:
  DerbyMenus.source_button(r,root,"bx_confirm",Rect2(110,285,195,43),"使用救济重赛" if zh else "USE RETRY",r.use_rescue)
 else:
  DerbyMenus.source_button(r,root,"bx_confirm",Rect2(110,285,195,43),"再挑战一次" if zh else "NEW CHALLENGE",r.new_game)
 DerbyMenus.source_button(r,root,"px_menu",Rect2(335,285,195,43),"主菜单" if zh else "MAIN MENU",r.request_main_menu,true)

static func exit_choice(r,root):
 var zh: bool=r.language=="zh"
 DerbyMenus.art(root,"sx_panel_plain",Rect2(70,75,500,250))
 DerbyMenus.title(r,root,Vector2(100,100),Vector2(440,32),"如何返回主菜单？" if zh else "RETURN TO MAIN MENU",22,DerbyPainter.GOLD)
 DerbyMenus.title(r,root,Vector2(100,140),Vector2(440,44),"保存后可继续同一场比赛。放弃会清除本次挑战。" if zh else "Save to resume this race. Abandon resets the entire run.",13)
 DerbyMenus.button(r,root,Rect2(120,196,400,33),"保存比赛进度，返回主菜单" if zh else "SAVE PROGRESS / MAIN MENU",func():r.show_menu("menu"))
 DerbyMenus.button(r,root,Rect2(120,236,400,33),"放弃挑战，重置第一轮 / 300本金" if zh else "ABANDON / RESET TO ROUND 1 AND 300",r.abandon_to_menu)
 DerbyMenus.button(r,root,Rect2(230,280,180,30),"取消，继续比赛" if zh else "CANCEL / RESUME",r.cancel_exit)
