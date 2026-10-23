#!/usr/bin/env python3
"""Append CI-only multi-display screenshots to an unpacked complete R2 LÖVE staging build."""
from pathlib import Path
import sys
target = Path(sys.argv[1]) / "main.lua"
source = target.read_text()
assert source.count("function love.quit()") == 1
injection = r'''
-- Isolated UI/visual equivalence matrix. No production gameplay changes.
if os.getenv("OSMAN_R2_DISPLAY_MATRIX")=="1" then
 assert(r2_pilot and r2_perf_overhaul and stream.viewport_cover,
   "display matrix requires active optimized R2 with viewport coverage")
 local original_update,original_draw=love.update,love.draw
 local layouts={
  {320,700,1.7},{360,780,1.7},{392,850,1.7},
  {411,891,1.7},{691,1536,1.7},{720,1600,1.7},
  {1280,800,1.7},{360,780,.65},{360,780,3.2}
 }
 local phase="advance"
 local index,stable,ticks=0,0,0
 local function variant(enabled)
  r2_pilot.render_options.viewport_cull=enabled
  ObjectRenderer.viewport_cull=enabled
  ObjectRenderer.order_cull=enabled
 end
 local function ready()
  if not boot_ready or not stats or stats.pending~=0 or
      stats.loaded<=0 or stats.loaded~=stats.needed then return false end
  for _,chunk in ipairs(stream:visible()) do
   if chunk._terrain_job or not chunk._terrain_meshes then return false end
   if chunk._object_render_world~=objects or
     not chunk._object_render_candidates then return false end
  end
  return true
 end
 function love.update(dt)
  ticks=ticks+1
  assert(ticks<=6400,
    "R2_DISPLAY_TIMEOUT index="..index.." phase="..phase)
  if phase=="advance" then
   index=index+1
   if index>#layouts then phase="finish";return end
   local layout=layouts[index]
   assert(love.window.setMode(layout[1],layout[2],
     {resizable=false,highdpi=true,usedpiscale=true}),
     "matrix display mode unavailable")
   w,h=love.graphics.getDimensions()
   assert(w==layout[1] and h==layout[2],
     "logical viewport differs from requested display")
   camera.zoom=layout[3]
   stable=0
   variant(true)
   phase="warm"
  end
  if phase=="warm" then
   original_update(1/60)
   if ready() then stable=stable+1 else stable=0 end
   if stable>=3 then
    variant(false)
    phase="baseline"
   end
  elseif phase=="finish" then
   if ticks%3==0 then
    print("R2_DISPLAY_MATRIX_DONE cases="..#layouts)
    io.stdout:flush()
    love.event.quit(0)
   end
  end
 end
 function love.draw()
  original_draw()
  if phase=="baseline" then
   love.graphics.captureScreenshot(string.format("matrix-%02d-baseline.png",index))
   variant(true)
   phase="optimized"
  elseif phase=="optimized" then
   love.graphics.captureScreenshot(string.format("matrix-%02d-optimized.png",index))
   local layout=layouts[index]
   local fp=assert(io.open("R2_DISPLAY_MATRIX.csv",index==1 and "w" or "a"))
   if index==1 then fp:write("case,width,height,zoom,dpi,loaded,needed,drawcalls,texture_mib\n") end
   local st=love.graphics.getStats()
   fp:write(string.format("%d,%d,%d,%.2f,%.2f,%d,%d,%d,%.3f\n",
     index,w,h,camera.zoom,love.graphics.getDPIScale(),
     stats.loaded,stats.needed,st.drawcalls or 0,
     (st.texturememory or 0)/1048576))
   fp:close()
   phase="advance"
  end
 end
end
'''
target.write_text(source+"\n"+injection)
print("R2_DISPLAY_MATRIX_INSTRUMENTED", target)
