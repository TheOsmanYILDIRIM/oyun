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

-- The obstacle cache cannot grow without limit as the camera roams.
local bounded=Adapter.new(q,8)
bounded.max_cache=32
for i=0,120 do bounded:blocked(i,-i) end
assert(bounded.cache_size<=32,"collision cache grew without bound")
-- Ensure A* respects the exact swept-square footprint, not endpoints alone.
local synthetic={obstacles=function(_,x1,y1,x2,y2)
  local wall={x=7,y=-4,w=2,h=8}
  if x1<wall.x+wall.w and x2>wall.x and y1<wall.y+wall.h and y2>wall.y then return {wall} end
  return {}
end}
assert(Collision.can_stand(synthetic,0,0,1) and Collision.can_stand(synthetic,16,0,1))
local sx,sy,hit=Collision.move(synthetic,0,0,16,0,1)
assert(hit and sx<7,"swept wall penetration")
print("WORLD_PLAYER_EDGE_OK")

-- Conservative organic-boundary raster check for 8-unit collision cells.
local inspected,wet=0,0
for y=-512,512,8 do for x=-512,512,8 do
  local ix,iy=math.floor(x/8),math.floor(y/8)
  for _,uv in ipairs({{0,0},{.25,.25},{.5,.5},{.75,.75},{1,1}}) do
    local wx,wy=x+uv[1]*8,y+uv[2]*8
    if not q:is_walkable(wx,wy) then
      wet=wet+1
      assert(a:blocked(ix,iy),'sampled water not blocked')
    end
    inspected=inspected+1
  end
end end
-- A real seed can legitimately have no water in a bounded local window.
-- Independently assert an explicit synthetic organic water boundary.
local synthetic_water={
  is_walkable=function(_,x,y)
    return ((x-3)^2+(y+5)^2)>24^2
  end
}
local water_adapter=Adapter.new(synthetic_water,8)
local wet_fixture=0
for iy=-5,5 do for ix=-5,5 do
  for _,uv in ipairs({{0,0},{.25,.25},{.5,.5},{.75,.75},{1,1}}) do
    local x,y=(ix+uv[1])*8,(iy+uv[2])*8
    if not synthetic_water:is_walkable(x,y) then
      assert(water_adapter:blocked(ix,iy),'synthetic water collision missing')
      wet_fixture=wet_fixture+1
    end
  end
end end
assert(wet_fixture>0,'synthetic water fixture has no water')
print('WORLD_PLAYER_WATER_SAMPLES_OK',inspected,wet)

-- A* must reject a blocked connector between non-grid start and first grid node.
local thinwall={obstacles=function(_,x1,y1,x2,y2)
  local rect={x=3,y=-2,w=1,h=4}
  if x1<rect.x+rect.w and x2>rect.x and y1<rect.y+rect.h and y2>rect.y then return {rect} end
  return {}
end}
local blocked_path,blocked_reason=Path.find(thinwall,5,0,32,0,0,16,128)
assert(blocked_path==nil and blocked_reason=='start_connector_blocked',tostring(blocked_reason))
print('WORLD_PLAYER_CONNECTOR_OK')
