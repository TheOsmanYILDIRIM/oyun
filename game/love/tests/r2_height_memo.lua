-- Immutable R2 memo: exact geometry parity, bounded lifetime, dynamic bypass.
package.path="./?.lua;./?/init.lua;"..package.path
local Topo=require("world.topography_surface")
local computations=0
local function height(x,y)
  computations=computations+1
  return x*.023+y*.017+math.sin(x*.11-y*.013)
end
local raw=Topo.new({height_at=height})
local memo=Topo.new({height_at=height,static_height_cache=true})
local points={{0,0},{-0.1,4.5},{17,19},{-40,-70},{128.5,0.2}}
for _,p in ipairs(points) do
  local x,y=p[1],p[2]
  assert(memo:height(x,y)==raw:height(x,y))
  local a,b=memo:sample(x,y),raw:sample(x,y)
  for _,field in ipairs({"height","gradient_x","gradient_y","grade","class"}) do
    assert(a[field]==b[field],"height memo parity "..field)
  end
end
local hits_before=memo._height_cache.hits
local misses_before=memo._height_cache.misses
for _=1,5 do memo:sample(-0.1,4.5) end
assert(memo._height_cache.hits>hits_before,"memo did not reuse")
assert(memo._height_cache.misses==misses_before,"memo unexpected miss")
local changed=0
local dynamic=Topo.new({height_at=function(x,y) changed=changed+1;return x+y+changed end})
assert(dynamic:height(1,2)~=dynamic:height(1,2),"dynamic accidentally cached")
assert(not dynamic._height_cache,"dynamic must not cache")
for i=1,33000 do memo:height(i*0.5,-i*0.25) end
assert(memo._height_cache.count<=32768 and memo._height_cache.cursor>=1)
assert(memo._height_cache.count==32768)
print("R2_HEIGHT_MEMO_PARITY_OK hit="..memo._height_cache.hits.." miss="..memo._height_cache.misses)
