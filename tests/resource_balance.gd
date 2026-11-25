extends SceneTree

func _initialize():call_deferred("run")

func run():
 var r=load("res://main.tscn").instantiate()
 root.add_child(r)
 r.set_process(false)
 r.sound.muted=true
 r.player_id=0
 r.combat.configure(6,DerbyDifficulty.distance(6))
 for h in r.horses:h.progress=0
 var before: int=r.combat.budgets.reduce(func(a,b):return a+b,0)
 r.combat.opening_rush(r)
 assert(r.combat.budgets.reduce(func(a,b):return a+b,0)==before-4)
 r.combat.opening_rush(r)
 assert(r.combat.budgets.reduce(func(a,b):return a+b,0)==before-4)
 for i in range(6):
  r.horses[i].progress=2200+i*40
  r.horses[i].energy=0
  r.horses[i].effect=0
  r.horses[i].y=140
 r.shift_charges=0
 r.combat.catch_up(r,22.0)
 assert(r.shift_charges==1 and r.horses[0].energy>0 and r.horses[2].energy==0)
 assert(r.combat.try_assist(r,r.horses[2],r.horses[5].progress,true))
 assert(is_equal_approx(r.horses[2].energy,8.0))
 assert(DerbyDifficulty.DISTANCE_LAPS==[1.0,1.2,1.5,1.8,2.0,2.2,2.4,2.6])
 print("PASS resource balance")
 quit()
