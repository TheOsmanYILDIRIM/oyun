package.path="./?.lua;./?/init.lua;"..package.path
local Query=require("world.world_query")
local Adapter=require("world.collision_adapter")
local Collision=require("physics.collision")
local Controller=require("player.controller")
local Path=require("navigation.pathfinder")
local q=Query.new(20261015)
local a=Adapter.new(q,8)
for _,p in ipairs({{-513,-257},{-256,-256},{0,0},{127,128},{256,-1}}) do
  local first=a:obstacles(p[1],p[2],p[1]+32,p[2]+32)
  local again=a:obstacles(p[1],p[2],p[1]+32,p[2]+32)
  assert(#first==#again,"non-deterministic collision")
end
local ok=pcall(function() a:obstacles(0,0,999999,999999) end)
assert(not ok,"must fail closed on huge query")
local found
for y=-128,128,8 do for x=-128,128,8 do
  if Collision.can_stand(a,x,y,5) then found={x=x,y=y};break end
end if found then break end end
assert(found,"no test spawn")
local p=Controller.new(a,{x=found.x,y=found.y,radius=5})
for _=1,120 do
  p:update(1/60,1,0)
  assert(Collision.can_stand(a,p.x,p.y,5),"player crossed water")
end
local path,reason=Path.find(a,p.x,p.y,p.x,p.y,5,16,128)
assert(path or reason=="goal_blocked",reason or "path failed")
print("WORLD_PLAYER_INTEGRATION_OK",p.x,p.y)

-- Fail-closed / negative-coordinates / chunk-independent collision regression.
local b=Adapter.new(q,8)
local before=a:obstacles(-300,-300,-250,-250)
local after=b:obstacles(-300,-300,-250,-250)
assert(#before==#after,"eviction-independent colliders differ")
local bad=pcall(function() a:obstacles(0/0,0,1,1) end)
assert(not bad,"nonfinite bounds permitted")
for _,r in ipairs(a:obstacles(-128,-128,128,128)) do
  local cx,cy=r.x+r.w*.5,r.y+r.h*.5
  assert(not Collision.can_stand(a,cx,cy,0),"water obstacle did not block")
end
print("WORLD_PLAYER_NEGATIVE_OK")
