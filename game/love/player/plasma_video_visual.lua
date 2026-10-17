-- External Core PNG + approved optically looped 102 plasma frames.
-- Preview state is visual-only; it never touches player stats or saves.
local Fallback=require("player.core_visual")
local Aura=require("player.core_aura")
local Energy=require("player.plasma_energy_controller")
local M={}
local loaded,state,lastTime
local mode,energyFraction=1,1
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
local labels={"NORMAL","SLOW","BREATH","LEVEL UP","TWO RINGS","THREE RINGS"}
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
function M.setPreview(nextMode,nextEnergy)
  if nextMode~=nil then assert(finite(nextMode) and nextMode>=1 and nextMode<=6 and nextMode==math.floor(nextMode));mode=nextMode end
  if nextEnergy~=nil then assert(finite(nextEnergy));energyFraction=clamp(nextEnergy,0,1) end
  -- Keep visual energy state across UI changes: otherwise shrink/restore snaps.
  -- Changing modes does not erase the smoothing clock either.
end
function M.getPreview() return mode,energyFraction,labels[mode] end
local function resources()
  if loaded then return loaded end
  loaded={frames={}}
  local root="assets/core_plasma/"
  if not love.filesystem.getInfo(root.."core_original.png") then return loaded end
  local ok,img=pcall(love.graphics.newImage,root.."core_original.png")
  if not ok then return loaded end
  loaded.core=img;img:setFilter("linear","linear")
  for i=0,101 do
    local path=string.format("%sloop/frame_%03d.png",root,i)
    if not love.filesystem.getInfo(path) then break end
    local good,frame=pcall(love.graphics.newImage,path)
    if not good then break end
    frame:setFilter("linear","linear")
    local fw,fh=frame:getDimensions()
    local cut=math.floor(fh*.51)
    loaded.frames[#loaded.frames+1]={
      image=frame,
      back=love.graphics.newQuad(0,0,fw,cut,fw,fh),
      front=love.graphics.newQuad(0,cut,fw,fh-cut,fw,fh),
      fw=fw,fh=fh,cut=cut,
    }
  end
  if #loaded.frames~=102 then loaded.core=nil;loaded.frames={} end
  return loaded
end
local function drawHalf(g,frame,x,y,width,height,angle,back,alpha,tint)
  local top=back and 0 or frame.cut
  local q=back and frame.back or frame.front
  g.setColor(tint[1],tint[2],tint[3],alpha)
  g.draw(frame.image,q,x,y,angle,width/frame.fw,height/frame.fh,
    frame.fw/2,frame.fh/2-top)
end
-- A diagnostic only; missing sources are never mislabeled as full plasma.
function M.assetStatus()
  local assets=resources()
  return {ready=assets.core~=nil and #assets.frames==102,
    frame_count=#assets.frames}
end
function M.draw(g,camera,w,h,player,context)
  local assets=resources()
  if not assets.core or #assets.frames~=102 then
    return Fallback.draw(g,camera,w,h,player,context)
  end
  context=context or {}
  local t=(type(player.time)=="number" and player.time) or 0
  local dt=lastTime and clamp(t-lastTime,0,.1) or 0
  lastTime=t
  local aura=Aura.resolve(context.stats,context.palette,context.previous,context.options)
  local input={energy_fraction=context.energy_fraction or energyFraction,
    ring_count=context.ring_count or (mode==6 and 3 or mode==5 and 2 or 1),
    primary_color=aura.primary_color,secondary_color=aura.secondary_color}
  if not state then state=Energy.resolve(input,nil,0) else state=Energy.resolve(input,state,dt) end
  local z=camera.zoom
  local x,foot=camera:project(player.x,player.y,w,h)
  local moving=player.state=="walk"
  local cy=foot-(21+(moving and 1.3 or .55)*math.sin(t*math.pi*3.5))*z
  local cw,ch=assets.core:getDimensions()
  local coreWidth=42*z
  local ringWidth=108*z*state.orbit_scale
  local ringHeight=62*z*state.orbit_scale
  local rate=mode==2 and 7 or 12
  local breath=mode==3 and (.78+.22*(.5+.5*math.cos(t*1.5))) or 1
  local charge=mode==4 and math.exp(-((t%5-1.35)/.48)^2) or 0
  local specs={{rate=1,shift=0,size=1,tilt=0,alpha=1}}
  if state.rings>=2 then specs[#specs+1]={rate=.74,shift=39,size=.88,tilt=.15,alpha=.48} end
  if state.rings>=3 then specs[#specs+1]={rate=1.37,shift=71,size=.76,tilt=-.20,alpha=.37} end
  g.push("all")
  local function drawPass(alpha)
    for _,back in ipairs({true,false}) do
      if not back then
        local scale=coreWidth/math.max(cw,ch)
        g.setColor(1,1,1,alpha)
        g.draw(assets.core,x,cy,0,scale,scale,cw/2,ch/2)
      end
      for index,s in ipairs(specs) do
        local n=(math.floor(t*rate*s.rate)+s.shift)%102+1
        local tint={1,1,1}
        if not aura.neutral then
          local c=(index==1) and aura.primary_color or aura.secondary_color
          -- Mild tint preserves optical artwork highlights and white-hot centre.
          tint={.58+.42*c[1],.58+.42*c[2],.58+.42*c[3]}
        end
        drawHalf(g,assets.frames[n],x,cy,ringWidth*s.size*breath,
          ringHeight*s.size*breath,s.tilt,back,state.opacity*s.alpha*alpha,tint)
      end
    end
    if not back and not aura.neutral and aura.secondary then
      g.setColor(aura.secondary_color[1],aura.secondary_color[2],aura.secondary_color[3],.38*state.opacity*alpha)
      g.setLineWidth(math.max(1,z))
      g.ellipse("line",x,cy,ringWidth*.31,ringHeight*.31)
    end
    if charge>.015 then
      g.setBlendMode("add")
      g.setColor(.27,.75,1,.26*charge*alpha)
      g.circle("fill",x,cy,coreWidth*(.12+.14*charge))
      g.setLineWidth(math.max(1,z*1.1))
      g.setColor(.20,.85,1,.50*charge*alpha)
      g.ellipse("line",x,cy,ringWidth*(.42+.38*charge),ringHeight*(.42+.38*charge))
      g.setBlendMode("alpha")
    end
  end
  local immersion=clamp(player.immersion or 0,0,1)
  if immersion>0 then
    local waterline=foot-(2+35*immersion)*z
    local cut=clamp(math.floor(waterline+.5),0,h)
    g.setScissor(0,0,w,cut);drawPass(1)
    g.setScissor(0,cut,w,h-cut);drawPass(.16)
    g.setScissor()
    g.setColor(.4,.79,.86,.72)
    g.setLineWidth(math.max(1,z))
    g.ellipse("line",x,waterline,13*z,4*z)
  else drawPass(1) end
  g.pop()
  return aura
end
return M
