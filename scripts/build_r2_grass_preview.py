#!/usr/bin/env python3
"""Build-only R2 grass preview; never mutates checked-out sources."""
import hashlib, os, pathlib, re, shutil, sys, zipfile
from PIL import Image

repo=pathlib.Path(sys.argv[1]).resolve()
root=pathlib.Path(sys.argv[2]).resolve()
out=pathlib.Path(sys.argv[3]).resolve()
if root.exists(): shutil.rmtree(root)
shutil.copytree(repo/"game/love",root)
(root/"data/worldbuild").mkdir(parents=True,exist_ok=True)
for name,expected in {
 "fisilti_ormani.r2.v1.json":"df5d0eeca59030e6585558c15d8f1e7bf049638ea8032dc17c1b80c74106f598",
 "osman_overworld.v2.json":"ac5903fd22cd466cfc1786cbeef44f2679be87317c6bfd757a05a282172f78dc",
}.items():
 data=(repo/"data/worldbuild"/name).read_bytes()
 assert hashlib.sha256(data).hexdigest()==expected,(name,"mismatch")
 (root/"data/worldbuild"/name).write_bytes(data)
names=[f"grass_{biome}_{i}.png" for biome in ("meadow","forest","rocky") for i in (0,1)]
for name in names:
 src=repo/"game/love/assets"/name
 assert src.exists(),name
 with Image.open(src) as im:
  im.load()
  assert im.width==im.height and im.width>=512,(name,im.size)
  # Bounded runtime GPU memory; preserve originals in git.
  im.convert("RGB").resize((512,512),Image.Resampling.LANCZOS).save(root/"assets"/name,optimize=True)
main=root/"main.lua"
s=main.read_text()
for a,b in [
 ('local r2_pilot_enabled=os.getenv("OSMAN_R2_PILOT")=="1"',
  'local r2_pilot_enabled=os.getenv("OSMAN_R2_PILOT")~="0"'),
 ('local cache_pilot_enabled=os.getenv("OSMAN_CHUNK_CACHE_PILOT")=="1"',
  'local cache_pilot_enabled=os.getenv("OSMAN_CHUNK_CACHE_PILOT")~="0"'),
 ('local r2_perf_overhaul=os.getenv("OSMAN_R2_PERF_OVERHAUL")=="1"',
  'local r2_perf_overhaul=os.getenv("OSMAN_R2_PERF_OVERHAUL")~="0"')
]:
 assert s.count(a)==1,a
 s=s.replace(a,b)
