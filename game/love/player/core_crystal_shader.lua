-- Core crystal V3: isolated visual shader; no player physics or save logic.
-- Inputs: approved base PNG + one aligned 1254x1254 mask. Mask white=active.
-- Module is not wired into production renderer before visual acceptance.
local M = {}

local SOURCE = [[
extern Image mask_tex;
extern number clock;
extern vec2 crystal_center;
extern vec2 crystal_radius;
extern number intensity;
extern vec3 glow_tint;

float hash21(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec4 effect(vec4 tint, Image tex, vec2 uv, vec2 pixel) {
  vec4 base = Texel(tex, uv) * tint;
  float mask = Texel(mask_tex, uv).r;
  float feather = smoothstep(0.035, 0.93, mask);
  vec2 coord = (uv - crystal_center) / max(crystal_radius, vec2(0.001));
  float radial = clamp(1.0 - length(coord), 0.0, 1.0);
  radial = pow(radial, 0.55);
  float n = sin(uv.x * 480.0 + clock * 2.5) *
            sin(uv.y * 390.0 - clock * 1.8);
  float edge = clamp(1.0 + 0.12 * n * (1.0 - feather), 0.82, 1.18);
  float pulse = 0.58 + 0.42 * (0.5 - 0.5 * cos(clock * 6.2831853 / 2.08));
  float strength = clamp(intensity * feather * (0.30 + 0.70 * radial) * edge * pulse, 0.0, 1.0);
  vec3 light = clamp(glow_tint * strength, 0.0, 1.0);
  vec3 screened = 1.0 - (1.0 - base.rgb) * (1.0 - light);
  vec3 lifted = min(base.rgb + light * (0.38 + 0.32 * radial), vec3(1.0));
  // Blend inside the existing base sprite alpha; preserve panel identity.
  vec3 result = mix(screened, lifted, 0.38);
  return vec4(result, base.a);
}
]]

function M.new(base_image, mask_image)
  assert(base_image and mask_image, "base and mask images required")
  assert(base_image:getWidth() == mask_image:getWidth()
    and base_image:getHeight() == mask_image:getHeight(), "crystal mask must match base dimensions")
  local instance = {base = base_image, mask = mask_image, shader = love.graphics.newShader(SOURCE)}
  instance.shader:send("mask_tex", mask_image)
  -- Initial center/radii are approximations from the aligned V3 mask.
  -- Calibrate exact geometry from the approved mask bounds before production integration.
  instance.shader:send("crystal_center", {776.43 / 1254, 667.31 / 1254})
  instance.shader:send("crystal_radius", {150 / 1254, 170 / 1254})
  instance.shader:send("intensity", 1.0)
  instance.shader:send("glow_tint", {0.55, 0.90, 1.0})
  return instance
end

function M.draw(instance, x, y, rotation, sx, sy, ox, oy, seconds)
  assert(instance and instance.shader, "valid crystal effect required")
  local g = love.graphics
  g.push("all")
  -- Keep existing renderer blend state, masked shader updates the same sprite pass.
  g.setShader(instance.shader)
  instance.shader:send("clock", seconds or 0)
  g.draw(instance.base, x, y, rotation or 0, sx or 1, sy or sx or 1, ox or 0, oy or 0)
  g.pop()
end

return M
