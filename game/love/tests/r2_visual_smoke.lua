-- Production-independent R2 visual render fixture. CI copies this as main.lua
-- in /tmp and executes real LOVE under Xvfb; never edits game/love/main.lua.
package.path="./?.lua;./?/init.lua;/tmp/?.lua;"..package.path
local Query=require("world.world_query")
local Stream=require("world.stream")
local Camera=require("core.camera")
local Terrain=require("world.terrain_renderer")
local Surface=require("r2_visual_topography_surface")
local query=Query.new(20261015)
local camera=Camera.new()
local w,h,frames=720,1100,0
local stream=Stream.new(query,{size=256,step=32,max_loaded=48,build_budget=48})
local topography=Surface.new({world=query})
function love.load()
 local viewport=os.getenv("OSMAN_R2_VISUAL_DISPLAY") or "720x1100"
 local sx,sy=viewport:match("^(%d+)x(%d+)$")
 assert(sx and sy and tonumber(sx)>=320 and tonumber(sy)>=700)
 w,h=tonumber(sx),tonumber(sy)
 assert(love.window.setMode(w,h,{resizable=false,msaa=0}))
 camera.x,camera.y=-960,-960
 camera.zoom=w<=360 and 1.0 or 1.4
 stream:update(camera,w,h,48)
end
function love.update()
 frames=frames+1
 if frames>22 then
  print("R2_VISUAL_LOVE_SMOKE_OK "..w.."x"..h)
  io.stdout:flush()
  love.event.quit(0)
 end
end
function love.draw()
 Terrain.draw(stream,camera,w,h,{
  quality=w<=360 and "low" or "standard",topography=topography,
  atmosphere=true})
 if frames==12 then
  love.graphics.captureScreenshot("r2-visual-"..w.."x"..h..".png")
 end
end
