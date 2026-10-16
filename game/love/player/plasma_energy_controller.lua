-- Visual-only energy controller. No canonical level thresholds or save mutations.
local M={}
local function clamp(x) return math.max(0,math.min(1,x)) end
local function finite(x) return type(x)=="number" and x==x and math.abs(x)<math.huge end
function M.resolve(input, previous, dt)
  input=input or {}
  assert(type(input)=="table","energy input table required")
  local energy=input.energy_fraction
  if energy==nil then energy=1 end -- neutral preview when no energy registry exists
  assert(finite(energy),"energy_fraction must be finite")
  local target=clamp(energy)
  local before=previous and previous.energy or target
  assert(finite(before),"previous energy must be finite")
  dt=dt or 0
  assert(finite(dt) and dt>=0,"invalid delta")
  local smooth=before+(target-before)*(1-math.exp(-math.min(dt,1)*5))
  -- Levels are visual complexity hints from a future canonical progression adapter,
  -- never invented numeric level thresholds.
  local rings=input.ring_count or 1
  assert(type(rings)=="number" and rings==math.floor(rings) and rings>=1 and rings<=3,"ring_count must be 1..3")
  return {
    energy=smooth,
    orbit_scale=.34+.66*smooth,
    opacity=.20+.80*smooth,
    rings=rings,
    phase=(previous and previous.phase or 0)+dt*(.45+.45*smooth),
    primary_color=input.primary_color,
    secondary_color=input.secondary_color,
  }
end
return M
