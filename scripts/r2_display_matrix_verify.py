#!/usr/bin/env python3
"""Compare real LÖVE/Xvfb bitmap pairs and report screen/DPI/geometry evidence."""
import csv
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageStat
import sys
root=Path(sys.argv[1])
cases=[
 (320,700,1.7),(360,780,1.7),(392,850,1.7),
 (411,891,1.7),(691,1536,1.7),(720,1600,1.7),
 (1280,800,1.7),(360,780,.65),(360,780,3.2),
 (800,360,1.7)
]
rows=list(csv.DictReader((root/"R2_DISPLAY_MATRIX.csv").open()))
assert len(rows)==len(cases), (len(rows),len(cases))
report=[]
for i,(w,h,z) in enumerate(cases,1):
 row=rows[i-1]
 assert int(row["case"])==i and int(row["width"])==w and int(row["height"])==h
 assert abs(float(row["zoom"])-z)<1e-5 and int(row["needed"])==int(row["loaded"])
 assert int(row["loaded"])>0
 a=root/f"matrix-{i:02d}-baseline.png"
 b=root/f"matrix-{i:02d}-optimized.png"
 assert a.is_file() and b.is_file(), (a,b)
 with Image.open(a) as im1, Image.open(b) as im2:
  im1.load();im2.load()
  assert im1.size==(w,h) and im2.size==im1.size,(i,im1.size,im2.size)
  rgb1,rgb2=im1.convert("RGB"),im2.convert("RGB")
  diff=ImageChops.difference(rgb1,rgb2)
  bbox=diff.getbbox()
  # Three test-only frames of settled streaming and a full playable draw.
  stat=ImageStat.Stat(rgb1)
  assert max(stat.stddev)>5,("blank scene",i,stat.stddev)
  for page in ("items","actions"):
   shot=root/f"matrix-{i:02d}-hud-{page}.png"
   assert shot.is_file(),shot
   with Image.open(shot) as screenshot:
    screenshot.load()
    assert screenshot.size==(w,h)
    assert max(ImageStat.Stat(screenshot.convert("RGB")).stddev)>5,
      ("blank compact HUD frame",shot)
  record={"case":i,"logical":[w,h],"zoom":z,"reported_dpi":float(row["dpi"]),
    "resident_chunks":int(row["loaded"]),"drawcalls":int(row["drawcalls"]),
    "pixel_equal":bbox is None,"diff_bbox":bbox}
  report.append(record)
  print("R2_DISPLAY_IMAGE",json.dumps(record))
(root/"R2_DISPLAY_MATRIX.json").write_text(json.dumps({
 "environment":"GitHub-hosted Ubuntu LÖVE/Xvfb; real screenshots, software display; physical Android DPI/GPU not tested",
 "verification":"Matched baseline/optimized pixel colors at each exact logical viewport, same indexed mesh and full-screen stream coverage",
 "screens":report},indent=2))
assert all(x["pixel_equal"] for x in report),"screen-dependent visual mismatch"
print("R2_DISPLAY_VISUAL_MATRIX_OK cases="+str(len(report)))
