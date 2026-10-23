-- Screen-space R2 touch selection must exactly match old behavior.
package.path="./?.lua;./?/init.lua;"..package.path
package.loaded["player.core_visual"]={draw=function()end}
package.loaded["player.axe_strike"]={draw=function()end}
local Iso=require("world.iso")
local R=require("objects.renderer")
local objects={}
for i=-80,80 do
 local wx,wy=i*23,i*7
 objects[#objects+1]={id="obj:"..i,x=wx,y=wy,
  cx=math.floor(wx/256),cy=math.floor(wy/256),
  radius=4+(i%5),kind=i%2==0 and "tree" or "rock"}
end
local world={generator_version=1,is_depleted=function()return false end}
function world:objects_in(bounds,all)
 assert(all)
 local ans={}
 for _,o in ipairs(objects) do
  if o.x>=bounds.min_x and o.x<bounds.max_x and
     o.y>=bounds.min_y and o.y<bounds.max_y then ans[#ans+1]=o end
 end
 return ans
end
local chunks={}
for cy=-3,3 do for cx=-9,9 do
 chunks[#chunks+1]={cx=cx,cy=cy,x=cx*256,y=cy*256,size=256}
end end
local stream={visible=function()return chunks end}
local cam={x=0,y=0,zoom=1.7}
local projected=0
function cam:project(x,y,w,h)
 projected=projected+1
 local px,py=Iso.project(x-self.x,y-self.y)
 local relief=.35*(math.sin(x*.01+y*.02)*40)
 return w*.5+px*self.zoom,h*.5+(py-relief)*self.zoom
end
love={timer={getTime=os.clock}}
local avoided=0
for _,wh in ipairs({{320,700},{360,780},{691,1536},{1280,800}}) do
 for _,pos in ipairs({{0,0,.65},{350,-120,1.7},{-150,400,3.2}}) do
  cam.x,cam.y,cam.zoom=pos[1],pos[2],pos[3]
  for sx=0,wh[1],math.max(32,math.floor(wh[1]/7)) do
   for sy=0,wh[2],math.max(48,math.floor(wh[2]/5)) do
    projected=0;R.pick_x_cull=false
    local a=R.pick(world,stream,cam,wh[1],wh[2],sx,sy)
    local all=projected
    projected=0;R.pick_x_cull=true
    local b=R.pick(world,stream,cam,wh[1],wh[2],sx,sy)
    assert((a and a.id)==(b and b.id),"touch target changed")
    assert(projected<=all,"pre-filter projected extra objects")
    avoided=avoided+(all-projected)
   end
  end
 end
end
assert(avoided>0 and R.metrics.pick_skipped>0)
print("R2_PICK_EXACT_PARITY_OK avoided="..avoided)
