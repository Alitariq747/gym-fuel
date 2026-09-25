#!/usr/bin/env python3
"""Plate mascot preview: every move, animating, in light and dark.

    python3 design-canvas/mascot/preview.py

Writes preview.html next to this file (git ignores it; run again to refresh).

The drawings come from the app's asset catalogue, so they cannot drift from the
build. A drawing in drafts/ with the same name wins, which is how a new or
changed piece is shown before it goes into the app.

The motion below is a copy of GymFuel/Design/PlateMascotMoves.swift, in the same
units (degrees, canvas points, seconds). Change both together, or the preview
shows something the app does not do.
"""
import base64
import json
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
ASSETS = HERE.parent.parent / "GymFuel" / "Assets.xcassets" / "Mascot"
DRAFTS = HERE / "drafts"

# Joints on the 300 × 300 canvas, the same numbers as Rig in PlateMascot.swift.
LEFT_SHOULDER, RIGHT_SHOULDER = (67, 155), (233, 155)
LEFT_HIP, RIGHT_HIP = (133, 200), (167, 200)
EYE_LINE, FEET, BELL_HOOK = (150, 117), (150, 270), (262, 22)
LEG_LENGTH = 70

C, L = "cubic", "linear"


def step(amount):
    return [(amount, 0.2, C), (-amount, 0.4, C), (0, 0.2, C)]


def rise(target):
    return [(target, 0.6, C), (target, 1.2, L), (0, 0.6, C), (0, 0.6, L)]


IDLE = {
    "breath": [(1.015, 1.2, C), (1, 1.2, C), (1.015, 1.2, C), (1, 1.2, C)],
    "eyeOpen": [(1, 3.9, L), (0.1, 0.08, L), (1, 0.1, L), (1, 0.72, L)],
}

MOVES = {
    "wave": dict(costume=dict(rightArm="MascotArmRightRaised"), rest={}, tracks=dict(
        rightArm=[(-16, 0.3, C), (10, 0.35, C), (-16, 0.35, C), (10, 0.35, C), (0, 0.35, C), (0, 3.1, L)])),
    "wonder": dict(costume=dict(air="MascotQuestion"), rest=dict(lookX=3, lookY=-3), tracks=dict(
        tilt=[(-5, 0.8, C), (-5, 0.6, L), (3, 0.9, C), (0, 0.7, C)],
        propLift=[(-6, 0.75, C), (0, 0.75, C), (-6, 0.75, C), (0, 0.75, C)])),
    "stretch": dict(costume=dict(rightArm="MascotArmRightRaised", ground="MascotRuler"),
                    rest=dict(rightArm=-8, reach=14), tracks=dict(
        reach=[(14, 0.9, L), (2, 0.4, C), (2, 1, L), (14, 0.7, C)],
        rightArm=[(-8, 0.9, L), (0, 0.4, C), (0, 1, L), (-8, 0.7, C)])),
    "weigh": dict(costume=dict(ground="MascotScale"), rest=dict(lift=-8, lookY=5), tracks=dict(
        lift=[(-28, 0.35, C), (-7, 0.25, C), (-8, 0.2, C), (-8, 2.2, L)],
        squash=[(1, 0.35, L), (0.94, 0.25, C), (1, 0.2, C), (1, 2.2, L)])),
    "walk": dict(costume={}, rest={}, tracks=dict(
        leftLeg=step(16), rightLeg=step(-16), leftArm=step(-16), rightArm=step(16),
        lift=[(-4, 0.2, C), (0, 0.2, C), (-4, 0.2, C), (0, 0.2, C)])),
    "lookAhead": dict(costume=dict(ground="MascotFlag"), rest=dict(lookX=6), tracks=dict(
        lift=[(-8, 0.18, C), (0, 0.18, C), (-8, 0.18, C), (0, 0.18, C), (0, 1.68, L)])),
    "write": dict(costume=dict(leftArm=None, rightArm="MascotArmRightPencil", held="MascotNotepadHold"),
                  rest=dict(lookX=-3, lookY=5), tracks=dict(
        rightArm=[(-4, 0.12, C), (3, 0.12, C), (-4, 0.12, C), (3, 0.12, C), (-4, 0.12, C), (0, 0.12, C), (0, 0.48, L)],
        tilt=[(2, 0.6, C), (0, 0.6, C)])),
    "phone": dict(costume=dict(rightArm=None, held="MascotPhoneHold"), rest=dict(lookX=4, lookY=5), tracks=dict(
        propLift=rise(-5), tilt=rise(3))),
    "bell": dict(costume=dict(air="MascotBell"), rest=dict(lookX=4, lookY=-5), tracks=dict(
        propTurn=[(14, 0.15, C), (-12, 0.2, C), (10, 0.2, C), (-8, 0.2, C), (4, 0.2, C), (0, 0.2, C), (0, 0.85, L)],
        lift=[(-6, 0.15, C), (0, 0.2, C), (0, 1.65, L)])),
    "hug": dict(costume=dict(leftArm=None, rightArm=None, held="MascotHug", eyes="MascotEyesHappy"), rest={},
                tracks=dict(tilt=[(-4, 0.8, C), (4, 1.6, C), (0, 0.8, C)])),
}

