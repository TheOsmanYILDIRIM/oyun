-- Immediate crafting MVP; recipe duration remains a job-contract for Stage 6.
-- Inputs and outputs are committed together in memory or not at all.
local Catalog=require("systems.catalog")
local Crafting={}
Crafting.__index=Crafting

function Crafting.new(inventory)
  assert(inventory and type(inventory.preview)=="function"
    and type(inventory.commit_preview)=="function","inventory required")
  return setmetatable({inventory=inventory,commands={}},Crafting)
end

local function stations_allowed(recipe,available)
  available=available or {}
  assert(type(available)=="table","station tags must be a table")
  local known={}
  for _,tag in ipairs(available) do
    assert(type(tag)=="string","station tag must be string")
    known[tag]=true
  end
  for _,tag in ipairs(recipe.station_tags) do
    if not known[tag] then return false end
  end
  return true
end

function Crafting:execute(command_id,recipe_id,station_tags)
  assert(type(command_id)=="string" and #command_id>0 and #command_id<=128,
    "invalid crafting command")
  if self.commands[command_id] then return self.commands[command_id] end
  local recipe=Catalog.recipe(recipe_id)
  local result
  if not stations_allowed(recipe,station_tags) then
    result={ok=false,status="station_required"}
  else
    local candidate=self.inventory:preview()
    local enough=true
    for _,input in ipairs(recipe.inputs) do
      if not self.inventory:preview_remove(candidate,input.def_id,input.count)
         then enough=false;break end
    end
    if not enough then
      result={ok=false,status="insufficient_materials"}
    else
      local space=true
      for _,output in ipairs(recipe.outputs) do
        if not self.inventory:preview_add(candidate,output.def_id,output.count)
          then space=false;break end
      end
      if not space then
        result={ok=false,status="inventory_full"}
      else
        self.inventory:commit_preview(candidate)
        result={ok=true,status="crafted",recipe_id=recipe_id,
          duration_ticks=recipe.duration_ticks}
      end
    end
  end
  self.commands[command_id]=result
  return result
end

return Crafting
