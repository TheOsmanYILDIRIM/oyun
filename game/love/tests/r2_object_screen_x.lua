-- Pixel command parity of exact screen-X rejection before depth sort.
package.path="./?.lua;./?/init.lua;"..package.path
local events={}
package.loaded["player.core_visual"]={draw=function() events[#events+1]="P" end}
package.loaded["player.axe_strike"]={draw=function() end}
local Camera=require("core.camera")
local R=require("objects.renderer")
love={graphics={
 push=function() end,pop=function() end,setColor=function() end,
 setLineWidth=function() end,
 ellipse=function(kind,x,y,a,b) events[#events+1]=
  "E:"..kind..":"..string.format("%.3f:%.3f",x,y) end,
 rectangle=function(kind,x,y,a,b) events[#events+1]="R:"..kind end,
 polygon=function(kind,...) events[#events+1]="G:"..kind end}}
local world={generator_version=1}
function world:is_depleted(id) return id=="dead" end
local objects={}
for i=-15,15 do
 objects[#objects+1]={id=tostring(i),x=i*45,y=i*11,
   cx=math.floor(i*45/256),cy=math.floor(i*11/256),
   kind=i%2==0 and "rock" or "tree",radius=4+i%3}
end
local chunks={}
for cy=-4,4 do for cx=-4,4 do
 chunks[#chunks+1]={x=cx*256,y=cy*256,cx=cx,cy=cy,size=256}
end end
function world:objects_in(bounds,include_depleted)
 assert(include_depleted==true)
 local ans={}
 for _,o in ipairs(objects) do
  if o.x>=bounds.min_x and o.x<bounds.max_x
    and o.y>=bounds.min_y and o.y<bounds.max_y then
   ans[#ans+1]=o
  end
 end
 return ans
end
local stream={visible=function() return chunks end}
local player={x=10,y=20}
local cam=Camera.new()
R.viewport_cull=true
local function render(prefilter,w,h)
 R.order_cull=prefilter
 events={}
 local n=R.draw(world,stream,cam,w,h,player,nil,nil)
 return table.concat(events,","),n
end
for _,dims in ipairs({{320,700},{720,1100},{691,1536}}) do
 for _,pos in ipairs({{0,0,1.7},{150,25,3.2},{-220,40,.65}}) do
  cam.x,cam.y,cam.zoom=pos[1],pos[2],pos[3]
  local before,n=render(false,dims[1],dims[2])
  local after,m=render(true,dims[1],dims[2])
  assert(before==after,"visible object geometry/order diverged")
  assert(n==m,"object HUD count changed")
 end
end
print("R2_OBJECT_SCREEN_X_PARITY_OK camera/zoom/portrait/depth")
