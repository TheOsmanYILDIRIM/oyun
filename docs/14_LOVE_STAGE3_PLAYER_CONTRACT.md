# Aşama 3 — İzole oyuncu, çarpışma, navigasyon sözleşmesi

## Kapsam ve sınır

Bu dal **Aşama 2 dalından bağımsız** `main` üstünde geliştirilir. Hiçbir aktif dünya, `main.lua`, `core/app.lua`, `core/camera.lua`, stüdyo, PNG, IndexedDB veya Godot kaynağı değiştirilmez. Üretim oyununa entegrasyon **henüz yapılmamıştır**. Aşama 3'ün testleri saf Lua, sürüm hedefi 5.4 ve LÖVE 11.x'dir.

## WorldQuery v1 — Aşama 2 ajanı için adaptör

```lua
local query = {}
function query:obstacles(minX,minY,maxX,maxY)
  -- WORLD units. Return *every* solid AABB intersecting query bounds.
  -- Array of {x=worldX,y=worldY,w=width,h=height}; w,h > 0.
  -- Unknown/unloaded terrain: raise an error, NOT {}.
end
```

Coordinates `x,y` are the same world coordinates used by `world.iso` and `core.camera`: positive y is down on the ground plane; `z` is visual height. Player footprint is an axis-aligned **square** `2*radius` on the ground plane. Collision boundaries come from a conservative AABB interpretation; Marching Squares contours need solid-region AABB approximations or separate polygon collision support after coordinated interface evolution. Streaming adapters must guarantee the swept query rectangle is loaded before returning, otherwise fail explicitly. Caller owns query lifecycle and spatial indexing.

`Controller.new(query,{x=0,y=0,speed=96,radius=5})` checks safe spawn; `:update(dt, worldAxisX, worldAxisY)` runs bounded 60 Hz fixed steps; `:step(x,y)` is useful for deterministic simulation. `state` is `idle`, `walk` or `blocked`, `facing` is one of E/SE/S/SW/W/NW/N/NE projected onto the screen. `:depth(z)` gives foot-based projected y sort; use `Depth.before(a,b)` with stable instance IDs to break exact ties.

Input axes are WORLD coordinates: camera-space on-screen movement must be converted using `world.iso.unproject` or an equivalent inverse isometric rotation **without multiplying by zoom**. For a touch joystick, feed `Joystick:axis()` into that conversion. Keyboard handling and camera follow belong in the later integration layer, not inside `core/app.lua` in this branch. `Controller:navigate_to(x,y,cell,max_nodes)` runs bounded 8-neighbor A* (no corner-cutting), with a discrete occupancy raster derived from the same collision query. It is intentionally not an infinite-world global pathfinder; route requests outside a loaded search region must error or return explicit failure. Input overrides a pending path. Movement uses swept rectangles with wall slide to avoid high-speed tunneling.

## Tests and integration gate

Run from `game/love`: `lua5.4 tests/player_stage3.lua`, `lua5.4 tests/run.lua`, `lua5.4 tests/runtime.lua`. Branch workflow `LOVE player Stage 3` also syntax-checks and executes the legacy LÖVE smoke; that smoke **does not render the player**, because production integration is deliberately postponed. Before merging a later integration PR, agree with the world-generation agent on obstacle coordinate units, unload policy, collision resolution of organic contours, input/camera ownership, sprite foot anchors and deterministic combined smoke scenes. Android APK, device, multiplayer, profiling and actual end-to-end character render are **not validated by isolated tests**.
