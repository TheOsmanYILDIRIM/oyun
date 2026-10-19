# WORLDBUILD R2 — Agent H / A–F compatibility and approved river-valley repair

## Verified delivery

- **Agent:** H / Round 2 compatibility and integration repairs.
- **State:** `done` for the approved *opt-in A–F diagnostic integration* and crossing-aligned authored valley. This **does not mean the G playable pilot is completed**.
- **Branch:** `experiment/worldbuild-r2-compat-20261019`; no main merge.
- **Source main HEAD (rechecked):** `4fa358ea42dbcb8b50ec956a7e14d247bf10f52b`. Main, backup, A–F branches, production `main.lua`, save/, catalog, player/Core/plasma, user data and old editor localStorage/IndexedDB preserved.
- **Verified upstream heads:** A `4d40a62c3b56733cbae5b7c78c563a626c2f01f4`, B `63b2baafffbd8f03842f1e44fcf6b169d1edff58`, C `1f36bed46102db15d77741004adb9349b8f9409c`, D `37a39c4f1a39c386a8c0da2c31f936408663c72d`, E `ab5316b9c221faa2ea386ebed0d551051fe8f706`, F `1d1ce3d6b2263d6cd3fd60160851fb679d61e092`.
- **Last fully tested implementation commit:** `8e7859a3bb1466a047ce83849d18f6cb2b642f46`. Reporting-only commit intentionally does not self-reference; coordinator must read live branch HEAD.

## Source selection and shared API

- A map/authored source and v1/v2 schemas, validators, seed 20261018, stable IDs and polygon/route/connector graph retained as the initial H base.
- B `topography_surface.lua` (blob `a8767569bd893f8f167855c30698137f0a52aa3e`), C `authored_features.lua` (`0c1f7d897b3ff864aceedfc1b20ea25fc781ec91`) and `routes_water.lua` (`1495f0bb64e837acee82b4925cbd01aab28dce34`), D `materials.lua` (`64873ce5eb60a9a22eea1b528e91ece60db5855d`) and `terrain_renderer.lua` (`70a3ca8982a48687e12d94a8e6b958366943a79e`), E `r2_population.lua` (`e41797a5e67fc35919b2a7dc45777016bacb45ff`) and F `r2-core.mjs` (`ea273b5dbb845caade8b5f8dfb63e764cfd820ea`) plus corresponding tests/authoring UI were selected and copied by exact blob—not wholesale merged.
- **H shared constructor:** `game/love/world/r2_compat_bridge.lua` accepts externally schema-validated A v1+v2 documents, wires one continuous world-space `query:sample/get_height/is_walkable/water_mask/route_cost`, B grade and colliders, C water/paths, D material mesh, E visible object/build-area checks. Stable `worldobj:v1:*`/authored IDs unchanged. No hidden save conversion or runtime activation.

## Approved river + topography correction

- **User decision (2026-10-19):** The river must follow an actual valley and intersect the *existing* crossing site; keep the main path/site anchored. B's original height is Generator-v1 procedural noise, **not** an authored valley; merely relocating the painted water would have left terrain and hydrology out of sync.
- **Old river:** `feature:fisilti-dere-izi` centerline `[[536,56],[616,62],[735,74]]`; former real water-bank gap at `site:fisilti-dere` (704,128): **45.838 world units**.
- **New river:** centerline `[[536,56],[616,62],[704,128],[735,74]]`, same permanent feature ID and world width **22**; old independent `fisilti_ormani.v1.json` pilot remains unchanged. `site:fisilti-dere` (704,128), `site:fisilti-dere-kiyisi` (616,62), all routes/connectors/region polygons and IDs, seed and Generator v1 unchanged. No migration or coordinate rebasing.
- **New opt-in `r2_valley_surface.lua`:** C1-smooth deterministic riverbed, baseline B height minus maximum **2 world units** at the water centerline; smoothly zero outside **47 world units** from the river. B's `height_at` uses this one authoritative world-space offset for C flow, D projected mesh and E slope checks. No global Generator-v1 modification.
- **Physical evidence:** C crossing now reports `valid=true`, `water_bank_gap=0` and matching path+stream centerline at the site. Every authored river segment passes real B height downhill test. The crossing is wet and traversable with existing water multiplier `0.55` and immersion `0.50`.
- **Safety:** A hypothetical, *uninstantiated* 64-world-unit-length / width-8 bridge candidate passes bank-span geometry; a too-short bridge and a deep ford at authored depth **2** fail-closed. **No bridge or ford is spawned or approved for G gameplay** by this patch.
- **Visual integration defect and fix:** Before H repair, coarse 32-unit Marching mesh samples could miss parts of the 22-unit-wide river, visibly fragmenting the blue water despite continuous physics. H's **isolated LÖVE river diagnostic** now samples at **8-unit** terrain contour resolution, preserving C mask and world-space projection. Production quality/FPS is not inferred or changed.

## Changed files relative to prior H working state

