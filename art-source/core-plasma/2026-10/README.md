# Core Plasma — Original production archive (October 2026)

This folder is the durable **source-of-truth destination for original art/video provenance**, separate from the optimized runtime assets in `game/love/assets/core_plasma/`.

## Preservation rules

- Preserve original bytes of the approved `121222.png` metal Core and raw Veo recordings `121237.mp4`, `121246.mp4`; do not substitute screenshots, compressed previews, or AI reconstructions.
- Keep the high-quality image references and their unchanged inputs. Treat loops, masks, edited references, preview GIFs, and scripts as **derived** files, never replacements for masters.
- Approved optical loop: derived from `121246.mp4`; investigate `make_optical_loop.py` and `find_plasma_loop.py` for reproducibility. No fake perfect-loop claims.
- Each imported binary must match the size and SHA-256 in `manifest.json`, plus the GitHub blob SHA after upload.
- Record missing or pending files explicitly; **a manifest row is not proof a binary exists in GitHub**.
- All source files are conversation-provided or produced for this project; do not import third-party game/MTS licensed materials without checking permissions.
- Never mutate main, backup, gameplay save data, Stage5/6, or already functioning player systems to archive art.
- Branch: `experiment/core-plasma-energy-runtime-20261016`. Task `oyun-core-plasma-art-assets-20261016`.
- Binary path: use controlled Supabase `github-binary-upload` queue, current contract in [docs/23_GITHUB_BINARY_UPLOAD_QUEUE.md](../../../docs/23_GITHUB_BINARY_UPLOAD_QUEUE.md), with independent GitHub HEAD/hash readback. For archives bigger than 6 MiB, preserve intact originals via separate uploads or an approved safe larger-file pathway; never silently recompress.
- Suggested source layouts: `sources/core`, `sources/plasma`, `sources/veo`, `references`, `working/optical_loop`, `working/animations`, and `working/scripts`.

## Current state

The source manifest is a **verified local-file inventory**, not a claim that 30 binary assets have reached this branch. Individual source upload status must be updated to `github_verified` only after reading the remote file/hash. The conversation also exports source ZIP archives to allow independent safekeeping.

## Verified Osman Google Drive backup (2026-10-17)

- [core_plasma_all_original_sources.zip — Google Drive](https://drive.google.com/file/d/1S-0zSMvfLODz2E_mdKUER9tTamQ2YiMU/view?usp=drivesdk)
- Google Drive file ID: `1S-0zSMvfLODz2E_mdKUER9tTamQ2YiMU`; verified account: Osman (`osman13241429` connection).
- Exact bytes: `34544512` (verified by Drive metadata).
- SHA-256 of local archive: `e54442ee8dcc7dde61bc8600ca4eb34eaf4a8ec05ea31271240a292b0035e4c3`.
- ZIP integrity verified locally; Google Drive download/re-hash was not performed.
- This is a **Drive backup**, NOT evidence of individual binary assets being imported to GitHub. Do not mark manifest items `github_verified` until binary import and GitHub blob readback.
- Subsequent agents should retrieve original bytes from the Osman Drive connection, verify archive checksum and per-file manifest hashes, then use the authorized Supabase binary queue with an active Avenox Beyin task and fresh branch HEAD.