COSTUME = dict(leftArm="MascotArmLeft", rightArm="MascotArmRight", held=None, eyes="MascotEyes",
               ground=None, air=None)
POSE = dict(leftArm=0, rightArm=0, leftLeg=0, rightLeg=0, reach=0, lift=0, tilt=0, squash=1,
            lookX=0, lookY=0, propLift=0, propTurn=0, breath=1, eyeOpen=1)


def rotate(v): return f"rotate({v}deg)"
def move_y(v): return f"translateY({v}px)"


# Which element each pose value moves, mirroring the modifiers in PlateMascot.swift.
TARGETS = {
    "leftArm": [("arm-l", rotate, LEFT_SHOULDER)],
    "rightArm": [("arm-r", rotate, RIGHT_SHOULDER)],
    "leftLeg": [("leg-l", rotate, LEFT_HIP)],
    "rightLeg": [("leg-r", rotate, RIGHT_HIP)],
    "reach": [("legs", lambda v: f"scaleY({1 + v / LEG_LENGTH:.4f})", FEET), ("upper", lambda v: move_y(-v), None)],
    "lift": [("lift", move_y, None)],
    "tilt": [("tilt", rotate, FEET)],
    "squash": [("squash", lambda v: f"scaleY({v})", FEET)],
    "lookX": [("look-x", lambda v: f"translateX({v}px)", None)],
    "lookY": [("look-y", move_y, None)],
    "propLift": [("held", move_y, None), ("air-lift", move_y, None)],
    "propTurn": [("air-turn", rotate, BELL_HOOK)],
    "breath": [("breath", lambda v: f"scale({v})", FEET)],
    "eyeOpen": [("blink", lambda v: f"scaleY({v})", EYE_LINE)],
}


def drawing(name, dark):
    """A data URI for the drawing, preferring drafts/, then the dark twin if asked."""
    names = [f"{name}-dark.svg", f"{name}.svg"] if dark else [f"{name}.svg"]
    for file in names:
        if (DRAFTS / file).exists():
            return uri(DRAFTS / file)
    imageset = ASSETS / f"{name}.imageset"
    if not imageset.exists():
        raise SystemExit(f"No drawing called {name} in drafts/ or {ASSETS}")
    images = json.loads((imageset / "Contents.json").read_text())["images"]
    light = next(i["filename"] for i in images if "appearances" not in i)
    dark_file = next((i["filename"] for i in images if "appearances" in i), None)
    return uri(imageset / (dark_file if dark and dark_file else light))


def uri(path):
    return "data:image/svg+xml;base64," + base64.b64encode(path.read_bytes()).decode()


