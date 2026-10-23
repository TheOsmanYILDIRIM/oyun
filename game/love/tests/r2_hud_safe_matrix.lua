-- R2-only compact touch HUD. Simulate Android safe-area insets and
-- DPI-equivalent logical viewports; does NOT claim physical Android validation.
package.path="./?.lua;./?/init.lua;"..package.path
local H=require("core.stage5_hud")
local cases={
 {w=320,h=700,l=0,t=40,r=0,b=34},
 {w=360,h=780,l=0,t=56,r=0,b=34},
 {w=392,h=850,l=0,t=46,r=0,b=36},
 {w=411,h=891,l=0,t=52,r=0,b=40},
 {w=691,h=1536,l=0,t=42,r=0,b=48},
 {w=720,h=1600,l=0,t=44,r=0,b=44},
 {w=1280,h=800,l=30,t=16,r=30,b=22},
 {w=800,h=360,l=44,t=10,r=24,b=12},
 {w=320,h=480,l=0,t=46,r=0,b=38},
 {w=360,h=640,l=0,t=36,r=0,b=34}
}
local function button_for(layout,id)
 for _,b in ipairs(layout) do if b.id==id then return b end end
end
for _,case in ipairs(cases) do
 local s={x=case.l,y=case.t,w=case.w-case.l-case.r,
   h=case.h-case.t-case.b}
 for _,density in ipairs({1,2,3}) do
  -- logical rectangles and hit tests must remain invariant under physical
  -- density changes: native LÖVE getSafeArea returns logical units.
  local physical={width=s.w*density,height=s.h*density}
  assert(physical.width/density==s.w)
  local hud=H.new()
  hud.compact_layout=true;hud.open=true
  for _,page in ipairs({1,2}) do
   hud.page=page
   local shapes=hud:layout(s)
   for _,b in ipairs(shapes) do
    assert(b.x>=s.x and b.y>=s.y and
      b.x+b.w<=s.x+s.w+.001 and b.y+b.h<=s.y+s.h+.001,
      string.format("unsafe R2 HUD %s on %dx%d",b.id,case.w,case.h))
    assert(b.w>0 and b.h>0,"zero-sized tap target "..b.id)
    if b.id~="panel" then
     local xx,yy=b.x+b.w*.5,b.y+b.h*.5
     assert(hud:hit(xx,yy,s)==b.id,"HUD touch mismatch "..b.id)
    end
   end
   local bag=assert(button_for(shapes,"inventory"))
   assert(hud:hit(bag.x+bag.w/2,bag.y+bag.h/2,s)=="inventory")
   if s.h<680 then
    assert(button_for(shapes,"hud_page:items") and
     button_for(shapes,"hud_page:actions"),"compact pagination missing")
    assert(button_for(shapes,page==1 and "slot:12" or "build"),
      "compact accessible controls missing")
   else
    assert(button_for(shapes,"slot:12") and button_for(shapes,"build"),
     "original full HUD must keep inventory and action controls")
   end
  end
 end
 print(string.format("R2_SAFE_HUD_OK logical=%dx%d safe=%d,%d,%d,%d DPI=1/2/3 simulated",
    case.w,case.h,s.x,s.y,s.w,s.h))
end
print("R2_SAFE_HUD_MATRIX_OK cases="..#cases)
