# Aşama 2/3 entegrasyon deneyi

Stage 2 procedural scalar query remains authoritative for walkability independent
of visual chunk residency. Stage 3 swept AABB consumes
`world.collision_adapter`, which rasterizes water conservatively into solid
8-unit rectangles. This approximates organic Marching Squares boundaries; it is
not exact polygon collision. Sampling is discrete (3x3 samples per cell), so
sub-cell water islands smaller than sample spacing are a known limitation.
Do not claim mathematically perfect boundary fidelity.

The adapter raises an explicit error if a query spans more than 4096 cells.
The gameplay seed is fixed (20261015) for reproducible testing.
No object colliders or persistent modifications exist yet.

Controls: WASD/arrows screen directions, touch joystick bottom left,
tap-to-path A*, mouse wheel zoom; player follows camera.
All coordinates used for physics/pathfinding are world units.

This integration remains an experiment pending review of actual real LOVE
CI smoke, branch protection, visual screenshot inspection, and edge-case tests.
Android real-device, FPS and APK builds have not been verified.
\nThe water adapter now samples a 9x9 lattice including cell edges, still an approximation rather than an exact mathematical boundary. CI separately captures a seeded diagnostic view; biome richness must be assessed from its pixels, not success logs alone. Touch joystick placement considers LÖVE safe area when present.\n