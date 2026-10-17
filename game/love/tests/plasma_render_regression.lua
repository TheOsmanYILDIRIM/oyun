-- Isolated sprite-path regression: validates the actual 102-frame render adapter
-- with in-memory image/quad doubles, without redistributing binary master art.
package.path="./?.lua;./?/init.lua;"..package.path
local quadAlloc,draws,colors,scissors=0,{},{},0
local g={}
local function noop() end
for _,name in ipairs({"push","pop","setBlendMode","circle","ellipse","setLineWidth"}) do g[name]=noop end
g.newQuad=function(...) quadAlloc=quadAlloc+1;return {quad=true} end
g.newImage=function(path)
  return {path=path,setFilter=noop,getDimensions=function()
    if path:find("core_original",1,true) then return 256,256 end
    return 128,96
  end}
end
g.setColor=function(r,gc,b,a) colors[#colors+1]={r,gc,b,a} end
g.draw=function(img,q,x,y,angle,sx,sy,ox,oy)
  if type(q)=="table" and q.quad then
    draws[#draws+1]={kind="plasma",sx=sx,sy=sy,img=img.path}
  else
    draws[#draws+1]={kind="core"}
  end
end
g.setScissor=function(...) scissors=scissors+1 end
_G.love={graphics=g,filesystem={
  getInfo=function(path) return {type="file"} end
}}
local P=require("player.plasma_video_visual")
local a=P.assetStatus()
assert(a.ready and a.frame_count==102)
assert(quadAlloc==204,"2 quads per frame should be cached at load")
local camera={zoom=1,project=function(_,x,y,w,h) return w/2,h/2 end}
local player={x=0,y=0,time=0,state="idle",immersion=0}
local function render(context)
  draws,colors,scissors={},{},0
  P.draw(g,camera,360,780,player,context or {})
  local rings={}
  for _,entry in ipairs(draws) do
    if entry.kind=="plasma" then rings[#rings+1]=entry end
  end
  return rings
end
local full=render()
assert(#full==2)
assert(#draws==3 and draws[1].kind=="plasma"
  and draws[2].kind=="core" and draws[3].kind=="plasma",
  "core should be between rear and front plasma passes")
local widthFull=full[1].sx*128
assert(math.abs(widthFull-108)<.001)
P.setPreview(nil,0)
player.time=.1
local smooth=render()
local widthSmooth=smooth[1].sx*128
assert(widthSmooth<widthFull and widthSmooth>60,
  "energy UI must smooth instead of snapping")
for i=1,35 do player.time=player.time+.1;render() end
local depleted=render()
assert(depleted[1].sx*128<38,"energy zero must shrink")
P.setPreview(5,1)
player.time=player.time+.1
local twice=render()
assert(#twice==4,"two rings must have front and rear")
P.setPreview(6,1)
player.time=player.time+.1
local thrice=render({stats={["test:a"]=75,["test:b"]=25},
  palette={["test:a"]={1,0,0},["test:b"]={0,1,0}}})
assert(#thrice==6,"three rings must have front and rear")
local tintedPrimary,tintedSecondary=false,false
for _,c in ipairs(colors) do
  if math.abs(c[1]-1)<.001 and math.abs(c[2]-.58)<.001 then tintedPrimary=true end
  if math.abs(c[1]-.58)<.001 and math.abs(c[2]-1)<.001 then tintedSecondary=true end
end
assert(tintedPrimary and tintedSecondary,"both supplied stat tints should be visible")
assert(quadAlloc==204,"quads must not be allocated per frame")
player.immersion=.5
local water=render()
assert(#water==12 and scissors==3,"water must clip 3 rings in two passes")
assert(#draws==14 and draws[4].kind=="core" and draws[11].kind=="core",
  "core overlap must be preserved in both water passes")
assert(not pcall(P.setPreview,nil,math.huge))
assert(not pcall(P.setPreview,7,nil))
assert(not pcall(P.setPreview,nil,0/0))
assert(player.x==0 and player.y==0 and player.immersion==.5)
package.loaded["player.plasma_video_visual"]=nil
love.filesystem.getInfo=function() return nil end
local Missing=require("player.plasma_video_visual")
local status=Missing.assetStatus()
assert(not status.ready and status.frame_count==0,
  "missing art must not report a full production plasma")
print("PLASMA_RENDER_REGRESSION_OK quads="..quadAlloc.." rings=1/2/3 energy=smooth water=clipped palette=two-stat")