def css_for(scope, tracks, rest, skip=()):
    """Static rest transforms, plus one keyframe animation per animated element."""
    out = []
    cycle = max((sum(d for _, d, _ in t) for t in tracks.values()), default=1)
    for value, targets in TARGETS.items():
        if value in skip:
            continue
        for cls, fn, origin in targets:
            start = rest.get(value, POSE[value])
            rule = f"{scope} .{cls}{{transform:{fn(start)};"
            if origin:
                rule += f"transform-origin:{origin[0]}px {origin[1]}px;"
            if value in tracks:
                name = f"k-{scope.lstrip('.')}-{cls}"
                rule += f"animation:{name} {cycle}s infinite;"
                stops, t, current = [], 0.0, start
                for target, duration, kind in tracks[value]:
                    ease = "ease-in-out" if kind == C else "linear"
                    stops.append(f"{t / cycle * 100:.3f}%{{transform:{fn(current)};animation-timing-function:{ease}}}")
                    t, current = t + duration, target
                stops.append(f"{min(t / cycle, 1) * 100:.3f}%,100%{{transform:{fn(current)}}}")
                out.append(f"@keyframes {name}{{{''.join(stops)}}}")
            out.append(rule + "}")
    return "\n".join(out)


def figure(key, move, dark):
    costume = {**COSTUME, **move["costume"]}

    def img(name):
        return f'<image href="{drawing(name, dark)}" width="300" height="300"/>' if name else ""

    return (f'<svg viewBox="0 0 300 300" role="img" aria-label="{key}">'
            f'{img("MascotShadow")}{img(costume["ground"])}'
            f'<g class="lift"><g class="tilt"><g class="squash"><g class="breath">'
            f'<g class="legs"><g class="leg-l">{img("MascotLegLeft")}</g><g class="leg-r">{img("MascotLegRight")}</g></g>'
            f'<g class="upper">{img("MascotPlate")}'
            f'<g class="look-x"><g class="look-y"><g class="blink">{img(costume["eyes"])}</g></g></g>'
            f'{img("MascotMouth")}<g class="held">{img(costume["held"])}</g>'
            f'<g class="arm-l">{img(costume["leftArm"])}</g><g class="arm-r">{img(costume["rightArm"])}</g>'
            f'</g></g></g></g></g>'
            f'<g class="air-lift"><g class="air-turn">{img(costume["air"])}</g></g></svg>')


def page():
    cards, css = {False: [], True: []}, []
    for key, move in MOVES.items():
        scope = f".m-{key}"
        blinks = {**COSTUME, **move["costume"]}["eyes"] == "MascotEyes"
        css.append(css_for(scope, move["tracks"], move["rest"], skip=("breath", "eyeOpen")))
        css.append(css_for(scope, IDLE if blinks else {"breath": IDLE["breath"]}, {}, skip=tuple(
            v for v in TARGETS if v not in ("breath", "eyeOpen"))))
        for dark in (False, True):
            cards[dark].append(f'<div class="card m-{key}{" dark" if dark else ""}">{figure(key, move, dark)}<p>{key}</p></div>')
    return f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Plate mascot preview</title><style>
body{{margin:0;background:#FBFAF6;color:#1A1917;font-family:-apple-system,system-ui,sans-serif}}
.wrap{{max-width:1100px;margin:0 auto;padding:24px 20px}}
.label{{font:11px ui-monospace,Menlo,monospace;letter-spacing:1.4px;text-transform:uppercase;color:#6E6B64;margin:0 0 12px}}
.row{{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px;margin-bottom:28px}}
.card{{background:#fff;border:1px solid #E3DFD3;border-radius:16px;padding:10px;text-align:center}}
.card.dark{{background:#171612;border-color:#2D2A23;color:#F2F0E8}}
.card svg{{width:100%;height:auto;overflow:visible}} .card p{{margin:2px 0 0;font-size:14px;font-weight:500}}
svg g{{transform-box:view-box}} .note{{font-size:13px;color:#6E6B64}}
@media (prefers-reduced-motion: reduce){{*{{animation:none!important}}}}
{chr(10).join(css)}
</style></head><body><div class="wrap">
<div class="label">Plate mascot · every move · light</div><div class="row">{"".join(cards[False])}</div>
<div class="label">Dark mode</div><div class="row">{"".join(cards[True])}</div>
<p class="note">With Reduce Motion on, each move holds its rest pose, as in the app.</p>
</div></body></html>"""


if __name__ == "__main__":
    out = HERE / "preview.html"
    out.write_text(page())
    print(f"Wrote {out}")
