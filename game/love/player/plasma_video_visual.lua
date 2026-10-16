-- Optional real-Core and plasma loop renderer. Safe fallback when assets absent.
-- Export loop frames as PNG to assets/core_plasma/loop/frame_000.png ...
local M={}
local CoreVisual=require("player.core_visual")
local Energy=require("player.plasma_energy_controller")
local state
local function load()
  if state then return state end
  state={frames={}}
  local root="assets/core_plasma/"
  if not love.filesystem.getInfo(root.."core_original.png") then return state end
  local ok,img=pcall(love.graphics.newImage,root.."core_original.png")
  if not ok then return state end
  state.core=img
  for i=0,115 do
    local path=string.format("%sloop/frame_%03d.png",root,i)
    if not love.filesystem.getInfo(path) then break end
    local success,frame=pcall(love.graphics.newImage,path)
    if not success then break end
    state.frames[#state.frames+1]=frame
  end
  return state
end
function M.draw(g,camera,w,h,player,context)
  local assets=load()
  if not assets.core or #assets.frames<2 then
    return CoreVisual.draw(g,camera,w,h,player,context)
  end
  local x,foot=camera:project(player.x,player.y,w,h)
  local z=camera.zoom
  local y=foot-21*z
  local t=player.time or 0
  local cfg=Energy.resolve(context and context.energy or nil,nil,0)
  local frame=assets.frames[math.floor(t*24)%#assets.frames+1]
  local fw,fh=frame:getDimensions()
  local cw,ch=assets.core:getDimensions()
  local s=32*z/math.max(cw,ch)
  local ring_scale=cfg.orbit_scale*55*z/fw
  g.push("all")
  -- rear half of orbit, Core, then front half: preserves local depth.
  local function plasma(front)
    local split=fh*.5
    local q=g.newQuad(0,front and split or 0,fw,front and fh-split or split,fw,fh)
    g.setColor(1,1,1,cfg.opacity)
    g.draw(frame,q,x,y+(front and 0 or -split*ring_scale),0,ring_scale,ring_scale,fw*.5,front and 0 or split)
  end
  plasma(false)
  g.setColor(1,1,1)
  g.draw(assets.core,x,y,0,s,s,cw*.5,ch*.5)
  plasma(true)
  g.pop()
  return true
end
return M
