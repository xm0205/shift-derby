class_name DerbyBetting
extends RefCounted
const NAMES = ["CHESTNUT","SHADOW","SILVER","ONYX","GOLDIE","PATCHES"]
const ZH = ["赤栗","苍影","银风","黑曜","金麦","花斑"]
const STATS = [[1.03,.55,1.0],[1.01,.52,1.06],[1.02,.68,1.02],[1.02,.60,1.05],[1.01,.65,1.04],[1.02,.60,1.08]]
const STAMINA = [.94,1.04,.97,.99,1.05,1.04]
const STARTING_FUNDS = 300
const ROUND_LIMIT = 8
const TARGET_FUNDS = 50000
const ROUND_GATES = [450,900,1800,3500,7000,14000,26000,50000]
const PODIUM_SHARE = [1.0,.60,.40]
var funds: int=STARTING_FUNDS
var selected: int=0
var amount: int=0
var odds: Array[float]=[]
var active:=false
var settled:=false
var reward:=0
var net:=0
var round_number:=0
var rescue_used:=false
var rider_results: Dictionary={}
var champion_seen: bool=false
var round_start_funds: int=STARTING_FUNDS
func prepare(seed_id: int):
 var rng:=RandomNumberGenerator.new()
 rng.seed=seed_id+901
 odds.clear()
 for stats in STATS:
  var strength: float=stats[0]*.65+stats[1]*.15+stats[2]*.20
  odds.append(snappedf(clampf(3.6-(strength-.94)*10+rng.randf_range(-.55,.55),1.5,6),.1))
 amount=0
 active=false
 settled=false
 reward=0
 net=0
func adjust(delta: int):
 amount=clampi(amount+delta,0,funds)
 if amount>0 and amount<50:amount=0
func maximum() -> int:
 return funds if funds>=50 else 0
func confirm() -> bool:
 if campaign_outcome()!="ongoing" or active or amount<0 or amount>funds or (amount>0 and amount<50):return false
 round_start_funds=funds
 funds-=amount
 active=true
 settled=false
 round_number+=1
 return true
func projected_return(place: int,rider: int=-1) -> int:
 if amount==0 or place<1 or place>PODIUM_SHARE.size():return 0
 var winning_profit := amount*(odds[selected if rider<0 else rider]-1.0)
 return amount+roundi(winning_profit*PODIUM_SHARE[place-1])
func settle(winner: int, finish_order: Array=[]):
 if not active or settled:return
 var place: int=finish_order.find(selected)+1 if not finish_order.is_empty() else (1 if winner==selected else 0)
 reward=projected_return(place)
 funds+=reward
 net=reward-amount
 if finish_order.size()==STATS.size() and odds.size()==STATS.size() and not rider_results.has(round_number):
  var earnings: Array[int]=[]
  for rider in range(STATS.size()):
   earnings.append(projected_return(finish_order.find(rider)+1,rider)-amount)
  rider_results[round_number]={"net":earnings,"order":finish_order.duplicate()}
 settled=true
func rider_standings() -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 var latest: Dictionary=rider_results.get(round_number,{})
 var current: Array=latest.get("net",[])
 var finish: Array=latest.get("order",[])
 for rider in range(STATS.size()):
  var total: int=0
  for race: Dictionary in rider_results.values():total+=int(race.net[rider])
  var place: int=finish.find(rider)+1 if not finish.is_empty() else rider+1
  result.append({"rider":rider,"net":int(current[rider]) if not current.is_empty() else 0,"total":total,"place":place})
 result.sort_custom(func(a,b):return a.total>b.total if a.total!=b.total else a.place<b.place)
 return result
func champion_presentation_available() -> bool:
 return round_number==ROUND_LIMIT and settled and rider_results.has(ROUND_LIMIT) and not can_rescue() and not champion_seen and int(rider_standings()[0].rider)==selected
func refund_abandoned():
 if active and not settled:funds+=amount
 active=false
func new_game():
 funds=STARTING_FUNDS
 round_start_funds=STARTING_FUNDS
 selected=0
 round_number=0
 active=false
 settled=false
 rescue_used=false
 rider_results.clear()
 champion_seen=false

func retry_round_fee() -> int:
 var base: int=round_start_funds if round_start_funds>0 else (funds+amount if not settled else maxi(funds,amount))
 return maxi(1,roundi(base*.20)) if base>=5 else 0

func retry_round_available(offer_paid: int=0) -> bool:
 if not active or round_number<1 or round_number>ROUND_LIMIT:return false
 var fee: int=retry_round_fee()
 if fee<=0:return false
 var base_funds: int=funds-reward-offer_paid if settled else funds
 return maxi(0,base_funds)+amount>=fee

func retry_current_round(offer_paid: int=0) -> bool:
 if not retry_round_available(offer_paid):return false
 var fee: int=retry_round_fee()
 if settled:
  funds=maxi(0,funds-reward-offer_paid)
  rider_results.erase(round_number)
  champion_seen=false
  settled=false
  reward=0
  net=0
 var from_bet: int=mini(amount,fee)
 amount-=from_bet
 funds=maxi(0,funds-(fee-from_bet))
 round_start_funds=funds+amount
 active=true
 return true

func can_rescue() -> bool:
 return settled and round_number>=1 and round_number<=ROUND_LIMIT and funds<ROUND_GATES[round_number-1] and not rescue_used

func rescue_balance() -> int:
 if not can_rescue():return funds
 return maxi(funds,maxi(STARTING_FUNDS,ceili(ROUND_GATES[round_number-1]*.5)))

func rescue() -> bool:
 if not can_rescue():return false
 funds=rescue_balance()
 rescue_used=true
 rider_results.erase(round_number)
 champion_seen=false
 round_number-=1
 active=false
 settled=false
 return true

func campaign_outcome() -> String:
 # An all-in bet can have zero liquid funds while the horse is still racing.
 if active and not settled:return "ongoing"
 if round_number>=ROUND_LIMIT and funds>=TARGET_FUNDS:return "victory"
 if funds<=0 or round_number>=ROUND_LIMIT:return "defeat"
 if settled and round_number>0 and funds<ROUND_GATES[round_number-1]:return "defeat"
 return "ongoing"
func save_state() -> Dictionary:
 return {"funds":funds,"round_start_funds":round_start_funds,"selected":selected,"amount":amount,"odds":odds.duplicate(),"active":active,"settled":settled,"reward":reward,"net":net,"round_number":round_number,"rescue_used":rescue_used,"rider_results":rider_results.duplicate(true),"champion_seen":champion_seen}
func restore_state(state: Dictionary):
 for key in state:
  if key=="odds":odds.assign(state[key])
  elif key=="rider_results":rider_results=state[key].duplicate(true)
  elif key in save_state():set(key,state[key])
