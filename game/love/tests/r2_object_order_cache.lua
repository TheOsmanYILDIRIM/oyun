-- Validate stable R2 depth ordering against the original each frame.
package.path="./?.lua;./?/init.lua;"..package.path
local events={}
package.loaded["player.core_visual"]={draw=function() events[#events+1]="player" end}
package.loaded["player.axe_strike"]={draw=function() end}
local R=require("objects.renderer")
love={graphics={
 push=function() end,pop=function() end,setColor=function() end,
 ellipse=function(mode,x) if mode=="fill" then
   events[#events+1]="obj:"..tostring(x) end end,
 rectangle=function() end,polygon=function() end,
 setLineWidth=function() end
}}
local objs={
 {id="a",x=10,y=0,cx=0,cy=0,kind="rock",radius=2},
 {id="b",x=20,y=0,cx=0,cy=0,kind="rock",radius=2},
 {id="c",x=265,y=0,cx=1,cy=0,kind="rock",radius=2}
}
local depleted,queries={},0
local world={generator_version=1}
function world:is_depleted(id) return depleted[id] or false end
function world:objects_in(bounds,all)
 assert(all==true)
 queries=queries+1
 local result={}
 for _,o in ipairs(objs) do
  if o.x>=bounds.min_x and o.x<bounds.max_x then
   result[#result+1]=o
  end
 end
 return result
end
local chunks={
 {x=0,y=0,cx=0,cy=0,size=256},
 {x=256,y=0,cx=1,cy=0,size=256}}
local stream={visible=function() return chunks end}
local camera={zoom=1,project=function(_,x,y) return x,y end}
local player={x=15,y=0}
local function render(mode)
 events={};R.static_order=mode
 local n=R.draw(world,stream,camera,400,400,player,nil,nil)
 return table.concat(events,","),n
end
assert(R.prewarm(world,stream,1)==1)
assert(R.prewarm(world,stream,1)==1)
assert(R.prewarm(world,stream,1)==0)
assert(queries==2)
for _,x in ipairs({15,100,10,300}) do
 player.x=x
 local baseline,n=render(false)
 local optimized,m=render(true)
 assert(baseline==optimized and n==m and n==3,"ordered pixels/count diverged")
end
local old_queries=queries
local baseline=select(1,render(false))
assert(select(1,render(true))==baseline and queries==old_queries,
 "cached draw repeated cold object queries")
depleted["a"]=true
assert(select(1,render(false))==select(1,render(true)),
 "depleted instance persisted in indexed render")
depleted["a"]=nil
assert(select(1,render(false))==select(1,render(true)),
 "regrown instance not drawn")
table.remove(chunks)
assert(select(1,render(false))==select(1,render(true)),
 "eviction retained old object")
local newworld={generator_version=1}
function newworld:is_depleted(id) return false end
function newworld:objects_in(bounds,all) return world:objects_in(bounds,all) end
assert(#R.prepare(newworld,stream)==2,"changed object world reused candidates")
print("R2_OBJECT_ORDER_PARITY_OK warm/depletion/regrowth/eviction/world identity")
