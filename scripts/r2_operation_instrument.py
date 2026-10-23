#!/usr/bin/env python3
"""Append instrumentation to a disposable playable staging copy only."""
from pathlib import Path
import sys
root=Path(sys.argv[1])
main=root/"main.lua"
s=main.read_text()
assert 'function love.draw()' in s and 'function love.update(dt)' in s
instrument=r'''
-- Per-operation root cause sampler. All hooks call actual production functions.
if os.getenv("OSMAN_R2_OP_AUDIT")=="1" then
 local timer=love.timer.getTime
 local seq,frames=0,tonumber(os.getenv("OSMAN_R2_OP_FRAMES")) or 240
 local bootmax=tonumber(os.getenv("OSMAN_R2_OP_BOOT_MAX")) or 1500
 local csv=assert(io.open("R2_OPERATION_FRAMES.csv","w"))
 local operation=assert(io.open("R2_OPERATION_CALLS.csv","w"))
 csv:write("frame,phase,frame_ms,update_ms,draw_ms,loaded,needed,pending,evictions,canvas_switches,drawcalls,texture_mib,lua_kib,gc_kib_delta,x,y,action\n")
 operation:write("frame,phase,function,calls,total_ms,max_ms\n")
 local acc,phase,frame={}, "boot",0
 local action="boot"
 local function track(name,fn)
  return function(...)
   local t=timer()
   local v={fn(...)}
   local ms=(timer()-t)*1000
   local a=acc[name] or {0,0,0};acc[name]=a
   a[1]=a[1]+1;a[2]=a[2]+ms;a[3]=math.max(a[3],ms)
   return unpack(v)
  end
 end
 local function wrap(tbl,key,name)
  if tbl and type(tbl[key])=="function" then tbl[key]=track(name,tbl[key]) end
 end
 local chunks=require("world.chunks")
 wrap(chunks,"build","chunks.build")
 local collision=require("physics.collision")
 wrap(collision,"move","collision.move")
 wrap(collision,"can_stand","collision.can_stand")
 local path=require("navigation.pathfinder")
 for _,k in ipairs({"find","begin","begin_any"}) do wrap(path,k,"path."..k) end
 local source_query=stream.query
 for _,k in ipairs({"sample","surface_at","get_height","get_biome"}) do wrap(source_query,k,"worldquery."..k) end
 local topo=r2_pilot and r2_pilot.topography
 for _,k in ipairs({"sample","height","colliders","prewarm_colliders"}) do wrap(topo,k,"topography."..k) end
 wrap(topo,"height_at","topography.raw_height_at")
 for _,k in ipairs({"objects_in","obstacles","get","is_depleted"}) do wrap(objects,k,"objects."..k) end
 wrap(ObjectRenderer,"collect","object_renderer.collect")
 wrap(ObjectRenderer,"draw","object_renderer.draw")
 wrap(Terrain,"draw","terrain.draw")
 wrap(Terrain,"prepare_cpu","terrain.prepare_cpu")
 wrap(stream,"update","stream.update")
 wrap(stream,"needed","stream.needed")
 local old_update,old_draw=love.update,love.draw
 local update_ms,measured=0,0
 local old_resident={}
 local pre_vram=0
 local old_gc=collectgarbage("count")
 local old_stats=love.graphics.getStats()
 local movement=assert(os.getenv("OSMAN_R2_OP_MOTION"),"motion required")
 local control_down=false
 local function drive()
  if movement=="idle" then action="idle";return end
  local bx,by=joystick_center()
  local step=measured
  if step==1 or step==120 then
   love.touchpressed("op-joystick",bx,by);control_down=true
  end
  if control_down then
   local dx=step<120 and 60 or -60
   love.touchmoved("op-joystick",bx+dx,by+22)
   action="joystick"
  end
  if step==88 or step==198 then
   love.touchreleased("op-joystick",bx,by);control_down=false
  end
  if step==90 or step==103 or step==203 then
   local x,y=w*.5+65,h*.5+19
   love.touchpressed("op-tap",x,y);love.touchreleased("op-tap",x,y)
   action="tap_nav"
  end
  if step==108 then
   love.touchpressed("op-joystick",bx,by)
   love.touchmoved("op-joystick",bx-28,by+15)
   love.touchreleased("op-joystick",bx-28,by+15)
   action="manual_cancel"
  end
 end
 local function ready()
  if not stats or stats.pending~=0 or stats.loaded==0 then return false end
  for _,c in ipairs(stream:visible()) do if not c._terrain_meshes then return false end end
  return true
 end
 function love.update(dt)
  frame=frame+1
  if phase=="boot" and ready() then phase="measure";measured=0;print("R2_OPERATION_READY frame="..frame) end
  if phase=="measure" then measured=measured+1;drive() end
  local t=timer()
  old_update(math.min(dt,1/60))
  update_ms=(timer()-t)*1000
 end
 function love.draw()
  local t=timer()
  old_draw()
  local draw_ms=(timer()-t)*1000
  if phase=="measure" then
   local resident={}
   for k in pairs(stream.resident) do resident[k]=true end
   local evict=0
   for k in pairs(old_resident) do if not resident[k] then evict=evict+1 end end
   old_resident=resident
   local g=love.graphics.getStats()
   local gc=collectgarbage("count")
   local canvas_switches=(g.canvasSwitches or 0)
   csv:write(string.format("%d,%s,%.4f,%.4f,%.4f,%d,%d,%d,%d,%d,%d,%.3f,%.1f,%.1f,%.3f,%.3f,%s\n",
      measured,phase,update_ms+draw_ms,update_ms,draw_ms,
      stats.loaded or 0,stats.needed or 0,stats.pending or 0,
      evict,canvas_switches,g.drawcalls or 0,(g.texturememory or 0)/1048576,gc,gc-old_gc,
      player.x,player.y,action))
   old_gc=gc
   for k,a in pairs(acc) do
    operation:write(string.format("%d,%s,%s,%d,%.6f,%.6f\n",measured,phase,k,a[1],a[2],a[3]))
   end
   acc={}
   if measured>=frames then
    csv:close();operation:close()
    print("R2_OPERATION_DONE frames="..measured.." mode="..movement)
    io.stdout:flush()
    love.event.quit()
   end
  elseif frame>bootmax then
   csv:close();operation:close()
   error("R2_OPERATION_BOOT_TIMEOUT")
  end
 end
end
'''
main.write_text(s+"\n"+instrument)
print("OP_AUDIT_INSTALLED")
