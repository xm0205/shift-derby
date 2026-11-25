class_name DerbyTrack
extends RefCounted
const STRAIGHT = 1000.0
const BEND_LENGTH = 700.0
const RADIUS = BEND_LENGTH / PI
const LANE_METERS = 18.0
const LAP_LENGTH = 3400.0
static func gap(from_progress: float,to_progress: float) -> float:
 return fposmod(to_progress-from_progress+LAP_LENGTH*.5,LAP_LENGTH)-LAP_LENGTH*.5
static func bend(s: float) -> bool:
 var p:=fposmod(s,LAP_LENGTH)
 return (p>=STRAIGHT and p<STRAIGHT+BEND_LENGTH) or p>=2*STRAIGHT+BEND_LENGTH
static func bend_weight(s: float) -> float:
 var p:=fposmod(s,LAP_LENGTH)
 for start in [STRAIGHT,2*STRAIGHT+BEND_LENGTH]:
  if p>=start and p<start+BEND_LENGTH:
   return smoothstep(0.0,35.0,minf(p-start,start+BEND_LENGTH-p))
 return 0.0
static func point(s: float) -> Vector2:
 var p:=fposmod(s,LAP_LENGTH)
 if p<STRAIGHT:return Vector2(p,0)
 if p<STRAIGHT+BEND_LENGTH:
  var a: float=(p-STRAIGHT)/RADIUS
  return Vector2(STRAIGHT+RADIUS*sin(a),RADIUS-RADIUS*cos(a))
 if p<2*STRAIGHT+BEND_LENGTH:return Vector2(2*STRAIGHT+BEND_LENGTH-p,2*RADIUS)
 var a: float=(p-2*STRAIGHT-BEND_LENGTH)/RADIUS
 return Vector2(-RADIUS*sin(a),RADIUS+RADIUS*cos(a))
static func tangent(s: float) -> Vector2:
 var p:=fposmod(s,LAP_LENGTH)
 if p<STRAIGHT:return Vector2.RIGHT
 if p<STRAIGHT+BEND_LENGTH:return Vector2.from_angle((p-STRAIGHT)/RADIUS)
 if p<2*STRAIGHT+BEND_LENGTH:return Vector2.LEFT
 return Vector2.from_angle(PI+(p-2*STRAIGHT-BEND_LENGTH)/RADIUS)
static func progress_factor(s: float, lane_position: float) -> float:
 if not bend(s): return 1.0
 return RADIUS/(RADIUS+(lane_position-2.5)*(LANE_METERS*.42))
static func visual_offset(s: float, focus: float) -> float:
 var tangent_here := tangent(focus)
 var inward := Vector2(-tangent_here.y,tangent_here.x)
 return -(point(s)-point(focus)).dot(inward)*0.10
static func world_position(s: float, lane_position: float) -> Vector2:
 var t:=tangent(s)
 return point(s)+Vector2(t.y,-t.x)*(lane_position-2.5)*LANE_METERS
static func project(s: float, lane_position: float, focus: float) -> Vector2:
 # Fixed horizontal camera: a bird's-eye ellipse with side-on horse sprites.
 var delta:=point(s)-point(focus)
 var direction:=tangent(s)
 var forward:=Vector2(direction.x,direction.y*.30).normalized()
 var normal:=Vector2(direction.y,-direction.x)
 return Vector2(320+delta.x,207.5+delta.y*.30)+normal*(lane_position-2.5)*27
static func overview(s: float, lane_position: float) -> Vector2:
 var center:=Vector2(208,111)+Vector2(point(s).x*.44,point(s).y*.22)
 var t:=tangent(s)
 var normal:=Vector2(t.y,-t.x)
 return center+normal*(lane_position-2.5)*5
static func view_angle(s: float, focus: float) -> float:
 return (project(s+1,2.5,focus)-project(s,2.5,focus)).angle()

const SCREEN_SCALE=Vector2(.43,.24)
const SCREEN_OFFSET=Vector2(212,102)
static func map_position(progress: float, lane_position: float) -> Vector2:
 var p:=fposmod(progress,LAP_LENGTH)
 var d: float=lane_position-2.5
 var x: float
 var y: float
 if p<STRAIGHT:
  x=330+1010*p/STRAIGHT
  y=304.75-d*20.3
 elif p<STRAIGHT+BEND_LENGTH:
  var angle: float=(p-STRAIGHT)/RADIUS
  x=1340+(230+d*29.5)*sin(angle)
  y=498.625-(193.875+d*lerpf(20.3,25.0,(1-cos(angle))*.5))*cos(angle)
 elif p<2*STRAIGHT+BEND_LENGTH:
  x=1340-1010*(p-STRAIGHT-BEND_LENGTH)/STRAIGHT
  y=692.5+d*25.0
 else:
  var angle: float=(p-2*STRAIGHT-BEND_LENGTH)/RADIUS
  x=330-(230+d*29.5)*sin(angle)
  y=498.625+(193.875+d*lerpf(25.0,20.3,(1-cos(angle))*.5))*cos(angle)
 return Vector2(4,39)+Vector2(x/1672.0*632,y/941.0*284)
static func screen_ring(lane_position: float) -> PackedVector2Array:
 var points:=PackedVector2Array()
 for i in range(171):points.append(map_position(i*LAP_LENGTH/170,lane_position))
 return points
