"""Lager UTOP-sjablong (stencil) for 3D-print.

Bokstavene skjæres ut av en flat plate. Lukkede rom (i O og P) holdes fast
med stege (broer), ellers ville de falt ut.

Kjør:  python3 lag_sjablong.py
"""
import numpy as np
import trimesh
from matplotlib.font_manager import FontProperties
from matplotlib.textpath import TextPath
from shapely.geometry import Polygon, box
from shapely.ops import unary_union
from shapely import affinity

FONT = "/usr/share/fonts/opentype/inter/Inter-Bold.otf"
TEXT = "UTOP"
THICK = 1.5          # platetykkelse (mm)
CORNER = 6           # hjørneradius på platen

# Byggeplater: navn -> (plate-bredde, plate-høyde, kant rundt tekst, stegbredde)
VARIANTER = {
    "256": (250, 92, 14, 5.0),   # Bambu X1 / P1 / A1 (256 x 256)
    "180": (175, 64, 10, 3.5),    # Bambu A1 mini (180 x 180)
}


def text_polygon(text):
    tp = TextPath((0, 0), text, prop=FontProperties(fname=FONT), size=100)
    polys = []
    for verts in tp.to_polygons():
        if len(verts) >= 3:
            polys.append(Polygon(verts).buffer(0))
    # yttre konturer og hull: bruk symmetrisk differanse (even-odd)
    shape = Polygon()
    for p in polys:
        shape = shape.symmetric_difference(p)
    return shape.buffer(0)


def make(name, PW, PH, MARGIN, BRIDGE):
    letters = text_polygon(TEXT)
    minx, miny, maxx, maxy = letters.bounds
    s = min((PW - 2 * MARGIN) / (maxx - minx), (PH - 2 * MARGIN) / (maxy - miny))
    letters = affinity.scale(letters, s, s, origin=(minx, miny))
    letters = affinity.translate(letters, -minx * 0, 0)
    minx, miny, maxx, maxy = letters.bounds
    letters = affinity.translate(letters, PW / 2 - (minx + maxx) / 2, PH / 2 - (miny + maxy) / 2)

    # Stege: loddrett bro gjennom midten av hvert lukket rom (O og P)
    geoms = letters.geoms if letters.geom_type == "MultiPolygon" else [letters]
    bridges = []
    for g in geoms:
        _, gy0, _, gy1 = g.bounds
        for hole in g.interiors:
            cx = Polygon(hole).centroid.x
            bridges.append(box(cx - BRIDGE / 2, gy0 - 1, cx + BRIDGE / 2, gy1 + 1))
    cut = letters.difference(unary_union(bridges)) if bridges else letters

    plate = box(CORNER, CORNER, PW - CORNER, PH - CORNER).buffer(CORNER, resolution=16)
    stencil = plate.difference(cut).buffer(0)
    assert stencil.geom_type == "Polygon", "sjablongen falt fra hverandre"
    mesh = trimesh.creation.extrude_polygon(stencil, THICK)
    assert mesh.is_watertight
    out = f"utop_sjablong_{name}.stl"
    mesh.export(out)
    print(out, "plate", PW, "x", PH, "mm, tekst %.0f x %.0f mm" % (letters.bounds[2] - letters.bounds[0], letters.bounds[3] - letters.bounds[1]),
          "| stege:", len(bridges))
    return stencil


if __name__ == "__main__":
    for k, v in VARIANTER.items():
        make(k, *v)
