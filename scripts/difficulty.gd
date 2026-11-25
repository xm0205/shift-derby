class_name DerbyDifficulty
extends RefCounted

const DISTANCE_LAPS=[1.0,1.2,1.5,1.8,2.0,2.2,2.4,2.6]
const WARNING=[2.65,2.43,2.18,2.00,1.84,1.68,1.52,1.38]
const WINDOW=[.55,.45,.35,.31,.28,.25,.225,.205]
const AI_COUNTER_ODDS=[.12,.38,.72,.80,.85,.89,.93,.95]
const PRESSURE_PHASES=[
 [.06,.20], [.06,.20], [.06,.17,.29,.43], [.06,.17,.29,.43],
 [.06,.17,.29,.43], [.055,.15,.26,.48,.72], [.05,.145,.25,.48,.74], [.05,.14,.24,.46,.72],
]
const FINAL_TACTICS_START=.77

static func index(round_number: int) -> int:return clampi(round_number-1,0,DISTANCE_LAPS.size()-1)
static func laps(round_number: int) -> int:return ceili(DISTANCE_LAPS[index(round_number)])
static func distance(round_number: int) -> float:return DerbyTrack.LAP_LENGTH*DISTANCE_LAPS[index(round_number)]
static func warning(round_number: int) -> float:return WARNING[index(round_number)]
static func window(round_number: int) -> float:return WINDOW[index(round_number)]
static func open_attack_slots(round_number: int,progress: float) -> int:
 var slots: int=0
 for phase: float in PRESSURE_PHASES[index(round_number)]:
  if progress<phase:break
  slots+=1
 return slots
static func in_final_stretch(progress: float,distance: float) -> bool:return progress>=distance*FINAL_TACTICS_START
static func counter_odds(round_number: int) -> float:return AI_COUNTER_ODDS[index(round_number)]
static func opening_after_hit(round_number: int) -> int:
 return [0,1,1,2,2,3,4,5][index(round_number)]
