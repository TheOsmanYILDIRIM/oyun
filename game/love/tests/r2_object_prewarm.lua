package.path="./?.lua;./?/init.lua;"..package.path
package.loaded["player.core_visual"]={draw=function() end}
package.loaded["player.axe_strike"]={draw=function() end}
local R=require("objects.renderer")
local n=0
local world={generator_version=1}
function world:is_depleted() return false end
function world:objects_in(bounds,include_depleted)
 assert(include_depleted==true)
 n=n+1
 return {{id="o"..tostring(bounds.min_x),x=bounds.min_x+8,
   y=8,cx=bounds.min_x/256,cy=0,kind="tree",radius=5}}
end
local chunks={}
for i=0,7 do chunks[#chunks+1]={x=i*256,y=0,cx=i,cy=0,size=256} end
local stream={visible=function() return chunks end}
for frame=1,5 do
 local warmed=R.prewarm(world,stream,2)
 assert(warmed==(frame<=4 and 2 or 0))
 assert(n==math.min(frame*2,8))
end
local list=R.collect(world,stream)
assert(#list==8 and n==8,"prewarm must avoid all cold first-draw queries")
chunks[1]={x=0,y=0,cx=0,cy=0,size=256}
assert(R.prewarm(world,stream,1)==1 and n==9,
 "fresh resident identity must invalidate old prewarm")
local nextworld={generator_version=1,is_depleted=world.is_depleted,
  objects_in=world.objects_in}
assert(R.prewarm(nextworld,stream,1)==1 and n==10,
 "changed object-world identity must invalidate prewarm")
print("R2_OBJECT_PREWARM_OK cold_query_budget/lifetime/live_state")
