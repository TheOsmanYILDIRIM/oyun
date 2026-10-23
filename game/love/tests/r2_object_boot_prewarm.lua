-- Identical immutable candidates; no startup frame-wide cold queries.
package.path="./?.lua;./?/init.lua;"..package.path
package.loaded["player.core_visual"]={draw=function() end}
package.loaded["player.axe_strike"]={draw=function() end}
local R=require("objects.renderer")
local queries,depleted=0,{}
local world={generator_version=1}
function world:is_depleted(id) return depleted[id]==true end
function world:objects_in(bounds,include_depleted)
 assert(include_depleted==true)
 queries=queries+1
 local cx=math.floor(bounds.min_x/256)
 return {{id="tree:"..cx,x=cx*256+16,y=12,cx=cx,cy=0,kind="tree",radius=5}}
end
local chunks={}
for cx=0,7 do chunks[#chunks+1]={x=cx*256,y=0,cx=cx,cy=0,size=256} end
local stream={visible=function() return chunks end}
for frame=1,8 do
 local n,done=R.prewarm(world,stream,1)
 assert(n==1 and done==(frame==8), "must prepare one resident chunk/frame")
 assert(queries==frame)
end
local n,done=R.prewarm(world,stream,1)
assert(n==0 and done and queries==8)
assert(#R.collect(world,stream)==8 and queries==8,"cold first-draw query survived")
depleted["tree:0"]=true
assert(#R.collect(world,stream)==7 and queries==8,"live depletion lost")
depleted["tree:0"]=nil
assert(#R.collect(world,stream)==8 and queries==8,"live regrowth lost")
chunks[1]={x=0,y=0,cx=0,cy=0,size=256}
assert(R.prewarm(world,stream,1)==1 and queries==9,
 "new chunk identity reused stale candidates")
local nextworld={generator_version=1,is_depleted=world.is_depleted,
  objects_in=world.objects_in}
assert(R.prewarm(nextworld,stream,1)==1 and queries==10,
 "new world identity reused old candidates")
print("R2_OBJECT_BOOT_PREWARM_OK deterministic/identity/live-regrowth")
