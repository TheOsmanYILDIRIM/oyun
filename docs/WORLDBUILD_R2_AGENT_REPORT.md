# WORLDBUILD R2 — Agent H / compatibility and repairs

- **Agent:** H — A–F compatibility gate before G pilot.
- **State:** active / verification pending; do not mark done.
- **Branch:** experiment/worldbuild-r2-compat-20261019.
- **Base:** A 4d40a62c3b56733cbae5b7c78c563a626c2f01f4; main 4fa358ea42dbcb8b50ec956a7e14d247bf10f52b protected.
- **Source heads (verified):** A 4d40a62c; B 63b2baaf; C 1f36bed4; D 37a39c4f; E ab5316b9; F 1d1ce3d6.
- **Policy:** controlled source-blob selection, no wholesale branch merge; original A–F reports remain in their respective branches.
- **Selected sources:** A manifest/authored/schema/validator; B topography module/test; C authored_features/routes_water/test; D materials/terrain_renderer/test; E r2_population/test; F r2-core/r2-app/r2.html/index/test/package. No original A–F workflow changes imported.
- **Integration adapter:** game/love/world/r2_compat_bridge.lua, opt-in, externally validated JSON, shared B slope/C water and D chunk scalar source, E map sites/resources, deterministic IDs. No production activation or persistence changes.
- **Testing:** game/love/tests/r2_h_compat.lua; game/love/tests/r2_h_visual_smoke.lua; existing quality workflow branch-scoped new real combined test/render/artifact steps. CI not yet verified.
- **Unresolved blocked geography:** A site:fisilti-dere (704,128) C measured real water bank gap 45.838; no crossing created. User approval needed before editing A's approved coordinates/path geometry.
- **Stage6:** E regrowth save remains fail-closed; no migration/autosave.
- **Protected:** main, A–F experiment branches, main.lua, save/, Core/plasma, backups, old editor localStorage/IndexedDB and user files.
- **Beyin:** tasks/oyun-worldbuild-r2-compat-20261019.md revision 1 / active, official request oyun_r2_compat_create_20261019_h01; applied and canonical task reread.
- **Next:** check CI run/job/step and artifact/PNG for combined tree, repair failures in H only. G handoff NOT ready until all integration gates verified and crossing decision made.
