class_name DerbyCollision
extends RefCounted
static func tick(horses: Array, elapsed: float=0.0, player_id: int=-1, ally_ids: Array=[]) -> Array:
 var impacts: Array=[]
 for i in range(horses.size()):
  for j in range(i+1,horses.size()):
   var a: DerbyHorse=horses[i]
   var b: DerbyHorse=horses[j]
   if a.finished or b.finished:continue
   var phase_delta:=fposmod(a.x-b.x+DerbyTrack.LAP_LENGTH*.5,DerbyTrack.LAP_LENGTH)-DerbyTrack.LAP_LENGTH*.5
   # Use distance along the course and actual lateral occupancy, including lane changes.
   # A bend must not turn two separate adjacent lanes into a false head-on contact.
   var across: float=absf(a.y-b.y)
   var factor: float=DerbyTrack.progress_factor((a.x+b.x)*.5,((a.y+b.y)*.5-140)/27.0)
   var along: float=absf(phase_delta)/factor
   if across>=DerbyConfig.BODY_WIDTH or along>=DerbyConfig.BODY_LENGTH:continue
   var friendly_pair: bool=player_id>=0 and ((a.id==player_id and b.id in ally_ids) or (b.id==player_id and a.id in ally_ids))
   var gap: float=DerbyConfig.BODY_LENGTH-along+.01
   var direction: float=1 if phase_delta>=0 else -1
   if friendly_pair:
    var ally: DerbyHorse=b if a.id==player_id else a
    var push_dir: float=-direction if ally==b else direction
    ally.x=maxf(0.0,ally.x+push_dir*gap*DerbyTrack.progress_factor(ally.x,(ally.y-140)/27))
    continue
   var rear: DerbyHorse=b if phase_delta>0 else a
   var lead: DerbyHorse=a if phase_delta>0 else b
   var rammer: DerbyHorse=null
   var victim: DerbyHorse=null
   if rear.overdrive_active and (rear.speed>lead.speed+2.0 or rear.blend<1):
    rammer=rear
    victim=lead
   elif lead.overdrive_active and lead.blend<1:
    rammer=lead
    victim=rear
   # Separate the pair. When a ramming horse is involved, only the victim is pushed:
   # the attacker must keep its charge instead of being shoved backwards by the solver.
   var a_share: float=0.0 if a.invincible>0 and b.invincible<=0 else 1.0 if b.invincible>0 and a.invincible<=0 else .5
   if rammer!=null:
    var victim_push: float=gap if victim==lead else -gap
    victim.x=maxf(0.0,victim.x+victim_push*DerbyTrack.progress_factor(victim.x,(victim.y-140)/27))
   else:
    a.x=maxf(0.0,a.x+direction*gap*a_share*DerbyTrack.progress_factor(a.x,(a.y-140)/27))
    b.x=maxf(0.0,b.x-direction*gap*(1-a_share)*DerbyTrack.progress_factor(b.x,(b.y-140)/27))
   if rammer!=null and not victim.attack_guarded() and float(rammer.ram_cooldowns.get(victim.id,0))<=elapsed:
    var stall: float=DerbyConfig.OVERDRIVE_RED_STALL if rammer.id==0 else DerbyConfig.OVERDRIVE_CONTACT_STALL
    victim.overdrive_stall=maxf(victim.overdrive_stall,stall/maxf(.7,victim.recovery_stat))
    victim.collision_count+=1
    victim.protection=maxf(victim.protection,stall)
    rammer.ram_cooldowns[victim.id]=elapsed+DerbyConfig.OVERDRIVE_CONTACT_COOLDOWN
    var aimed: bool=rammer.ram_target==victim.id
    if aimed:
     victim.knockdown=maxf(victim.knockdown,DerbyConfig.OVERDRIVE_AIMED_FALL)
     rammer.ram_target=-1
    impacts.append({"heavy":aimed,"horses":[a.id,b.id],"rammer":rammer.id,"victim":victim.id})
    continue
   if rammer!=null:continue
   if (a.protection<=0 or b.protection<=0) and (rear.speed-lead.speed>6 or a.blend<1 or b.blend<1):
    if (a.attack_guarded() or a.overdrive_active) and (b.attack_guarded() or b.overdrive_active):continue
    impacts.append({"heavy":rear.speed-lead.speed>30 or (a.blend<1 and b.blend<1),"horses":[a.id,b.id]})
    for h in [a,b]:
     if h.attack_guarded() or h.overdrive_active:continue
     if h.protection<=0:
      if rear.speed-lead.speed>30 or (a.blend<1 and b.blend<1):h.knockdown=1.0
      h.collision_count+=1
      h.stun=DerbyConfig.COLLISION_SECONDS/h.recovery_stat
     h.protection=DerbyConfig.PROTECTION_SECONDS
     h.dash_time=0

 return impacts
