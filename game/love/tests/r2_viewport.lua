-- Pure-Lua regression: opt-in must preserve every screen-overlapping chunk
-- at the tall mobile viewport where 48 centre-distance slots miss corners.
package.path="./?.lua;./?/init.lua;"..package.path
local Camera=require("core.camera")
local Stream=require("world.stream")
local Iso=require("world.iso")
local query={field={},sample=function() return {biome="meadow"} end}
local cam=Camera.new()
cam.x,cam.y,cam.zoom=64,128,1.7
local world=Stream.new(query,{size=256,step=8,max_loaded=48})
local function overlaps(c,w,h,pad)
  local x,y=Iso.project(c.cx*256-cam.x,c.cy*256-cam.y)
  local edge=256*math.sqrt(.5)*cam.zoom
  local sx,sy=w*.5+x*cam.zoom,h*.5+y*cam.zoom
  return sx+edge>=-pad and sx-edge<=w+pad
    and sy+edge>=-pad and sy<=h+pad
end
for _,dims in ipairs({{720,1600},{691,1536},{360,780}}) do
  local w,h=dims[1],dims[2]
  local old=world:needed(cam,w,h)
  assert(#old<=48)
  local old_keys={}
  for _,v in ipairs(old) do old_keys[v.key]=true end
  world.viewport_cover=true
  local covered=world:needed(cam,w,h)
  local present={}
  for _,v in ipairs(covered) do present[v.key]=true end
  local needed=0
  local lost_old=0
  -- Cover the entire AABB candidate range, not just the returned list.
  for cy=-7,7 do for cx=-7,7 do
    local c={cx=cx,cy=cy,key=cx..":"..cy}
    if overlaps(c,w,h,0) then
      needed=needed+1
      if not old_keys[c.key] then lost_old=lost_old+1 end
      assert(present[c.key],"screen-visible chunk missing: "..c.key)
    end
  end end
  for _,c in ipairs(covered) do
    assert(c.key and c.distance)
  end
  if h>=1536 then
    assert(lost_old>=1,"regression fixture no longer exercises 48 cutoff")
  end
  print(string.format("R2_VIEWPORT_COVER_OK size=%dx%d visible=%d old_lost=%d covered=%d",
    w,h,needed,lost_old,#covered))
  world.viewport_cover=nil
end
-- Matrix of portrait, wide, zoom-out and deep zoom. No mesh or
-- material mutation: assert conservative coverage in world/screen space.
for _,v in ipairs({
 {320,700,.65},{360,780,1.7},{392,850,1.7},{411,891,1.7},
 {691,1536,1.7},{720,1600,1.7},{1280,800,1.7},
 {360,780,3.2},{720,1600,.65}
}) do
 local width,height,zoom=v[1],v[2],v[3]
 for _,pt in ipairs({{64,128},{-200,420},{704,128}}) do
  cam.x,cam.y,cam.zoom=pt[1],pt[2],zoom
  world.viewport_cover=true
  local have=world:needed(cam,width,height)
  local present={}
  for _,chunk in ipairs(have) do present[chunk.key]=true end
  local count,pad=0,160*zoom+16
  for cy=-30,30 do for cx=-30,30 do
   local k=cx..":"..cy
   if overlaps({cx=cx,cy=cy},width,height,pad) then
    count=count+1
    assert(present[k],string.format("missing screen chunk %s %dx%d zoom %.2f",
      k,width,height,zoom))
   end
  end end
  assert(#have>=count,"visible chunk budget truncated")
  print(string.format("R2_DISPLAY_COVER_OK %dx%d zoom=%.2f screen=%d resident=%d",
    width,height,zoom,count,#have))
 end
end
world.viewport_cover=nil
cam.x,cam.y,cam.zoom=64,128,1.7

-- Exact R2 sort, chunk IDs and nearest-first order across displays.
for _,size in ipairs({{320,700},{360,780},{691,1536},
                      {720,1600},{1280,800},{800,360}}) do
 for _,zoom in ipairs({.65,.9,1.7,3.2,4.5}) do
  for _,pos in ipairs({{64,128},{704,128},{-256,-300},
                        {130.7,247.1},{512,512}}) do
   cam.x,cam.y,cam.zoom=pos[1],pos[2],zoom
   world.viewport_cover=true
   world.fast_cover_candidates=nil
   local a=world:needed(cam,size[1],size[2])
   world.fast_cover_candidates=true
   local b=world:needed(cam,size[1],size[2])
   assert(#a==#b,"screen-covered residency count changed")
   for i=1,#a do
    assert(a[i].key==b[i].key and a[i].distance==b[i].distance,
      "visible chunk ranking changed")
   end
  end
 end
end
world.fast_cover_candidates=nil;world.viewport_cover=nil
cam.x,cam.y,cam.zoom=64,128,1.7
print("R2_FAST_COVER_ORDER_PARITY_OK cases=150")
-- Per-process comparison removes most variability from separately
-- scheduled GitHub runners. These times are pure Lua candidate selection only.
local t_old,t_fast=0,0
for _,dims in ipairs({{360,780,.65},{720,1600,1.7},{1280,800,1.7}}) do
 local w,h,z=dims[1],dims[2],dims[3]
 cam.zoom=z;world.viewport_cover=true
 for n=1,120 do
  cam.x=64+n*.61;cam.y=128+n*.27
  world.fast_cover_candidates=false
  local t=os.clock()
  local reference=world:needed(cam,w,h)
  t_old=t_old+(os.clock()-t)
  world.fast_cover_candidates=true
  t=os.clock()
  local fast=world:needed(cam,w,h)
  t_fast=t_fast+(os.clock()-t)
  assert(#reference==#fast)
  for i=1,#fast do assert(reference[i].key==fast[i].key) end
 end
end
world.fast_cover_candidates=nil;world.viewport_cover=nil
cam.x,cam.y,cam.zoom=64,128,1.7
print(string.format("R2_SORT_MICRO old_ms=%.3f fast_ms=%.3f gain=%.2f%%",
 t_old*1000,t_fast*1000,100*(1-t_fast/t_old)))
-- Default Stream:needed ordering and cap remain unchanged when opt-in is off.
assert(#world:needed(cam,720,1600)==48)
print("R2_VIEWPORT_RENDER_ONLY_TEST_OK")

-- Real Terrain.draw contract under a deterministic graphics mock. The Canvas
-- caches only complete static materials and invalidates on mesh/camera/size/DPI.
local Terrain=require("world.terrain_renderer")
local target=nil
local draws={terrain=0,canvas=0,builds=0,releases=0}
local pw,ph,dpi=720,1600,1
local function new_canvas()
 draws.builds=draws.builds+1
 return {is_canvas=true,release=function() draws.releases=draws.releases+1 end}
end
love={graphics={
 newCanvas=function(w,h,settings)
  assert(w==pw and h==ph and settings.dpiscale==dpi)
  return new_canvas()
 end,
 getPixelDimensions=function() return pw,ph end,
 getDPIScale=function() return dpi end,
 setCanvas=function(c) target=c end,
 clear=function() end,push=function() end,pop=function() end,
 translate=function() end,scale=function() end,setColor=function() end,
 draw=function(item)
  if item.is_canvas then
   assert(target==nil,"drawing Canvas into itself")
   draws.canvas=draws.canvas+1
  else
   draws.terrain=draws.terrain+1
  end
 end,
}}
local q={field={},sample=function() return {biome="meadow"} end}
local meshA={is_canvas=false}
local chunk={x=0,y=0,cx=0,cy=0,size=256,
 _terrain_meshes={meadow=meshA}}
local scene={query=q,wanted_count=1,visible=function() return {chunk} end}
local cam2=Camera.new()
cam2.x,cam2.y,cam2.zoom=0,0,1.7
local opts={canvas_cache=true,viewport_cull=true,atmosphere=false}
local key="standard:0.35:nil:nil:"..tostring(q)
chunk._terrain_key=key
Terrain.draw(scene,cam2,720,1600,opts)
assert(draws.terrain==1 and draws.canvas==1 and draws.builds==1)
Terrain.draw(scene,cam2,720,1600,opts)
assert(draws.terrain==1 and draws.canvas==2 and
 Terrain._canvas_hits==1,"stationary Canvas should bypass all material meshes")
cam2.x=16
Terrain.draw(scene,cam2,720,1600,opts)
assert(draws.terrain==2 and draws.builds==1,
 "camera movement must repaint existing Canvas")
chunk._terrain_meshes={meadow={is_canvas=false}}
Terrain.draw(scene,cam2,720,1600,opts)
assert(draws.terrain==3,"mesh identity change must invalidate")
scene.wanted_count=2
Terrain.draw(scene,cam2,720,1600,opts)
assert(draws.terrain==4,"incomplete streamed scene must bypass old Canvas")
scene.wanted_count=1
pw,ph,dpi=691,1536,1
Terrain.draw(scene,cam2,691,1536,opts)
assert(draws.builds==2 and draws.releases==1,
 "resizing must release and recreate high-DPI compatible Canvas")
pw,ph,dpi=1382,3072,2
Terrain.draw(scene,cam2,691,1536,opts)
assert(draws.builds==3 and draws.releases==2,
 "pixel-density change must recreate Canvas at physical size")
opts.canvas_cache=false
Terrain.draw(scene,cam2,691,1536,opts)
assert(draws.releases==3,"disabling cached terrain must release framebuffer")
print("R2_CANVAS_INVALIDATION_OK still/move/mesh/pending/resize/dpi/disable")
