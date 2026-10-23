package.path="./?.lua;./?/init.lua;"..package.path
package.loaded["player.core_visual"]={draw=function()end}
package.loaded["player.axe_strike"]={draw=function()end}
local Iso=require("world.iso")
local R=require("objects.renderer")
local objs={}
for i=1,16 do objs[i]={id=tostring(i),x=i*8,y=i*3,cx=0,cy=0,radius=4,kind="tree"} end
local world={generator_version=1,is_depleted=function()return false end}
function world:objects_in(_,include) assert(include);return objs end
local stream={visible=function()return {{cx=0,cy=0,x=0,y=0,size=256}} end}
local topo={calls=0}
function topo:height(x,y)self.calls=self.calls+1;return math.sin(x+y)*15 end
local cam={x=0,y=0,zoom=1.7}
function cam:project(x,y,w,h)
 local px,py=Iso.project(x-self.x,y-self.y)
 return w/2+px*self.zoom,h/2+py*self.zoom-topo:height(x,y)*.35*self.zoom
end
local out={}
love={graphics={
 push=function()end,pop=function()end,setColor=function()end,
 rectangle=function()end,polygon=function()end,setLineWidth=function()end,
 ellipse=function(mode,x,y)if mode=="fill" then out[#out+1]={x,y} end end}}
local function draw(cached)
 R.r2_static_topography=cached and topo or nil
 R.r2_static_height_scale=cached and .35 or nil
 out={};R.draw(world,stream,cam,360,780,{x=0,y=0},nil,nil)
 return out
end
for _,p in ipairs({{0,0,1.7},{90,40,.65},{-80,100,3.2}}) do
 cam.x,cam.y,cam.zoom=p[1],p[2],p[3]
 local a=draw(false);local b=draw(true)
 assert(#a==#b)
 for i=1,#a do for k=1,2 do
  assert(math.abs(a[i][k]-b[i][k])<1e-9,"object screen mismatch")
 end end
end
assert(R.metrics.foot_misses==#objs)
assert(R.metrics.foot_hits>=#objs*2)
print("R2_STATIC_FOOT_PARITY_OK")
