class_name DerbyLeaderboardUI
extends RefCounted

const COLUMNS=[64,142,112,126]
const CHAMPION_PREVIEW_SECONDS=4.0

static func panel(root,rect: Rect2,fill: Color,border: Color,radius: int=3) -> Panel:
 var card:=Panel.new()
 var style:=StyleBoxFlat.new()
 style.bg_color=fill
 style.border_color=border
 style.set_border_width_all(1)
 style.set_corner_radius_all(radius)
 card.add_theme_stylebox_override("panel",style)
 card.position=rect.position
 card.size=rect.size
 card.mouse_filter=Control.MOUSE_FILTER_IGNORE
 root.add_child(card)
 return card

static func build(r,root):
 var zh: bool=r.language=="zh"
 var b: DerbyBetting=r.betting
 var standings:=b.rider_standings()
 var final_round: bool=b.round_number==DerbyBetting.ROUND_LIMIT
 var champion_name: String=r.dialogue.rider_name(int(standings[0].rider))
 if final_round:
  DerbyMenus.art(root,"champion_podium_bg",Rect2(0,0,640,360))
  var dim:=ColorRect.new()
  dim.size=Vector2(640,360)
  dim.color=Color(.025,.04,.10,.23)
  dim.mouse_filter=Control.MOUSE_FILTER_IGNORE
  root.add_child(dim)
 DerbyMenus.art(root,"sx_panel_plain",Rect2(60,21,520,318))
 DerbyMenus.art(root,"leader_title",Rect2(135,4,370,46))
 if final_round:
  DerbyMenus.title(r,root,Vector2(153,7),Vector2(334,14),"最终金额排行榜" if zh else "FINAL RIDER STANDINGS",10,Color("ffe4a5"))
  DerbyMenus.title(r,root,Vector2(153,19),Vector2(334,22),("金额冠军 · %s" if zh else "CHAMPION · %s") % champion_name,16,Color("fff4d1"))
 else:
  DerbyMenus.title(r,root,Vector2(153,5),Vector2(334,40),"骑手金额排行榜" if zh else "RIDER EARNINGS",19,Color("fff4d1"))
 var header=["排名","骑手","本轮收益","累计金额"] if zh else ["RANK","RIDER","ROUND NET","TOTAL NET"]
 panel(root,Rect2(92,53,444,23),Color("0e1b34"),DerbyPainter.GOLD)
 var x: float=92
 for i in range(COLUMNS.size()):
  DerbyMenus.title(r,root,Vector2(x,53),Vector2(COLUMNS[i],23),header[i],12,DerbyPainter.GOLD)
  x+=COLUMNS[i]
 for i in range(standings.size()):
  var row: Dictionary=standings[i]
  var id: int=row.rider
  var y: float=80+i*30
  var cloth: Color=DerbyPainter.CLOTH[id]
  var border: Color=Color("ffc95b")
  var fill: Color=cloth.darkened(.53)
  panel(root,Rect2(92,y,444,28),fill,border)
  DerbyMenus.art(root,"rank_blank",Rect2(99,y+1,49,26))
  DerbyMenus.title(r,root,Vector2(99,y+4),Vector2(49,22),str(i+1),15,Color("fff7dd"))
  DerbyMenus.art(root,"leader_rider_%d" % id,Rect2(162,y,31,28)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  var name: String=r.dialogue.rider_name(id)
  if id==b.selected:name+=" ★"
  DerbyMenus.art(root,"leader_row_%d" % id,Rect2(195,y,341,28))
  DerbyMenus.title(r,root,Vector2(196,y),Vector2(103,28),name,12,Color("27243b"))
  DerbyMenus.title(r,root,Vector2(302,y),Vector2(104,28),"%+d" % int(row.net),14,Color("9e2731") if row.net<0 else Color("24632e"))
  DerbyMenus.title(r,root,Vector2(412,y),Vector2(107,28),str(row.total),14,Color("27243b"))
 var goal: String=("第 %d/8 轮 · 最终目标：累计金额第1名" if zh else "ROUND %d/8 · GOAL: TOP TOTAL EARNINGS") % b.round_number
 if final_round:goal="第 8/8 轮 · 最终结算" if zh else "ROUND 8/8 · FINAL RESULTS"
 DerbyMenus.title(r,root,Vector2(92,261),Vector2(444,17),goal,12,DerbyPainter.GOLD)
 var wallet_text: String=("实际钱包 %d" if zh else "WALLET %d") % b.funds
 var wallet: Label=DerbyMenus.title(r,root,Vector2(410,281),Vector2(126,14),wallet_text,9)
 r.coins.bind(wallet,"实际钱包 " if zh else "WALLET ")
 DerbyMenus.title(r,root,Vector2(92,281),Vector2(313,14),"各骑手按本轮下注额及各自赔率计算" if zh else "SAME ROUND STAKE · EACH RIDER'S OWN ODDS",9,Color("d7dbe5"))
 var detail: Button=DerbyMenus.button(r,root,Rect2(171,325,142,28),"比赛结算" if zh else "RACE RESULTS",func():r.show_menu("results"))
 detail.name="LeaderboardResults"
 var next_text: String="下一轮" if zh else "NEXT ROUND"
 var next_action: Callable=r.begin_round
 if b.can_rescue():next_text="救济重赛" if zh else "ONE RETRY"
 elif b.champion_presentation_available():
  next_text=("自动播放 %d秒" if zh else "AUTO PLAY IN %ds") % int(CHAMPION_PREVIEW_SECONDS)
  next_action=r.show_champion_presentation
 elif b.campaign_outcome()!="ongoing":next_text="挑战结算" if zh else "RUN RESULTS"
 var next: Button=DerbyMenus.button(r,root,Rect2(327,325,142,28),next_text,next_action)
 next.name="LeaderboardNext"
 if b.champion_presentation_available():
  var countdown: Tween=root.create_tween()
  countdown.tween_method(func(remaining: float):
   next.text=("自动播放 %d秒" if zh else "AUTO PLAY IN %ds") % maxi(1,ceili(remaining)),
   CHAMPION_PREVIEW_SECONDS,0.0,CHAMPION_PREVIEW_SECONDS)
  countdown.tween_callback(func():
   if r.mode=="leaderboard" and root.get_parent()==r.menu_layer and b.champion_presentation_available():
    r.show_champion_presentation())
