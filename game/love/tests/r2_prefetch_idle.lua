-- R2-only moving-camera prefetch suppression, stable world residency.
package.path="./?.lua;./?/init.lua;"..package.path
local Stream=require("world.stream")
local Camera=require("core.camera")
local timer=0
local calls=0
love={timer={getTime=function() timer=timer+.00002 return timer end}}
local query={field={},sample=function() return {biome="meadow"} end}
local cache={metrics={},poll=function() end,
 has=function(self,cx,cy) calls=calls+1;return true end}
local cam=Camera.new();cam.x,cam.y=64,128
local stream=Stream.new(query,{size=256,step=8,max_loaded=48,
 build_budget=4,cache=cache,prefetch_options={quality="standard"}})
stream.prefetch_idle_only=true
stream.viewport_cover=true
local w,h=360,780
local candidates=stream:needed(cam,w,h)
for _,c in ipairs(candidates) do
 stream.resident[c.key]={key=c.key,cx=c.cx,cy=c.cy,
 x=c.cx*256,y=c.cy*256,size=256,_terrain_meshes={}}
end
for i=1,3 do
 local stats=stream:update(cam,w,h,0)
 assert(stats.pending==0,"prepopulated resident chunk changed")
 assert(calls==0,"prefetch started before idle")
end
stream:update(cam,w,h,0)
assert(calls>0,"prefetch did not resume at rest")
local ready_calls=calls
cam.x=cam.x+.1
stream:update(cam,w,h,0)
assert(calls==ready_calls,"prefetch consumed moving-camera CPU time")
local resumed=false
for i=1,5 do
 stream:update(cam,w,h,0)
 if calls>ready_calls then resumed=true;break end
end
assert(resumed,"prefetch never resumed on camera idle")
-- Default historical path remains enabled when the R2 flag is off.
stream.prefetch_idle_only=false
cam.x=cam.x+.1
local before=calls
stream:update(cam,w,h,0)
assert(calls>before,"default prefetch unexpectedly disabled")
print("R2_IDLE_PREFETCH_PARITY_OK active_camera_motion_suppressed")
