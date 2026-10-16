# Axe strike FX — isolated experiment

Branch: `experiment/core-axe-strike-fx-20261017`.

- `game/love/player/axe_strike.lua`: deterministic rigid tool pose, sampled cutting-edge cyan trail, impact particles. No energy arm, no Stage5/6 mutations.
- `game/love/axe_strike_demo.lua`: standalone LÖVE callback entrypoint; **not** loaded by production `main.lua`.
- Source PNG: conversation attachment `121227.png`, SHA-256 `294005fae2b80d404a9b5919f7c2dee67734f33e85c2761e31cc47be1d1e52f4`.
- **BLOCKER**: binary PNG has not been imported to GitHub; demo expects `game/love/assets/axe_121227.png`. Do not claim a complete GitHub-playable build.
- Run after importing verified PNG: from `game/love`, copy `axe_strike_demo.lua` to a separate temporary test directory as `main.lua`, with `player/axe_strike.lua` and `assets/axe_121227.png`; run `love <test-dir>`. Do not replace production main.
- No real LÖVE/Xvfb screenshot or CI verification has been completed.
- Production main, backup, camera, physics, Stage5/6, user data, studios remain untouched.
