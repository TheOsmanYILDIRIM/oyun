#!/usr/bin/env python3
"""Install deterministic player-driven profiler ONLY into disposable .love staging."""
from pathlib import Path
import sys
root=Path(sys.argv[1])
main=root/"main.lua"
source=main.read_text()
assert source.count("function love.quit()")==1
profile=r'''
-- R2 PROFILE LAB: isolated package instrumentation; no gameplay files modified.
if os.getenv("OSMAN_R2_PROFILE")=="1" then
 local clock=love.timer.getTime
 local mode=assert(os.getenv("OSMAN_R2_PROFILE_MODE"),"profile mode")
 local motion=mode:find("walk",1,true)~=nil
 -- Benchmark-only fixed query count for the *real* A* worker and CCD.
 -- Normal production pathfinder remains untouched. Wall-time checkpoints
 -- otherwise advance on different frames and invalidate paired routes.
 if os.getenv("OSMAN_R2_NAV_FIXED_QUERY_BUDGET")=="1" then
  local finder=require("navigation.pathfinder")
  for _,name in ipairs({"begin","begin_any"}) do
   local new_search=assert(finder[name])
   finder[name]=function(...)
    local job=new_search(...)
    local original_step=assert(job.step)
    function job:step(_ms,_queries)
     return original_step(self,100000,2)
    end
    return job
   end
  end
 end
 local run_frames=tonumber(os.getenv("OSMAN_R2_PROFILE_FRAMES")) or 240
 local hard_frames=tonumber(os.getenv("OSMAN_R2_PROFILE_BOOT_MAX")) or 1800
 local frame,measured,phase=0,0,"boot"
 local csv=assert(io.open("r2-profile-"..mode..".csv","w"))
 csv:write("mode,phase,frame,elapsed_ms,update_ms,draw_ms,stream_ms,terrain_ms,objects_ms,loaded,needed,pending,mesh_ready,object_collect_calls,object_cold_queries,object_cold_ms,cache_hits,cache_misses,cache_invalid,cache_writes,lua_kib,drawcalls,texture_mb,x,y\n")
 local function metric(m,k) return m and m[k] or 0 end
 local org_stream=stream.update
 local stream_ms,terrain_ms,objects_ms=0,0,0
 function stream:update(...)
  local start=clock()
  local out=org_stream(self,...)
  stream_ms=stream_ms+(clock()-start)*1000
  return out
 end
 local org_terrain=Terrain.draw
 function Terrain.draw(...)
  local start=clock()
  local out=org_terrain(...)
  terrain_ms=terrain_ms+(clock()-start)*1000
  return out
 end
 local org_objects=ObjectRenderer.draw
 function ObjectRenderer.draw(...)
  local start=clock()
  local out=org_objects(...)
  objects_ms=objects_ms+(clock()-start)*1000
  return out
 end
 local old_update=love.update
 local old_draw=love.draw
 local update_ms,draw_ms=0,0
 local joystick_down=false
 local touched=false
 local last_collect=0
 local last_cold=0
 local last_cold_ms=0
 local function status()
  -- The active cache-loading game also waits for all immutable object
  -- candidates. Never start measuring while the loading overlay is visible.
  local ready=stats and stats.loaded>0 and stats.pending==0 and
    (not cache_pilot_enabled or boot_ready)
  if ready then
   for _,chunk in ipairs(stream:visible()) do
    if not chunk._terrain_meshes then return false end
   end
  end
  return ready
 end
 local function drive()
  -- Real input callbacks (not teleportation): joystick, tap nav, retap,
  -- manual cancel, and returning across chunk boundary.
  if not motion then return end
  local bx,by=joystick_center()
  local step=measured
  if step==1 or step==142 then
   love.touchpressed("profile-joystick",bx,by)
   joystick_down=true
  end
  if joystick_down then
   if step<142 then love.touchmoved("profile-joystick",bx+58,by+25)
   else love.touchmoved("profile-joystick",bx-58,by-25) end
  end
  if step==95 or step==210 then
   love.touchreleased("profile-joystick",bx,by)
   joystick_down=false
  end
  if step==99 or step==111 or step==214 then
   local x,y=w*.5+82,h*.5+16
   love.touchpressed("profile-tap",x,y)
   love.touchreleased("profile-tap",x,y)
   touched=true
  end
  if step==115 then
   love.touchpressed("profile-joystick",bx,by)
   love.touchmoved("profile-joystick",bx-32,by+16)
   love.touchreleased("profile-joystick",bx-32,by+16)
  end
 end
 function love.update(dt)
  frame=frame+1
  stream_ms,terrain_ms,objects_ms=0,0,0
  if phase=="boot" and status() then
   phase="measured";measured=0
   -- Never charge boot-time object collection to the first measured frame.
   local om=ObjectRenderer.metrics or {}
   last_collect=metric(om,"collect_calls")
   last_cold=metric(om,"cold_queries")
   last_cold_ms=metric(om,"cold_query_ms")
   print("R2_PROFILE_READY mode="..mode.." boot_frames="..frame)
   io.stdout:flush()
  end
  if phase=="measured" then
   measured=measured+1
   drive()
  end
  local start=clock()
  -- Fixed simulation dt to keep gameplay distance comparable among modes.
  if os.getenv("OSMAN_R2_PROFILE_FIXED_STEP")=="1" then
   old_update(1/60)
  else
   old_update(math.min(dt,1/60))
  end
  update_ms=(clock()-start)*1000
 end
 function love.draw()
  local start=clock()
  old_draw()
  draw_ms=(clock()-start)*1000
  if phase=="measured" then
   local cm=chunk_cache and chunk_cache.metrics or {}
   local om=ObjectRenderer.metrics or {}
   local ready_count=0
   for _,c in ipairs(stream:visible()) do
    if c._terrain_meshes then ready_count=ready_count+1 end
   end
   local draw=love.graphics.getStats()
   local tex=draw.texturememory or 0
   local calls=metric(om,"collect_calls")-last_collect
   local cold=metric(om,"cold_queries")-last_cold
   local coldms=metric(om,"cold_query_ms")-last_cold_ms
   last_collect=metric(om,"collect_calls")
   last_cold=metric(om,"cold_queries")
   last_cold_ms=metric(om,"cold_query_ms")
   csv:write(string.format("%s,%s,%d,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%d,%d,%d,%d,%d,%d,%.4f,%d,%d,%d,%d,%.1f,%d,%.3f,%.2f,%.2f\n",
     mode,phase,measured,update_ms+draw_ms,update_ms,draw_ms,
     stream_ms,terrain_ms,objects_ms,
     stats.loaded or 0,stats.needed or 0,stats.pending or 0,ready_count,
     calls,cold,coldms,
     metric(cm,"hits"),metric(cm,"misses"),metric(cm,"invalid"),
     metric(cm,"writes"),collectgarbage("count"),draw.drawcalls or 0,
     tex/1048576,player.x,player.y))
   if os.getenv("OSMAN_R2_ENGINE_LAB")=="1" and
       (measured==math.floor(run_frames/2) or measured==run_frames-10) then
    local frame_name=string.format("r2-engine-%s-%03d.png",mode,measured)
    love.graphics.captureScreenshot(function(image)
      image:encode("png",frame_name)
    end)
   end
   if measured>=run_frames then
    if joystick_down then
     local bx,by=joystick_center()
     love.touchreleased("profile-joystick",bx,by)
    end
    csv:close()
    print("R2_PROFILE_DONE mode="..mode.." frames="..measured.." taps="..tostring(touched))
    io.stdout:flush()
    love.event.quit()
   end
  elseif frame>hard_frames then
   csv:close()
   error("R2_PROFILE_BOOT_TIMEOUT mode="..mode.." loaded="..tostring(stats and stats.loaded))
  end
 end
end
'''
main.write_text(source+"\n"+profile)
print("R2_PROFILE_INSTRUMENTED",root)
