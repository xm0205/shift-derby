extends RefCounted
class_name DerbyRiderFavors

const DATA_PATH="res://assets/data/rider_favors.json"
const RIDER_COUNT=6

var rules: Dictionary
var records: Array[Dictionary]=[]
var previous_gaps: Array[float]=[]
var last_request_round: int=0
var last_player_request: Dictionary={}
var check_after: float=0.0
var affection: Array[int]=[0,0,0,0,0,0]
var asked_topics: Array=[[],[],[],[],[],[]]
var mid_assist_used: Array[bool]=[false,false,false,false,false,false]

func _init():
 rules=JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
 restore({})
 reset_race()

func reset_race():
 previous_gaps.assign([INF,INF,INF,INF,INF,INF])
 mid_assist_used.assign([false,false,false,false,false,false])
 check_after=0.0

func save_state() -> Dictionary:
 return {"last_request_round":last_request_round,"riders":records.duplicate(true),"player_request":last_player_request.duplicate(),"affection":affection.duplicate(),"asked_topics":asked_topics.duplicate(true)}

func restore(state: Dictionary):
 last_request_round=clampi(int(state.get("last_request_round",0)),0,DerbyBetting.ROUND_LIMIT)
 last_player_request=state.get("player_request",{}).duplicate()
 var saved_aff: Array=state.get("affection",[])
 affection.assign([0,0,0,0,0,0])
 for i in range(mini(RIDER_COUNT,saved_aff.size())):
  affection[i]=clampi(int(saved_aff[i]),0,100)
 var saved_asked: Array=state.get("asked_topics",[])
 asked_topics=[[],[],[],[],[],[]]
 for i in range(mini(RIDER_COUNT,saved_asked.size())):
  if saved_asked[i] is Array:asked_topics[i]=saved_asked[i].duplicate()
 records.clear()
 var saved: Array=state.get("riders",[])
 for id in range(RIDER_COUNT):
  var rider: Dictionary=saved[id] if id<saved.size() else {}
  records.append({"chat":rider.get("chat",[]).duplicate(),"requests":rider.get("requests",{}).duplicate(),"helped_round":int(rider.get("helped_round",0))})

func observe(r) -> int:
 var own: DerbyHorse=r.horses[r.player_id]
 var round_no: int=r.betting.round_number
 if own.finished or round_no<1 or round_no<=last_request_round:return -1
 var max_gap: float=rules.request.approach_range
 var ready: bool=r.elapsed>=maxf(float(rules.request.start_after),check_after) and own.progress<r.race_distance*.88
 var closest: float=INF
 var candidate: int=-1
 for h: DerbyHorse in r.horses:
  if h==own or h.finished:continue
  var gap: float=h.progress-own.progress
  var previous: float=previous_gaps[h.id]
  previous_gaps[h.id]=gap
  if not ready or not eligible(h.id,round_no):continue
  if previous>=-5 or gap-previous<.5 or gap< -max_gap or gap>2.0 or absf(gap)>=closest:continue
  if not r.dialogue.near_player(h.id):continue
  candidate=h.id
  closest=absf(gap)
 return candidate

func eligible(id: int,round_no: int) -> bool:
 var rider: Dictionary=records[id]
 if rider.helped_round!=0 or rider.requests.size()>=int(rules.request.maximum_per_rider):return false
 for previous in rider.requests:
  if round_no-int(previous)<int(rules.request.rider_round_interval):return false
 return true

func begin(id: int,round_no: int) -> bool:
 if round_no<=last_request_round or not eligible(id,round_no):return false
 last_request_round=round_no
 records[id].requests[str(round_no)]="ignored"
 return true

func respond(id: int,round_no: int,accepted: bool) -> bool:
 var entry: Dictionary=records[id]
 var key: String=str(round_no)
 if round_no!=last_request_round or entry.requests.get(key,"")!="ignored":return false
 entry.requests[key]="helped" if accepted else "declined"
 if accepted:entry.helped_round=round_no
 return true

func friendly_topic(spoken: String,emote_id: int) -> String:
 var normalized:=spoken.to_lower()
 for separator in [" ","\t","。","！","？","，","、",".","!","?",",","～","~"]:
  normalized=normalized.replace(separator,"")
 for token: Dictionary in rules.chat.signals:
  if normalized in token.words or token.emotes.any(func(icon):return int(icon)==emote_id):return token.id
 return ""

func record_chat(id: int,topic: String) -> bool:
 if topic.is_empty():return false
 var chat: Array=records[id].chat
 if topic in chat or chat.size()>=int(rules.chat.maximum):return false
 chat.append(topic)
 return true

func topic_asked(id: int,topic: String) -> bool:
 return id>=0 and id<asked_topics.size() and topic in asked_topics[id]

func mark_topic_asked(id: int,topic: String):
 if id>=0 and id<asked_topics.size() and not (topic in asked_topics[id]):
  asked_topics[id].append(topic)

func affection_of(id: int) -> int:
 return affection[id] if id>=0 and id<affection.size() else 0

func add_affection(id: int,delta: int) -> int:
 if id<0 or id>=affection.size():return 0
 var before: int=affection[id]
 affection[id]=clampi(before+delta,0,100)
 return affection[id]-before

func heart_stage(id: int) -> int:
 return heart_stage_for(affection_of(id))

static func heart_stage_for(val: int) -> int:
 if val>=100:return 6
 if val>=80:return 5
 if val>=60:return 4
 if val>=40:return 3
 if val>=20:return 2
 if val>0:return 1
 return 0

func social_bonus(id: int) -> float:
 var record: Dictionary=records[id]
 var trust: float=float(rules.help_bonus) if record.helped_round>0 else 0.0
 return trust+minf(record.chat.size(),float(rules.chat.maximum))*float(rules.chat.bonus)+float(affection_of(id))/100.0*.25

func chance_for(base: float,id: int) -> float:
 return clampf(base+float(rules.riders[id].inclination)+social_bonus(id),float(rules.minimum_chance),float(rules.maximum_chance))
