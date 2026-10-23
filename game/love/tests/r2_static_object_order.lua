-- Exact visible draw ordering with live depletion, camera motion and eviction.
package.path="./?.lua;./?/init.lua;"..package.path
local cmds={}
package.loaded["player.core_visual"]={draw=function() cmds[#cmds+1]="P" end}
package.loaded["player.axe_strike"]={draw=function() end}
local Camera=require("core.camera")
local R=require("objects.renderer")
love={graphics={
 push=function() end,pop=function() end,setColor=function() end,
 ellipse=function(kind,x,y) cmds[#cmds+1]="E"..kind..":"..string.format("%.3f/%.3f",x,y) end,
 rectangle=function(kind)cmds[#cmds+1]="R"..kind end,
 polygon=function(kind)cmds[#cmds+1]="G"..kind end,
 setLineWidth=function() end}}
local objects={}
for i=-15,15 do
 objects[#objects+1]={id=tostring(i),x=i*36,y=i*11,cx=math.floor(i*36/256),
  cy=math.floor(i*11/256),kind=i%2==0 and "rock" or "tree",radius=6}
end
local depleted={}
local world={generator_version=1}
function world:is_depleted(id) return depleted[id] or false end
function world:objects_in(bounds,include_depleted)
 assert(include_depleted)
 local ans={}
 for _,o in ipairs(objects) do
  if o.x>=bounds.min_x and o.x<bounds.max_x and
     o.y>=bounds.min_y and o.y<bounds.max_y then ans[#ans+1]=o end
 end
 return ans
end
local chunks={}
for cy=-3,3 do for cx=-3,3 do
 chunks[#chunks+1]={cx=cx,cy=cy,x=cx*256,y=cy*256,size=256}
end end
local stream={visible=function()return chunks end}
local camera=Camera.new()
local player={x=5,y=8}
R.viewport_cull=true;R.order_cull=true
local function draw(static,w,h)
 R.static_order=static
 cmds={}
 local count=R.draw(world,stream,camera,w,h,player,nil,nil)
 return table.concat(cmds,"|"),count
end
for _,dims in ipairs({{320,700},{720,1100}}) do
 for _,pos in ipairs({{0,0,1.7},{180,60,1.2},{-220,-12,3.2}}) do
  camera.x,camera.y,camera.zoom=pos[1],pos[2],pos[3]
  for _,px in ipairs({-100,0,250}) do
   player.x=px
   local a,n=draw(false,dims[1],dims[2])
   local b,m=draw(true,dims[1],dims[2])
   assert(a==b and n==m,"depth order or HUD counter changed")
  end
 end
end
local builds=R.metrics.static_order_builds
assert(draw(true,720,1100)==draw(false,720,1100))
assert(R.metrics.static_order_builds==builds,"static sort repeated")
depleted["2"]=true
local a,n=draw(false,720,1100)
local b,m=draw(true,720,1100)
assert(a==b and n==m,"depletion must remain live")
depleted["2"]=nil
assert(draw(false,720,1100)==draw(true,720,1100),"regrowth failed")
chunks[1]={cx=chunks[1].cx,cy=chunks[1].cy,x=chunks[1].x,y=chunks[1].y,size=256}
R.prewarm(world,stream,1)
assert(draw(false,720,1100)==draw(true,720,1100),"new resident identity failed")
local newworld={generator_version=1,is_depleted=world.is_depleted,objects_in=world.objects_in}
R.collect(newworld,stream)
assert(#R.prepare(newworld,stream)==#R.prepare(world,stream),
  "world identity mix")
print("R2_STATIC_OBJECT_DEPTH_ORDER_PARITY_OK")