- `data/worldbuild/fisilti_ormani.r2.v1.json` — river geometry only.
- `game/love/world/r2_compat_bridge.lua` — shared height and verified geometry activation fail-closed.
- **New:** `game/love/world/r2_valley_surface.lua` — H opt-in valley offset.
- `game/love/tests/r2_h_compat.lua` — deterministic valley/physical crossing/width/depth/route/surface/seed test.
- `game/love/tests/r2_features_hydrology.lua` — branch-local C regression adapted to user-authorized river geometry; deliberate invalid bridge still rejected.
- `tests/test_worldbuild_map_v2.py` — narrow exception for corrected R2 child river; keeps immutable original v1 pilot, all other feature prefixes and stable IDs.
- `game/love/tests/r2_h_visual_smoke.lua` — corrected camera location and 8-unit narrow-water rendering.
- This **H-owned** `docs/WORLDBUILD_R2_AGENT_REPORT.md`; all A–F reports remain in their own branches.
- Existing `.github/workflows/quality.yml` already runs H combined tests and PNG smoke. No additional workflow.

## Executed CI and visual evidence

- **Verified final quality PASS:** [run #39244914458](https://github.com/TheOsmanYILDIRIM/oyun/actions/runs/39244914458), [job test #118034389132](https://github.com/TheOsmanYILDIRIM/oyun/actions/runs/39244914458/job/118034389132), implementation commit `8e7859a3`. **17/17 job steps SUCCESS** including Python strict nested v1+v2 validator/contract, JS↔Python editor model 8/8, A–F targeted tests on **both Lua 5.4 and LuaJIT**, core/Stage5/Stage6 regression, real production LÖVE/Xvfb, and H's separately executable river+spawn diagnostic screenshots.
- Logs from each Lua runtime: `R2_C_H_CROSSING_ALIGNED site=site:fisilti-dere bank_gap=0.000`; `R2_H_COMPAT_OK sites=7 objects=18 bank_gap=0.000`; `R2_VISUAL_MATERIAL_MESH_OK variants=18 seam=9 profiles=3`; `R2_POPULATION_OK`. Global authored digest: `1f530be34b6393e7e9ea93fe6a1777de4e7811c96bf4c8c609c2162767ba61be`.
- **Real rendered H evidence:** `R2_H_LOVE_SMOKE_OK mode=river objects=19`, `mode=spawn objects=16`. [Artifact ID 12183601252](https://github.com/TheOsmanYILDIRIM/oyun/actions/runs/39244914458/artifacts/12183601252) downloaded; ZIP CRC verified, both PNGs actual **720×1100 RGB** opened and inspected.
  - ZIP SHA256 `5a9201c78051a51b2e6048065f8859261e00eff9af0b2dc2c713fe2ddd6c00a9`.
  - River PNG SHA256 `06624f311cc7649103ccd99ac450e7d0c350f3fecf9d351248938329d9baeb6e`.
  - Spawn PNG SHA256 `df3588a86fab4398ce41b701ac5e6fa6bf3abd1ad130a7a423d6ef8fb93a8c82`.
- **Manual visual finding:** Authored blue river is now visibly **continuous** through the valley and scene markers remain placed. River segments are still angular, and authored region biome boundaries remain conspicuously straight; this is a **diagnostic scene**, not final organic/production-grade G play.
- **Failed interim run (superseded):** [#39244297108](https://github.com/TheOsmanYILDIRIM/oyun/actions/runs/39244297108) failed Python legacy river-prefix invariant until the strictly scoped correction was made; [#39244423079](https://github.com/TheOsmanYILDIRIM/oyun/actions/runs/39244423079) passed functional tests, but manual PNG showed fragmented narrow-river mesh at step 32, leading to final step-8 verified run. Neither earlier run is final proof.
- **Separate pre-existing agent jobs independently checked:** A #39161676983, B #39167270921, C #39212455000, D #39228090552, E #39167895170, F #39168764095 successful; F Pages deploy intentionally skipped. Their scoped proof is not substituted for H's combined run.

## Limits and next owner

- H is complete for the approved integration and valley/crossing geometry; **G may base its opt-in diagnostic/playable pilot work on this H branch**, but must not treat this as production activation.
- **G remains unimplemented here:** real gameplay UI, player and A* crossing collision, optional real bridge/ford design, authentic tree/asset presentation, world edge aesthetics, Stage6 approved authored object/regrowth persistence, autosave, save migration, Android touch/FPS and device tests. Maintain fail-closed renewal/export and disabled autosave until separately approved.
- **No main merge.** Coordinator/G must decide future production activation and crossing construction or wet traversal semantics separately.

## Avenox Beyin (canonical main)

- Task: `tasks/oyun-worldbuild-r2-compat-20261019.md`, **revision 3 / status done**, independently verified after official v2 `oyun_r2_h_valley_done_20261019_h05`, [dispatcher run #39245458237](https://github.com/TheOsmanYILDIRIM/agy-vault/actions/runs/39245458237) status applied; no duplicate task.
- Verified official H valley receipt: event `oyun-worldbuild-r2-valley-ci39244914458`, request `oyun_r2_h_valley_receipt_20261019_h04`, [run #39245365573](https://github.com/TheOsmanYILDIRIM/agy-vault/actions/runs/39245365573) applied; source reread: `agy-vault/main/receipts/e75604c1eb496ae30ed7acdd098f1de016b96b5bdebda76e618dff8dee1c39e7.md`.
- Prior H diagnostic receipt/CI remains historically accurate for the *old unresolved* geometry, not for this final fix.