# Discard old per-user OSC geometry: older cache payloads have (0,0) UV.
old_stamp='"r2-fisilti-20261019-pinned"'
assert s.count(old_stamp)==1,"cache stamp contract changed"
s=s.replace(old_stamp,'"r2-fisilti-grass-worlduv-v2"')
# Profile-only opt-out for grass, no change to checked-out production sources.
flag='local r2_pilot=r2_pilot_enabled and require("world.r2_playable").new() or nil'
assert s.count(flag)==1,"pilot init contract changed"
s=s.replace(flag,flag+'\nif r2_pilot and os.getenv("OSMAN_R2_PROFILE")=="1" then\n r2_pilot.render_options.grass_preview=os.getenv("OSMAN_PROFILE_TEXTURE")~="0"\nend')
main.write_text(s)
pilot=root/"world/r2_playable.lua"
s=pilot.read_text()
s,n=re.subn(r"local function source_read\(name\)\n.*?\nend\nlocal function read_doc",'''local function source_read(name)
 assert(files[name], "unknown R2 authored map")
 local bytes,err=love.filesystem.read("data/worldbuild/"..name)
 assert(bytes,"missing packaged R2 map: "..tostring(err))
 return bytes
end
local function read_doc''',s,flags=re.S)
assert n==1,n
pilot.write_text(s)
renderer=root/"world/terrain_renderer.lua"
s=renderer.read_text()
# Bind grass UV to immutable WORLD mesh coordinates before projection;
# screen-pixel reconstruction drifts on R2 topography and camera movement.
old_vertex='local v={geo[1],geo[2],0,0,math.min(1,color[1]*shade),'
new_vertex='local v={geo[1],geo[2],x/192,y/192,math.min(1,color[1]*shade),'
assert s.count(old_vertex)==1,"world-UV vertex contract changed"
s=s.replace(old_vertex,new_vertex)
needle='local cached={}\n local count_total=0'
assert s.count(needle)==1
setup='''local active_texture=options.grass_preview~=false
 local shader
 local texture_pair={}
 if active_texture then
  if not Terrain._grass_shader then
   Terrain._grass_shader=lg.newShader([[
     extern Image secondGrass;
     vec4 effect(vec4 color, Image firstGrass, vec2 uv, vec2 pixel) {
       // UV is interpolated from absolute WORLD coordinates, including relief.
       float wx=uv.x*192.0;
       float wy=uv.y*192.0;
       vec2 tuv=fract(uv);
       vec4 one=Texel(firstGrass,tuv);
       vec4 two=Texel(secondGrass,tuv);
       float drift=0.5+0.5*sin(wx*0.013+wy*0.011)*cos(wx*0.007-wy*0.012);
       vec3 rgb=mix(one.rgb,two.rgb,smoothstep(0.28,0.73,drift));
       return vec4(rgb*0.88,color.a);
     }
   ]])
  end
  shader=Terrain._grass_shader
  if not Terrain._grass_images then
   Terrain._grass_images={}
   for _,biome in ipairs({"meadow","forest","rocky"}) do
    local first=lg.newImage("assets/grass_"..biome.."_0.png")
    local second=lg.newImage("assets/grass_"..biome.."_1.png")
    first:setFilter("linear","linear");second:setFilter("linear","linear")
    first:setWrap("repeat","repeat");second:setWrap("repeat","repeat")
    Terrain._grass_images[biome]={first,second}
   end
  end
  texture_pair=Terrain._grass_images
 end
 '''
s=s.replace(needle,setup+needle)
needle2='''if drawables[name] then
    lg.draw(drawables[name])
    material_calls=material_calls+1
   end'''
repl='''if drawables and drawables[name] then
    local pair=texture_pair[name]
    if pair then
     drawables[name]:setTexture(pair[1])
     shader:send("secondGrass",pair[2])
     lg.setShader(shader)
    else
     lg.setShader()
    end
    lg.draw(drawables[name])
    material_calls=material_calls+1
   end'''
assert s.count(needle2)==1
s=s.replace(needle2,repl)
needle3='''lg.pop()
 if Terrain.on_visibility'''
assert s.count(needle3)==1
s=s.replace(needle3,'''lg.setShader()
 lg.pop()
 if Terrain.on_visibility''')
renderer.write_text(s)
(root/"PREVIEW_GRASS_README.txt").write_text(
"Osman R2 grass full playable preview. Original save and texture assets unchanged. "
"R2, disposable terrain cache, and validated experimental R2 performance path "
"enabled by default in this portable package (set OSMAN_R2_PERF_OVERHAUL=0 "
"to compare baseline). The checked-out main.lua still defaults opt-out. "
"Six 512px downsized preview textures; originals remain in GitHub. "
"No official Android FPS proof. LÖVE 11.x.\n")
out.parent.mkdir(parents=True,exist_ok=True)
if out.exists():out.unlink()
with zipfile.ZipFile(out,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=5) as z:
 for item in sorted(root.rglob("*")):
  if item.is_file():z.write(item,item.relative_to(root).as_posix())
with zipfile.ZipFile(out) as z:
 assert z.testzip() is None
 assert all("assets/"+name in z.namelist() for name in names)
 assert all("data/worldbuild/"+name in z.namelist() for name in ["fisilti_ormani.r2.v1.json","osman_overworld.v2.json"])
 assert "main.lua" in z.namelist() and "conf.lua" in z.namelist()
print("GRASS_PREVIEW_ZIP_OK",out.stat().st_size,hashlib.sha256(out.read_bytes()).hexdigest())
