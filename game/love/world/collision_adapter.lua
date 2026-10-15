-- Deterministic collision representation independent of loaded render chunks.
-- Conservative sampling within 8-world-unit cells converts organic water masks
-- into solid AABBs for the Stage 3 swept-square collision engine.
local WorldCollision = {}
WorldCollision.__index = WorldCollision
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
function WorldCollision.new(world,cell)
  assert(world and type(world.is_walkable)=="function", "world query required")
  cell=cell or 8
  assert(finite(cell) and cell>0 and cell<=32, "invalid collision cell")
  return setmetatable({world=world,cell=cell,cache={},cache_size=0,max_cache=32768},WorldCollision)
end
function WorldCollision:blocked(ix,iy)
  local key=ix..":"..iy
  local value=self.cache[key]
  if value==nil then
    local c=self.cell
    local x,y=ix*c,iy*c
    -- Sampling footprint centre, corners and quarter points is conservative
    -- at the chosen collision resolution; not an exact contour intersection.
    value=false
    for _,u in ipairs({.125,.5,.875}) do
      for _,v in ipairs({.125,.5,.875}) do
        if not self.world:is_walkable(x+u*c,y+v*c) then value=true;break end
      end
      if value then break end
    end
    if self.cache_size>=self.max_cache then
      -- Derived values only; drop all to prevent unbounded growth on roaming.
      self.cache={}
      self.cache_size=0
    end
    self.cache[key]=value
    self.cache_size=self.cache_size+1
  end
  return value
end
function WorldCollision:obstacles(x1,y1,x2,y2)
  assert(finite(x1) and finite(y1) and finite(x2) and finite(y2)
    and x1<=x2 and y1<=y2, "invalid obstacle bounds")
  local c=self.cell
  local ix1,iy1=math.floor(x1/c),math.floor(y1/c)
  local ix2,iy2=math.floor(x2/c),math.floor(y2/c)
  local count=(ix2-ix1+1)*(iy2-iy1+1)
  assert(count<=4096, "collision query budget exceeded")
  local result={}
  for iy=iy1,iy2 do for ix=ix1,ix2 do
    if self:blocked(ix,iy) then
      result[#result+1]={x=ix*c,y=iy*c,w=c,h=c}
    end
  end end
  return result
end
return WorldCollision
