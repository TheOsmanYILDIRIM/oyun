local scene=require("world.scene")
local Iso=require("world.iso")
local Biomes=require("world.biomes")
local scale=1.7
function love.load() Biomes.validate() end
local function drawRegion(region,cx,cy)
 local points={}
 for _,p in ipairs(region.polygon) do
  local x,y=Iso.project(p[1],p[2])
  points[#points+1]=cx+x*scale
  points[#points+1]=cy+y*scale
 end
 local b=Biomes.resolve(region.biome,region.variant)
 love.graphics.setColor(b.color)
 love.graphics.polygon("fill",points)
 love.graphics.setColor(.18,.25,.21)
 love.graphics.setLineWidth(2)
 love.graphics.polygon("line",points)
end
function love.draw()
 love.graphics.clear(.10,.15,.13)
 local w,h=love.graphics.getDimensions()
 for _,region in ipairs(scene.regions) do drawRegion(region,w*.5,h*.5) end
 love.graphics.setColor(1,1,1)
 love.graphics.print("Three authored biomes - textures not yet supplied",16,28)
end
function love.wheelmoved(_,dy) scale=math.max(.5,math.min(4,scale*(1+dy*.1))) end
