-- Touch-first, safe-area-aware Stage 5 inventory/hotbar controls.
-- Geometry is shared by rendering and hit tests; nothing lives in WebView.
local Catalog=require("systems.catalog")
local H={};H.__index=H
local names={["core:wood_log"]="LOG",["core:wood_plank"]="PLANK",
  ["core:stone"]="STONE",["core:workbench"]="BENCH"}
function H.new()
  return setmetatable({open=false,selected=1,page=1,compact_layout=false},H)
end
local function add(out,id,x,y,w,h)
  out[#out+1]={id=id,x=x,y=y,w=w,h=h}
end
function H:layout(s)
  local x,y,w,h=s.x,s.y,s.w,s.h
  local out={}
  assert(type(x)=="number" and type(y)=="number" and
    type(w)=="number" and type(h)=="number" and w>=180 and h>=260,
    "R2 HUD needs a usable logical safe area")
  local pad=math.max(8,math.min(14,w*.03))
  local unit=math.min(52,(w-pad*2-16)/5)
  add(out,"inventory",x+w-116,y+12,104,40)
  local compact=self.compact_layout and h<680
  local bar_y=y+h-275
  if compact then
    bar_y=w>=600 and y+h-69 or y+h-265
  end
  if not self.open or not compact then
    if not (compact and w<600 and h<480) then
      local bar_x=x+(w-(unit*5+16))/2
      for i=1,5 do add(out,"slot:"..i,
        bar_x+(i-1)*(unit+4),bar_y,unit,49) end
    end
  end
  if self.open and compact then
    local px=x+pad
    local pw=w-pad*2
    local top=y+60
    local bottom=y+h-10
    add(out,"panel",px,top,pw,bottom-top)
    local nav_w=math.min(130,(pw-16)/2)
    local nav_x=px+(pw-(nav_w*2+8))/2
    add(out,"hud_page:items",nav_x,top+10,nav_w,42)
    add(out,"hud_page:actions",nav_x+nav_w+8,top+10,nav_w,42)
    local left,usable=px+6,pw-12
    local cy=top+64
    if self.page==2 then
      local ht=math.min(48,(bottom-cy-12)/3-4)
      add(out,"recipe:core:planks_from_log",left,cy,usable,ht)
      add(out,"recipe:core:bench_from_planks",left,cy+ht+4,usable,ht)
      add(out,"build",left,cy+(ht+4)*2,usable,ht)
      local foot=cy+(ht+4)*3
      if foot+34<=bottom then
        add(out,"rotate",left,foot,(usable-8)/2,34)
        add(out,"cancel",left+(usable+8)/2,foot,(usable-8)/2,34)
      end
    else
      local ht=math.min(56,(bottom-cy-12)/3-3)
      local cell=(usable-12)/4
      for i=1,12 do
        local ri=math.floor((i-1)/4)
        local co=(i-1)%4
        add(out,"slot:"..i,left+co*(cell+4),
          cy+ri*(ht+3),cell,ht)
      end
    end
  elseif self.open then
    local px=x+pad
    local pw=w-pad*2
    local pt=y+141
    -- Shrink panel vertically on 320x700 without overlapping hotbar.
    local scale=math.max(.7,math.min(1,(bar_y-pt-12)/325))
    add(out,"panel",px-3,pt-4,pw+6,330*scale+5)
    local cell=(pw-12)/4
    for i=1,12 do
      local row=math.floor((i-1)/4)
      local col=(i-1)%4
      add(out,"slot:"..i,px+col*(cell+4),pt+row*45*scale,cell,42*scale)
    end
    add(out,"recipe:core:planks_from_log",px,pt+145*scale,pw,38*scale)
    add(out,"recipe:core:bench_from_planks",px,pt+188*scale,pw,38*scale)
    add(out,"build",px,pt+237*scale,pw,39*scale)
    add(out,"rotate",px,pt+283*scale,(pw-8)/2,38*scale)
    add(out,"cancel",px+(pw+8)/2,pt+283*scale,(pw-8)/2,38*scale)
  end
  if self.placing then
    add(out,"confirm",x+w-136,y+h-355,120,54)
  end
  return out
end
function H:hit(px,py,s)
  local buttons=self:layout(s)
  -- Controls drawn later win; panel background intercepts world taps.
  for i=#buttons,1,-1 do
    local b=buttons[i]
    if px>=b.x and px<=b.x+b.w and py>=b.y and py<=b.y+b.h then
      return b.id=="panel" and "panel" or b.id
    end
  end
  -- An open inventory is modal: no accidental world navigation in the gaps.
  if self.compact_layout and self.open then return "panel" end
end
local function rounded(g,b,r,fill)
  g.rectangle(fill or "fill",b.x,b.y,b.w,b.h,r or 7,r or 7)
end
local function label(g,text,b)
  g.printf(text,b.x+3,b.y+b.h/2-7,b.w-6,"center")
end
function H:draw(inv,craft,s,rotation,message)
  local g=love.graphics
  g.push("all")
  local all=self:layout(s)
  for _,b in ipairs(all) do
    if b.id=="panel" then
      g.setColor(.045,.10,.11,.94); rounded(g,b,12)
    elseif b.id:sub(1,9)=="hud_page:" then
      local active=(b.id=="hud_page:items" and self.page==1) or
        (b.id=="hud_page:actions" and self.page==2)
      g.setColor(active and .29 or .13,active and .42 or .26,.30,.98)
      rounded(g,b,7)
      g.setColor(.96,.96,.85)
      label(g,b.id=="hud_page:items" and "ITEMS" or "CRAFT/BUILD",b)
    elseif b.id=="inventory" then
      g.setColor(.15,.29,.30,.94);rounded(g,b)
      g.setColor(.96,.96,.85);label(g,self.open and "CLOSE" or "BAG (12)",b)
    elseif b.id:sub(1,5)=="slot:" then
      local idx=tonumber(b.id:sub(6))
      local stack=inv.slots[idx]
      g.setColor(idx==self.selected and .31 or .11,idx==self.selected and .39 or .22,.24,.94)
      rounded(g,b)
      g.setColor(idx==self.selected and 1 or .45,.8,.52,.85)
      rounded(g,b,6,"line")
      g.setColor(.97,.95,.82)
      if stack then
        g.printf(names[stack.def_id] or stack.def_id,b.x+2,b.y+2,b.w-4,"center")
        g.printf("x"..stack.count,b.x+2,b.y+b.h-18,b.w-4,"center")
      else
        label(g,tostring(idx),b)
      end
    else
      local title
      if b.id=="recipe:core:planks_from_log" then title="CRAFT  1 LOG > 4 PLANKS  (0.5s)"
      elseif b.id=="recipe:core:bench_from_planks" then title="CRAFT  4 PLANKS > BENCH  (1s)"
      elseif b.id=="build" then title="PLACE WORKBENCH"
      elseif b.id=="confirm" then title="CONFIRM"
      elseif b.id=="rotate" then title="ROTATE "..rotation
      elseif b.id=="cancel" then title="CANCEL" end
      if title then
        g.setColor(.11,.26,.23,.98);rounded(g,b)
        g.setColor(.78,.92,.78);rounded(g,b,7,"line")
        g.setColor(1,.96,.85);label(g,title,b)
      end
    end
  end
  if craft.active then
    local bx,by=s.x+16,s.y+120
    g.setColor(.08,.14,.15,.92)
    g.rectangle("fill",bx,by,math.min(180,s.w-32),9,4,4)
    g.setColor(.91,.67,.26,1)
    g.rectangle("fill",bx,by,math.min(180,s.w-32)*craft:progress(),9,4,4)
  end
  g.pop()
end
return H
