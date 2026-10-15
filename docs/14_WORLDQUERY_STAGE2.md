# Stage 2 Procedural World / parallel Stage 3 API (2026-10-15)

## Branch isolation

World agent owns `experiment/world-generation-v2`, branching from verified
main `99b28e3a391f13efb2f5ecb12f52590fd665ab99`.
Another agent owns `experiment/player-systems-v1`; **do not edit**
`game/love/player/**`, `physics/**`, `navigation/**`,
`game/love/core/**`, or production `game/love/main.lua` here.
This world branch is an independent tested library and debug entrypoint,
not a main-branch merge or a playable production release.

## WorldQuery v1 — mandatory consumer contract

Import using Lua `local Query=require("world.world_query")`.
Construct `world=Query.new(seed)` with nonnegative integer seed less than
2147483647; no global random, Love runtime, wall-clock or mutable editor state.
Query methods always use colon syntax and **continuous world coordinates**,
not projected screen pixels:

- `world:sample(x,y)` returns `{biome,feature,height,moisture,walkable}`
- `world:get_biome(x,y)` returns `"meadow" | "forest" | "rocky"`
- `world:get_height(x,y)` returns a continuous finite height (world units)
- `world:get_feature(x,y)` returns `"water" | "path" | nil`
- `world:is_walkable(x,y)` returns boolean (water is impassable)
- `world:get_obstacles({min_x, min_y, max_x, max_y})` returns list.
  **Stage 2 has no placed obstacle instances** so currently returns `{}`
  after validating bounds. Do not infer that trees or rocks have been
  built. Consumers must check is_walkable for water.
- `world.generator_version=1`, `world.seed`; future persistence must
  save both and support versioned migration rather than silently alter terrain.

Terrain generation uses smooth global scalar fields independent of chunk
generation order. `world.marching.build(sampler, x0,y0,size,step,level)`
returns clipped fill `vertices` (triples of `{x,y}`) and `contours`
(segment endpoint pairs). Ambiguous saddles use center disambiguation.
Identical absolute edge sample coordinates yield identical contour endpoints
on adjacent chunks, including negative coordinates. Patch meshes render
above an undivided meadow base without drawing tile grid edges.

`world.chunks` builds standalone deterministic geometry at integer chunk
coordinates, 256 world units per chunk by default, sampling at step 32.
`world.stream` incrementally loads/evicts camera-centred chunks with
bounded per-update budget and capped residency. On revisit a chunk is
regenerated from the seed; no user data is serialized in this stage.

## Test and rendering

From `game/love` run:

```sh
lua5.4 tests/run.lua
lua5.4 tests/runtime.lua
lua5.4 tests/world_stage2.lua
```

The dedicated GitHub workflow additionally launches the real LÖVE renderer
by copying `world/demo_main.lua` over `main.lua` **inside a temporary
runner directory only**; shared production `game/love/main.lua` remains
untouched. Interactive local demo: similarly copy the game to a scratch
directory and run LÖVE there. CI smoke is NOT Android or visual design QA.

Terrain Studio's 18 variations, PNG, IndexedDB, existing World Builder and
other studios are unchanged; integration remains Phase 9.
